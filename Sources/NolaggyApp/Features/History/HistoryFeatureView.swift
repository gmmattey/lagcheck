import SwiftUI
import NolaggyDesign
import NolaggyDomain

/// Histórico local organizado pela pergunta que importa para quem joga: como
/// cada jogo evoluiu. A lista não mistura medições de contextos diferentes;
/// detalhes e comparações sempre ficam dentro de um contexto imutável.
struct HistoryView: View {
    let entries: [MeasurementHistoryEntry]
    let gameName: (MeasurementHistoryEntry) -> String
    let retry: (MeasurementHistoryEntry) -> Void
    let returnToHome: () -> Void
    let openSettings: () -> Void
    var showsBackHeader: Bool = true

    @State private var filter: HistoryConnectionFilter = .all

    private var filteredEntries: [MeasurementHistoryEntry] {
        entries.filter { filter.includes($0.historyPhoneNetwork) }
    }

    private var games: [HistoryGame] {
        Dictionary(grouping: filteredEntries, by: { $0.resolvedContext.context.gameID })
            .compactMap { gameID, entries in
                guard let latest = entries.max(by: { $0.completedAt < $1.completedAt }) else { return nil }
                return HistoryGame(id: gameID, entries: entries, latest: latest)
            }
            .sorted { $0.latest.completedAt > $1.latest.completedAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NLSpacing.lg) {
                if entries.isEmpty {
                    HistoryEmptyState(action: returnToHome)
                } else {
                    filterPicker

                    if games.isEmpty {
                        HistoryFilteredEmptyState(filter: filter)
                    } else {
                        LazyVStack(spacing: NLSpacing.md) {
                            ForEach(games) { game in
                                NavigationLink {
                                    HistoryGameDetailView(
                                        gameName: gameName(game.latest),
                                        entries: game.entries,
                                        retry: retry
                                    )
                                } label: {
                                    HistoryGameRow(entry: game.latest, gameName: gameName(game.latest))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(accessibilityLabel(for: game))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.lg)
        }
        .background(NolaggyScreenBackground())
        .navigationTitle(Text("history.title"))
        .navigationBarTitleDisplayMode(showsBackHeader ? .inline : .large)
        .toolbar {
            if showsBackHeader {
                ToolbarItem(placement: .topBarLeading) {
                    NolaggyBackButton(action: returnToHome, accessibilityIdentifier: "history-back")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var filterPicker: some View {
        Picker("history.filter.accessibility", selection: $filter) {
            ForEach(HistoryConnectionFilter.allCases) { filter in
                Text(filter.titleKey).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("history-connection-filter")
    }

    private func accessibilityLabel(for game: HistoryGame) -> String {
        let latest = game.latest
        let result = latest.isInconclusive
            ? AppLocalization.string("history.inconclusive", comment: "")
            : String(
                format: AppLocalization.string("history.score_accessibility %@", comment: ""),
                String(latest.result.finalScore)
            )
        return String(
            format: AppLocalization.string("history.game_accessibility %@ %@ %@", comment: ""),
            gameName(latest), result, latest.completedAt.formatted(date: .abbreviated, time: .shortened)
        )
    }
}

private struct HistoryGameDetailView: View {
    let gameName: String
    let entries: [MeasurementHistoryEntry]
    let retry: (MeasurementHistoryEntry) -> Void

    private var contexts: [HistoryContext] {
        Dictionary(grouping: entries, by: HistoryContextKey.init(entry:))
            .compactMap { key, entries in
                guard let latest = entries.max(by: { $0.completedAt < $1.completedAt }) else { return nil }
                return HistoryContext(id: key, entries: entries.sorted { $0.completedAt > $1.completedAt }, latest: latest)
            }
            .sorted { $0.latest.completedAt > $1.latest.completedAt }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: NLSpacing.lg) {
                ForEach(contexts) { context in
                    HistoryContextSection(context: context, retry: retry)
                }
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.lg)
        }
        .background(NolaggyScreenBackground())
        .navigationTitle(gameName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .preferredColorScheme(.dark)
    }
}

private struct HistoryContextSection: View {
    let context: HistoryContext
    let retry: (MeasurementHistoryEntry) -> Void

    private var summary: MeasurementHistorySummary? {
        MeasurementHistorySummary(entries: context.entries)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.md) {
            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                Text(context.title)
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)
                Text(context.routeLabel)
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
            }

            PrimaryButton(title: "history.retry", action: { retry(context.latest) })
                .accessibilityLabel(Text("history.retry"))

            if let summary, !context.latest.isInconclusive,
               summary.sevenDayAverageScore != nil || summary.trend != nil {
                HistoryEvolution(summary: summary)
            }

            VStack(spacing: NLSpacing.sm) {
                ForEach(context.entries) { entry in
                    HistoryTimelineRow(entry: entry)
                }
            }
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: NLRadius.card)
                .stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct HistoryEvolution: View {
    let summary: MeasurementHistorySummary

    var body: some View {
        HStack(spacing: NLSpacing.sm) {
            Image(systemName: trendSymbol)
                .foregroundStyle(NLColor.accentPrimary)
                .accessibilityHidden(true)
            Text(evolutionText)
                .font(NLTypography.footnote)
                .foregroundStyle(NLColor.textSecondary)
        }
        .padding(.vertical, NLSpacing.xs)
        .accessibilityLabel(evolutionText)
    }

    private var trendSymbol: String {
        switch summary.trend {
        case .improving: "arrow.up.right"
        case .worsening: "arrow.down.right"
        case .stable, .none: "minus"
        }
    }

    private var evolutionText: String {
        var parts: [String] = []
        if let average = summary.sevenDayAverageScore {
            parts.append(
                String(
                    format: AppLocalization.string("history.seven_day_average %@", comment: ""),
                    String(average)
                )
            )
        }
        if let trend = summary.trend {
            let key: String = switch trend {
            case .improving: "history.trend.improving"
            case .worsening: "history.trend.worsening"
            case .stable: "history.trend.stable"
            }
            parts.append(AppLocalization.string(key, comment: ""))
        }
        return parts.joined(separator: " · ")
    }
}

private struct HistoryGameRow: View {
    let entry: MeasurementHistoryEntry
    let gameName: String
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: NLSpacing.md) {
            GameArtwork(image: nil, sourceRecordID: nil, title: gameName)
                .frame(width: NLSizing.compactGameArtworkSide, height: NLSizing.compactGameArtworkSide)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                Text(gameName)
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)
                    .lineLimit(2)
                Text(resultText)
                    .font(NLTypography.callout.weight(.semibold))
                    .foregroundStyle(entry.isInconclusive ? NLColor.textSecondary : scoreColor)
                Text(contextText)
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                    .lineLimit(2)
                Text(entry.completedAt, style: .relative)
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.textTertiary)
            }

            Spacer(minLength: NLSpacing.sm)
            Image(systemName: "chevron.right")
                .font(NLTypography.captionStrong)
                .foregroundStyle(NLColor.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(NLSpacing.cardPadding)
        .frame(maxWidth: .infinity, minHeight: NLSizing.historyCardMinHeight, alignment: .leading)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay { RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline) }
    }

    private var resultText: String {
        if entry.isInconclusive {
            return AppLocalization.string("history.inconclusive", comment: "")
        }
        return entry.readinessVerdict.defaultHeadline
    }

    private var contextText: String {
        entry.historyContextDescription(routeLabel: entry.routeLabel(for: locale))
    }

    private var scoreColor: Color {
        switch entry.readinessVerdict {
        case .ready: NLColor.readyGreen
        case .caution: NLColor.cautionYellow
        case .notReady: NLColor.notReadyRed
        case .inconclusive: NLColor.textSecondary
        }
    }
}

private struct HistoryTimelineRow: View {
    let entry: MeasurementHistoryEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: NLSpacing.sm) {
            Circle()
                .fill(timelineDotColor)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                Text(entry.isInconclusive
                    ? AppLocalization.string("history.inconclusive", comment: "")
                    : "\(entry.readinessVerdict.defaultHeadline) · \(entry.result.finalScore)")
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)
                Text(entry.completedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                if entry.kind == .deep {
                    Text("history.deep_check_short")
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textTertiary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: NLSizing.touchTarget, alignment: .leading)
        .accessibilityLabel(entry.isInconclusive
            ? String(format: AppLocalization.string("history.timeline.inconclusive %@", comment: ""), entry.completedAt.formatted(date: .abbreviated, time: .shortened))
            : String(
                format: AppLocalization.string("history.timeline.score %@ %@", comment: ""),
                String(entry.result.finalScore),
                entry.completedAt.formatted(date: .abbreviated, time: .shortened)
            ))
    }

    private var timelineDotColor: Color {
        switch entry.readinessVerdict {
        case .ready: NLColor.readyGreen
        case .caution: NLColor.cautionYellow
        case .notReady: NLColor.notReadyRed
        case .inconclusive: NLColor.textTertiary
        }
    }
}

private struct HistoryEmptyState: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: NLSpacing.md) {
            Image(systemName: "clock.arrow.circlepath")
                .font(NLTypography.displayTitle)
                .foregroundStyle(NLColor.textTertiary)
                .accessibilityHidden(true)
            Text("history.empty")
                .font(NLTypography.body)
                .foregroundStyle(NLColor.textSecondary)
            PrimaryButton(title: "history.choose_game", action: action)
        }
        .frame(maxWidth: .infinity, minHeight: NLSizing.emptyStateMinHeight)
    }
}

private struct HistoryFilteredEmptyState: View {
    let filter: HistoryConnectionFilter

    var body: some View {
        Text(filter == .wifi ? "history.filter.empty_wifi" : "history.filter.empty_cellular")
            .font(NLTypography.body)
            .foregroundStyle(NLColor.textSecondary)
            .frame(maxWidth: .infinity, minHeight: NLSizing.emptyStateMinHeight)
            .multilineTextAlignment(.center)
    }
}

private struct HistoryGame: Identifiable {
    let id: String
    let entries: [MeasurementHistoryEntry]
    let latest: MeasurementHistoryEntry
}

private struct HistoryContext: Identifiable {
    let id: HistoryContextKey
    let entries: [MeasurementHistoryEntry]
    let latest: MeasurementHistoryEntry

    var title: String { [id.platform.displayName, id.externalLink.title, id.phoneNetwork.title].joined(separator: " · ") }
    var routeLabel: String { id.routeLabel }
}

private struct HistoryContextKey: Hashable, Identifiable {
    let gameID: String
    let platform: Platform
    let externalLink: HistoryExternalLink
    let phoneNetwork: HistoryPhoneNetwork
    let regionID: String
    let profileRuleVersion: String

    init(entry: MeasurementHistoryEntry) {
        gameID = entry.resolvedContext.context.gameID
        platform = entry.resolvedContext.context.platform
        externalLink = entry.historyExternalLink
        phoneNetwork = entry.historyPhoneNetwork
        regionID = entry.resolvedContext.regionID
        profileRuleVersion = entry.profileRuleVersion
    }

    var id: String { [gameID, platform.rawValue, externalLink.rawValue, phoneNetwork.rawValue, regionID, profileRuleVersion].joined(separator: "|") }

    var routeLabel: String {
        let identifier = AppLocalization.locale.identifier.lowercased()
        let languageCode = identifier.hasPrefix("pt") ? "pt-BR" : identifier.hasPrefix("es") ? "es" : "en"
        return GlobalProbeRegistry.friendlyLabel(for: regionID, languageCode: languageCode)
    }
}

private enum HistoryConnectionFilter: String, CaseIterable, Identifiable {
    case all
    case wifi
    case cellular

    var id: Self { self }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all: "history.filter.all"
        case .wifi: "history.filter.wifi"
        case .cellular: "history.filter.cellular"
        }
    }

    func includes(_ network: HistoryPhoneNetwork) -> Bool {
        switch self {
        case .all: true
        case .wifi: network == .wifi
        case .cellular: network == .cellular
        }
    }
}

private extension MeasurementHistoryEntry {
    /// A ausência das respostas UDP mínimas não é uma nota baixa: é ausência
    /// de evidência. Snapshots antigos preservam um `QualityResult`, então a
    /// apresentação precisa reconhecer esse estado pelo fato medido.
    var isInconclusive: Bool { result.metrics.validResponseCount < 10 }

    var readinessVerdict: GameReadinessVerdict {
        if isInconclusive { return .inconclusive }
        return GameReadinessEvaluator.evaluate(
            qualityResult: result,
            loadImpact: deepCheck?.metrics.loadImpact,
            profile: resolvedContext.profileID
        ).verdict
    }

    var historyPhoneNetwork: HistoryPhoneNetwork {
        guard resolvedContext.hasCompleteConnectionFacts else { return .unrecorded }
        return HistoryPhoneNetwork(resolvedContext.observedPhoneNetwork)
    }

    var historyExternalLink: HistoryExternalLink {
        HistoryExternalLink(resolvedContext.context.declaredExternalLink)
    }

    func historyContextDescription(routeLabel: String) -> String {
        [
            resolvedContext.context.platform.displayName,
            historyExternalLink.title,
            historyPhoneNetwork.title,
            routeLabel
        ]
        .joined(separator: " · ")
    }

    func routeLabel(for locale: Locale) -> String {
        let identifier = locale.identifier.lowercased()
        let languageCode = identifier.hasPrefix("pt") ? "pt-BR" : identifier.hasPrefix("es") ? "es" : "en"
        return GlobalProbeRegistry.friendlyLabel(for: resolvedContext.regionID, languageCode: languageCode)
    }
}

private enum HistoryPhoneNetwork: String, Hashable {
    case wifi
    case cellular
    case other
    case unrecorded

    init(_ networkKind: NetworkKind?) {
        switch networkKind {
        case .wifi: self = .wifi
        case .cellular: self = .cellular
        case .other: self = .other
        case nil: self = .unrecorded
        }
    }

    var title: String {
        switch self {
        case .wifi: AppLocalization.string("history.connection.wifi", comment: "")
        case .cellular: AppLocalization.string("history.connection.cellular", comment: "")
        case .other: AppLocalization.string("history.connection.other", comment: "")
        case .unrecorded: AppLocalization.string("history.connection.unrecorded", comment: "")
        }
    }
}

private enum HistoryExternalLink: String, Hashable {
    case wifi
    case ethernet
    case notDeclared

    init(_ link: ExternalEquipmentLink?) {
        switch link {
        case .wifi: self = .wifi
        case .ethernet: self = .ethernet
        case nil: self = .notDeclared
        }
    }

    var title: String {
        switch self {
        case .wifi: AppLocalization.string("history.equipment.wifi", comment: "")
        case .ethernet: AppLocalization.string("history.equipment.ethernet", comment: "")
        case .notDeclared: AppLocalization.string("history.equipment.not_declared", comment: "")
        }
    }
}
