import XCTest
@testable import NolaggyDomain

final class MeasurementHistoryEntryTests: XCTestCase {
    func testCompletedEntryPreservesTheAppliedPilotSnapshotAndWorstRTT() throws {
        let context = try PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "BR", platform: .iphone))
        let evaluation = QualityEvaluator.evaluateBattleRoyaleCompetitive(samples: (0..<60).map {
            ProbeSample(sequence: $0, roundTripMilliseconds: $0 == 59 ? 120 : 30, outcome: .received)
        })
        guard case let .completed(result) = evaluation else { return XCTFail("Expected valid result") }

        let entry = MeasurementHistoryEntry.completedQuickCheck(resolvedContext: context, result: result)

        XCTAssertEqual(entry.resolvedContext.catalogVersion, "pilot-2026.09.08.1")
        XCTAssertEqual(entry.profileRuleVersion, QualityEvaluator.ruleVersion(for: context.profileID))
        XCTAssertEqual(entry.resolvedContext.strategy, .genericRegion)
        XCTAssertEqual(entry.result?.metrics.worstSpikeMilliseconds, 120)
    }

    func testCompletedDeepCheckPreservesRestResultAndOptionalLoadImpactWithoutSamples() throws {
        let context = try PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "BR", platform: .iphone))
        let restSamples = (0..<60).map { ProbeSample(sequence: $0, roundTripMilliseconds: 30, outcome: .received) }
        let loadSamples = (0..<60).map { ProbeSample(sequence: $0, roundTripMilliseconds: 93, outcome: .received) }
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
            validResponseCount: 3, timeoutCount: 57, invalidResponseCount: 0,
            p50Milliseconds: 32, p95Milliseconds: 40, p99Milliseconds: 40, jitterMilliseconds: 4,
            packetLossPercentage: 95, spikeCount: 0, severeSpikeCount: 0, spikeRatePercentage: 0,
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

    /// Prova que entradas salvas no formato antigo (sem o campo `spikePattern`) decodificam sem erro.
    func testDecodeLegacyMeasurementHistoryEntryWithoutSpikePattern() throws {
        let legacyJson = """
        {
          "id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
          "completedAt": 1700000000,
          "kind": "deep",
          "resolvedContext": {
            "context": {
              "gameID": "fortnite",
              "market": "BR",
              "platform": "iphone"
            },
            "catalogVersion": "pilot-2026.09.08.1",
            "profileID": "BATTLE_ROYALE_COMPETITIVE",
            "profileRuleVersion": "pilot-2026.09.08.1",
            "regionID": "sa-east-1",
            "destination": {
              "host": "gamelift-ping.sa-east-1.api.aws",
              "port": 7770
            },
            "strategy": "genericRegion",
            "confidence": "high",
            "precisionKey": "regionalReference",
            "observedPhoneNetwork": "wifi"
          },
          "profileRuleVersion": "pilot-2026.09.08.1",
          "result": {
            "metrics": {
              "validResponseCount": 30,
              "timeoutCount": 0,
              "invalidResponseCount": 0,
              "p50Milliseconds": 28.0,
              "p95Milliseconds": 32.0,
              "p99Milliseconds": 35.0,
              "jitterMilliseconds": 1.5,
              "packetLossPercentage": 0.0,
              "spikeCount": 0,
              "severeSpikeCount": 0,
              "spikeRatePercentage": 0.0,
              "p95ToP50Ratio": 1.14,
              "worstSpikeMilliseconds": 35.0,
              "outOfOrderCount": 0,
              "outOfOrderRatePercentage": 0.0
            },
            "rawScore": 100,
            "finalScore": 100,
            "resultClass": "excellent",
            "appliedGuardrails": []
          },
          "primaryCause": "stableConnection",
          "readinessVerdict": "ready",
          "readinessRuleVersion": "readiness-v3.0"
        }
        """

        let entry = try JSONDecoder().decode(MeasurementHistoryEntry.self, from: Data(legacyJson.utf8))
        XCTAssertEqual(entry.resolvedContext.context.gameID, "fortnite")
        XCTAssertEqual(entry.readinessVerdict, .ready)
        XCTAssertEqual(entry.result?.finalScore, 100)
        XCTAssertNil(entry.result?.metrics.spikePattern, "spikePattern deve ser opcional e decodificar como nil para dados legados")
    }

    /// Decisão 135 item 7: Paridade tela × histórico.
    /// A mesma medição deve produzir o MESMO veredito e MESMO score na tela (GameReadinessEvaluator) e no histórico (completedDeepCheck).
    func testParityBetweenGameReadinessEvaluatorAndHistoryEntry() throws {
        let context = try PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "BR", platform: .iphone))
        let restSamples = (0..<60).map { ProbeSample(sequence: $0, roundTripMilliseconds: 28.0, outcome: .received) }
        let loadSamples = (0..<60).map { ProbeSample(sequence: $0, roundTripMilliseconds: 45.0, outcome: .received) }

        let evaluation = DeepCheckEvaluator.evaluateBattleRoyaleCompetitive(
            restSamples: restSamples,
            loadSamples: loadSamples
        )
        guard case let .completed(deepResult) = evaluation else {
            return XCTFail("Expected completed Deep Check")
        }

        // 1. Avaliação direta para a tela
        let screenEvaluation = GameReadinessEvaluator.evaluate(
            deepCheckResult: deepResult,
            profile: context.profileID,
            confidence: context.confidence
        )

        // 2. Avaliação gravada no histórico
        let historyEntry = MeasurementHistoryEntry.completedDeepCheck(
            resolvedContext: context,
            result: deepResult
        )

        XCTAssertEqual(
            screenEvaluation.verdict,
            historyEntry.readinessVerdict,
            "Veredito da tela (\(screenEvaluation.verdict)) e do histórico (\(String(describing: historyEntry.readinessVerdict))) devem ser idênticos"
        )
        XCTAssertEqual(historyEntry.profileRuleVersion, QualityEvaluator.ruleVersion(for: context.profileID))
    }
}
