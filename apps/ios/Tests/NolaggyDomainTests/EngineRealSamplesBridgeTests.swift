import XCTest
@testable import NolaggyDomain

/// A ponte do iOS passa ao motor os pacotes reais medidos, não uma série reconstruída das médias.
/// Tela, histórico e Home precisam chegar ao mesmo veredito que o motor deu na hora da medição.
final class EngineRealSamplesBridgeTests: XCTestCase {
    private func received(_ count: Int, rtt: Double, from: Int = 0) -> [ProbeSample] {
        (from..<(from + count)).map { ProbeSample(sequence: $0, roundTripMilliseconds: rtt, outcome: .received) }
    }

    private func timeouts(_ count: Int, from: Int) -> [ProbeSample] {
        (from..<(from + count)).map { ProbeSample(sequence: $0, outcome: .timeout) }
    }

    private func deepResult(rest: [ProbeSample], load: [ProbeSample]) throws -> DeepCheckResult {
        guard case let .completed(result) = DeepCheckEvaluator.evaluate(
            restSamples: rest, loadSamples: load, profile: .battleRoyaleCompetitive
        ) else {
            throw XCTSkip("Expected a completed Deep Check")
        }
        return result
    }

    func testResultCarriesTheRealSamplesOfBothPhases() throws {
        let rest = received(60, rtt: 30)
        let load = received(58, rtt: 30) + timeouts(2, from: 58)
        let result = try deepResult(rest: rest, load: load)

        XCTAssertEqual(result.restResult.samples, rest)
        XCTAssertEqual(result.metrics.loadSamples, load)
    }

    /// Dois pacotes perdidos só na carga, sem mudar o P50: degradação material (Decisão 136).
    /// Uma série reconstruída das médias não tem esses timeouts e daria "pronto".
    func testScreenAndHistoryUseTheRealLoadSamples() throws {
        let rest = received(60, rtt: 30)
        let load = received(58, rtt: 30) + timeouts(2, from: 58)
        let result = try deepResult(rest: rest, load: load)
        XCTAssertEqual(result.metrics.loadImpact?.tier, .material)

        let screen = GameReadinessEvaluator.evaluate(deepCheckResult: result, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(screen.verdict, .caution)

        let context = try PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "BR", platform: .iphone))
        let entry = MeasurementHistoryEntry.completedDeepCheck(resolvedContext: context, result: result)
        XCTAssertEqual(entry.readinessVerdict, screen.verdict)
    }

    /// Picos recorrentes numa posição que a reconstrução não reproduz: a tela segue o motor.
    func testScreenMatchesTheEngineVerdictForTheMeasuredRestSeries() throws {
        var rest = received(60, rtt: 30)
        for sequence in [20, 22, 24] {
            rest[sequence] = ProbeSample(sequence: sequence, roundTripMilliseconds: 120, outcome: .received)
        }
        let engine = LagCheckEngineBridge.evaluate(request: EngineRequestDTO(
            source: "APP_UDP",
            profile: "BATTLE_ROYALE_COMPETITIVE",
            rest: rest.map(LagCheckEngineBridge.toSampleDTO),
            load: nil,
            loadTransfer: "NOT_RUN"
        ))
        guard case let .completed(quality) = QualityEvaluator.evaluate(samples: rest, profile: .battleRoyaleCompetitive) else {
            return XCTFail("Expected a completed Quick Check")
        }
        let screen = GameReadinessEvaluator.evaluate(qualityResult: quality, loadImpact: nil, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(LagCheckEngineBridge.toProfileKey(.battleRoyaleCompetitive), "BATTLE_ROYALE_COMPETITIVE")
        XCTAssertEqual(screen.verdict.rawValue.uppercased(), engine.verdict)
        XCTAssertEqual(screen.score, engine.score)
    }

    /// Entradas gravadas antes desta versão não têm `samples`: continuam abrindo,
    /// mas não ganham uma série inventada nem um novo diagnóstico.
    func testLegacyHistoryResultWithoutSamplesBecomesInconclusive() throws {
        guard case let .completed(quality) = QualityEvaluator.evaluate(samples: received(60, rtt: 30), profile: .battleRoyaleCompetitive) else {
            return XCTFail("Expected a completed Quick Check")
        }
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(quality)) as? [String: Any])
        json.removeValue(forKey: "samples")
        let legacy = try JSONDecoder().decode(QualityResult.self, from: JSONSerialization.data(withJSONObject: json))

        XCTAssertNil(legacy.samples)
        XCTAssertEqual(legacy.metrics, quality.metrics)
        let verdict = GameReadinessEvaluator.evaluate(qualityResult: legacy, loadImpact: nil, profile: .battleRoyaleCompetitive).verdict
        XCTAssertEqual(verdict, .inconclusive)
    }
}

/// Roteador, causa raiz e bufferbloat vêm do motor; o Swift não repete regra.
final class EngineGatewayBridgeTests: XCTestCase {
    func testGatewayNeedsThreeValidResponsesOutOfFive() {
        // Antes, o Swift aceitava 1 resposta em 5 e classificava o roteador como estável.
        XCTAssertEqual(WiFiLocalTelemetry(gatewayRTTMedianMs: 3, gatewayJitterMs: 0.5, validSampleCount: 1, plannedSampleCount: 5).gatewayOutcome, .unobservable)
        XCTAssertEqual(WiFiLocalTelemetry(gatewayRTTMedianMs: 3, gatewayJitterMs: 0.5, validSampleCount: 5, plannedSampleCount: 5).gatewayOutcome, .stable(rttMilliseconds: 3))
        XCTAssertEqual(WiFiLocalTelemetry(gatewayRTTMedianMs: 3, gatewayJitterMs: 0.5, validSampleCount: 4, plannedSampleCount: 5).gatewayOutcome, .degraded(rttMilliseconds: 3, lossPercentage: 20))
    }

    func testRequestCarriesTheMeasuredGatewayStateWithoutInventedNumbers() throws {
        guard case let .completed(quality) = QualityEvaluator.evaluate(
            samples: (0..<60).map { ProbeSample(sequence: $0, roundTripMilliseconds: 30, outcome: .received) },
            profile: .battleRoyaleCompetitive
        ) else { return XCTFail("Expected a completed Quick Check") }

        let degraded = GatewayProbeOutcome.degraded(rttMilliseconds: 25, lossPercentage: 20)
        let request = LagCheckEngineBridge.buildRequest(
            qualityResult: quality, loadImpact: nil, profile: .battleRoyaleCompetitive, gatewayOutcome: degraded
        )
        XCTAssertNil(request.gateway)
        XCTAssertEqual(request.gatewayOutcome, EngineGatewayOutcomeDTO(kind: "DEGRADED", rttMs: 25, lossPercentage: 20))

        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: quality, loadImpact: nil, profile: .battleRoyaleCompetitive, gatewayOutcome: degraded
        )
        XCTAssertEqual(readiness.verdict, .caution)
    }

    func testBufferbloatGradeComesStraightFromTheEngine() {
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 2.0), .aPlus)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 5.0), .a)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 15.0), .b)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 60.001), .f)
    }
}
