# Reddimon Attribution SDK

![Test](https://github.com/Davidon4/reddimon-attribution-ios/workflows/Test/badge.svg)
![SwiftLint](https://github.com/Davidon4/reddimon-attribution-ios/workflows/SwiftLint/badge.svg)

## Installation

### Swift Package Manager

In Xcode:

1. Go to File → Add Packages
2. Enter: `https://github.com/Davidon4/reddimon-attribution-ios`
3. Select version: 1.0.2 or higher

## Usage

Initialize the SDK in your AppDelegate:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    AttributionManager.initialize(
        apiKey: "your_api_key",
        baseURL: "https://reddimon.com/"
    )
    return true
}
```

Handle attribution links:

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    AttributionManager.shared.handleAttributionLink(url)
    return true
}
```

Track conversions:

```swift
AttributionManager.shared.trackConversion(
    type: "subscription",
    value: 99.99,
    currency: "USD"
)
```

## Documentation

Full documentation is available [here](https://github.com/Davidon4/reddimon-attribution-ios/)

## License

MIT License
