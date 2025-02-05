import Foundation

public struct AttributionConfig {
    static let version = "1.0.6"
    
    struct Network {
        static let defaultTimeout: TimeInterval = 30
        
        struct Endpoints {
            static let install = "installations"
            static let subscription = "subscriptions"
        }
    }
    
    struct Parameters {
        // Core attribution parameters
        static let shortCode = "short_code"
        static let attributionUrl = "attribution_url"
        static let clickTimestamp = "click_timestamp"
        static let installTimestamp = "install_timestamp"
        
        // Installation parameters
        static let platform = "platform"
        static let deviceType = "device_type"
        static let deviceId = "device_id"
        static let installSource = "install_source"
        
        // Subscription parameters
        static let subscriptionId = "subscription_id"
        static let planType = "plan_type"
        static let amount = "amount"
        static let currency = "currency"
        static let status = "status"
        static let interval = "interval"          // "monthly", "yearly"
        static let subscriptionDate = "subscription_date"
    }
    
    struct SubscriptionStatus {
        static let active = "active"
        static let cancelled = "cancelled"
        static let expired = "expired"
    }
} 