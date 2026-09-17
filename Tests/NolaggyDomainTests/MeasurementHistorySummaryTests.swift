import XCTest
@testable import NolaggyDomain

final class MeasurementHistorySummaryTests: XCTestCase {
    func testSevenDayAverageRequiresTwoDifferentDays() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let sameDay = [entry(score: 80, date: now), entry(score: 90, date: now.addingTimeInterval(-60))]
        XCTAssertNil(MeasurementHistorySummary(entries: sameDay, now: now)?.sevenDayAverageScore)

        let differentDays = [entry(score: 80, date: now), entry(score: 90, date: now.addingTimeInterval(-86_400))]
        XCTAssertEqual(MeasurementHistorySummary(entries: differentDays, now: now)?.sevenDayAverageScore, 85)
    }

    func testTrendRefusesDifferentRuleVersions() {
        let now = Date()
        let newer = entry(score: 95, date: now, ruleVersion: "rule-2")
        let older = entry(score: 70, date: now.addingTimeInterval(-86_400), ruleVersion: "rule-1")
        XCTAssertNil(MeasurementHistorySummary(entries: [newer, older], now: now)?.trend)
    }

    private func entry(score: Int, date: Date, ruleVersion: String = "rule-1") -> MeasurementHistoryEntry {
        let context = try! PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "BR", platform: .iphone))
        let metrics = QualityMetrics(validResponseCount: 30, timeoutCount: 0, invalidResponseCount: 0, p50Milliseconds: 30, p95Milliseconds: 30, p99Milliseconds: 30, jitterMilliseconds: 0, packetLossPercentage: 0, spikeCount: 0, severeSpikeCount: 0, spikeRatePercentage: 0, p95ToP50Ratio: 1, worstSpikeMilliseconds: 30, components: nil)
        return MeasurementHistoryEntry(completedAt: date, resolvedContext: context, profileRuleVersion: ruleVersion, result: QualityResult(metrics: metrics, rawScore: score, finalScore: score, resultClass: .excellent, appliedGuardrails: []), primaryCause: .stableConnection)
    }
}
