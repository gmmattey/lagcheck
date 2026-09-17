import XCTest
@testable import NolaggyDomain

final class QualityEvaluatorExpandedProfileTests: XCTestCase {
    func testMR001StableMobileRealtimeUsesItsOwnVersionedThresholds() throws {
        let result = try completed(QualityEvaluator.evaluateMobileRealtime(samples: received(30, rtt: 50)))
        XCTAssertEqual(result.finalScore, 100)
        XCTAssertEqual(result.resultClass, .excellent)
    }

    func testMR002MobileLossAboveFivePercentAppliesGuardrail() throws {
        let result = try completed(QualityEvaluator.evaluateMobileRealtime(samples: received(28, rtt: 50) + timeouts(2, startingAt: 28)))
        XCTAssertEqual(result.metrics.packetLossPercentage, 6.666666666666667, accuracy: 0.000001)
        XCTAssertEqual(result.finalScore, 59)
        XCTAssertEqual(result.appliedGuardrails, [.excessiveLossOrLatency])
    }

    func testCR001StableCasualRealtimeUsesItsOwnVersionedThresholds() throws {
        let result = try completed(QualityEvaluator.evaluateCasualRealtime(samples: received(30, rtt: 70)))
        XCTAssertEqual(result.finalScore, 100)
        XCTAssertEqual(result.resultClass, .excellent)
    }

    func testCR002CasualLatencyAboveOneHundredEightyAppliesGuardrail() throws {
        let result = try completed(QualityEvaluator.evaluateCasualRealtime(samples: received(30, rtt: 181)))
        XCTAssertEqual(result.finalScore, 59)
        XCTAssertEqual(result.appliedGuardrails, [.excessiveLossOrLatency])
    }
}

private extension QualityEvaluatorExpandedProfileTests {
    func completed(_ evaluation: MeasurementEvaluation) throws -> QualityResult {
        guard case let .completed(result) = evaluation else { throw NSError(domain: "QualityEvaluatorExpandedProfileTests", code: 1) }
        return result
    }

    func received(_ count: Int, rtt: Double, startingAt: Int = 0) -> [ProbeSample] {
        (0..<count).map { ProbeSample(sequence: startingAt + $0, roundTripMilliseconds: rtt, outcome: .received) }
    }

    func timeouts(_ count: Int, startingAt: Int) -> [ProbeSample] {
        (0..<count).map { ProbeSample(sequence: startingAt + $0, outcome: .timeout) }
    }
}
