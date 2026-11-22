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
        XCTAssertEqual(result.metrics.loadImpact?.ruleVersion, "deep-load-impact-v4")
        XCTAssertEqual(result.metrics.loadImpact?.classification, .material)
        XCTAssertEqual(result.metrics.loadImpact?.tier, .severe)
    }

    func testDeepLoadImpactRuleV2TestVectors() {
        func c(_ p: Double, _ j: Double, _ l: Double, _ s: Int) -> LoadDegradationTier {
            DeepCheckLoadImpactMaterialityRuleV2.classify(profile: .battleRoyaleCompetitive, deltaP50: p, deltaJitter: j, deltaLoss: l, deltaSpikes: s)
        }
        XCTAssertEqual(c(5.0, 2.0, 0.0, 0), .light)
        XCTAssertEqual(c(12.0, 5.0, 0.0, 0), .light)
        XCTAssertEqual(c(22.0, 6.0, 0.0, 0), .material)
        XCTAssertEqual(c(10.0, 10.0, 0.0, 0), .material)
        // Decisão 136 (v4): perda sob carga em pacotes; 1 é ruído, 2 é material, 3 é severo no BR.
        XCTAssertEqual(c(10.0, 2.0, 100.0 / 60.0, 0), .light)
        XCTAssertEqual(c(10.0, 2.0, 200.0 / 60.0, 0), .material)
        XCTAssertEqual(c(10.0, 2.0, 300.0 / 60.0, 0), .severe)
        XCTAssertEqual(c(4.9, 0.0, 0.0, 0), .none)
        XCTAssertEqual(c(14.9, 0.0, 0.0, 0), .light)
        XCTAssertEqual(c(15.0, 0.0, 0.0, 0), .material)
        XCTAssertEqual(c(35.0, 0.0, 0.0, 0), .severe)
        XCTAssertEqual(c(5.0, 0.0, 0.0, 2), .material)
        XCTAssertEqual(c(5.0, 0.0, 0.0, 4), .severe)
        XCTAssertEqual(c(45.0, 25.0, 6.0, 4), .severe)
    }

    func testFailedLoadMakesDeepCheckInconclusive() {
        let evaluation = DeepCheckEvaluator.evaluateBattleRoyaleCompetitive(
            restSamples: received(30, rtt: 30),
            loadSamples: nil
        )

        guard case let .inconclusive(reason, diagnostics) = evaluation else {
            return XCTFail("A Deep Check without load samples must be inconclusive")
        }
        XCTAssertEqual(reason, .insufficientUDPResponses)
        XCTAssertEqual(diagnostics.p50Milliseconds, 30)
    }

    func testInsufficientLoadResponsesDoNotExposePartialLoadMetrics() throws {
        // V135-09: Carga com menos de 20 respostas válidas torna a medição inconclusiva (POOR_SAMPLE_QUALITY)
        let eval = DeepCheckEvaluator.evaluateBattleRoyaleCompetitive(
            restSamples: received(30, rtt: 30),
            loadSamples: received(9, rtt: 90) + timeouts(21, startingAt: 9)
        )
        guard case let .inconclusive(reason, _) = eval else {
            return XCTFail("Expected inconclusive when load responses < 20")
        }
        XCTAssertEqual(reason, .poorSampleQuality)
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

    func testBufferbloatGradeThresholdBoundaries() {
        XCTAssertEqual(BufferbloatRuleV1.version, "bufferbloat-grade-v1")
        
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: -5.0), .aPlus)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 0.0), .aPlus)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 2.0), .aPlus)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 2.001), .a)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 5.0), .a)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 5.01), .b)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 15.0), .b)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 15.001), .c)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 35.0), .c)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 35.01), .d)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 60.0), .d)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 60.001), .f)
        XCTAssertEqual(BufferbloatGrade(increaseMilliseconds: 120.0), .f)
    }

    func testBufferbloatDecodingFallbackForLegacyPayload() throws {
        // JSON sem o campo 'bufferbloatGrade' (payload legado pré-Decisão 74)
        let legacyJSON = """
        {
            "restP50Milliseconds": 20.0,
            "loadP50Milliseconds": 24.0,
            "increaseMilliseconds": 4.0,
            "ruleVersion": "materiality-2026.09.19.1",
            "classification": "descriptive",
            "tier": "none"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(DeepCheckLoadImpact.self, from: legacyJSON)
        XCTAssertEqual(decoded.bufferbloatGrade, .a) // 4.0ms -> Grade A
    }

    func testBufferbloatIntegratedInCompletedDeepCheck() throws {
        let rest = received(30, rtt: 20.0)
        let load = received(30, rtt: 23.0) // delta = +3.0 -> Grade A
        let result = try completedDeepCheck(restSamples: rest, loadSamples: load)
        XCTAssertEqual(result.metrics.loadImpact?.bufferbloatGrade, .a)
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
