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
        let week = entries.filter {
            $0.completedAt >= sevenDaysAgo && Self.isComparable($0, to: latest)
        }
        let days = Set(week.map { calendar.startOfDay(for: $0.completedAt) })
        if days.count >= 2 {
            sevenDayAverageScore = Int((Double(week.map(\.result.finalScore).reduce(0, +)) / Double(week.count)).rounded())
        } else {
            sevenDayAverageScore = nil
        }

        let comparable = entries
            .filter { Self.isComparable($0, to: latest) }
            .sorted { $0.completedAt > $1.completedAt }
        guard comparable.count >= 2 else {
            trend = nil
            return
        }
        let delta = comparable[0].result.finalScore - comparable[1].result.finalScore
        trend = delta > 3 ? .improving : delta < -3 ? .worsening : .stable
    }

    /// Um score só é comparável quando veio de evidência UDP suficiente e do mesmo
    /// recorte de jogo, equipamento, conexão, região e regra da medição mais recente.
    /// O histórico preserva os scores originais: esta seleção nunca os recalcula.
    private static func isComparable(_ entry: MeasurementHistoryEntry, to latest: MeasurementHistoryEntry) -> Bool {
        guard entry.result.metrics.validResponseCount >= 10 else { return false }

        let entryContext = entry.resolvedContext
        let latestContext = latest.resolvedContext
        return entryContext.context.gameID == latestContext.context.gameID &&
            entryContext.context.platform == latestContext.context.platform &&
            entryContext.context.equipmentConnection == latestContext.context.equipmentConnection &&
            entryContext.regionID == latestContext.regionID &&
            entry.profileRuleVersion == latest.profileRuleVersion
    }
}
