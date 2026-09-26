import XCTest
@testable import NolaggyDomain

final class HighImpactOptimizationTests: XCTestCase {

    func testConsoleOnWiFiRecommendsEthernetCableAsTopPriority() {
        let evaluation = GameReadinessEvaluation(
            verdict: .ready,
            headlineKey: "game_readiness.verdict.ready",
            subtitleKey: "game_readiness.subtitle.ready",
            stabilityRatio: 1.0,
            stabilitySummaryKey: "game_readiness.stability.stable",
            findings: [],
            pingMs: 15.0,
            jitterMs: 1.5,
            packetLossPercentage: 0.0,
            isUnderLoadAffected: false
        )

        let opt = HighImpactOptimizationEvaluator.evaluateSingleTopOptimization(
            targetPlatform: .playstation,
            evaluation: evaluation,
            isWiFi: true
        )

        XCTAssertTrue(opt.isCritical)
        XCTAssertEqual(opt.systemImage, "cable.connector")
        XCTAssertTrue(opt.title.contains("Cabo Ethernet"))
    }

    func testLocalGatewayDegradationRecommends5GHz() {
        let findings = [
            NetworkFinding(kind: .localGateway, severity: .warning, labelKey: "finding.wifi.contention")
        ]
        let evaluation = GameReadinessEvaluation(
            verdict: .caution,
            headlineKey: "game_readiness.verdict.caution",
            subtitleKey: "game_readiness.subtitle.caution",
            stabilityRatio: 0.7,
            stabilitySummaryKey: "game_readiness.stability.jitter",
            findings: findings,
            pingMs: 25.0,
            jitterMs: 6.0,
            packetLossPercentage: 0.0,
            isUnderLoadAffected: false
        )

        let opt = HighImpactOptimizationEvaluator.evaluateSingleTopOptimization(
            targetPlatform: .iphone,
            evaluation: evaluation,
            isWiFi: true
        )

        XCTAssertTrue(opt.isCritical)
        XCTAssertTrue(opt.title.contains("5 GHz"))
    }

    func testLoadDegradationRecommendsSQMAndPauseDownloads() {
        let findings = [
            NetworkFinding(kind: .loadDegradation, severity: .negative, labelKey: "finding.load.heavy")
        ]
        let evaluation = GameReadinessEvaluation(
            verdict: .caution,
            headlineKey: "game_readiness.verdict.caution",
            subtitleKey: "game_readiness.subtitle.caution",
            stabilityRatio: 0.6,
            stabilitySummaryKey: "game_readiness.stability.load",
            findings: findings,
            pingMs: 22.0,
            jitterMs: 2.0,
            packetLossPercentage: 0.0,
            isUnderLoadAffected: true
        )

        let opt = HighImpactOptimizationEvaluator.evaluateSingleTopOptimization(
            targetPlatform: .iphone,
            evaluation: evaluation,
            isWiFi: true
        )

        XCTAssertTrue(opt.isCritical)
        XCTAssertTrue(opt.title.contains("SQM"))
    }

    func testReadyVerdictRecommendsProSetup() {
        let evaluation = GameReadinessEvaluation(
            verdict: .ready,
            headlineKey: "game_readiness.verdict.ready",
            subtitleKey: "game_readiness.subtitle.ready",
            stabilityRatio: 1.0,
            stabilitySummaryKey: "game_readiness.stability.stable",
            findings: [],
            pingMs: 12.0,
            jitterMs: 1.0,
            packetLossPercentage: 0.0,
            isUnderLoadAffected: false
        )

        let opt = HighImpactOptimizationEvaluator.evaluateSingleTopOptimization(
            targetPlatform: .iphone,
            evaluation: evaluation,
            isWiFi: true
        )

        XCTAssertFalse(opt.isCritical)
        XCTAssertEqual(opt.systemImage, "checkmark.seal.fill")
    }
}
