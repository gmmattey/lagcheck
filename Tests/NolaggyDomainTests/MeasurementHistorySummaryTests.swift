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

    func testSummaryRefusesDifferentEquipmentConnection() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let latest = entry(score: 90, date: now, equipmentConnection: .wifi)
        let cellular = entry(score: 40, date: now.addingTimeInterval(-86_400), equipmentConnection: .cellular)

        let summary = MeasurementHistorySummary(entries: [latest, cellular], now: now)
        XCTAssertNil(summary?.sevenDayAverageScore)
        XCTAssertNil(summary?.trend)
    }

    func testSummaryRefusesDifferentGame() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let latest = entry(score: 90, date: now, gameID: "fortnite")
        let otherGame = entry(score: 40, date: now.addingTimeInterval(-86_400), gameID: "minecraft")

        let summary = MeasurementHistorySummary(entries: [latest, otherGame], now: now)
        XCTAssertNil(summary?.sevenDayAverageScore)
        XCTAssertNil(summary?.trend)
    }

    func testSummaryRefusesDifferentPlatformOrReferenceRegion() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let latest = entry(score: 90, date: now)
        let otherPlatform = entry(score: 40, date: now.addingTimeInterval(-86_400), platform: .xbox)
        let otherRegion = entry(score: 40, date: now.addingTimeInterval(-172_800), regionID: "us-east-1")

        let summary = MeasurementHistorySummary(entries: [latest, otherPlatform, otherRegion], now: now)
        XCTAssertNil(summary?.sevenDayAverageScore)
        XCTAssertNil(summary?.trend)
    }

    func testSummaryExcludesInconclusiveEntriesFromAverageAndTrend() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let latest = entry(score: 90, date: now)
        let inconclusive = entry(score: 10, date: now.addingTimeInterval(-86_400), validResponseCount: 9)

        let summary = MeasurementHistorySummary(entries: [latest, inconclusive], now: now)
        XCTAssertNil(summary?.sevenDayAverageScore)
        XCTAssertNil(summary?.trend)
    }

    private func entry(
        score: Int,
        date: Date,
        ruleVersion: String = "rule-1",
        gameID: String = "fortnite",
        equipmentConnection: NetworkKind? = nil,
        platform: Platform = .pc,
        regionID: String = "sa-east-1",
        validResponseCount: Int = 30
    ) -> MeasurementHistoryEntry {
        let context = resolvedContext(
            gameID: gameID,
            equipmentConnection: equipmentConnection,
            platform: platform,
            regionID: regionID
        )
        let metrics = QualityMetrics(validResponseCount: validResponseCount, timeoutCount: 0, invalidResponseCount: 0, p50Milliseconds: 30, p95Milliseconds: 30, p99Milliseconds: 30, jitterMilliseconds: 0, packetLossPercentage: 0, spikeCount: 0, severeSpikeCount: 0, spikeRatePercentage: 0, p95ToP50Ratio: 1, worstSpikeMilliseconds: 30, components: nil)
        return MeasurementHistoryEntry(completedAt: date, resolvedContext: context, profileRuleVersion: ruleVersion, result: QualityResult(metrics: metrics, rawScore: score, finalScore: score, resultClass: .excellent, appliedGuardrails: []), primaryCause: .stableConnection)
    }

    private func resolvedContext(
        gameID: String,
        equipmentConnection: NetworkKind?,
        platform: Platform,
        regionID: String
    ) -> ResolvedMeasurementContext {
        let destination = try! ProbeDestination(host: "gamelift-ping.sa-east-1.api.aws", port: 7770)
        return ResolvedMeasurementContext(
            context: GameContext(gameID: gameID, market: "BR", platform: platform, equipmentConnection: equipmentConnection),
            catalogVersion: "catalog-1",
            profileID: .battleRoyaleCompetitive,
            profileRuleVersion: "rule-1",
            regionID: regionID,
            destination: destination,
            strategy: .genericRegion,
            confidence: .medium
        )
    }
}
