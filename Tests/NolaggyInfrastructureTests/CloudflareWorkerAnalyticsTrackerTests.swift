import XCTest
import NolaggyApplication
@testable import NolaggyInfrastructure

final class CloudflareWorkerAnalyticsTrackerTests: XCTestCase {

    func testInstallationIDIsPersistedDeterministically() {
        let suiteName = "test.lagcheck.analytics.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let id1 = CloudflareWorkerAnalyticsTracker.getOrCreateInstallationID(userDefaults: userDefaults)
        XCTAssertNotNil(UUID(uuidString: id1))

        let id2 = CloudflareWorkerAnalyticsTracker.getOrCreateInstallationID(userDefaults: userDefaults)
        XCTAssertEqual(id1, id2, "O mesmo installation ID deve ser reutilizado")
    }

    func testTrackerDispatchesValidPayloadsWithoutCrashing() {
        let tracker = CloudflareWorkerAnalyticsTracker()
        
        // Verifica que o disparo de todos os eventos canônicos não gera crash
        tracker.track(.appOpen)
        tracker.track(.lagcheckStarted(gameID: "fortnite", platform: "iphone", networkType: "wifi", regionID: "sa-east-1"))
        tracker.track(.resultViewed(gameID: "fortnite", platform: "iphone", resultClass: "ready"))
        tracker.track(.retestStarted(gameID: "fortnite", platform: "iphone"))
    }
}
