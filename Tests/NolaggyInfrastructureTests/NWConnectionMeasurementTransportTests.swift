import XCTest
@testable import NolaggyInfrastructure
@testable import NolaggyDomain

final class NWConnectionMeasurementTransportTests: XCTestCase {
    func testAcceptsOnlyTheExactEchoBeforeItsIndividualTimeout() {
        let payload = Data(repeating: 7, count: 33)
        let ledger = ProbeLedger(probes: [(sequence: 0, payload: payload)])
        ledger.register(sequence: 0, payload: payload, sentAt: 1_000_000_000)

        XCTAssertEqual(
            ledger.accept(response: payload, receivedAt: 1_125_000_000),
            ProbeSample(sequence: 0, roundTripMilliseconds: 125, outcome: .received)
        )

        XCTAssertEqual(
            ledger.finish(at: 17_000_000_000),
            [ProbeSample(sequence: 0, roundTripMilliseconds: 125, outcome: .received)]
        )
    }

    func testRejectsDifferentDuplicateAndLateResponsesWithoutTurningThemIntoSuccess() {
        let payload = Data(repeating: 7, count: 33)
        let differentPayload = Data(repeating: 8, count: 33)
        let ledger = ProbeLedger(probes: [(sequence: 0, payload: payload)])
        ledger.register(sequence: 0, payload: payload, sentAt: 1_000_000_000)

        XCTAssertNil(ledger.accept(response: differentPayload, receivedAt: 1_100_000_000))
        XCTAssertNil(ledger.accept(response: payload, receivedAt: 3_000_000_000))

        let samples = ledger.finish(at: 17_000_000_000)
        XCTAssertEqual(samples.filter { $0.outcome == .received }.count, 0)
        XCTAssertEqual(samples.filter { $0.outcome == .timeout }.count, 1)
        XCTAssertEqual(samples.filter { $0.outcome == .invalidResponse }.count, 2)
    }

    func testTransportErrorDoesNotBecomeAValidResponse() {
        let payload = Data(repeating: 7, count: 33)
        let ledger = ProbeLedger(probes: [(sequence: 0, payload: payload)])
        ledger.register(sequence: 0, payload: payload, sentAt: 1_000_000_000)
        ledger.markTransportError(sequence: 0)

        XCTAssertEqual(
            ledger.finish(at: 17_000_000_000),
            [ProbeSample(sequence: 0, outcome: .transportError)]
        )
    }

    func testFinalSamplesUseSendingSequenceWhenCorrelatedResponsesArriveOutOfOrder() {
        let first = Data(repeating: 1, count: 33)
        let second = Data(repeating: 2, count: 33)
        let ledger = ProbeLedger(probes: [
            (sequence: 0, payload: first),
            (sequence: 1, payload: second)
        ])
        ledger.register(sequence: 0, payload: first, sentAt: 1_000_000_000)
        ledger.register(sequence: 1, payload: second, sentAt: 1_000_000_000)

        XCTAssertEqual(
            ledger.accept(response: second, receivedAt: 1_050_000_000),
            ProbeSample(sequence: 1, roundTripMilliseconds: 50, outcome: .received)
        )
        XCTAssertEqual(
            ledger.accept(response: first, receivedAt: 1_100_000_000),
            ProbeSample(sequence: 0, roundTripMilliseconds: 100, outcome: .received)
        )

        XCTAssertEqual(
            ledger.finish(at: 17_000_000_000),
            [
                ProbeSample(sequence: 0, roundTripMilliseconds: 100, outcome: .received),
                ProbeSample(sequence: 1, roundTripMilliseconds: 50, outcome: .received)
            ]
        )
    }
}
