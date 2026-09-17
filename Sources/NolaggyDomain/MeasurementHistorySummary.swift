import Foundation

public enum MeasurementTrend: String, Equatable, Sendable {
    case improving
    case worsening
    case stable
}

/// Deriva acompanhamento somente de fatos comparáveis; nunca recalcula scores históricos.
public struct MeasurementHistorySummary: Equatable, Sendable {
    public let latest: MeasurementHistoryEntry
    public let sevenDayAverageScore: Int?
    public let trend: MeasurementTrend?

    public init?(entries: [MeasurementHistoryEntry], now: Date = Date(), calendar: Calendar = .current) {
        guard let latest = entries.max(by: { $0.completedAt < $1.completedAt }) else { return nil }
        self.latest = latest

        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let week = entries.filter { $0.completedAt >= sevenDaysAgo }
        let days = Set(week.map { calendar.startOfDay(for: $0.completedAt) })
        if days.count >= 2 {
            sevenDayAverageScore = Int((Double(week.map(\.result.finalScore).reduce(0, +)) / Double(week.count)).rounded())
        } else {
            sevenDayAverageScore = nil
        }

        let comparable = entries
            .filter {
                $0.resolvedContext.context == latest.resolvedContext.context &&
                $0.resolvedContext.regionID == latest.resolvedContext.regionID &&
                $0.profileRuleVersion == latest.profileRuleVersion
            }
            .sorted { $0.completedAt > $1.completedAt }
        guard comparable.count >= 2 else {
            trend = nil
            return
        }
        let delta = comparable[0].result.finalScore - comparable[1].result.finalScore
        trend = delta > 3 ? .improving : delta < -3 ? .worsening : .stable
    }
}
