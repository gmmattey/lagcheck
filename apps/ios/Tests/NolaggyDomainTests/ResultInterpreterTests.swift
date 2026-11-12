import XCTest
@testable import NolaggyDomain

final class ResultInterpreterTests: XCTestCase {
    func testHealthyResultUsesReadyConclusionAndStableCause() throws {
        let interpretation = ResultInterpreter.interpret(
            try completed(samples: received(30, rtt: 30), profile: .battleRoyaleCompetitive),
            profile: .battleRoyaleCompetitive
        )

        XCTAssertEqual(interpretation.conclusionKey, .readyToPlay)
        XCTAssertEqual(interpretation.primaryCauseKey, .stableConnection)
        XCTAssertEqual(interpretation.score, 100)
        XCTAssertEqual(interpretation.scoreBand, .excellent)
        XCTAssertEqual(interpretation.headlineKey, .excellent)
        XCTAssertEqual(interpretation.explanationKey, .stableConnection)
        XCTAssertEqual(interpretation.insightKey, .stableConnection)
        XCTAssertEqual(interpretation.metrics.p50Milliseconds, 30)
    }

    func testLossHasPriorityAndUsesRiskConclusion() throws {
        let interpretation = ResultInterpreter.interpret(
            try completed(samples: received(20, rtt: 30) + timeouts(10, startingAt: 20), profile: .battleRoyaleCompetitive),
            profile: .battleRoyaleCompetitive
        )

        XCTAssertEqual(interpretation.conclusionKey, .investigateBeforePlaying)
        XCTAssertEqual(interpretation.primaryCauseKey, .packetLoss)
    }

    func testP50AboveGuardrailIsPrimaryCause() throws {
        let interpretation = ResultInterpreter.interpret(
            try completed(samples: received(30, rtt: 101), profile: .battleRoyaleCompetitive),
            profile: .battleRoyaleCompetitive
        )

        XCTAssertEqual(interpretation.conclusionKey, .investigateBeforePlaying)
        XCTAssertEqual(interpretation.primaryCauseKey, .highLatency)
    }

    func testSevereSpikesArePrimaryCause() throws {
        let interpretation = ResultInterpreter.interpret(
            try completed(
                samples: received(28, rtt: 30) + [
                    ProbeSample(sequence: 28, roundTripMilliseconds: 160, outcome: .received),
                    ProbeSample(sequence: 29, roundTripMilliseconds: 160, outcome: .received)
                ],
                profile: .battleRoyaleCompetitive
            ),
            profile: .battleRoyaleCompetitive
        )

        XCTAssertEqual(interpretation.conclusionKey, .lagMayOccur)
        XCTAssertEqual(interpretation.primaryCauseKey, .severeSpikes)
    }

    func testJitterAboveRiskBandIsPrimaryCause() throws {
        let samples = (0..<30).map { sequence in
            ProbeSample(
                sequence: sequence,
                roundTripMilliseconds: sequence.isMultiple(of: 2) ? 30 : 90,
                outcome: .received
            )
        }

        let interpretation = ResultInterpreter.interpret(
            try completed(samples: samples, profile: .battleRoyaleCompetitive),
            profile: .battleRoyaleCompetitive
        )

        XCTAssertEqual(interpretation.conclusionKey, .lagMayOccur)
        XCTAssertEqual(interpretation.primaryCauseKey, .highJitter)
    }

    // MARK: - Regressão: a causa principal precisa usar os guardrails do perfil
    // ativo, não os valores fixos de BATTLE_ROYALE_COMPETITIVE. Antes desta
    // correção, um P50 de 110 ms era rotulado `highLatency` mesmo em perfis
    // cujo guardrail de latência é bem maior que 100 ms.

    func testMobileRealtimeUsesItsOwnLatencyGuardrailNotBattleRoyales() throws {
        // 110 ms está dentro da faixa "Ótimo" do MOBILE_REALTIME (guardrail é > 130 ms)
        // e seria incorretamente sinalizado como `highLatency` pelo limite fixo de 100 ms.
        let interpretation = ResultInterpreter.interpret(
            try completed(samples: received(30, rtt: 110), profile: .mobileRealtime),
            profile: .mobileRealtime
        )

        XCTAssertEqual(interpretation.primaryCauseKey, .stableConnection)
    }

    func testMobileRealtimeFlagsLatencyOnlyAboveItsOwnGuardrail() throws {
        let interpretation = ResultInterpreter.interpret(
            try completed(samples: received(30, rtt: 131), profile: .mobileRealtime),
            profile: .mobileRealtime
        )

        XCTAssertEqual(interpretation.primaryCauseKey, .highLatency)
    }

    func testMobileRealtimeUsesItsOwnLossGuardrailNotBattleRoyales() throws {
        // 1 timeout em 30 probes é ~3,33% de perda: acima do guardrail de 3% do
        // BATTLE_ROYALE_COMPETITIVE (dispararia `packetLoss` com o limite antigo
        // hardcoded), mas abaixo do guardrail de 5% do MOBILE_REALTIME.
        let interpretation = ResultInterpreter.interpret(
            try completed(samples: received(29, rtt: 30) + timeouts(1, startingAt: 29), profile: .mobileRealtime),
            profile: .mobileRealtime
        )

        XCTAssertEqual(interpretation.primaryCauseKey, .stableConnection)
    }

    func testCasualRealtimeRequiresThreeSevereSpikesNotTwo() throws {
        // O CASUAL_REALTIME só limita por spikes severos com 3 ocorrências; o limite
        // fixo antigo de 2 (herdado do BATTLE_ROYALE_COMPETITIVE) marcaria este caso
        // incorretamente como `severeSpikes`.
        let interpretation = ResultInterpreter.interpret(
            try completed(
                samples: received(28, rtt: 30) + [
                    ProbeSample(sequence: 28, roundTripMilliseconds: 310, outcome: .received),
                    ProbeSample(sequence: 29, roundTripMilliseconds: 310, outcome: .received)
                ],
                profile: .casualRealtime
            ),
            profile: .casualRealtime
        )

        XCTAssertEqual(interpretation.primaryCauseKey, .stableConnection)
    }
}

private extension ResultInterpreterTests {
    func completed(samples: [ProbeSample], profile: QualityProfileID) throws -> QualityResult {
        let evaluation = QualityEvaluator.evaluate(samples: samples, profile: profile)
        guard case let .completed(result) = evaluation else {
            throw NSError(domain: "ResultInterpreterTests", code: 1)
        }
        return result
    }

    func received(_ count: Int, rtt: Double, startingAt sequence: Int = 0) -> [ProbeSample] {
        (0..<count).map {
            ProbeSample(sequence: sequence + $0, roundTripMilliseconds: rtt, outcome: .received)
        }
    }

    func timeouts(_ count: Int, startingAt sequence: Int) -> [ProbeSample] {
        (0..<count).map { ProbeSample(sequence: sequence + $0, outcome: .timeout) }
    }
}
