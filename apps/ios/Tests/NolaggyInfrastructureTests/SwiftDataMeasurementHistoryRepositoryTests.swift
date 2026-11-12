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

    func testGenericGamingEntryCanBeSavedAndLoaded() async throws {
        let repository = try SwiftDataMeasurementHistoryRepository(inMemory: true)
        let resolved = ResolvedMeasurementContext(
            context: GameContext.genericGaming(market: "BR", platform: .playstation, declaredExternalLink: .ethernet),
            catalogVersion: "test-v3",
            profileID: .battleRoyaleCompetitive,
            profileRuleVersion: "rule-1",
            regionID: "sa-east-1",
            destination: try ProbeDestination(host: "gamelift-ping.sa-east-1.api.aws", port: 7770),
            strategy: .genericRegion,
            confidence: .medium
        )
        let result = QualityResult(
            metrics: QualityMetrics(validResponseCount: 30, timeoutCount: 0, invalidResponseCount: 0, p50Milliseconds: 25, p95Milliseconds: 28, p99Milliseconds: 30, jitterMilliseconds: 2, packetLossPercentage: 0, spikeCount: 0, severeSpikeCount: 0, spikeRatePercentage: 0, p95ToP50Ratio: 1.1, worstSpikeMilliseconds: 30, components: nil),
            rawScore: 98, finalScore: 98, resultClass: .excellent, appliedGuardrails: []
        )
        let entry = MeasurementHistoryEntry(completedAt: Date(), resolvedContext: resolved, profileRuleVersion: "rule-1", result: result, primaryCause: .stableConnection)

        try await repository.save(entry)
        let loaded = try await repository.loadHistory()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.resolvedContext.context.gameID, GameContext.genericGamingID)
        XCTAssertEqual(loaded.first?.resolvedContext.context.platform, .playstation)
        XCTAssertEqual(loaded.first?.resolvedContext.context.declaredExternalLink, .ethernet)
        XCTAssertEqual(loaded.first?.result?.finalScore, 98)
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
