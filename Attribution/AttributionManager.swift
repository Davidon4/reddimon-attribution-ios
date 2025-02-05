import Foundation
import UIKit
#if canImport(RevenueCat)
import RevenueCat
#endif
#if canImport(StoreKit)
import StoreKit
#endif

public class AttributionManager {
    public static let shared = AttributionManager()
    private let networkService: NetworkService
    private var attributionData: [String: Any]?
    private var appId: String
    
    public static func initialize(apiKey: String, baseUrl: String, appId: String) {
        if let shared = shared as? AttributionManager {
            shared.networkService = NetworkService(baseUrl: baseUrl, apiKey: apiKey)
            shared.appId = appId
        }
    }
    
    private init() {
        self.networkService = NetworkService(baseUrl: "", apiKey: "")
        self.appId = ""
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
        UserDefaults.standard.synchronize()
        
        let appStoreURL = URL(string: "https://apps.apple.com/app/id\(appId)")!
            UIApplication.shared.open(appStoreURL)
        }
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
        
        networkService.sendEvent(installData, endpoint: "installations") { result in
            switch result {
            case .success:
                UserDefaults.standard.removeObject(forKey: "pending_attribution")
                completion(true)
            case .failure(let error):
                print("Failed to track installation: \(error)")
                completion(false)
            }
        }
    }
    
    // Core subscription tracking method
    private func trackSubscription(
        subscriptionId: String,
        planType: String,
        amount: Double,
        currency: String = "USD",
        interval: String  // "monthly" or "yearly"
    ) {
        guard let shortCode = attributionData?["short_code"] as? String else { return }
        
        let subscriptionData: [String: Any] = [
            "short_code": shortCode,
            "subscription_id": subscriptionId,
            "plan_type": planType,
            "amount": amount,
            "currency": currency,
            "status": "active",
            "interval": interval,
            "subscription_date": Date().timeIntervalSince1970
        ]
        
        networkService.sendEvent(subscriptionData, endpoint: "subscriptions") { result in
            switch result {
            case .success:
                print("Subscription tracked successfully")
            case .failure(let error):
                print("Failed to track subscription: \(error)")
            }
        }
    }
    
    // Payment provider specific methods
    #if canImport(StoreKit)
    public func trackStoreKitPurchase(_ transaction: SKPaymentTransaction, _ product: SKProduct) {
        trackSubscription(
            subscriptionId: transaction.transactionIdentifier ?? UUID().uuidString,
            planType: product.productIdentifier,
            amount: product.price.doubleValue,
            currency: product.priceLocale.currencyCode ?? "USD",
            interval: product.subscriptionPeriod?.unit == .year ? "yearly" : "monthly"
        )
    }
    #endif
    
    #if canImport(RevenueCat)
    public func trackRevenueCatPurchase(_ purchase: Purchase) {
        trackSubscription(
            subscriptionId: purchase.purchaseId,
            planType: purchase.productIdentifier,
            amount: purchase.price,
            currency: "USD",
            interval: purchase.periodType == .annual ? "yearly" : "monthly"
        )
    }
    #endif
    
    public func trackStripeSubscription(
        subscriptionId: String,
        planType: String,
        amount: Double,
        interval: String
    ) {
        trackSubscription(
            subscriptionId: subscriptionId,
            planType: planType,
            amount: amount,
            currency: "USD",
            interval: interval
        )
    }
    
    public func checkInitialAttribution() {
        if let attributionData = UserDefaults.standard.dictionary(forKey: "pending_attribution") {
            self.attributionData = attributionData
            trackInstall { success in
                print("Installation tracked: \(success)")
            }
        }
    }
}