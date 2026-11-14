import XCTest
@testable import NolaggyDomain

/// Testes normativos de paridade e mapeamento com o motor Kotlin Multiplatform (Decisões 134 e 135).
/// Valida que as fachadas públicas em Swift produzem exatamente os resultados idênticos aos vetores de ENGINE_CONTRACT.md.
final class EngineNormativeVectorsTests: XCTestCase {

    // MARK: - Helpers

    private func received(_ count: Int, rtt: Double, startingAt: Int = 0) -> [ProbeSample] {
        (0..<count).map {
            ProbeSample(sequence: startingAt + $0, roundTripMilliseconds: rtt, outcome: .received)
        }
    }

    private func timeouts(_ count: Int, startingAt: Int) -> [ProbeSample] {
        (0..<count).map {
            ProbeSample(sequence: startingAt + $0, roundTripMilliseconds: nil, outcome: .timeout)
        }
    }

    private func withRtt(baseRtt: Double = 30.0, overrides: [Int: Double], total: Int = 60) -> [ProbeSample] {
        (0..<total).map { seq in
            let rtt = overrides[seq] ?? baseRtt
            return ProbeSample(sequence: seq, roundTripMilliseconds: rtt, outcome: .received)
        }
    }

    // MARK: - Vetores Normativos Decisão 135

    /// V135-01: 60 respostas UDP de 30 ms -> READY, score 100, STABLE_CONNECTION.
    func testVectorV135_01_Stable() {
        let samples = received(60, rtt: 30.0)
        let eval = QualityEvaluator.evaluateBattleRoyaleCompetitive(samples: samples)

        guard case let .completed(result) = eval else {
            return XCTFail("V135-01 esperado completed")
        }
        XCTAssertEqual(result.finalScore, 100)
        XCTAssertEqual(result.resultClass, .excellent)

        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: result,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(readiness.verdict, .ready)
        XCTAssertEqual(readiness.score, 100)

        let interp = ResultInterpreter.interpret(result, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(interp.primaryCauseKey, .stableConnection)
    }

    /// V135-02: 59 respostas de 30 ms e 1 timeout: perda de 1,6667% sem cruzar o guardrail de 3%.
    /// Esperado: READY, score 92, perda 1,6667%.
    func testVectorV135_02_OneTimeoutNoGuardrail() {
        let samples = received(59, rtt: 30.0) + timeouts(1, startingAt: 59)
        let eval = QualityEvaluator.evaluateBattleRoyaleCompetitive(samples: samples)

        guard case let .completed(result) = eval else {
            return XCTFail("V135-02 esperado completed")
        }
        XCTAssertEqual(result.finalScore, 92)
        XCTAssertEqual(result.metrics.packetLossPercentage, 1.6666666666666667, accuracy: 0.0001)

        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: result,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(readiness.verdict, .ready)
        XCTAssertEqual(readiness.score, 92)
    }

    /// V135-03: Dois timeouts cruzam o guardrail de perda de Battle Royale (3%).
    /// Esperado: NOT_READY, score 59, PACKET_LOSS, perda 3,3333%.
    func testVectorV135_03_TwoTimeoutsPacketLossGuardrail() {
        let samples = received(58, rtt: 30.0) + timeouts(2, startingAt: 58)
        let eval = QualityEvaluator.evaluateBattleRoyaleCompetitive(samples: samples)

        guard case let .completed(result) = eval else {
            return XCTFail("V135-03 esperado completed")
        }
        XCTAssertEqual(result.metrics.packetLossPercentage, 3.3333333333333335, accuracy: 0.0001)

        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: result,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(readiness.verdict, .notReady)
        XCTAssertEqual(readiness.score, 59)

        let interp = ResultInterpreter.interpret(result, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(interp.primaryCauseKey, .packetLoss)
    }

    /// V135-04: 19 respostas e 41 timeouts: abaixo do mínimo de 20 respostas válidas.
    /// Esperado: INCONCLUSIVE sem score.
    func testVectorV135_04_InsufficientResponsesIsInconclusive() {
        let samples = received(19, rtt: 30.0) + timeouts(41, startingAt: 19)
        let eval = QualityEvaluator.evaluateBattleRoyaleCompetitive(samples: samples)

        guard case let .inconclusive(reason, diagnostics) = eval else {
            return XCTFail("V135-04 esperado inconclusive")
        }
        XCTAssertEqual(reason, .insufficientUDPResponses)
        XCTAssertEqual(diagnostics.validResponseCount, 19)

        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: nil,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(readiness.verdict, .inconclusive)
        XCTAssertNil(readiness.score)
    }

    /// V135-05: 20 respostas é o mínimo válido; 40 timeouts ainda tornam a perda determinante.
    /// Esperado: NOT_READY, score 59, PACKET_LOSS, perda 66,6667%.
    func testVectorV135_05_MinimumValidResponsesLossDominant() {
        let samples = received(20, rtt: 30.0) + timeouts(40, startingAt: 20)
        let eval = QualityEvaluator.evaluateBattleRoyaleCompetitive(samples: samples)

        guard case let .completed(result) = eval else {
            return XCTFail("V135-05 esperado completed")
        }
        XCTAssertEqual(result.finalScore, 59)
        XCTAssertEqual(result.metrics.packetLossPercentage, 66.66666666666667, accuracy: 0.0001)

        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: result,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(readiness.verdict, .notReady)
        XCTAssertEqual(readiness.score, 59)
    }

    /// V135-06: Dois picos severos isolados, nas sequências 5 e 40 (200 ms).
    /// Esperado: CAUTION, score 74, spikePattern: ISOLATED.
    func testVectorV135_06_TwoIsolatedSevereSpikes() {
        let samples = withRtt(overrides: [5: 200.0, 40: 200.0])
        let eval = QualityEvaluator.evaluateBattleRoyaleCompetitive(samples: samples)

        guard case let .completed(result) = eval else {
            return XCTFail("V135-06 esperado completed")
        }
        XCTAssertEqual(result.metrics.severeSpikeCount, 2)
        XCTAssertEqual(result.metrics.spikePattern, .isolated(count: 2, severeCount: 2))

        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: result,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(readiness.verdict, .caution)
        XCTAssertEqual(readiness.score, 74)
    }

    /// V135-07: Três picos severos recorrentes, nas sequências 10, 12 e 14 (220 ms).
    /// Esperado: NOT_READY, score 59, primaryCause: SEVERE_SPIKES, spikePattern: RECURRING.
    func testVectorV135_07_ThreeRecurringSevereSpikes() {
        let samples = withRtt(overrides: [10: 220.0, 12: 220.0, 14: 220.0])
        let eval = QualityEvaluator.evaluateBattleRoyaleCompetitive(samples: samples)

        guard case let .completed(result) = eval else {
            return XCTFail("V135-07 esperado completed")
        }
        XCTAssertEqual(result.metrics.severeSpikeCount, 3)
        XCTAssertEqual(result.metrics.spikePattern, .recurring(count: 3, severeCount: 3))

        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: result,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(readiness.verdict, .notReady)
        XCTAssertEqual(readiness.score, 59)

        let interp = ResultInterpreter.interpret(result, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(interp.primaryCauseKey, .severeSpikes)
    }

    /// V135-08: P50 de 95 ms sem perda continua READY sem margem de confiança.
    /// Esperado: READY, score 76.
    func testVectorV135_08_P50NinetyFiveMillisecondsReady76() {
        let samples = received(60, rtt: 95.0)
        let eval = QualityEvaluator.evaluateBattleRoyaleCompetitive(samples: samples)

        guard case let .completed(result) = eval else {
            return XCTFail("V135-08 esperado completed")
        }
        XCTAssertEqual(result.finalScore, 76)

        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: result,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(readiness.verdict, .ready)
        XCTAssertEqual(readiness.score, 76)
    }

    /// V135-09: Repouso perfeito; carga transferiu bytes, mas só 19 respostas válidas espalhadas.
    /// Esperado: INCONCLUSIVE sem score.
    func testVectorV135_09_MeasuredLoadWithNineteenResponsesIsInconclusive() {
        let restSamples = received(60, rtt: 30.0)
        // 19 respostas válidas nas sequências 0, 3, 6, ..., 54
        var loadSamples: [ProbeSample] = []
        let validIndices = Set(stride(from: 0, through: 54, by: 3))
        for seq in 0..<60 {
            if validIndices.contains(seq) {
                loadSamples.append(ProbeSample(sequence: seq, roundTripMilliseconds: 30.0, outcome: .received))
            } else {
                loadSamples.append(ProbeSample(sequence: seq, roundTripMilliseconds: nil, outcome: .timeout))
            }
        }

        let eval = DeepCheckEvaluator.evaluateBattleRoyaleCompetitive(
            restSamples: restSamples,
            loadSamples: loadSamples
        )

        guard case let .inconclusive(reason, _) = eval else {
            return XCTFail("V135-09 esperado inconclusive na avaliação sob carga insuficiente")
        }
        XCTAssertEqual(reason, .poorSampleQuality)

        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: nil,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(readiness.verdict, .inconclusive)
        XCTAssertNil(readiness.score)
    }

    /// V135-10: Falha de carga sem bytes: o resultado do repouso vale sem conclusão sobre carga.
    /// Esperado: READY, score 100, loadTier: nil.
    func testVectorV135_10_FailedLoadNoBytesPreservesRest() {
        let restSamples = received(60, rtt: 30.0)
        let eval = DeepCheckEvaluator.evaluateBattleRoyaleCompetitive(
            restSamples: restSamples,
            loadSamples: nil
        )

        guard case let .completed(result) = eval else {
            return XCTFail("V135-10 esperado completed")
        }
        XCTAssertEqual(result.restResult.finalScore, 100)
        XCTAssertNil(result.metrics.loadImpact)

        let readiness = GameReadinessEvaluator.evaluate(
            deepCheckResult: result,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(readiness.verdict, .ready)
        XCTAssertEqual(readiness.score, 100)
    }

    /// DLI3-01: BR: 28 -> 40 ms, ΔP50 12 ms, impacto leve.
    /// Esperado: READY, score 100, loadTier: LIGHT.
    func testVectorDLI3_01_BattleRoyaleLight() {
        let restSamples = received(60, rtt: 28.0)
        let loadSamples = received(60, rtt: 40.0)
        let eval = DeepCheckEvaluator.evaluateBattleRoyaleCompetitive(
            restSamples: restSamples,
            loadSamples: loadSamples
        )

        guard case let .completed(result) = eval else {
            return XCTFail("DLI3-01 esperado completed")
        }
        XCTAssertEqual(result.metrics.loadImpact?.tier, .light)
        XCTAssertEqual(result.metrics.loadImpact?.increaseMilliseconds, 12.0)

        let readiness = GameReadinessEvaluator.evaluate(
            deepCheckResult: result,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(readiness.verdict, .ready)
        XCTAssertEqual(readiness.score, 100)
    }

    /// DLI3-02: BR: 28 -> 45 ms, ΔP50 17 ms, impacto material.
    /// Esperado: CAUTION, score 74, loadTier: MATERIAL.
    func testVectorDLI3_02_BattleRoyaleMaterial() {
        let restSamples = received(60, rtt: 28.0)
        let loadSamples = received(60, rtt: 45.0)
        let eval = DeepCheckEvaluator.evaluateBattleRoyaleCompetitive(
            restSamples: restSamples,
            loadSamples: loadSamples
        )

        guard case let .completed(result) = eval else {
            return XCTFail("DLI3-02 esperado completed")
        }
        XCTAssertEqual(result.metrics.loadImpact?.tier, .material)
        XCTAssertEqual(result.metrics.loadImpact?.increaseMilliseconds, 17.0)

        let readiness = GameReadinessEvaluator.evaluate(
            deepCheckResult: result,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(readiness.verdict, .caution)
        XCTAssertEqual(readiness.score, 74)
    }

    /// DLI3-03: BR: 28 -> 65 ms, ΔP50 37 ms, impacto severo.
    /// Esperado: NOT_READY, score 59, loadTier: SEVERE.
    func testVectorDLI3_03_BattleRoyaleSevere() {
        let restSamples = received(60, rtt: 28.0)
        let loadSamples = received(60, rtt: 65.0)
        let eval = DeepCheckEvaluator.evaluateBattleRoyaleCompetitive(
            restSamples: restSamples,
            loadSamples: loadSamples
        )

        guard case let .completed(result) = eval else {
            return XCTFail("DLI3-03 esperado completed")
        }
        XCTAssertEqual(result.metrics.loadImpact?.tier, .severe)
        XCTAssertEqual(result.metrics.loadImpact?.increaseMilliseconds, 37.0)

        let readiness = GameReadinessEvaluator.evaluate(
            deepCheckResult: result,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(readiness.verdict, .notReady)
        XCTAssertEqual(readiness.score, 59)
    }
}
