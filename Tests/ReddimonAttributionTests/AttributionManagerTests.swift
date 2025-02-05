import XCTest
@testable import ReddimonAttribution

final class AttributionManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Initialize with test configuration
        AttributionManager.initialize(
            apiKey: "test_api_key",
            baseURL: "https://api.reddimon.test/v1",
            appId: "123456789"
        )
        
        // Clear any stored attribution data
        UserDefaults.standard.removeObject(forKey: "pending_attribution")
    }
    
    func testInitialization() {
        XCTAssertNotNil(AttributionManager.shared)
    }
    
    func testHandleAttributionLink() {
        // Setup
        let url = URL(string: "reddimon://attribution/c/creator_name/app_name/j44igo")!
        
        // Execute
        AttributionManager.shared.handleAttributionLink(url)
        
        // Verify
        let attributionData = UserDefaults.standard.dictionary(forKey: "pending_attribution")
        XCTAssertNotNil(attributionData)
        XCTAssertEqual(attributionData?["short_code"] as? String, "j44igo")
        XCTAssertNotNil(attributionData?["attribution_url"])
        XCTAssertNotNil(attributionData?["click_timestamp"])
    }
    
    func testInvalidAttributionLink() {
        // Setup
        let invalidUrl = URL(string: "reddimon://invalid/path")!
        
        // Execute
        AttributionManager.shared.handleAttributionLink(invalidUrl)
        
        // Verify
        let attributionData = UserDefaults.standard.dictionary(forKey: "pending_attribution")
        XCTAssertNil(attributionData)
    }
    
    func testCheckInitialAttribution() {
        // Setup
        let expectation = XCTestExpectation(description: "Installation tracked")
        let testData: [String: Any] = [
            "short_code": "j44igo",
            "attribution_url": "reddimon://attribution/c/creator_name/app_name/j44igo",
            "click_timestamp": Date().timeIntervalSince1970
        ]
        UserDefaults.standard.set(testData, forKey: "pending_attribution")
        
        // Execute
        AttributionManager.shared.checkInitialAttribution()
        
        // Verify through network service response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let storedData = UserDefaults.standard.dictionary(forKey: "pending_attribution")
            XCTAssertNil(storedData) // Should be cleared after successful tracking
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNetworkServiceConfiguration() {
        // Setup
        let expectation = XCTestExpectation(description: "Network request made")
        let testData: [String: Any] = [
            "short_code": "j44igo",
            "attribution_url": "test_url",
            "click_timestamp": Date().timeIntervalSince1970
        ]
        
        // Execute
        let networkService = NetworkService(
            baseURL: "https://api.reddimon.test/v1",
            apiKey: "test_api_key",
            appId: "123456789"
        )
        
        networkService.sendEvent(testData, endpoint: "installations") { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Network request failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    static var allTests = [
        ("testInitialization", testInitialization),
        ("testHandleAttributionLink", testHandleAttributionLink),
        ("testInvalidAttributionLink", testInvalidAttributionLink),
        ("testCheckInitialAttribution", testCheckInitialAttribution),
        ("testNetworkServiceConfiguration", testNetworkServiceConfiguration)
    ]
}