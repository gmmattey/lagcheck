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
        XCTAssertNil(readiness.packetLossPercentage, "Resultado inconclusivo NUNCA deve fabricar perda de pacotes")
        XCTAssertNil(readiness.pingMs)
        XCTAssertNil(readiness.jitterMs)
    }

    func testNilResultProducesInconclusiveVerdict() {
        let eval = GameReadinessEvaluator.evaluate(deepCheckResult: nil, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(eval.verdict, .inconclusive)
        XCTAssertNil(eval.packetLossPercentage)
    }

    func testHighLatencyProducesNotReadyVerdictAndNegativeFinding() throws {
        // P50 = 120ms (> 80ms guardrail para battleRoyaleCompetitive)
        let testSamples = samples(count: 30, rtt: 120.0)
        let eval = try evaluateSamples(testSamples, profile: .battleRoyaleCompetitive)

        XCTAssertEqual(eval.verdict, .notReady)
        let latencyFinding = eval.findings.first(where: { $0.kind == .highLatency })
        XCTAssertNotNil(latencyFinding, "Deve gerar achado de alta latência quando P50 excede guardrail")
        XCTAssertEqual(latencyFinding?.severity, .negative)
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

    // MARK: - Decisão 55 (readiness-v2.0) Tests

    func testMediumConfidenceSafetyMarginAppliesTenPercentTighterThresholds() {
        // P50 = 95ms para battleRoyaleCompetitive (guardrail padrão é 100ms)
        let testSamples = samples(count: 30, rtt: 95.0)
        let eval = QualityEvaluator.evaluate(samples: testSamples, profile: .battleRoyaleCompetitive)
        guard case let .completed(qualityResult) = eval else { return XCTFail() }

        // Com alta confiança: 95ms <= 100ms -> .ready
        let readyEval = GameReadinessEvaluator.evaluate(
            qualityResult: qualityResult,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive,
            confidence: .high
        )
        XCTAssertEqual(readyEval.verdict, .ready)

        // Com média confiança (Console/PC / rota genérica): threshold = 100 * 0.9 = 90ms. 95ms > 90ms -> .notReady
        let mediumEval = GameReadinessEvaluator.evaluate(
            qualityResult: qualityResult,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive,
            confidence: .medium
        )
        XCTAssertEqual(mediumEval.verdict, .notReady)
    }

    func testRecurringSevereSpikesTriggersNotReady() {
        let testSamples = samples(count: 30, rtt: 25.0)
        let eval = QualityEvaluator.evaluate(samples: testSamples, profile: .battleRoyaleCompetitive)
        guard case let .completed(qualityResult) = eval else { return XCTFail() }

        let pattern = SpikePattern.recurring(count: 2, severeCount: 2)
        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: qualityResult,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive,
            spikePattern: pattern
        )
        XCTAssertEqual(readiness.verdict, .notReady)
    }

    func testDegradedGatewayTriggersCautionAndFinding() {
        let testSamples = samples(count: 30, rtt: 25.0)
        let eval = QualityEvaluator.evaluate(samples: testSamples, profile: .battleRoyaleCompetitive)
        guard case let .completed(qualityResult) = eval else { return XCTFail() }

        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: qualityResult,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive,
            gatewayOutcome: .degraded(rttMilliseconds: 25.0, lossPercentage: 5.0)
        )
        XCTAssertEqual(readiness.verdict, .caution)
        let gatewayFinding = readiness.findings.first { $0.kind == .localGateway }
        XCTAssertNotNil(gatewayFinding)
        XCTAssertEqual(gatewayFinding?.severity, .negative)
    }

    func testSevereLoadTierTriggersNotReady() {
        let testSamples = samples(count: 30, rtt: 25.0)
        let eval = QualityEvaluator.evaluate(samples: testSamples, profile: .battleRoyaleCompetitive)
        guard case let .completed(qualityResult) = eval else { return XCTFail() }

        let loadImpact = DeepCheckLoadImpact(
            restP50Milliseconds: 25.0,
            loadP50Milliseconds: 80.0,
            tier: .severe
        )
        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: qualityResult,
            loadImpact: loadImpact,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(readiness.verdict, .notReady)
        let loadFinding = readiness.findings.first { $0.kind == .loadDegradation }
        XCTAssertEqual(loadFinding?.severity, .negative)
    }

    func testNATTopologyRelevanceByServerArchitecture() {
        let testSamples = samples(count: 30, rtt: 25.0)
        let eval = QualityEvaluator.evaluate(samples: testSamples, profile: .battleRoyaleCompetitive)
        guard case let .completed(qualityResult) = eval else { return XCTFail() }

        let nat = NATTopologySnapshot(
            natType: .type3Strict,
            cgnatStatus: .notDetected,
            doubleNATStatus: .notDetected,
            publicIPMasked: "192.0.2.1"
        )

        // Jogo P2P: achado de NAT é exibido
        let p2pEval = GameReadinessEvaluator.evaluate(
            qualityResult: qualityResult,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive,
            serverArchitecture: .peerToPeer,
            natSnapshot: nat
        )
        XCTAssertTrue(p2pEval.findings.contains(where: { $0.kind == .natTopology }))

        // Jogo com servidor dedicado: achado de NAT NÃO é exibido
        let dedicatedEval = GameReadinessEvaluator.evaluate(
            qualityResult: qualityResult,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive,
            serverArchitecture: .dedicatedServer,
            natSnapshot: nat
        )
        XCTAssertFalse(dedicatedEval.findings.contains(where: { $0.kind == .natTopology }))
    }

    func testFastFiberConnectionWithNormalVarianceEvaluatesToReady() {
        // Simula conexão rápida de fibra (captura real: p50 = 13ms, p95 = 24ms, jitter = 6ms)
        var testSamples = (0..<20).map { ProbeSample(sequence: $0, roundTripMilliseconds: 13.0, outcome: .received) }
        testSamples += (20..<28).map { ProbeSample(sequence: $0, roundTripMilliseconds: 15.0, outcome: .received) }
        testSamples.append(ProbeSample(sequence: 28, roundTripMilliseconds: 24.0, outcome: .received))
        testSamples.append(ProbeSample(sequence: 29, roundTripMilliseconds: 24.0, outcome: .received))

        let eval = QualityEvaluator.evaluate(samples: testSamples, profile: .battleRoyaleCompetitive)
        guard case let .completed(qualityResult) = eval else { return XCTFail() }

        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: qualityResult,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive
        )

        XCTAssertEqual(readiness.verdict, .ready, "Conexão de 13ms com delta de apenas 11ms deve ser PRONTO PARA RANKED")
        XCTAssertEqual(readiness.headlineKey, "game_readiness.verdict.ready.headline")
        XCTAssertFalse(readiness.findings.contains(where: { $0.labelKey == "game_readiness.finding.tail_latency_elevated" }))
    }

    func testElevatedTailLatencyWithHighDeltaDemotesToCaution() {
        // P50 = 35ms, mas P95 = 75ms (delta = 40ms >= 20ms, ratio = 2.14 >= 1.8, P95 = 75 > 45ms)
        var testSamples = (0..<26).map { ProbeSample(sequence: $0, roundTripMilliseconds: 35.0, outcome: .received) }
        testSamples += (26..<30).map { ProbeSample(sequence: $0, roundTripMilliseconds: 75.0, outcome: .received) }

        let eval = QualityEvaluator.evaluate(samples: testSamples, profile: .battleRoyaleCompetitive)
        guard case let .completed(qualityResult) = eval else { return XCTFail() }

        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: qualityResult,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive
        )

        XCTAssertEqual(readiness.verdict, .caution)
        XCTAssertTrue(readiness.findings.contains(where: { $0.labelKey == "game_readiness.finding.tail_latency_elevated" }))
    }

    func testOutOfOrderPacketsDemotesToCautionAndGeneratesFinding() {
        // 30 amostras saudáveis (25ms), mas com 3 pacotes recebidos fora de ordem
        // sequences: 0, 1, 3, 2, 4, 5, 7, 6, 8, ...
        var testSamples: [ProbeSample] = []
        var arrival = 0
        for seq in 0..<30 {
            let actualSeq: Int
            if seq == 2 { actualSeq = 3 }
            else if seq == 3 { actualSeq = 2 }
            else if seq == 6 { actualSeq = 7 }
            else if seq == 7 { actualSeq = 6 }
            else { actualSeq = seq }

            testSamples.append(ProbeSample(sequence: actualSeq, roundTripMilliseconds: 25.0, outcome: .received, arrivalIndex: arrival))
            arrival += 1
        }

        let eval = QualityEvaluator.evaluate(samples: testSamples, profile: .battleRoyaleCompetitive)
        guard case let .completed(qualityResult) = eval else { return XCTFail() }

        XCTAssertEqual(qualityResult.metrics.outOfOrderCount, 2)
        XCTAssertGreaterThan(qualityResult.metrics.outOfOrderRatePercentage, 0.0)

        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: qualityResult,
            loadImpact: nil,
            profile: .battleRoyaleCompetitive
        )

        XCTAssertEqual(readiness.verdict, .caution)
        XCTAssertEqual(readiness.subtitleKey, "game_readiness.verdict.caution.out_of_order")
        XCTAssertTrue(readiness.findings.contains(where: { $0.kind == .outOfOrderPackets }))
    }
}
