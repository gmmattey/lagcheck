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

    func testSummaryRefusesDifferentDeclaredExternalLink() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let latest = entry(score: 90, date: now, declaredExternalLink: .wifi)
        let ethernet = entry(score: 40, date: now.addingTimeInterval(-86_400), declaredExternalLink: .ethernet)

        let summary = MeasurementHistorySummary(entries: [latest, ethernet], now: now)
        XCTAssertNil(summary?.sevenDayAverageScore)
        XCTAssertNil(summary?.trend)
    }

    func testSummaryRefusesDifferentObservedPhoneNetwork() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let latest = entry(score: 90, date: now, observedPhoneNetwork: .wifi)
        let cellular = entry(score: 40, date: now.addingTimeInterval(-86_400), observedPhoneNetwork: .cellular)

        let summary = MeasurementHistorySummary(entries: [latest, cellular], now: now)
        XCTAssertNil(summary?.sevenDayAverageScore)
        XCTAssertNil(summary?.trend)
    }

    func testLegacySnapshotDoesNotParticipateInComparison() throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let current = entry(score: 90, date: now)
        let legacyContext = try legacyContext(from: current.resolvedContext)
        let legacy = MeasurementHistoryEntry(
            completedAt: now.addingTimeInterval(-86_400),
            resolvedContext: legacyContext,
            profileRuleVersion: "rule-1",
            result: current.result,
            primaryCause: .stableConnection
        )

        XCTAssertNil(legacy.resolvedContext.context.declaredExternalLink)
        XCTAssertNil(legacy.resolvedContext.observedPhoneNetwork)
        XCTAssertFalse(legacy.resolvedContext.hasCompleteConnectionFacts)
        XCTAssertNil(MeasurementHistorySummary(entries: [current, legacy], now: now)?.sevenDayAverageScore)
        XCTAssertNil(MeasurementHistorySummary(entries: [current, legacy], now: now)?.trend)
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
        declaredExternalLink: ExternalEquipmentLink? = nil,
        observedPhoneNetwork: NetworkKind? = .wifi,
        platform: Platform = .pc,
        regionID: String = "sa-east-1",
        validResponseCount: Int = 30
    ) -> MeasurementHistoryEntry {
        let context = resolvedContext(
            gameID: gameID,
            declaredExternalLink: declaredExternalLink,
            platform: platform,
            regionID: regionID,
            observedPhoneNetwork: observedPhoneNetwork
        )
        let metrics = QualityMetrics(validResponseCount: validResponseCount, timeoutCount: 0, invalidResponseCount: 0, p50Milliseconds: 30, p95Milliseconds: 30, p99Milliseconds: 30, jitterMilliseconds: 0, packetLossPercentage: 0, spikeCount: 0, severeSpikeCount: 0, spikeRatePercentage: 0, p95ToP50Ratio: 1, worstSpikeMilliseconds: 30, components: nil)
        return MeasurementHistoryEntry(completedAt: date, resolvedContext: context, profileRuleVersion: ruleVersion, result: QualityResult(metrics: metrics, rawScore: score, finalScore: score, resultClass: .excellent, appliedGuardrails: []), primaryCause: .stableConnection)
    }

    private func resolvedContext(
        gameID: String,
        declaredExternalLink: ExternalEquipmentLink?,
        platform: Platform,
        regionID: String,
        observedPhoneNetwork: NetworkKind?
    ) -> ResolvedMeasurementContext {
        let destination = try! ProbeDestination(host: "gamelift-ping.sa-east-1.api.aws", port: 7770)
        return ResolvedMeasurementContext(
            context: GameContext(gameID: gameID, market: "BR", platform: platform, declaredExternalLink: declaredExternalLink),
            catalogVersion: "catalog-1",
            profileID: .battleRoyaleCompetitive,
            profileRuleVersion: "rule-1",
            regionID: regionID,
            destination: destination,
            strategy: .genericRegion,
            confidence: .medium,
            observedPhoneNetwork: observedPhoneNetwork
        )
    }

    private func legacyContext(from current: ResolvedMeasurementContext) throws -> ResolvedMeasurementContext {
        var envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(current)) as? [String: Any])
        envelope.removeValue(forKey: "observedPhoneNetwork")
        envelope.removeValue(forKey: "connectionFactsVersion")
        var context = try XCTUnwrap(envelope["context"] as? [String: Any])
        context.removeValue(forKey: "declaredExternalLink")
        context["equipmentConnection"] = "wifi"
        envelope["context"] = context
        return try JSONDecoder().decode(ResolvedMeasurementContext.self, from: JSONSerialization.data(withJSONObject: envelope))
    }
}
