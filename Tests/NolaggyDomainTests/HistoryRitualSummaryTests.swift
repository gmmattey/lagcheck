import XCTest
@testable import NolaggyDomain

final class HistoryRitualSummaryTests: XCTestCase {
    func testCountsOnlyComparableVerdictsAndSeparatesInconclusive() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let entries = [
            entry(.ready, now),
            entry(.caution, now.addingTimeInterval(-86_400)),
            entry(.notReady, now.addingTimeInterval(-172_800)),
            entry(.inconclusive, now.addingTimeInterval(-86_400 * 3)),
            entry(.inconclusive, now.addingTimeInterval(-86_400 * 3), ruleVersion: "rule-2"),
            entry(.ready, now.addingTimeInterval(-86_400 * 4), regionID: "us-east-1")
        ]

        let summary = try! XCTUnwrap(HistoryRitualSummary(entries: entries, window: .sevenDays, now: now))
        XCTAssertEqual(summary.readyCount, 1)
        XCTAssertEqual(summary.cautionCount, 1)
        XCTAssertEqual(summary.notReadyCount, 1)
        XCTAssertEqual(summary.inconclusiveCount, 1)
        XCTAssertEqual(summary.comparableCount, 3)
        XCTAssertTrue(summary.hasEnoughEvidence)
    }

    func testRequiresThreeChecksAcrossTwoDaysBeforeClaimingARitual() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let sameDay = [entry(.ready, now), entry(.ready, now.addingTimeInterval(-60)), entry(.ready, now.addingTimeInterval(-120))]
        let summary = try! XCTUnwrap(HistoryRitualSummary(entries: sameDay, window: .sevenDays, now: now))
        XCTAssertFalse(summary.hasEnoughEvidence)
    }

    private func entry(
        _ verdict: GameReadinessVerdict,
        _ date: Date,
        regionID: String = "sa-east-1",
        ruleVersion: String = "rule-1"
    ) -> MeasurementHistoryEntry {
        let context = ResolvedMeasurementContext(
            context: GameContext(gameID: "fortnite", market: "BR", platform: .pc, declaredExternalLink: .ethernet),
            catalogVersion: "catalog-1",
            profileID: .battleRoyaleCompetitive,
            profileRuleVersion: ruleVersion,
            regionID: regionID,
            destination: try! ProbeDestination(host: "gamelift-ping.sa-east-1.api.aws", port: 7770),
            strategy: .genericRegion,
            confidence: .medium,
            observedPhoneNetwork: .wifi
        )
        let metrics = QualityMetrics(validResponseCount: verdict == .inconclusive ? 9 : 30, timeoutCount: 0, invalidResponseCount: 0, p50Milliseconds: 30, p95Milliseconds: 30, p99Milliseconds: 30, jitterMilliseconds: 0, packetLossPercentage: 0, spikeCount: 0, severeSpikeCount: 0, spikeRatePercentage: 0, p95ToP50Ratio: 1, worstSpikeMilliseconds: 30, components: nil)
        if verdict == .inconclusive {
            return MeasurementHistoryEntry.completedInconclusive(
                resolvedContext: context,
                diagnostics: metrics,
                completedAt: date
            )
        }
        return MeasurementHistoryEntry(completedAt: date, resolvedContext: context, profileRuleVersion: ruleVersion, result: QualityResult(metrics: metrics, rawScore: 80, finalScore: 80, resultClass: .excellent, appliedGuardrails: []), primaryCause: .stableConnection, readinessVerdict: verdict)
    }
}
