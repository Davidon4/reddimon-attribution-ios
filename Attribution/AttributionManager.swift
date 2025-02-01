import Foundation
import UIKit

/// AttributionManager is the main class for handling app attribution and conversion tracking.
/// It provides methods to track app installations, conversions, and user events while maintaining
/// attribution data from promotional links.
public class AttributionManager {
    /// Shared instance of the AttributionManager
    public static let shared = AttributionManager()
    
    private let networkService: NetworkService
    private let eventQueue: DispatchQueue
    private var pendingEvents: [[String: Any]] = []
    private let maxRetries = 3
    
    private var installAttributed = false
    private var attributionData: [String: Any] = [:]
    private var referralData: [String: String]?
    
    // MARK: - Initialization
    
    /// Initializes the Attribution SDK with your API credentials
    /// - Parameters:
    ///   - apiKey: Your unique API key provided by the attribution service
    ///   - baseURL: The base URL of your attribution service API
    /// - Example:
    ///   ```swift
    ///   AttributionManager.initialize(
    ///       apiKey: "your_api_key_here",
    ///       baseURL: "https://api.yourservice.com/v1"
    ///   )
    ///   ```
    public static func initialize(apiKey: String, baseURL: String) {
        if let shared = shared as? AttributionManager {
            shared.networkService = NetworkService(baseURL: baseURL, apiKey: apiKey)
        }
    }
    
    private init() {
        self.networkService = NetworkService(baseURL: "", apiKey: "")
        self.eventQueue = DispatchQueue(label: "com.attribution.eventQueue")
    }
    
    // MARK: - Attribution Handling
    
    /// Handles attribution links when users open the app through a promotional link
    /// - Parameter url: The URL containing attribution parameters
    /// - Note: This method should be called in your AppDelegate's URL handling methods
    /// - Example URL format: yourapp://install?creator_id=123&campaign=summer
    public func handleAttributionLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return
        }
        
        var attributionParams: [String: String] = [:]
        
        for item in queryItems {
            attributionParams[item.name] = item.value
        }
        
        // Store attribution data for later use
        self.referralData = attributionParams
        
        // If already installed, send attribution immediately
        if installAttributed {
            sendAttributionData()
        }
    }
    
    private func sendAttributionData() {
        guard let referralData = self.referralData else { return }
        
        var attributionEvent: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "platform": "ios",
            "app_id": Bundle.main.bundleIdentifier ?? "",
            "device_id": UIDevice.current.identifierForVendor?.uuidString ?? ""
        ]
        
        // Add referral data
        for (key, value) in referralData {
            attributionEvent[key] = value
        }
        
        sendEvent(attributionEvent, endpoint: AttributionConfig.Network.Endpoints.attribution)
    }
    
    // MARK: - Install Tracking
    
    // Add basic fraud prevention
    private struct DeviceFingerprint {
        let deviceId: String
        let model: String
        let systemVersion: String
        let screenResolution: String
        let timezone: String
        let language: String
    }
    
    private func generateDeviceFingerprint() -> DeviceFingerprint {
        let screen = UIScreen.main.bounds
        return DeviceFingerprint(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "",
            model: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            screenResolution: "\(screen.width)x\(screen.height)",
            timezone: TimeZone.current.identifier,
            language: Locale.current.languageCode ?? ""
        )
    }
    
    // Add IP address tracking (for fraud detection)
    private func getPublicIPAddress(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.ipify.org?format=json") else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, as: [String: String].self),
                  let ip = json["ip"] else {
                completion(nil)
                return
            }
            completion(ip)
        }.resume()
    }
    
    // Enhanced install tracking with fraud prevention
    /// Tracks app installation with attribution data
    /// - Parameter completion: Callback indicating success or failure
    /// - Note: Should be called once when the app is first launched
    /// - Example:
    ///   ```swift
    ///   AttributionManager.shared.trackInstall { success in
    ///       if success {
    ///           print("Installation tracked successfully")
    ///       }
    ///   }
    ///   ```
    public func trackInstall(completion: @escaping (Bool) -> Void) {
        guard !installAttributed else {
            completion(false)
            return
        }
        
        let fingerprint = generateDeviceFingerprint()
        getPublicIPAddress { [weak self] ipAddress in
            guard let self = self else { return }
            
            var installData: [String: Any] = [
                "install_timestamp": Date().timeIntervalSince1970,
                "device_type": fingerprint.model,
                "ios_version": fingerprint.systemVersion,
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
                "device_id": fingerprint.deviceId,
                "app_id": Bundle.main.bundleIdentifier ?? "",
                "screen_resolution": fingerprint.screenResolution,
                "timezone": fingerprint.timezone,
                "language": fingerprint.language
            ]
            
            if let ip = ipAddress {
                installData["ip_address"] = ip
            }
            
            // Add referral data if available
            if let referralData = self.referralData {
                for (key, value) in referralData {
                    installData[key] = value
                }
            }
            
            self.sendEvent(installData, endpoint: AttributionConfig.Network.Endpoints.install) { [weak self] result in
                switch result {
                case .success:
                    self?.installAttributed = true
                    completion(true)
                case .failure:
                    completion(false)
                }
            }
        }
    }
    
    // Add session tracking
    private var sessionStartTime: Date?
    
    /// Starts tracking a new user session
    /// - Note: Call this method when your app becomes active
    public func startSession() {
        sessionStartTime = Date()
        trackEvent("session_start", parameters: ["session_id": UUID().uuidString])
    }
    
    /// Ends the current user session
    /// - Note: Call this method when your app enters background
    public func endSession() {
        guard let startTime = sessionStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        trackEvent("session_end", parameters: [
            "duration": duration,
            "session_id": UUID().uuidString
        ])
        sessionStartTime = nil
    }
    
    // Add user value tracking
    public func trackUserValue(value: Double, currency: String) {
        let valueData: [String: Any] = [
            "lifetime_value": value,
            "currency": currency,
            "timestamp": Date().timeIntervalSince1970
        ]
        trackEvent("user_value", parameters: valueData)
    }
    
    // MARK: - Conversion Tracking
    
    /// Tracks user conversions such as subscriptions or feature activations
    /// - Parameters:
    ///   - type: Type of conversion (e.g., "subscription", "activation")
    ///   - value: Monetary value of the conversion (optional)
    ///   - currency: Currency code for the value (optional)
    /// - Example:
    ///   ```swift
    ///   // Track subscription
    ///   AttributionManager.shared.trackConversion(
    ///       type: AttributionConfig.ConversionTypes.subscription,
    ///       value: 99.99,
    ///       currency: "USD"
    ///   )
    ///   
    ///   // Track activation
    ///   AttributionManager.shared.trackConversion(
    ///       type: AttributionConfig.ConversionTypes.activation
    ///   )
    ///   ```
    public func trackConversion(type: String, value: Double? = nil, currency: String? = nil) {
        var conversionData: [String: Any] = [
            AttributionConfig.Parameters.conversionType: type,
            "timestamp": Date().timeIntervalSince1970,
            "device_id": UIDevice.current.identifierForVendor?.uuidString ?? ""
        ]
        
        if let value = value {
            conversionData[AttributionConfig.Parameters.conversionValue] = value
        }
        
        if let currency = currency {
            conversionData[AttributionConfig.Parameters.currency] = currency
        }
        
        // Add referral data if available
        if let referralData = self.referralData {
            for (key, value) in referralData {
                conversionData[key] = value
            }
        }
        
        sendEvent(conversionData, endpoint: AttributionConfig.Network.Endpoints.conversion)
    }
    
    // MARK: - Event Tracking
    
    private func sendEvent(_ eventData: [String: Any], endpoint: String, retryCount: Int = 0) {
        networkService.sendEvent(eventData, endpoint: endpoint) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                print("Event sent successfully: \(eventData)")
                
            case .failure(let error):
                print("Failed to send event: \(error)")
                
                // Retry logic for failed events
                if retryCount < self.maxRetries {
                    DispatchQueue.global().asyncAfter(deadline: .now() + pow(2.0, Double(retryCount))) {
                        self.sendEvent(eventData, endpoint: endpoint, retryCount: retryCount + 1)
                    }
                } else {
                    // Store failed event for later retry
                    self.eventQueue.async {
                        self.pendingEvents.append(eventData)
                    }
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    public func trackEvent(_ eventName: String, parameters: [String: Any]? = nil) {
        var eventData: [String: Any] = [
            "event_name": eventName,
            "timestamp": Date().timeIntervalSince1970,
            "sdk_version": AttributionConfig.version,
            "platform": "ios",
            "device_info": [
                "model": UIDevice.current.model,
                "system_version": UIDevice.current.systemVersion,
                "device_id": UIDevice.current.identifierForVendor?.uuidString ?? ""
            ]
        ]
        
        if let userId = self.userId {
            eventData["user_id"] = userId
        }
        
        if let params = parameters {
            eventData["parameters"] = params
        }
        
        sendEvent(eventData, endpoint: "events")
    }
    
    // Track subscription
    public func trackSubscription(subscriptionId: String,
                                type: String,
                                price: Double,
                                currency: String,
                                startDate: Date,
                                endDate: Date?) {
        let subscriptionData: [String: Any] = [
            AttributionConfig.Parameters.subscriptionId: subscriptionId,
            AttributionConfig.Parameters.subscriptionType: type,
            AttributionConfig.Parameters.price: price,
            AttributionConfig.Parameters.currency: currency,
            AttributionConfig.Parameters.startDate: startDate.timeIntervalSince1970
        ]
        
        var finalData = subscriptionData
        if let endDate = endDate {
            finalData[AttributionConfig.Parameters.endDate] = endDate.timeIntervalSince1970
        }
        
        trackEvent(AttributionConfig.Events.subscription, parameters: finalData)
    }
    
    // Track activation
    public func trackActivation(status: Bool, type: String) {
        let activationData: [String: Any] = [
            AttributionConfig.Parameters.activationStatus: status,
            AttributionConfig.Parameters.activationDate: Date().timeIntervalSince1970,
            AttributionConfig.Parameters.activationType: type
        ]
        
        trackEvent(AttributionConfig.Events.activation, parameters: activationData)
    }
    
    // Track user identification
    public func identifyUser(userId: String, email: String?) {
        self.userId = userId
        
        var userData: [String: Any] = [
            AttributionConfig.Parameters.userId: userId,
            AttributionConfig.Parameters.deviceId: UIDevice.current.identifierForVendor?.uuidString ?? ""
        ]
        
        if let email = email {
            userData[AttributionConfig.Parameters.email] = email
        }
        
        trackEvent(AttributionConfig.Events.userIdentification, parameters: userData)
    }
    
    public func getAttributionData() -> [String: Any] {
        return attributionData
    }
    
    // MARK: - Retry Management
    
    public func retryFailedEvents() {
        eventQueue.async { [weak self] in
            guard let self = self else { return }
            
            let events = self.pendingEvents
            self.pendingEvents.removeAll()
            
            for event in events {
                self.sendEvent(event, endpoint: "events")
            }
        }
    }
} 