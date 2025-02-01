# iOS Attribution SDK

![Test](https://github.com/Davidon4/reddimon-attribution-ios/workflows/Test/badge.svg)
![SwiftLint](https://github.com/Davidon4/reddimon-attribution-ios/workflows/SwiftLint/badge.svg)

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Davidon4/reddimon-attribution-ios.git", from: "1.0.0")
]
```

### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'ReddimonAttribution'
```

## Usage

Initialize the SDK in your AppDelegate:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    AttributionManager.initialize(
        apiKey: "your_api_key_here",
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
    type: AttributionConfig.ConversionTypes.subscription,
    value: 99.99,
    currency: "USD"
)
```

## Documentation

Full documentation is available [here](https://github.com/Davidon4/reddimon-attribution-ios/)

## License

MIT License
"# reddimon-attribution-ios"
