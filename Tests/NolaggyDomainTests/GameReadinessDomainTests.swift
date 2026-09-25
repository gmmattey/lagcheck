import XCTest
@testable import NolaggyDomain

final class GameReadinessDomainTests: XCTestCase {

    // MARK: - Helpers

    private func samples(count: Int, rtt: Double) -> [ProbeSample] {
        (0..<count).map { seq in
            ProbeSample(sequence: seq, roundTripMilliseconds: rtt, outcome: .received)
        }
    }

    private func evaluateSamples(
        _ samples: [ProbeSample],
        profile: QualityProfileID = .battleRoyaleCompetitive,
        loadDeltaMs: Double? = nil
    ) throws -> GameReadinessEvaluation {
        let eval = QualityEvaluator.evaluate(samples: samples, profile: profile)
        guard case let .completed(qualityResult) = eval else {
            return GameReadinessEvaluator.evaluate(qualityResult: nil, loadImpact: nil, profile: profile)
        }

        let loadImpact: DeepCheckLoadImpact?
        if let loadDeltaMs, let p50 = qualityResult.metrics.p50Milliseconds {
            loadImpact = DeepCheckLoadImpact(restP50Milliseconds: p50, loadP50Milliseconds: p50 + loadDeltaMs)
        } else {
            loadImpact = nil
        }

        return GameReadinessEvaluator.evaluate(
            qualityResult: qualityResult,
            loadImpact: loadImpact,
            profile: profile
        )
    }

    // MARK: - Ready Verdict Tests

    func testHealthyConnectionProducesReadyVerdict() throws {
        let testSamples = samples(count: 30, rtt: 25.0)
        let eval = try evaluateSamples(testSamples, profile: .battleRoyaleCompetitive, loadDeltaMs: 5.0)

        XCTAssertEqual(eval.verdict, .ready)
        XCTAssertTrue(eval.verdict.isReady)
        XCTAssertEqual(eval.headlineKey, "game_readiness.verdict.ready.headline")
        XCTAssertGreaterThanOrEqual(eval.stabilityRatio, 0.85)
        XCTAssertEqual(eval.packetLossPercentage, 0.0)
        XCTAssertFalse(eval.isUnderLoadAffected)

        // Verifica achados
        let lossFinding = eval.findings.first(where: { $0.kind == .packetLoss })
        XCTAssertEqual(lossFinding?.severity, .positive)

        let routeFinding = eval.findings.first(where: { $0.kind == .stableRoute })
        XCTAssertEqual(routeFinding?.severity, .positive)
    }

    // MARK: - Not Ready Verdict Tests

    func testPacketLossProducesNotReadyVerdict() throws {
        // 25 recebidos e 5 timeouts (~16.7% perda)
        var testSamples = samples(count: 25, rtt: 25.0)
        testSamples += (25..<30).map { seq in
            ProbeSample(sequence: seq, roundTripMilliseconds: nil, outcome: .timeout)
        }

        let eval = try evaluateSamples(testSamples, profile: .battleRoyaleCompetitive)

        XCTAssertEqual(eval.verdict, .notReady)
        XCTAssertFalse(eval.verdict.isReady)
        XCTAssertEqual(eval.headlineKey, "game_readiness.verdict.not_ready.headline")
        XCTAssertEqual(eval.subtitleKey, "game_readiness.verdict.not_ready.packet_loss")
        XCTAssertLessThanOrEqual(eval.stabilityRatio, 0.45)

        let lossFinding = eval.findings.first(where: { $0.kind == .packetLoss })
        XCTAssertEqual(lossFinding?.severity, .negative)
    }

    func testHighLatencyProducesNotReadyVerdict() throws {
        // Latência de 140ms para perfil battle royale (guardrail 100ms)
        let testSamples = samples(count: 30, rtt: 140.0)
        let eval = try evaluateSamples(testSamples, profile: .battleRoyaleCompetitive)

        XCTAssertEqual(eval.verdict, .notReady)
        XCTAssertEqual(eval.subtitleKey, "game_readiness.verdict.not_ready.high_latency")
    }

    func testSevereSpikesProducesNotReadyVerdict() throws {
        // 28 amostras normais + 2 spikes severos de 180ms
        var testSamples = samples(count: 28, rtt: 25.0)
        testSamples.append(ProbeSample(sequence: 28, roundTripMilliseconds: 180.0, outcome: .received))
        testSamples.append(ProbeSample(sequence: 29, roundTripMilliseconds: 180.0, outcome: .received))

        let eval = try evaluateSamples(testSamples, profile: .battleRoyaleCompetitive)

        XCTAssertEqual(eval.verdict, .notReady)
        XCTAssertEqual(eval.subtitleKey, "game_readiness.verdict.not_ready.severe_spikes")

        let spikeFinding = eval.findings.first(where: { $0.kind == .latencySpikes })
        XCTAssertEqual(spikeFinding?.severity, .negative)
    }

    // MARK: - Caution Verdict Tests

    func testMaterialLoadImpactProducesCautionVerdict() throws {
        let testSamples = samples(count: 30, rtt: 25.0)
        // Delta de 35ms (> 20ms material threshold)
        let eval = try evaluateSamples(testSamples, profile: .battleRoyaleCompetitive, loadDeltaMs: 35.0)

        XCTAssertEqual(eval.verdict, .caution)
        XCTAssertTrue(eval.isUnderLoadAffected)
        XCTAssertEqual(eval.subtitleKey, "game_readiness.verdict.caution.load")

        let loadFinding = eval.findings.first(where: { $0.kind == .loadDegradation })
        XCTAssertEqual(loadFinding?.severity, .warning)
    }

    func testModerateJitterProducesCautionVerdict() throws {
        // Alternando latências entre 20ms e 50ms para gerar jitter de 30ms (> 25ms de limiar instável)
        let testSamples = (0..<30).map { seq in
            let rtt = (seq % 2 == 0) ? 20.0 : 50.0
            return ProbeSample(sequence: seq, roundTripMilliseconds: rtt, outcome: .received)
        }

        let eval = try evaluateSamples(testSamples, profile: .battleRoyaleCompetitive)

        XCTAssertTrue(eval.verdict == .caution || eval.verdict == .notReady)
    }

    // MARK: - Inconclusive Tests

    func testInsufficientSamplesProducesInconclusiveVerdict() {
        // Apenas 8 amostras válidas (< 10 obrigatórias)
        let testSamples = samples(count: 8, rtt: 25.0)
        let eval = QualityEvaluator.evaluate(samples: testSamples, profile: .battleRoyaleCompetitive)

        guard case .inconclusive = eval else {
            XCTFail("Deveria ser inconclusivo")
            return
        }

        let readiness = GameReadinessEvaluator.evaluate(qualityResult: nil, loadImpact: nil, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(readiness.verdict, .inconclusive)
        XCTAssertEqual(readiness.stabilityRatio, 0.0)
    }

    func testNilResultProducesInconclusiveVerdict() {
        let eval = GameReadinessEvaluator.evaluate(deepCheckResult: nil, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(eval.verdict, .inconclusive)
    }

    // MARK: - Multi-Profile Consistency

    func testAllSupportedProfilesEvaluateProperly() throws {
        let profiles: [QualityProfileID] = [.battleRoyaleCompetitive, .mobileRealtime, .casualRealtime]
        let testSamples = samples(count: 30, rtt: 20.0)

        for profile in profiles {
            let eval = try evaluateSamples(testSamples, profile: profile)
            XCTAssertEqual(eval.verdict, .ready, "Perfil \(profile.rawValue) falhou para amostra saudável")
        }
    }
}
