import ReddimonAttribution  // Publisher imports our SDK

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Publisher initializes our SDK with their API key
        AttributionManager.initialize(
            appId: "com.yourapp.id",
            apiKey: "your_api_key_here",  // They get this from Reddimon dashboard
            baseUrl: "https://reddimon.com"
        )
        
        // Publisher calls our SDK method
        AttributionManager.shared.checkInitialAttribution()
        return true
    }
    
    // Publisher adds this to handle deep links
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Publisher uses our SDK method
        AttributionManager.shared.handleAttributionLink(url)
        return true
    }
}