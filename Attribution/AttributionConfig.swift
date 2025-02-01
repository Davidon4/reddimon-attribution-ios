import Foundation

public struct AttributionConfig {
    static let version = "1.0.1"
    
    struct Network {
        static let defaultTimeout: TimeInterval = 30
        
        struct Endpoints {
            static let install = "installs"
            static let conversion = "conversions"
            static let attribution = "attribution"
        }
    }
    
    struct Parameters {
        // Core attribution parameters
        static let creatorId = "creator_id"
        static let publisherId = "publisher_id"
        static let campaignId = "campaign_id"
        static let source = "source"
        
        // Event parameters
        static let deviceId = "device_id"
        static let timestamp = "timestamp"
        static let value = "value"
        static let currency = "currency"
    }
    
    struct ConversionTypes {
        static let subscription = "subscription"
        static let activation = "activation"
        static let purchase = "purchase"
    }
} 