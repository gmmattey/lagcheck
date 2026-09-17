import XCTest
@testable import NolaggyInfrastructure

final class NWPathMonitorNetworkPathObserverTests: XCTestCase {
    func testFirstSnapshotEstablishesBaselineWithoutInvalidatingSession() {
        let detector = NetworkPathChangeDetector()

        XCTAssertFalse(detector.register(wifiSnapshot))
        XCTAssertFalse(detector.register(wifiSnapshot))
    }

    func testInterfaceChangeInvalidatesSession() {
        let detector = NetworkPathChangeDetector()
        _ = detector.register(wifiSnapshot)

        XCTAssertTrue(detector.register(cellularSnapshot))
    }

    func testStatusAndCostChangesInvalidateSession() {
        let disconnected = NetworkPathSnapshot(
            status: .unsatisfied,
            usesWiFi: false,
            usesCellular: false,
            usesWiredEthernet: false,
            usesOther: false,
            isExpensive: false,
            isConstrained: false
        )
        let constrainedWiFi = NetworkPathSnapshot(
            status: .satisfied,
            usesWiFi: true,
            usesCellular: false,
            usesWiredEthernet: false,
            usesOther: false,
            isExpensive: false,
            isConstrained: true
        )
        let detector = NetworkPathChangeDetector()

        _ = detector.register(wifiSnapshot)
        XCTAssertTrue(detector.register(disconnected))
        XCTAssertTrue(detector.register(constrainedWiFi))
    }

    private var wifiSnapshot: NetworkPathSnapshot {
        NetworkPathSnapshot(
            status: .satisfied,
            usesWiFi: true,
            usesCellular: false,
            usesWiredEthernet: false,
            usesOther: false,
            isExpensive: false,
            isConstrained: false
        )
    }

    private var cellularSnapshot: NetworkPathSnapshot {
        NetworkPathSnapshot(
            status: .satisfied,
            usesWiFi: false,
            usesCellular: true,
            usesWiredEthernet: false,
            usesOther: false,
            isExpensive: true,
            isConstrained: false
        )
    }
}
