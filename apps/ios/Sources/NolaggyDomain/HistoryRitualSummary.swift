import Foundation

/// Resumo factual do histórico de um mesmo contexto de jogo. Não prevê rede,
/// recalcula score nem atribui causa a qualquer parte da conexão.
public struct HistoryRitualSummary: Equatable, Sendable {
    public enum Window: Int, CaseIterable, Sendable {
        case sevenDays = 7
        case fourteenDays = 14
        case thirtyDays = 30
    }

    public let window: Window
    public let readyCount: Int
    public let cautionCount: Int
    public let notReadyCount: Int
    public let inconclusiveCount: Int
    public let comparableCount: Int
    public let distinctDayCount: Int

    public var hasEnoughEvidence: Bool {
        comparableCount >= 3 && distinctDayCount >= 2
    }

    public init?(
        entries: [MeasurementHistoryEntry],
        window: Window,
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        let cutoff = calendar.date(byAdding: .day, value: -window.rawValue, to: now) ?? now
        let inWindow = entries.filter { $0.completedAt >= cutoff && $0.completedAt <= now }
        guard let latest = inWindow
            .filter(Self.isEligible)
            .max(by: { $0.completedAt < $1.completedAt }) else { return nil }

        let comparable = inWindow.filter { Self.isEligible($0) && Self.isComparable($0, to: latest) }
        self.window = window
        readyCount = comparable.count { $0.readinessVerdict == .ready }
        cautionCount = comparable.count { $0.readinessVerdict == .caution }
        notReadyCount = comparable.count { $0.readinessVerdict == .notReady }
        comparableCount = comparable.count
        distinctDayCount = Set(comparable.map { calendar.startOfDay(for: $0.completedAt) }).count
        inconclusiveCount = inWindow.count { $0.isInconclusive && Self.isComparable($0, to: latest) }
    }

    private static func isEligible(_ entry: MeasurementHistoryEntry) -> Bool {
        guard entry.result?.metrics.validResponseCount ?? 0 >= 10,
              entry.resolvedContext.hasCompleteConnectionFacts else { return false }
        switch entry.readinessVerdict {
        case .ready, .caution, .notReady: return true
        case .inconclusive, .none: return false
        }
    }

    private static func isComparable(_ entry: MeasurementHistoryEntry, to latest: MeasurementHistoryEntry) -> Bool {
        isComparableContext(entry, to: latest) && entry.profileRuleVersion == latest.profileRuleVersion
    }

    private static func isComparableContext(_ entry: MeasurementHistoryEntry, to latest: MeasurementHistoryEntry) -> Bool {
        guard entry.resolvedContext.hasCompleteConnectionFacts,
              latest.resolvedContext.hasCompleteConnectionFacts else { return false }
        let context = entry.resolvedContext
        let latestContext = latest.resolvedContext
        return context.context.gameID == latestContext.context.gameID &&
            context.context.platform == latestContext.context.platform &&
            context.context.declaredExternalLink == latestContext.context.declaredExternalLink &&
            context.observedPhoneNetwork == latestContext.observedPhoneNetwork &&
            context.regionID == latestContext.regionID
    }
}
