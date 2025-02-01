import Foundation

public struct AttributionConfig {
    static let version = "1.0.0"
    
    struct Network {
        static let defaultTimeout: TimeInterval = 30
        static let retryInterval: TimeInterval = 2
        
        struct Endpoints {
            static let install = "installs"
            static let conversion = "conversions"
            static let attribution = "attribution"
        }
    }
    
    struct Parameters {
        // Attribution parameters
        static let referralCode = "referral_code"
        static let creatorId = "creator_id"
        static let campaign = "campaign"
        static let clickId = "click_id"
        
        // Install parameters
        static let installId = "install_id"
        static let deviceId = "device_id"
        static let appId = "app_id"
        
        // Conversion parameters
        static let conversionType = "conversion_type"
        static let conversionValue = "conversion_value"
        static let currency = "currency"
        
        // User parameters
        static let userId = "user_id"
        static let userProperties = "user_properties"
    }
    
    struct ConversionTypes {
        static let subscription = "subscription"
        static let activation = "activation"
        static let purchase = "purchase"
    }
} 