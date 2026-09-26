import XCTest
@testable import NolaggyDomain

final class DeepCheckEvaluatorTests: XCTestCase {
    func testRestScoreIsPreservedAndLoadImpactIsOnlyTheP50Difference() throws {
        let restSamples = received(30, rtt: 30)
        let loadSamples = received(30, rtt: 93)
        let expectedRest = try completedQuickCheck(samples: restSamples)

        let result = try completedDeepCheck(restSamples: restSamples, loadSamples: loadSamples)

        XCTAssertEqual(result.restResult, expectedRest)
        XCTAssertEqual(result.restResult.finalScore, 100)
        XCTAssertEqual(result.restResult.resultClass, .excellent)
        XCTAssertEqual(result.metrics.rest, expectedRest.metrics)
        XCTAssertEqual(result.metrics.load?.p50Milliseconds, 93)
        XCTAssertEqual(result.metrics.loadImpact?.restP50Milliseconds, 30)
        XCTAssertEqual(result.metrics.loadImpact?.loadP50Milliseconds, 93)
        XCTAssertEqual(result.metrics.loadImpact?.increaseMilliseconds, 63)
        XCTAssertEqual(result.metrics.loadImpact?.ruleVersion, "deep-load-impact-v2")
        XCTAssertEqual(result.metrics.loadImpact?.classification, .material)
        XCTAssertEqual(result.metrics.loadImpact?.tier, .severe)
    }

    func testDeepLoadImpactRuleV2TestVectors() {
        // DLI2-01: battleRoyale none
        let tier1 = DeepCheckLoadImpactMaterialityRuleV2.classify(
            profile: .battleRoyaleCompetitive,
            deltaP50: 5,
            deltaJitter: 2,
            deltaLoss: 0,
            deltaSpikes: 0
        )
        XCTAssertEqual(tier1, .none)

        // DLI2-02: battleRoyale light
        let tier2 = DeepCheckLoadImpactMaterialityRuleV2.classify(
            profile: .battleRoyaleCompetitive,
            deltaP50: 12,
            deltaJitter: 5,
            deltaLoss: 0,
            deltaSpikes: 0
        )
        XCTAssertEqual(tier2, .light)

        // DLI2-03: battleRoyale material via deltaP50
        let tier3 = DeepCheckLoadImpactMaterialityRuleV2.classify(
            profile: .battleRoyaleCompetitive,
            deltaP50: 22,
            deltaJitter: 6,
            deltaLoss: 0,
            deltaSpikes: 0
        )
        XCTAssertEqual(tier3, .material)

        // DLI2-04: battleRoyale material via deltaJitter
        let tier4 = DeepCheckLoadImpactMaterialityRuleV2.classify(
            profile: .battleRoyaleCompetitive,
            deltaP50: 10,
            deltaJitter: 10,
            deltaLoss: 0,
            deltaSpikes: 0
        )
        XCTAssertEqual(tier4, .material)

        // DLI2-05: battleRoyale material via deltaLoss
        let tier5 = DeepCheckLoadImpactMaterialityRuleV2.classify(
            profile: .battleRoyaleCompetitive,
            deltaP50: 10,
            deltaJitter: 2,
            deltaLoss: 2.5,
            deltaSpikes: 0
        )
        XCTAssertEqual(tier5, .material)

        // DLI2-06: battleRoyale severe
        let tier6 = DeepCheckLoadImpactMaterialityRuleV2.classify(
            profile: .battleRoyaleCompetitive,
            deltaP50: 45,
            deltaJitter: 25,
            deltaLoss: 6.0,
            deltaSpikes: 4
        )
        XCTAssertEqual(tier6, .severe)
    }

    func testFailedLoadKeepsCompletedRestWithoutImpact() throws {
        let result = try completedDeepCheck(restSamples: received(30, rtt: 30), loadSamples: nil)

        XCTAssertEqual(result.restResult.finalScore, 100)
        XCTAssertNil(result.metrics.load)
        XCTAssertNil(result.metrics.loadImpact)
    }

    func testInsufficientLoadResponsesDoNotExposePartialLoadMetrics() throws {
        let result = try completedDeepCheck(
            restSamples: received(30, rtt: 30),
            loadSamples: received(9, rtt: 90) + timeouts(21, startingAt: 9)
        )

        XCTAssertEqual(result.restResult.finalScore, 100)
        XCTAssertNil(result.metrics.load)
        XCTAssertNil(result.metrics.loadImpact)
    }

    func testInsufficientRestResponsesMakeEntireDeepCheckInconclusive() {
        let evaluation = DeepCheckEvaluator.evaluateBattleRoyaleCompetitive(
            restSamples: received(9, rtt: 30) + timeouts(21, startingAt: 9),
            loadSamples: received(30, rtt: 90)
        )

        guard case let .inconclusive(reason, diagnostics) = evaluation else {
            return XCTFail("Expected an inconclusive rest phase.")
        }
        XCTAssertEqual(reason, .insufficientUDPResponses)
        XCTAssertEqual(diagnostics.validResponseCount, 9)
    }

    func testLoadImpactCanBeNegativeWithoutInventingAClass() throws {
        let result = try completedDeepCheck(
            restSamples: received(30, rtt: 93),
            loadSamples: received(30, rtt: 30)
        )

        XCTAssertEqual(result.metrics.loadImpact?.increaseMilliseconds, -63)
        XCTAssertEqual(result.restResult.resultClass, .great)
        XCTAssertEqual(result.metrics.loadImpact?.classification, .descriptive)
    }

    func testMaterialityUsesTheRawTwentyMillisecondBoundaryWithoutChangingRestScore() throws {
        let noChange = try completedDeepCheck(
            restSamples: received(30, rtt: 30),
            loadSamples: received(30, rtt: 30)
        )
        let belowBoundary = try completedDeepCheck(
            restSamples: received(30, rtt: 30),
            loadSamples: received(30, rtt: 49.999)
        )
        let atBoundary = try completedDeepCheck(
            restSamples: received(30, rtt: 30),
            loadSamples: received(30, rtt: 50)
        )

        XCTAssertEqual(noChange.metrics.loadImpact?.increaseMilliseconds, 0)
        XCTAssertEqual(noChange.metrics.loadImpact?.classification, .descriptive)
        XCTAssertEqual(try XCTUnwrap(belowBoundary.metrics.loadImpact?.increaseMilliseconds), 19.999, accuracy: 0.000_001)
        XCTAssertEqual(belowBoundary.metrics.loadImpact?.classification, .descriptive)
        XCTAssertEqual(try XCTUnwrap(atBoundary.metrics.loadImpact?.increaseMilliseconds), 20, accuracy: 0.000_001)
        XCTAssertEqual(atBoundary.metrics.loadImpact?.classification, .material)
        XCTAssertEqual(belowBoundary.restResult.finalScore, 100)
        XCTAssertEqual(atBoundary.restResult.finalScore, 100)
        XCTAssertEqual(belowBoundary.restResult, atBoundary.restResult)
    }

    func testLegacyImpactSnapshotMigratesToTheVersionedRule() throws {
        let legacy = try JSONDecoder().decode(
            DeepCheckLoadImpact.self,
            from: Data("""
            {
              "restP50Milliseconds": 30,
              "loadP50Milliseconds": 50,
              "increaseMilliseconds": 20
            }
            """.utf8)
        )

        XCTAssertEqual(legacy.ruleVersion, "deep-load-impact-v1")
        XCTAssertEqual(legacy.classification, .material)
    }

    func testDeepResultRoundTripsWithoutRawSamples() throws {
        let result = try completedDeepCheck(
            restSamples: received(30, rtt: 30),
            loadSamples: received(30, rtt: 93)
        )

        let restored = try JSONDecoder().decode(
            DeepCheckResult.self,
            from: JSONEncoder().encode(result)
        )

        XCTAssertEqual(restored, result)
    }

    func testExplicitProfileEntryPointUsesEachPublishedProfileRule() throws {
        let restSamples = received(30, rtt: 70)
        let loadSamples = received(30, rtt: 95)

        for profile in QualityProfileID.allCases {
            let expectedRest = try completedQuickCheck(samples: restSamples, profile: profile)
            let evaluation = DeepCheckEvaluator.evaluate(
                restSamples: restSamples,
                loadSamples: loadSamples,
                profile: profile
            )

            guard case let .completed(result) = evaluation else {
                return XCTFail("\(profile) should complete with valid rest UDP samples.")
            }
            XCTAssertEqual(result.restResult, expectedRest)
            XCTAssertEqual(result.metrics.load?.p50Milliseconds, 95)
            XCTAssertEqual(result.metrics.loadImpact?.increaseMilliseconds, 25)
            XCTAssertEqual(result.metrics.loadImpact?.classification, .material)
        }
    }

    func testProfileConvenienceEntryPointsMatchExplicitDispatch() {
        let restSamples = received(30, rtt: 70)
        let loadSamples = received(30, rtt: 95)

        XCTAssertEqual(
            DeepCheckEvaluator.evaluateMobileRealtime(restSamples: restSamples, loadSamples: loadSamples),
            DeepCheckEvaluator.evaluate(restSamples: restSamples, loadSamples: loadSamples, profile: .mobileRealtime)
        )
        XCTAssertEqual(
            DeepCheckEvaluator.evaluateCasualRealtime(restSamples: restSamples, loadSamples: loadSamples),
            DeepCheckEvaluator.evaluate(restSamples: restSamples, loadSamples: loadSamples, profile: .casualRealtime)
        )
    }
}

private extension DeepCheckEvaluatorTests {
    func completedDeepCheck(restSamples: [ProbeSample], loadSamples: [ProbeSample]?) throws -> DeepCheckResult {
        let evaluation = DeepCheckEvaluator.evaluateBattleRoyaleCompetitive(
            restSamples: restSamples,
            loadSamples: loadSamples
        )
        guard case let .completed(result) = evaluation else {
            throw NSError(domain: "DeepCheckEvaluatorTests", code: 1)
        }
        return result
    }

    func completedQuickCheck(samples: [ProbeSample], profile: QualityProfileID = .battleRoyaleCompetitive) throws -> QualityResult {
        let evaluation = QualityEvaluator.evaluate(samples: samples, profile: profile)
        guard case let .completed(result) = evaluation else {
            throw NSError(domain: "DeepCheckEvaluatorTests", code: 2)
        }
        return result
    }

    func received(_ count: Int, rtt: Double, startingAt: Int = 0) -> [ProbeSample] {
        (0..<count).map {
            ProbeSample(sequence: startingAt + $0, roundTripMilliseconds: rtt, outcome: .received)
        }
    }

    func timeouts(_ count: Int, startingAt: Int) -> [ProbeSample] {
        (0..<count).map { ProbeSample(sequence: startingAt + $0, outcome: .timeout) }
    }
}
