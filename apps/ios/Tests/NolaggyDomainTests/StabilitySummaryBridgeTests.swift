import XCTest
@testable import NolaggyDomain

final class StabilitySummaryBridgeTests: XCTestCase {
    func testOverviewSeparatesNetworksAndComputesRingsThroughSharedEngine() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let entries = [
            makeEntry(verdict: .ready, at: now.addingTimeInterval(-4 * 3600), p50: 20, jitter: 2, loss: 0, loadP50: 26, gameID: "valorant", network: .wifi),
            makeEntry(verdict: .ready, at: now.addingTimeInterval(-3 * 3600), p50: 22, jitter: 3, loss: 0, loadP50: nil, gameID: "fortnite", network: .wifi),
            makeEntry(verdict: .ready, at: now.addingTimeInterval(-2 * 3600), p50: 21, jitter: 2, loss: 0, loadP50: 27, gameID: "cs2", network: .wifi),
            makeEntry(verdict: .caution, at: now.addingTimeInterval(-1 * 3600), p50: 36, jitter: 8, loss: 0.5, loadP50: 46, gameID: "cs2", network: .cellular),
            makeEntry(verdict: .ready, at: now, p50: 24, jitter: 3, loss: 0, loadP50: 30, gameID: "valorant", network: .wifi)
        ]

        let summary = StabilityHistoryAdapter.evaluate(entries: entries, windowDays: 14, now: now)

        XCTAssertEqual(summary.ruleVersion, "stability-summary-v2")
        XCTAssertEqual(summary.totalComparableCount, 4)
        XCTAssertEqual(summary.availableNetworks, ["WIFI", "CELLULAR"])
        XCTAssertTrue(summary.hasSummary)
        XCTAssertTrue(summary.hasMixedContexts)
        XCTAssertTrue(summary.canDrawCurve)
        XCTAssertEqual(summary.points.map(\.connectToPrevious), [false, true, true, false, false])

        // Carga só deve usar os checks do mesmo contexto (Wi-Fi) que realmente mediram fase sob carga (+6, +6, +6)
        XCTAssertNotNil(summary.rings?.load.value)
        XCTAssertEqual(summary.rings?.load.value ?? 0, 6.0, accuracy: 0.2)
    }

    func testQuickChecksLeaveLoadRingEmptyInsteadOfZero() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let entries = [
            makeEntry(verdict: .ready, at: now.addingTimeInterval(-300), p50: 18, jitter: 2, loss: 0, loadP50: nil, network: .wifi),
            makeEntry(verdict: .ready, at: now.addingTimeInterval(-200), p50: 20, jitter: 2, loss: 0, loadP50: nil, network: .wifi),
            makeEntry(verdict: .ready, at: now.addingTimeInterval(-100), p50: 19, jitter: 2, loss: 0, loadP50: nil, network: .wifi)
        ]

        let summary = StabilityHistoryAdapter.evaluate(entries: entries, windowDays: 14, gameIdFilter: "fortnite", now: now)

        XCTAssertTrue(summary.canDrawCurve)
        XCTAssertTrue(summary.hasSummary)
        XCTAssertEqual(summary.stabilityPercentage, 100)
        XCTAssertNil(summary.rings?.load.value)
        XCTAssertEqual(summary.rings?.load.tone, "UNKNOWN")
    }

    func testPerGameSeparatesInconclusiveAndChecksBelowMinimum() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let entries = [
            makeEntry(verdict: .ready, at: now.addingTimeInterval(-200), p50: 25, jitter: 3, loss: 0, loadP50: nil, network: .wifi),
            makeEntry(verdict: .inconclusive, at: now.addingTimeInterval(-100), p50: 99, jitter: 30, loss: 10, loadP50: nil, network: .wifi)
        ]

        let summary = StabilityHistoryAdapter.evaluate(entries: entries, windowDays: 7, gameIdFilter: "fortnite", now: now)

        XCTAssertFalse(summary.canDrawCurve)
        XCTAssertFalse(summary.hasSummary)
        XCTAssertEqual(summary.totalComparableCount, 1)
        XCTAssertEqual(summary.inconclusiveCount, 1)
        XCTAssertEqual(summary.headlineKey, "stability.headline.insufficient")
        XCTAssertEqual(summary.latest?.pingMs, 25)
    }

    private func makeEntry(
        verdict: GameReadinessVerdict,
        at date: Date,
        p50: Double,
        jitter: Double,
        loss: Double,
        loadP50: Double?,
        gameID: String = "fortnite",
        network: NetworkKind = .wifi,
        regionID: String = "sa-east-1"
    ) -> MeasurementHistoryEntry {
        let ruleVersion = QualityEvaluator.ruleVersion(for: .battleRoyaleCompetitive)
        let context = ResolvedMeasurementContext(
            context: GameContext(gameID: gameID, market: "BR", platform: .pc, declaredExternalLink: .ethernet),
            catalogVersion: "catalog-1",
            profileID: .battleRoyaleCompetitive,
            profileRuleVersion: ruleVersion,
            regionID: regionID,
            destination: try! ProbeDestination(host: "gamelift-ping.sa-east-1.api.aws", port: 7770),
            strategy: .genericRegion,
            confidence: .medium,
            observedPhoneNetwork: network
        )
        let metrics = QualityMetrics(
            validResponseCount: verdict == .inconclusive ? 4 : 30,
            timeoutCount: 0,
            invalidResponseCount: 0,
            p50Milliseconds: p50,
            p95Milliseconds: p50 + 5,
            p99Milliseconds: p50 + 10,
            jitterMilliseconds: jitter,
            packetLossPercentage: loss,
            spikeCount: 0,
            severeSpikeCount: 0,
            spikeRatePercentage: 0,
            p95ToP50Ratio: 1.1,
            worstSpikeMilliseconds: p50 + 10,
            components: nil
        )
        if verdict == .inconclusive {
            return .completedInconclusive(
                resolvedContext: context,
                diagnostics: metrics,
                completedAt: date
            )
        }
        let qualityResult = QualityResult(
            metrics: metrics,
            rawScore: 85,
            finalScore: 85,
            resultClass: .excellent,
            appliedGuardrails: []
        )
        let deepCheck: DeepCheckResult? = loadP50.map { load in
            DeepCheckResult(
                restResult: qualityResult,
                metrics: DeepCheckMetrics(
                    rest: metrics,
                    load: nil,
                    loadImpact: DeepCheckLoadImpact(restP50Milliseconds: p50, loadP50Milliseconds: load)
                )
            )
        }
        return MeasurementHistoryEntry(
            completedAt: date,
            kind: deepCheck == nil ? .quick : .deep,
            resolvedContext: context,
            profileRuleVersion: ruleVersion,
            result: qualityResult,
            deepCheck: deepCheck,
            primaryCause: .stableConnection,
            readinessVerdict: verdict
        )
    }
}
