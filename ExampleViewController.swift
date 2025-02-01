// Initialize SDK
AttributionManager.initialize(
    apiKey: "your_api_key",
    baseURL: "https://reddimon.com/"
)

// Track a purchase event
AttributionManager.shared.trackEvent(AttributionConfig.Events.purchase, parameters: [
    AttributionConfig.Parameters.revenue: 9.99,
    AttributionConfig.Parameters.currency: "USD"
])

// Track user registration
AttributionManager.shared.trackEvent(AttributionConfig.Events.userRegistration, parameters: [
    AttributionConfig.Parameters.userId: "user123",
    AttributionConfig.Parameters.source: "email"
])

// Track user identification
AttributionManager.shared.identifyUser(
    userId: "user123",
    email: "user@example.com"
)

// Track subscription
AttributionManager.shared.trackSubscription(
    subscriptionId: "sub_123",
    type: "premium",
    price: 99.99,
    currency: "USD",
    startDate: Date(),
    endDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
)

// Track subscription conversion
AttributionManager.shared.trackConversion(
    type: AttributionConfig.ConversionTypes.subscription,
    value: 99.99,
    currency: "USD"
)

// Track activation
AttributionManager.shared.trackActivation(
    status: true,
    type: "email_verification"
)

// Track activation
AttributionManager.shared.trackConversion(
    type: AttributionConfig.ConversionTypes.activation
)

// Handle creator's attribution link
func handleCreatorLink(_ url: URL) {
    AttributionManager.shared.handleAttributionLink(url)
}

// Track conversion (e.g., when user subscribes)
func userSubscribed() {
    AttributionManager.shared.trackConversion(
        type: "subscription",
        value: 99.99,
        currency: "USD"
    )
} 