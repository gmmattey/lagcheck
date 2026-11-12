import XCTest
@testable import NolaggyDomain

final class SampleQualityEvaluatorTests: XCTestCase {

    func testEmptySamplesProducesNormalStatus() {
        let assessment = SampleQualityEvaluator.assess(samples: [])
        XCTAssertEqual(assessment.status, .normal)
        XCTAssertEqual(assessment.consecutiveTimeouts, 0)
        XCTAssertEqual(assessment.earlyLossPercentage, 0.0)
    }

    func testHealthySamplesProduceNormalStatus() {
        let samples = (1...15).map {
            ProbeSample(sequence: $0, roundTripMilliseconds: 25.0, outcome: .received)
        }
        let assessment = SampleQualityEvaluator.assess(samples: samples)
        XCTAssertEqual(assessment.status, .normal)
        XCTAssertEqual(assessment.consecutiveTimeouts, 0)
        XCTAssertEqual(assessment.earlyLossPercentage, 0.0)
    }

    func testFourConsecutiveTimeoutsInFirstSixProbesAbortsEarly() {
        let samples = [
            ProbeSample(sequence: 1, roundTripMilliseconds: 25.0, outcome: .received),
            ProbeSample(sequence: 2, roundTripMilliseconds: nil, outcome: .timeout),
            ProbeSample(sequence: 3, roundTripMilliseconds: nil, outcome: .timeout),
            ProbeSample(sequence: 4, roundTripMilliseconds: nil, outcome: .timeout),
            ProbeSample(sequence: 5, roundTripMilliseconds: nil, outcome: .timeout)
        ]
        let assessment = SampleQualityEvaluator.assess(samples: samples)
        XCTAssertEqual(assessment.status, .shouldAbort(reason: .poorSampleQuality))
        XCTAssertEqual(assessment.consecutiveTimeouts, 4)
    }

    func testSevereInitialLossRateInFirstTenProbesAbortsEarly() {
        // 7 timeouts out of 9 probes = 77.7% loss
        var samples: [ProbeSample] = []
        samples.append(ProbeSample(sequence: 1, roundTripMilliseconds: 20.0, outcome: .received))
        samples.append(ProbeSample(sequence: 2, roundTripMilliseconds: nil, outcome: .timeout))
        samples.append(ProbeSample(sequence: 3, roundTripMilliseconds: nil, outcome: .timeout))
        samples.append(ProbeSample(sequence: 4, roundTripMilliseconds: 25.0, outcome: .received))
        samples.append(ProbeSample(sequence: 5, roundTripMilliseconds: nil, outcome: .timeout))
        samples.append(ProbeSample(sequence: 6, roundTripMilliseconds: nil, outcome: .timeout))
        samples.append(ProbeSample(sequence: 7, roundTripMilliseconds: nil, outcome: .timeout))
        samples.append(ProbeSample(sequence: 8, roundTripMilliseconds: nil, outcome: .timeout))
        samples.append(ProbeSample(sequence: 9, roundTripMilliseconds: nil, outcome: .timeout))

        let assessment = SampleQualityEvaluator.assess(samples: samples)
        XCTAssertEqual(assessment.status, .shouldAbort(reason: .poorSampleQuality))
        XCTAssertGreaterThanOrEqual(assessment.earlyLossPercentage, 70.0)
    }

    func testSuddenDisconnectWithSixConsecutiveTimeoutsAborts() {
        var samples: [ProbeSample] = (1...12).map {
            ProbeSample(sequence: $0, roundTripMilliseconds: 22.0, outcome: .received)
        }
        // Suddenly 6 timeouts occur
        for seq in 13...18 {
            samples.append(ProbeSample(sequence: seq, roundTripMilliseconds: nil, outcome: .timeout))
        }

        let assessment = SampleQualityEvaluator.assess(samples: samples)
        XCTAssertEqual(assessment.status, .shouldAbort(reason: .poorSampleQuality))
        XCTAssertEqual(assessment.consecutiveTimeouts, 6)
    }

    func testGatewayOutcomeEvaluationFromTelemetry() {
        // Unobservable when not Wi-Fi
        let cellularTelemetry = WiFiLocalTelemetry(isWiFi: false)
        XCTAssertEqual(cellularTelemetry.gatewayOutcome, .unobservable)

        // Unobservable when gateway didn't answer (0 valid out of 5 planned)
        let unrespTelemetry = WiFiLocalTelemetry(validSampleCount: 0, plannedSampleCount: 5, isWiFi: true)
        XCTAssertEqual(unrespTelemetry.gatewayOutcome, .unobservable)

        // Stable when fast RTT and no loss
        let stableTelemetry = WiFiLocalTelemetry(
            gatewayRTTMedianMs: 2.1,
            gatewayJitterMs: 0.8,
            validSampleCount: 5,
            plannedSampleCount: 5,
            isWiFi: true
        )
        XCTAssertEqual(stableTelemetry.gatewayOutcome, .stable(rttMilliseconds: 2.1))
        XCTAssertTrue(stableTelemetry.gatewayOutcome.isStable)
        XCTAssertFalse(stableTelemetry.gatewayOutcome.isDegraded)

        // Degraded when RTT > 15ms or loss
        let degradedTelemetry = WiFiLocalTelemetry(
            gatewayRTTMedianMs: 22.5,
            gatewayJitterMs: 14.0,
            validSampleCount: 4,
            plannedSampleCount: 5,
            isWiFi: true
        )
        XCTAssertEqual(degradedTelemetry.gatewayOutcome, .degraded(rttMilliseconds: 22.5, lossPercentage: 20.0))
        XCTAssertTrue(degradedTelemetry.gatewayOutcome.isDegraded)
        XCTAssertFalse(degradedTelemetry.gatewayOutcome.isStable)
    }
}
