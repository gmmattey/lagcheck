import XCTest
@testable import NolaggyDomain
@testable import NolaggyInfrastructure

final class SwiftDataMeasurementHistoryRepositoryTests: XCTestCase {
    func testRetentionKeepsOnlyHundredRecentEntriesPerGame() async throws {
        let repository = try SwiftDataMeasurementHistoryRepository(inMemory: true)
        let base = Date().addingTimeInterval(-101)
        for index in 0..<101 {
            try await repository.save(makeEntry(date: base.addingTimeInterval(TimeInterval(index))))
        }
        let entries = try await repository.loadHistory()
        XCTAssertEqual(entries.count, 100)
        XCTAssertEqual(entries.first?.completedAt, base.addingTimeInterval(100))
    }

    func testExpiredRecordsAndDeleteAllDoNotRemain() async throws {
        let repository = try SwiftDataMeasurementHistoryRepository(inMemory: true)
        try await repository.save(makeEntry(date: .distantPast))
        try await repository.save(makeEntry(date: Date()))
        let retained = try await repository.loadHistory()
        XCTAssertEqual(retained.count, 1)
        try await repository.deleteAll()
        let afterDelete = try await repository.loadHistory()
        XCTAssertTrue(afterDelete.isEmpty)
    }

    private func makeEntry(date: Date) -> MeasurementHistoryEntry {
        let context = try! PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "BR", platform: .iphone))
        let result = QualityResult(
            metrics: QualityMetrics(validResponseCount: 30, timeoutCount: 0, invalidResponseCount: 0, p50Milliseconds: 30, p95Milliseconds: 30, p99Milliseconds: 30, jitterMilliseconds: 0, packetLossPercentage: 0, spikeCount: 0, severeSpikeCount: 0, spikeRatePercentage: 0, p95ToP50Ratio: 1, worstSpikeMilliseconds: 30, components: nil),
            rawScore: 100, finalScore: 100, resultClass: .excellent, appliedGuardrails: []
        )
        return MeasurementHistoryEntry(completedAt: date, resolvedContext: context, profileRuleVersion: context.catalogVersion, result: result, primaryCause: .stableConnection)
    }
}
