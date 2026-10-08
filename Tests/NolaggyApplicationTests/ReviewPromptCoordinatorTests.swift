import XCTest
@testable import NolaggyApplication
@testable import NolaggyDomain

final class ReviewPromptCoordinatorTests: XCTestCase {
    private let baseDate = Date(timeIntervalSince1970: 1700000000)

    func testCoordinatorAccumulatesReadyChecksAndTriggersOnThird() {
        let store = InMemoryReviewPromptStore()
        let coordinator = ReviewPromptCoordinator(
            store: store,
            appVersionProvider: { "1.0.0" }
        )

        // 1º check com .ready -> false
        let p1 = coordinator.recordMeasurementCompleted(verdict: .ready, now: baseDate)
        XCTAssertFalse(p1)
        XCTAssertEqual(coordinator.currentState().successfulReadyChecksCount, 1)

        // Check com .caution, .notReady ou .inconclusive -> não incrementa readyCount e retorna false
        XCTAssertFalse(coordinator.recordMeasurementCompleted(verdict: .caution, now: baseDate))
        XCTAssertFalse(coordinator.recordMeasurementCompleted(verdict: .notReady, now: baseDate))
        XCTAssertFalse(coordinator.recordMeasurementCompleted(verdict: .inconclusive, now: baseDate))
        XCTAssertEqual(coordinator.currentState().successfulReadyChecksCount, 1)

        // 2º check com .ready -> false
        let p2 = coordinator.recordMeasurementCompleted(verdict: .ready, now: baseDate)
        XCTAssertFalse(p2)
        XCTAssertEqual(coordinator.currentState().successfulReadyChecksCount, 2)

        // 3º check com .ready -> TRUE!
        let p3 = coordinator.recordMeasurementCompleted(verdict: .ready, now: baseDate)
        XCTAssertTrue(p3)
        XCTAssertEqual(coordinator.currentState().successfulReadyChecksCount, 3)
        // Antes de apresentar, ainda não gravou versão/data para não queimar cooldown prematuramente
        XCTAssertNil(coordinator.currentState().lastPromptedVersion)

        // UI apresenta o diálogo com sucesso:
        coordinator.recordPromptPresented(now: baseDate)
        XCTAssertEqual(coordinator.currentState().lastPromptedVersion, "1.0.0")
        XCTAssertEqual(coordinator.currentState().lastPromptedDate, baseDate)

        // 4º check na mesma versão -> false (já disparou nesta versão)
        let p4 = coordinator.recordMeasurementCompleted(verdict: .ready, now: baseDate.addingTimeInterval(10))
        XCTAssertFalse(p4)
    }

    final class VersionBox: @unchecked Sendable {
        var version: String
        init(_ version: String) { self.version = version }
    }

    func testCoordinatorHandlesPersistentStoreRoundtrip() {
        let store = InMemoryReviewPromptStore()
        let box = VersionBox("1.0.0")
        let coordinator1 = ReviewPromptCoordinator(store: store, appVersionProvider: { box.version })

        coordinator1.recordMeasurementCompleted(verdict: .ready, now: baseDate)
        coordinator1.recordMeasurementCompleted(verdict: .ready, now: baseDate)
        XCTAssertTrue(coordinator1.recordMeasurementCompleted(verdict: .ready, now: baseDate))
        coordinator1.recordPromptPresented(now: baseDate)

        // Nova instância do coordinator simulando relançamento do app com o mesmo store
        let coordinator2 = ReviewPromptCoordinator(store: store, appVersionProvider: { box.version })
        XCTAssertFalse(coordinator2.recordMeasurementCompleted(verdict: .ready, now: baseDate))

        // Nova versão e 95 dias depois
        box.version = "1.1.0"
        let futureDate = baseDate.addingTimeInterval(95 * 86400)
        XCTAssertTrue(coordinator2.recordMeasurementCompleted(verdict: .ready, now: futureDate))
    }
}
