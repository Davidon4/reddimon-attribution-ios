import XCTest
@testable import ReddimonAttribution

final class AttributionManagerTests: XCTestCase {
    func testInitialization() {
        XCTAssertNotNil(AttributionManager.shared)
    }
    
    static var allTests = [
        ("testInitialization", testInitialization),
    ]
} 