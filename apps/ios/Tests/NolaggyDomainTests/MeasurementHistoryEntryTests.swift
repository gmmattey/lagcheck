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
        XCTAssertEqual(entry.result?.metrics.worstSpikeMilliseconds, 120)
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

    func testCompletedInconclusivePreservesDiagnosticsWithoutScoreOrCause() throws {
        let context = try PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "BR", platform: .iphone))
        let diagnostics = QualityMetrics(
            validResponseCount: 3, timeoutCount: 27, invalidResponseCount: 0,
            p50Milliseconds: 32, p95Milliseconds: 40, p99Milliseconds: 40, jitterMilliseconds: 4,
            packetLossPercentage: 90, spikeCount: 0, severeSpikeCount: 0, spikeRatePercentage: 0,
            p95ToP50Ratio: 1.25, components: nil
        )

        let entry = MeasurementHistoryEntry.completedInconclusive(
            resolvedContext: context,
            diagnostics: diagnostics
        )

        XCTAssertTrue(entry.isInconclusive)
        XCTAssertEqual(entry.readinessVerdict, .inconclusive)
        XCTAssertNil(entry.result)
        XCTAssertNil(entry.primaryCause)
        XCTAssertEqual(entry.metrics, diagnostics)
    }
}
