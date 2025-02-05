# Reddimon Attribution SDK

![Test](https://github.com/Davidon4/reddimon-attribution-ios/workflows/Test/badge.svg)
![SwiftLint](https://github.com/Davidon4/reddimon-attribution-ios/workflows/SwiftLint/badge.svg)

## Installation

### Swift Package Manager

In Xcode:

1. Go to File → Add Packages
2. Enter: `https://github.com/Davidon4/reddimon-attribution-ios`
3. Select version: 1.0.5 or higher

## Setup

1. Initialize the SDK in your AppDelegate:

```swift
import ReddimonAttribution

class AppDelegate: UIResponder, UIApplicationDelegate {
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    AttributionManager.initialize(
        apiKey: "your_api_key",
        baseURL: "https://reddimon.com/"
    )
    AttributionManager.shared.checkInitialAttribution()
    return true
}

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AttributionManager.shared.handleAttributionLink(url)
        return true
        }
}
```

2. Track subscriptions based on your payment provider:

### App Store (StoreKit)

```swift
AttributionManager.shared.trackStoreKitPurchase(transaction, product)
```

### RevenueCat

```swift
AttributionManager.shared.trackRevenueCatPurchase(purchase)
```

### Stripe

```swift
AttributionManager.shared.trackStripeSubscription(
    subscriptionId: "sub_123",
    planType: "premium",
    amount: 9.99,
    interval: "monthly"
)
```

## Support

For issues and questions, please contact juggernaut.dev1@gmail.com

## License

MIT License
