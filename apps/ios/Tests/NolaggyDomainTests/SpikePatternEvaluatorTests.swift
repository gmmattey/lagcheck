import XCTest
@testable import NolaggyDomain

final class SpikePatternEvaluatorTests: XCTestCase {

    func testNoSpikesYieldsNone() {
        let samples = (0..<30).map {
            ProbeSample(sequence: $0, roundTripMilliseconds: 25.0, outcome: .received)
        }
        let pattern = SpikePatternEvaluator.evaluate(samples: samples, p50Milliseconds: 25.0)
        XCTAssertEqual(pattern, .none)
        XCTAssertFalse(pattern.isRecurring)
    }

    func testSingleSpikeYieldsIsolated() {
        var samples = (0..<30).map {
            ProbeSample(sequence: $0, roundTripMilliseconds: 25.0, outcome: .received)
        }
        // Spike: RTT > 25 + 30 = 55 AND >= 80 -> RTT 85
        samples[10] = ProbeSample(sequence: 10, roundTripMilliseconds: 85.0, outcome: .received)

        let pattern = SpikePatternEvaluator.evaluate(samples: samples, p50Milliseconds: 25.0)
        XCTAssertEqual(pattern, .isolated(count: 1, severeCount: 0))
        XCTAssertFalse(pattern.isRecurring)
    }

    func testTwoDispersedSpikesYieldsIsolated() {
        var samples = (0..<30).map {
            ProbeSample(sequence: $0, roundTripMilliseconds: 25.0, outcome: .received)
        }
        // Two spikes far apart (> 5 probes apart)
        samples[2] = ProbeSample(sequence: 2, roundTripMilliseconds: 85.0, outcome: .received)
        samples[20] = ProbeSample(sequence: 20, roundTripMilliseconds: 85.0, outcome: .received)

        let pattern = SpikePatternEvaluator.evaluate(samples: samples, p50Milliseconds: 25.0)
        XCTAssertEqual(pattern, .isolated(count: 2, severeCount: 0))
        XCTAssertFalse(pattern.isRecurring)
    }

    func testTwoSpikesInCloseWindowYieldsRecurring() {
        var samples = (0..<30).map {
            ProbeSample(sequence: $0, roundTripMilliseconds: 25.0, outcome: .received)
        }
        // Two spikes within a 5-probe window (e.g. sequence 10 and 13)
        samples[10] = ProbeSample(sequence: 10, roundTripMilliseconds: 85.0, outcome: .received)
        samples[13] = ProbeSample(sequence: 13, roundTripMilliseconds: 90.0, outcome: .received)

        let pattern = SpikePatternEvaluator.evaluate(samples: samples, p50Milliseconds: 25.0)
        XCTAssertEqual(pattern, .recurring(count: 2, severeCount: 0))
        XCTAssertTrue(pattern.isRecurring)
    }

    func testThreeTotalSpikesYieldsRecurringRegardlessOfSpacing() {
        var samples = (0..<30).map {
            ProbeSample(sequence: $0, roundTripMilliseconds: 25.0, outcome: .received)
        }
        // Three spikes across 30 probes
        samples[1] = ProbeSample(sequence: 1, roundTripMilliseconds: 85.0, outcome: .received)
        samples[15] = ProbeSample(sequence: 15, roundTripMilliseconds: 85.0, outcome: .received)
        samples[28] = ProbeSample(sequence: 28, roundTripMilliseconds: 85.0, outcome: .received)

        let pattern = SpikePatternEvaluator.evaluate(samples: samples, p50Milliseconds: 25.0)
        XCTAssertEqual(pattern, .recurring(count: 3, severeCount: 0))
        XCTAssertTrue(pattern.isRecurring)
    }

    func testSevereSpikesAreCountedCorrectly() {
        var samples = (0..<30).map {
            ProbeSample(sequence: $0, roundTripMilliseconds: 25.0, outcome: .received)
        }
        // Severe spike: RTT > 25 + 80 = 105 AND >= 150 -> RTT 160
        samples[5] = ProbeSample(sequence: 5, roundTripMilliseconds: 160.0, outcome: .received)
        samples[7] = ProbeSample(sequence: 7, roundTripMilliseconds: 170.0, outcome: .received)

        let pattern = SpikePatternEvaluator.evaluate(samples: samples, p50Milliseconds: 25.0)
        XCTAssertEqual(pattern, .recurring(count: 2, severeCount: 2))
        XCTAssertEqual(pattern.severeCount, 2)
    }
}
