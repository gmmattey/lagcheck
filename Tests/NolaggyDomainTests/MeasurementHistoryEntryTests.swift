import XCTest
@testable import NolaggyDomain

final class MeasurementHistoryEntryTests: XCTestCase {
    func testCompletedEntryPreservesTheAppliedPilotSnapshotAndWorstRTT() throws {
        let context = try PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "BR", platform: .iphone))
        let evaluation = QualityEvaluator.evaluateBattleRoyaleCompetitive(samples: (0..<30).map {
            ProbeSample(sequence: $0, roundTripMilliseconds: $0 == 29 ? 120 : 30, outcome: .received)
        })
        guard case let .completed(result) = evaluation else { return XCTFail("Expected valid result") }

        let entry = MeasurementHistoryEntry.completedQuickCheck(resolvedContext: context, result: result)

        XCTAssertEqual(entry.resolvedContext.catalogVersion, "pilot-2026.09.08.1")
        XCTAssertEqual(entry.profileRuleVersion, "pilot-2026.09.08.1")
        XCTAssertEqual(entry.resolvedContext.strategy, .genericRegion)
        XCTAssertEqual(entry.result.metrics.worstSpikeMilliseconds, 120)
    }

    func testCompletedDeepCheckPreservesRestResultAndOptionalLoadImpactWithoutSamples() throws {
        let context = try PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "BR", platform: .iphone))
        let restSamples = (0..<30).map { ProbeSample(sequence: $0, roundTripMilliseconds: 30, outcome: .received) }
        let loadSamples = (0..<30).map { ProbeSample(sequence: $0, roundTripMilliseconds: 93, outcome: .received) }
        let evaluation = DeepCheckEvaluator.evaluateBattleRoyaleCompetitive(
            restSamples: restSamples,
            loadSamples: loadSamples
        )
        guard case let .completed(deepResult) = evaluation else { return XCTFail("Expected valid Deep Check") }

        let entry = MeasurementHistoryEntry.completedDeepCheck(
            resolvedContext: context,
            result: deepResult,
            completedAt: Date(timeIntervalSince1970: 1_789_000_000)
        )
        let restored = try JSONDecoder().decode(
            MeasurementHistoryEntry.self,
            from: JSONEncoder().encode(entry)
        )

        XCTAssertEqual(entry.kind, .deep)
        XCTAssertEqual(entry.result, deepResult.restResult)
        XCTAssertEqual(entry.deepCheck?.metrics.loadImpact?.increaseMilliseconds, 63)
        XCTAssertEqual(restored, entry)
    }
}
