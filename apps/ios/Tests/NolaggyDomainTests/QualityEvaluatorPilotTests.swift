import XCTest
@testable import NolaggyDomain

final class QualityEvaluatorPilotTests: XCTestCase {
    func testBR001Stable() throws {
        let result = try completed(samples: received(60, rtt: 30))

        XCTAssertEqual(result.metrics.p50Milliseconds, 30)
        XCTAssertEqual(result.metrics.p95Milliseconds, 30)
        XCTAssertEqual(result.metrics.p99Milliseconds, 30)
        XCTAssertEqual(result.metrics.jitterMilliseconds, 0)
        XCTAssertEqual(result.metrics.packetLossPercentage, 0)
        XCTAssertEqual(result.metrics.spikeCount, 0)
        XCTAssertEqual(result.finalScore, 100)
        XCTAssertEqual(result.resultClass, .excellent)
    }

    func testBR002LossGuardrail() throws {
        // V135-03: 58 válidas a 30 ms + 2 timeouts (3.33% perda > 2.0% guardrail) -> score 59
        let result = try completed(samples: received(58, rtt: 30) + timeouts(2, startingAt: 58))

        XCTAssertEqual(result.metrics.p50Milliseconds, 30)
        XCTAssertEqual(result.metrics.packetLossPercentage, 3.3333333333333335, accuracy: 0.000001)
        XCTAssertEqual(result.finalScore, 59)
        XCTAssertEqual(result.resultClass, .lagRisk)
    }

    func testBR003SevereSpikes() throws {
        // V135-06: Picos severos isolados nas sequências 5 e 40 -> score 74, unstable
        var samples = received(58, rtt: 30)
        samples.append(ProbeSample(sequence: 5, roundTripMilliseconds: 160, outcome: .received))
        samples.append(ProbeSample(sequence: 40, roundTripMilliseconds: 160, outcome: .received))
        samples.sort { $0.sequence < $1.sequence }

        let result = try completed(samples: samples)

        XCTAssertEqual(result.metrics.p50Milliseconds, 30)
        XCTAssertEqual(result.metrics.severeSpikeCount, 2)
        XCTAssertEqual(result.finalScore, 74)
        XCTAssertEqual(result.resultClass, .unstable)
    }

    func testBR004InsufficientUDPResponsesIsInconclusive() {
        let evaluation = QualityEvaluator.evaluateBattleRoyaleCompetitive(
            samples: received(9, rtt: 30) + timeouts(21, startingAt: 9)
        )

        guard case let .inconclusive(reason, diagnostics) = evaluation else {
            return XCTFail("Expected insufficient valid UDP responses to be inconclusive.")
        }
        XCTAssertEqual(reason, .insufficientUDPResponses)
        XCTAssertEqual(diagnostics.validResponseCount, 9)
        XCTAssertEqual(diagnostics.packetLossPercentage, 35.0, accuracy: 0.000001)
    }

    func testBR005ResponseBeforeDrainageDeadlineIsReceived() {
        XCTAssertEqual(
            ProbeAcceptancePolicy.outcome(sentAt: 14.5, receivedAt: 16.499),
            .received
        )
    }

    func testBR006ResponseAfterIndividualTimeoutIsTimeout() {
        XCTAssertEqual(
            ProbeAcceptancePolicy.outcome(sentAt: 14.5, receivedAt: 16.501),
            .timeout
        )
    }

    func testBR007InvalidResponseDoesNotBecomeRTTOrSuccess() {
        let samples = received(29, rtt: 30) + [
            ProbeSample(sequence: 29, outcome: .invalidResponse)
        ]
        let result = try? completed(samples: samples)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.metrics.validResponseCount, 29)
        XCTAssertEqual(result?.metrics.invalidResponseCount, 1)
        XCTAssertEqual(result?.metrics.p50Milliseconds, 30)
        XCTAssertEqual(result?.metrics.jitterMilliseconds, 0)
    }

    func testBR008LatencyInterpolationIsReproducible() throws {
        let result = try completed(samples: received(60, rtt: 50))

        XCTAssertEqual(result.finalScore, 97)
        XCTAssertEqual(result.resultClass, .excellent)
    }

    func testBR009OneTimeoutAppliesLossGuardrailAfterMinimumResponses() throws {
        // V135-02: 59 respostas a 30 ms + 1 timeout (1.67% perda <= 2.0% guardrail) -> score 92 (READY)
        let result = try completed(samples: received(59, rtt: 30) + timeouts(1, startingAt: 59))

        XCTAssertEqual(result.metrics.validResponseCount, 59)
        XCTAssertEqual(result.metrics.packetLossPercentage, 1.6666666666666667, accuracy: 0.000001)
        XCTAssertEqual(result.finalScore, 92)
        XCTAssertEqual(result.resultClass, .excellent)
    }

    func testBR010P50AtHundredDoesNotApplyLatencyGuardrail() throws {
        let result = try completed(samples: received(30, rtt: 100))

        XCTAssertEqual(result.metrics.p50Milliseconds, 100)
        XCTAssertEqual(result.finalScore, 65)
    }

    func testBR011P50AboveHundredAppliesLatencyGuardrail() throws {
        let result = try completed(samples: received(30, rtt: 101))

        XCTAssertEqual(result.metrics.p50Milliseconds, 101)
        XCTAssertEqual(result.finalScore, 59)
        XCTAssertEqual(result.resultClass, .lagRisk)
    }

    func testBR012JitterUsesConsecutiveRTTsInMeasurementSequence() throws {
        let samples = [
            ProbeSample(sequence: 0, roundTripMilliseconds: 30, outcome: .received),
            ProbeSample(sequence: 1, roundTripMilliseconds: 60, outcome: .received)
        ] + received(28, rtt: 30, startingAt: 2)

        let result = try completed(samples: samples)

        XCTAssertEqual(result.metrics.jitterMilliseconds ?? -1, 60.0 / 29.0, accuracy: 0.000001)
    }
}

private extension QualityEvaluatorPilotTests {
    func completed(samples: [ProbeSample]) throws -> QualityResult {
        let evaluation = QualityEvaluator.evaluateBattleRoyaleCompetitive(samples: samples)
        guard case let .completed(result) = evaluation else {
            throw NSError(domain: "QualityEvaluatorPilotTests", code: 1)
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
