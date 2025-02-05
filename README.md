# Reddimon Attribution SDK

Track app installations and subscriptions from creator referrals.

![Test](https://github.com/Davidon4/reddimon-attribution-ios/workflows/Test/badge.svg)
![SwiftLint](https://github.com/Davidon4/reddimon-attribution-ios/workflows/SwiftLint/badge.svg)

## Installation

### Swift Package Manager

1. In Xcode, go to File → Add Packages
2. Enter: `https://github.com/Davidon4/reddimon-attribution-ios`
3. Select version: `v1.0.7`

## Setup

1. Initialize the SDK in your AppDelegate:

```swift
import ReddimonAttribution

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AttributionManager.initialize(
            apiKey: "your_api_key", // From Reddimon dashboard
            baseUrl: "https://reddimon.com",
            appId: "your_app_store_id"  // Your App Store ID (e.g., "1234567890")
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

## Track Subscriptions

### App Store (StoreKit)

```swift
// In your SKPaymentTransactionObserver
func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
        if transaction.transactionState == .purchased {
            if let product = // your product lookup logic {
                AttributionManager.shared.trackStoreKitPurchase(transaction, product)
            }
        }
        queue.finishTransaction(transaction)
    }
```

### Web-based Payments (Stripe, etc.)

```swift
// In your WKNavigationDelegate
func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if let url = navigationAction.request.url,
       url.scheme == "your-app-scheme",
       url.path == "/subscription/success" {

        // Extract subscription details from URL
        // Example URL: your-app-scheme://subscription/success?subscription_id=sub_123&plan=premium&amount=9.99&interval=monthly
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let queryItems = components?.queryItems ?? []

        let subscriptionId = queryItems.first(where: { $0.name == "subscription_id" })?.value ?? ""
        let planType = queryItems.first(where: { $0.name == "plan" })?.value ?? ""
        let amount = Double(queryItems.first(where: { $0.name == "amount" })?.value ?? "0") ?? 0
        let interval = queryItems.first(where: { $0.name == "interval" })?.value ?? "monthly"

        AttributionManager.shared.trackWebPurchase(
            subscriptionId: subscriptionId,
            planType: planType,
            amount: amount,
            interval: interval
        )
    }
    decisionHandler(.allow)
}
```

## Requirements

- iOS 13.0+
- Xcode 13.0+
- Swift 5.5+

## Notes

- For RevenueCat, Superwall, or SwiftyStoreKit users: Track the underlying StoreKit transaction using `trackStoreKitPurchase`
- Web payments require proper URL scheme configuration in Info.plist

## Support

For issues and questions, please contact support@reddimon.com

## License

MIT License
