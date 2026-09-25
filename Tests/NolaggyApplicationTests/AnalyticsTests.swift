import XCTest
@testable import NolaggyApplication

final class AnalyticsTests: XCTestCase {

    final class MockTracker: AnalyticsTracker, @unchecked Sendable {
        private let lock = NSLock()
        private var _events: [AnalyticsEvent] = []

        func track(_ event: AnalyticsEvent) {
            lock.lock()
            defer { lock.unlock() }
            _events.append(event)
        }

        var events: [AnalyticsEvent] {
            lock.lock()
            defer { lock.unlock() }
            return _events
        }
    }

    func testEventNamesMatchFunnelRequirements() {
        XCTAssertEqual(AnalyticsEvent.appOpen.name, "app_open")
        XCTAssertEqual(AnalyticsEvent.gameSelected(gameID: "fortnite").name, "game_selected")
        XCTAssertEqual(AnalyticsEvent.platformSelected(platform: "iphone").name, "platform_selected")
        XCTAssertEqual(AnalyticsEvent.lagcheckStarted(gameID: "fortnite", platform: "iphone", networkType: "wifi", regionID: "sa-east-1").name, "lagcheck_started")
        XCTAssertEqual(AnalyticsEvent.lagcheckCompleted(gameID: "fortnite", platform: "iphone", networkType: "wifi", regionID: "sa-east-1", resultClass: "excellent", durationSeconds: 15.2).name, "lagcheck_completed")
        XCTAssertEqual(AnalyticsEvent.lagcheckInconclusive(gameID: "fortnite", platform: "iphone", networkType: "wifi", regionID: "sa-east-1", reason: "insufficient_samples").name, "lagcheck_inconclusive")
        XCTAssertEqual(AnalyticsEvent.lagcheckCancelled(gameID: "fortnite", platform: "iphone", networkType: "wifi", regionID: "sa-east-1", reason: "user_cancelled").name, "lagcheck_cancelled")
        XCTAssertEqual(AnalyticsEvent.resultViewed(gameID: "fortnite", platform: "iphone", resultClass: "excellent").name, "result_viewed")
        XCTAssertEqual(AnalyticsEvent.retestStarted(gameID: "fortnite", platform: "iphone").name, "retest_started")
    }

    func testEventParametersContainOnlySafeAndApprovedFields() {
        let completed = AnalyticsEvent.lagcheckCompleted(
            gameID: "fortnite",
            platform: "iphone",
            networkType: "wifi",
            regionID: "sa-east-1",
            resultClass: "excellent",
            durationSeconds: 15.2
        )
        let params = completed.parameters
        XCTAssertEqual(params["game_id"], "fortnite")
        XCTAssertEqual(params["platform"], "iphone")
        XCTAssertEqual(params["network_type"], "wifi")
        XCTAssertEqual(params["region_id"], "sa-east-1")
        XCTAssertEqual(params["result_class"], "excellent")
        XCTAssertEqual(params["duration_seconds"], "15.2")

        // Validação estrita de não-vazamento de dados privados ou sensíveis
        XCTAssertNil(params["ip"])
        XCTAssertNil(params["ssid"])
        XCTAssertNil(params["bssid"])
        XCTAssertNil(params["router"])
        XCTAssertNil(params["raw_samples"])
        XCTAssertNil(params["user_id"])
    }

    func testTrackerRecordsEventsInOrder() {
        let tracker = MockTracker()
        tracker.track(.appOpen)
        tracker.track(.gameSelected(gameID: "fortnite"))
        tracker.track(.platformSelected(platform: "iphone"))
        tracker.track(.lagcheckStarted(gameID: "fortnite", platform: "iphone", networkType: "wifi", regionID: "sa-east-1"))
        tracker.track(.lagcheckCompleted(gameID: "fortnite", platform: "iphone", networkType: "wifi", regionID: "sa-east-1", resultClass: "excellent", durationSeconds: 15.0))
        tracker.track(.resultViewed(gameID: "fortnite", platform: "iphone", resultClass: "excellent"))
        tracker.track(.retestStarted(gameID: "fortnite", platform: "iphone"))

        let recorded = tracker.events
        XCTAssertEqual(recorded.count, 7)
        XCTAssertEqual(recorded[0], .appOpen)
        XCTAssertEqual(recorded[1], .gameSelected(gameID: "fortnite"))
        XCTAssertEqual(recorded[2], .platformSelected(platform: "iphone"))
        XCTAssertEqual(recorded[3], .lagcheckStarted(gameID: "fortnite", platform: "iphone", networkType: "wifi", regionID: "sa-east-1"))
        XCTAssertEqual(recorded[5], .resultViewed(gameID: "fortnite", platform: "iphone", resultClass: "excellent"))
        XCTAssertEqual(recorded[6], .retestStarted(gameID: "fortnite", platform: "iphone"))
    }
}
