import XCTest
@testable import ReddimonAttribution

final class AttributionManagerTests: XCTestCase {
    func testInitialization() {
        XCTAssertNotNil(AttributionManager.shared)
    }
    
    func testHandleAttributionLink() {
        let url = URL(string: "yourapp://install?creator_id=123")!
        AttributionManager.shared.handleAttributionLink(url)
    }
    
    func testTrackConversion() {
        AttributionManager.shared.trackConversion(
            type: "subscription",
            value: 99.99,
            currency: "USD"
        )
    }
    
    static var allTests = [
        ("testInitialization", testInitialization),
        ("testHandleAttributionLink", testHandleAttributionLink),
        ("testTrackConversion", testTrackConversion),
    ]
} 