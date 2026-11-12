import XCTest
@testable import NolaggyDomain

final class CheckCompletoResultDomainTests: XCTestCase {

    func testHealthyMeasurementProducesHeldVerdictAndAllChecks() throws {
        let restResult = try completedQualityResult(samples: sampleSequence(count: 30, rtt: 25.0))
        let deepResult = DeepCheckResult(
            restResult: restResult,
            metrics: DeepCheckMetrics(
                rest: restResult.metrics,
                load: restResult.metrics,
                loadImpact: DeepCheckLoadImpact(restP50Milliseconds: 25.0, loadP50Milliseconds: 28.0)
            )
        )

        let verdict = CheckCompletoResultEvaluator.evaluateVerdict(result: deepResult, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(verdict, .held)
        XCTAssertEqual(verdict.titleKey, "check_completo.verdict.held")

        let trail = CheckCompletoResultEvaluator.evaluateTrail(result: deepResult, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(trail.networkState, .check)
        XCTAssertEqual(trail.responseState, .check)
        XCTAssertEqual(trail.deliveryState, .check)
        XCTAssertEqual(trail.loadState, .check)
        XCTAssertEqual(trail.regionState, .check)

        let nat = NATTopologySnapshot(
            natType: .type2Moderate,
            cgnatStatus: .notDetected,
            doubleNATStatus: .notDetected
        )
        let compatibility = CheckCompletoResultEvaluator.evaluateCompatibility(
            result: deepResult,
            natSnapshot: nat,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(compatibility.multiplayer, .check)
        XCTAssertEqual(compatibility.calls, .check)
        XCTAssertEqual(compatibility.streaming, .neutral)
    }

    func testMaterialLoadImpactProducesLoadHeavyVerdict() throws {
        let restResult = try completedQualityResult(samples: sampleSequence(count: 30, rtt: 25.0))
        let loadResult = try completedQualityResult(samples: sampleSequence(count: 30, rtt: 55.0))
        let deepResult = DeepCheckResult(
            restResult: restResult,
            metrics: DeepCheckMetrics(
                rest: restResult.metrics,
                load: loadResult.metrics,
                loadImpact: DeepCheckLoadImpact(restP50Milliseconds: 25.0, loadP50Milliseconds: 55.0)
            )
        )

        let verdict = CheckCompletoResultEvaluator.evaluateVerdict(result: deepResult, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(verdict, .loadHeavy)

        let trail = CheckCompletoResultEvaluator.evaluateTrail(result: deepResult, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(trail.loadState, .attention)
        XCTAssertEqual(trail.deliveryState, .check)
    }

    func testPacketLossProducesDeliveryFailedVerdict() throws {
        let samples = sampleSequence(count: 20, rtt: 25.0) + (20..<30).map {
            ProbeSample(sequence: $0, roundTripMilliseconds: nil, outcome: .timeout)
        }
        let restResult = try completedQualityResult(samples: samples)
        let deepResult = DeepCheckResult(
            restResult: restResult,
            metrics: DeepCheckMetrics(rest: restResult.metrics, load: nil, loadImpact: nil)
        )

        let verdict = CheckCompletoResultEvaluator.evaluateVerdict(result: deepResult, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(verdict, .deliveryFailed)

        let trail = CheckCompletoResultEvaluator.evaluateTrail(result: deepResult, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(trail.deliveryState, .attention)
    }

    func testGeneralInstabilityProducesOscillatedVerdict() throws {
        // High latency above guardrail (120ms)
        let restResult = try completedQualityResult(samples: sampleSequence(count: 30, rtt: 120.0))
        let deepResult = DeepCheckResult(
            restResult: restResult,
            metrics: DeepCheckMetrics(rest: restResult.metrics, load: nil, loadImpact: nil)
        )

        let verdict = CheckCompletoResultEvaluator.evaluateVerdict(result: deepResult, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(verdict, .oscillated)

        let trail = CheckCompletoResultEvaluator.evaluateTrail(result: deepResult, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(trail.regionState, .attention)
    }

    func testInconclusiveResultProducesInconclusiveVerdictAndNeutralNodes() {
        let verdict = CheckCompletoResultEvaluator.evaluateVerdict(result: nil, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(verdict, .inconclusive)

        let trail = CheckCompletoResultEvaluator.evaluateTrail(result: nil, profile: .battleRoyaleCompetitive)
        XCTAssertEqual(trail.networkState, .check)
        XCTAssertEqual(trail.responseState, .neutral)
        XCTAssertEqual(trail.deliveryState, .neutral)
        XCTAssertEqual(trail.loadState, .neutral)
        XCTAssertEqual(trail.regionState, .neutral)

        let compatibility = CheckCompletoResultEvaluator.evaluateCompatibility(
            result: nil,
            natSnapshot: nil,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(compatibility.multiplayer, .neutral)
        XCTAssertEqual(compatibility.calls, .neutral)
        XCTAssertEqual(compatibility.streaming, .neutral)
    }

    func testNATRestrictionTriggersAttentionInMultiplayerAndCalls() throws {
        let restResult = try completedQualityResult(samples: sampleSequence(count: 30, rtt: 25.0))
        let deepResult = DeepCheckResult(
            restResult: restResult,
            metrics: DeepCheckMetrics(
                rest: restResult.metrics,
                load: restResult.metrics,
                loadImpact: DeepCheckLoadImpact(restP50Milliseconds: 25.0, loadP50Milliseconds: 28.0)
            )
        )

        let strictNAT = NATTopologySnapshot(
            natType: .type3Strict,
            cgnatStatus: .detected,
            doubleNATStatus: .suspectOrDetected
        )
        let compatibility = CheckCompletoResultEvaluator.evaluateCompatibility(
            result: deepResult,
            natSnapshot: strictNAT,
            profile: .battleRoyaleCompetitive
        )
        XCTAssertEqual(compatibility.multiplayer, .attention)
        XCTAssertEqual(compatibility.calls, .attention)
        XCTAssertEqual(compatibility.streaming, .neutral)
    }

    // MARK: - Helpers

    private func sampleSequence(count: Int, rtt: Double) -> [ProbeSample] {
        (0..<count).map { sequence in
            ProbeSample(sequence: sequence, roundTripMilliseconds: rtt, outcome: .received)
        }
    }

    private func completedQualityResult(samples: [ProbeSample]) throws -> QualityResult {
        let eval = QualityEvaluator.evaluate(samples: samples, profile: .battleRoyaleCompetitive)
        guard case let .completed(result) = eval else {
            throw XCTSkip("Evaluation not completed")
        }
        return result
    }
}
