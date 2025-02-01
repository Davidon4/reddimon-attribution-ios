import XCTest
@testable import ReddimonAttribution

final class AttributionManagerTests: XCTestCase {
    func testInitialization() {
        XCTAssertNotNil(AttributionManager.shared)
    }
    
    func testHandleAttributionLink() {
        // Setup
        let url = URL(string: "reddimon://attribution?creator_id=123&publisher_id=456&campaign_id=789&source=instagram")!
        
        // Execute
        AttributionManager.shared.handleAttributionLink(url)
        
        // Verify
        let attributionData = AttributionManager.shared.getAttributionData()
        XCTAssertEqual(attributionData["creator_id"] as? String, "123")
        XCTAssertEqual(attributionData["publisher_id"] as? String, "456")
        XCTAssertEqual(attributionData["campaign_id"] as? String, "789")
        XCTAssertEqual(attributionData["source"] as? String, "instagram")
    }
    
    // Test multiple creators
    func testMultipleCreatorLinks() {
        // Creator 1
        let url1 = URL(string: "reddimon://attribution?creator_id=123&publisher_id=456&campaign_id=789&source=instagram")!
        AttributionManager.shared.handleAttributionLink(url1)
        
        // Creator 2
        let url2 = URL(string: "reddimon://attribution?creator_id=456&publisher_id=456&campaign_id=789&source=twitter")!
        AttributionManager.shared.handleAttributionLink(url2)
    }
    
    func testTrackConversion() {
        // Setup
        let expectation = XCTestExpectation(description: "Conversion tracked")
        
        // Execute
        AttributionManager.shared.trackConversion(
            type: "subscription",
            value: 99.99,
            currency: "USD"
        )
        
        // Verify through your backend response
        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCampaignTracking() {
        // Setup
        let campaignId = "summer2024"
        let expectation = XCTestExpectation(description: "Campaign event tracked")
        
        // Track campaign event
        AttributionManager.shared.trackCampaignEvent(
            campaignId: campaignId,
            eventType: "link_click",
            data: [
                "creator_id": "123",
                "platform": "instagram"
            ]
        )
        
        // Get campaign stats
        AttributionManager.shared.getCampaignStats(campaignId: campaignId) { stats in
            XCTAssertNotNil(stats)
            XCTAssertEqual(stats?["campaign_id"] as? String, campaignId)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    static var allTests = [
        ("testInitialization", testInitialization),
        ("testHandleAttributionLink", testHandleAttributionLink),
        ("testMultipleCreatorLinks", testMultipleCreatorLinks),
        ("testTrackConversion", testTrackConversion),
        ("testCampaignTracking", testCampaignTracking),
    ]
} 