import Foundation
import UIKit
#if canImport(StoreKit)
import StoreKit
#endif

public class AttributionManager {
    public static let shared = AttributionManager()
    private let networkService: NetworkService
    
    // Thread safety
    private let queue = DispatchQueue(label: "com.reddimon.attribution", attributes: .concurrent)
    
    // Event queue for failed requests
    private var eventQueue: [[String: Any]] = []
    private let maxQueueSize = 100
    private let maxRetries = 3
    private var isProcessingQueue = false
    
    private var _attributionData: [String: Any]?
    private var attributionData: [String: Any]? {
        get {
            return queue.sync { _attributionData }
        }
        set {
            queue.async(flags: .barrier) {
                self._attributionData = newValue
                // Persist attribution data when it changes
                if let attributionData = newValue {
                    UserDefaults.standard.set(attributionData, forKey: "attribution_data")
                }
            }
        }
    }
    private var appId: String?
    
    public static func initialize(appId: String, apiKey: String, baseUrl: String) {
        shared.appId = appId
        shared.networkService = NetworkService(baseUrl: baseUrl, apiKey: apiKey, appId: appId)
        // Load attribution data during initialization
        shared.loadAttributionData()
        // Load any queued events from previous sessions
        shared.loadEventQueue()
        // Start processing any queued events
        shared.processEventQueue()
        
        // Register for app lifecycle notifications to process queue when app becomes active
        NotificationCenter.default.addObserver(
            shared,
            selector: #selector(shared.applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func applicationDidBecomeActive() {
        // Process any queued events when the app becomes active
        processEventQueue()
    }
    
    private init() {
        self.networkService = NetworkService(baseUrl: "", apiKey: "", appId: "")
        // Load attribution data during initialization
        loadAttributionData()
        // Load any queued events from previous sessions
        loadEventQueue()
    }
    
    private func loadAttributionData() {
        queue.async(flags: .barrier) {
            // First check for pending attribution (new install/click)
            if let pendingData = UserDefaults.standard.dictionary(forKey: "pending_attribution") {
                self._attributionData = pendingData
            } 
            // Then fall back to stored attribution data (for returning users)
            else if let storedData = UserDefaults.standard.dictionary(forKey: "attribution_data") {
                self._attributionData = storedData
            }
        }
    }
    
    // MARK: - Event Queue Management
    
    private func loadEventQueue() {
        if let savedQueue = UserDefaults.standard.array(forKey: "attribution_event_queue") as? [[String: Any]] {
            queue.async(flags: .barrier) {
                self.eventQueue = savedQueue
            }
        }
    }
    
    private func saveEventQueue() {
        queue.async {
            UserDefaults.standard.set(self.eventQueue, forKey: "attribution_event_queue")
        }
    }
    
    private func addToEventQueue(event: [String: Any], endpoint: String) {
        queue.async(flags: .barrier) {
            // Add retry count and endpoint to the event data
            var eventWithMetadata = event
            eventWithMetadata["_endpoint"] = endpoint
            eventWithMetadata["_retryCount"] = 0
            eventWithMetadata["_timestamp"] = Date().timeIntervalSince1970
            
            // Add to queue
            if self.eventQueue.count < self.maxQueueSize {
                self.eventQueue.append(eventWithMetadata)
                self.saveEventQueue()
                
                // Start processing the queue if not already processing
                if !self.isProcessingQueue {
                    DispatchQueue.main.async {
                        self.processEventQueue()
                    }
                }
            } else {
                print("Warning: Attribution event queue is full, dropping oldest event")
                // Remove oldest event and add new one
                self.eventQueue.removeFirst()
                self.eventQueue.append(eventWithMetadata)
                self.saveEventQueue()
            }
        }
    }
    
    private func processEventQueue() {
        queue.async(flags: .barrier) {
            // If already processing or queue is empty, return
            if self.isProcessingQueue || self.eventQueue.isEmpty {
                return
            }
            
            self.isProcessingQueue = true
            
            // Process the first event in the queue
            let event = self.eventQueue.first!
            let retryCount = event["_retryCount"] as? Int ?? 0
            let endpoint = event["_endpoint"] as? String ?? "events"
            
            // Create a copy without the metadata fields
            var eventCopy = event
            eventCopy.removeValue(forKey: "_endpoint")
            eventCopy.removeValue(forKey: "_retryCount")
            eventCopy.removeValue(forKey: "_timestamp")
            
            self.networkService.sendEvent(eventCopy, endpoint: endpoint) { [weak self] result in
                guard let self = self else { return }
                
                self.queue.async(flags: .barrier) {
                    switch result {
                    case .success:
                        // Event sent successfully, remove from queue
                        if !self.eventQueue.isEmpty {
                            self.eventQueue.removeFirst()
                            self.saveEventQueue()
                        }
                        
                        // Continue processing the queue
                        self.isProcessingQueue = false
                        if !self.eventQueue.isEmpty {
                            DispatchQueue.main.async {
                                self.processEventQueue()
                            }
                        }
                        
                    case .failure(let error):
                        // Check if we should retry
                        if retryCount < self.maxRetries {
                            // Update retry count and move to the end of the queue
                            if !self.eventQueue.isEmpty {
                                var updatedEvent = self.eventQueue.removeFirst()
                                updatedEvent["_retryCount"] = retryCount + 1
                                
                                // Use exponential backoff for retries
                                let delaySeconds = pow(2.0, Double(retryCount)) * 1.0
                                
                                // Add back to queue after delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) {
                                    self.queue.async(flags: .barrier) {
                                        self.eventQueue.append(updatedEvent)
                                        self.saveEventQueue()
                                        self.isProcessingQueue = false
                                        self.processEventQueue()
                                    }
                                }
                            }
                        } else {
                            // Max retries reached, remove from queue
                            print("Error: Failed to send event after \(self.maxRetries) retries: \(error)")
                            if !self.eventQueue.isEmpty {
                                self.eventQueue.removeFirst()
                                self.saveEventQueue()
                            }
                            
                            // Continue processing the queue
                            self.isProcessingQueue = false
                            if !self.eventQueue.isEmpty {
                                DispatchQueue.main.async {
                                    self.processEventQueue()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func handleAttributionLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.path.starts(with: "/c/") else {
            return
        }
        
        let pathComponents = components.path.split(separator: "/")
        guard pathComponents.count == 4 else { return }
        
        let shortCode = String(pathComponents[3])
        
        let attributionData: [String: Any] = [
            "short_code": shortCode,
            "attribution_url": url.absoluteString,
            "click_timestamp": Date().timeIntervalSince1970
        ]
        
        UserDefaults.standard.set(attributionData, forKey: "pending_attribution")
        
        // Also update the instance variable
        self.attributionData = attributionData
        
        guard let appId = self.appId, !appId.isEmpty else {
            print("Error: App ID not set. Make sure to call AttributionManager.initialize() first.")
            return
        }
        
        let appStoreURL = URL(string: "https://apps.apple.com/app/id\(appId)")!
        UIApplication.shared.open(appStoreURL)
    }
    
    private func trackInstall(completion: @escaping (Bool) -> Void) {
        guard let attributionData = UserDefaults.standard.dictionary(forKey: "pending_attribution"),
              let shortCode = attributionData["short_code"] as? String else {
            completion(false)
            return
        }
        
        let installData: [String: Any] = [
            "short_code": shortCode,
            "platform": "ios",
            "device_type": UIDevice.current.model,
            "attribution_url": attributionData["attribution_url"] as? String ?? "",
            "click_timestamp": attributionData["click_timestamp"] as? TimeInterval ?? 0,
            "install_timestamp": Date().timeIntervalSince1970,
            "install_source": "app_store",
            "device_id": UIDevice.current.identifierForVendor?.uuidString ?? ""
        ]
        
        // Add to queue and process immediately
        addToEventQueue(event: installData, endpoint: AttributionConfig.Network.Endpoints.install)
        
        // Remove from pending but keep in attribution_data
        UserDefaults.standard.removeObject(forKey: "pending_attribution")
        
        // Make sure we keep the attribution data for future events
        self.attributionData = attributionData
        
        // Since we're using a queue now, we'll consider this successful
        completion(true)
    }
    
    // Core subscription tracking method
    private func trackSubscription(
        subscriptionId: String,
        planType: String,
        amount: Double,
        currency: String = "USD",
        interval: String  // "monthly" or "yearly"
    ) {
        // Load attribution data if not already loaded
        if attributionData == nil {
            loadAttributionData()
        }
        
        // Use a local copy to avoid race conditions
        let localAttributionData = queue.sync { self._attributionData }
        
        guard let attributionData = localAttributionData,
              let shortCode = attributionData["short_code"] as? String else {
            print("Error: No attribution data available for subscription tracking")
            return
        }
        
        let subscriptionData: [String: Any] = [
            "short_code": shortCode,
            "subscription_id": subscriptionId,
            "plan_type": planType,
            "amount": amount,
            "currency": currency,
            "status": AttributionConfig.SubscriptionStatus.active,
            "interval": interval,
            "subscription_date": Date().timeIntervalSince1970
        ]
        
        // Add to queue and process
        addToEventQueue(event: subscriptionData, endpoint: AttributionConfig.Network.Endpoints.subscription)
    }
    
    // StoreKit-based subscriptions (App Store)
    #if canImport(StoreKit)
    public func trackStoreKitPurchase(_ transaction: SKPaymentTransaction, _ product: SKProduct) {
        // Safely handle potential nil values
        let transactionId = transaction.transactionIdentifier ?? UUID().uuidString
        let productId = product.productIdentifier
        let price = product.price.doubleValue
        let currency = product.priceLocale.currencyCode ?? "USD"
        
        // Safely determine interval
        var interval = "monthly" // Default
        if #available(iOS 11.2, *), let period = product.subscriptionPeriod {
            interval = period.unit == .year ? "yearly" : "monthly"
        }
        
        trackSubscription(
            subscriptionId: transactionId,
            planType: productId,
            amount: price,
            currency: currency,
            interval: interval
        )
    }
    #endif
    
    // Web-based subscriptions (Stripe, etc.)
    public func trackWebPurchase(
        subscriptionId: String,
        planType: String,
        amount: Double,
        interval: String
    ) {
        trackSubscription(
            subscriptionId: subscriptionId,
            planType: planType,
            amount: amount,
            interval: interval
        )
    }
    
    public func checkInitialAttribution() {
        if let pendingAttributionData = UserDefaults.standard.dictionary(forKey: "pending_attribution") {
            self.attributionData = pendingAttributionData
            trackInstall { success in
                print("Installation tracked: \(success)")
            }
        }
    }
    
    // MARK: - Public Utilities
    
    /// Manually retry sending any queued events
    public func retryQueuedEvents() {
        processEventQueue()
    }
    
    /// Get the number of events currently in the queue
    public func getQueuedEventCount() -> Int {
        return queue.sync { eventQueue.count }
    }
    
    /// Clear all queued events (use with caution)
    public func clearEventQueue() {
        queue.async(flags: .barrier) {
            self.eventQueue.removeAll()
            self.saveEventQueue()
        }
    }
}