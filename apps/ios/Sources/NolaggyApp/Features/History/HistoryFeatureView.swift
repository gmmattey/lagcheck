import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Histórico local do LagCheck (Mockup 06 · Dark Competitive UI).
/// Agrupado por jogo, com veredito semântico, métricas monoespaçadas,
/// confirmação de exclusão em bottom sheet e estados de carregamento/vazio.
struct HistoryView: View {
    let entries: [MeasurementHistoryEntry]
    let gameName: (MeasurementHistoryEntry) -> String
    var catalogGame: (MeasurementHistoryEntry) -> CatalogMeasurementJourney.Game? = { _ in nil }
    let retry: (MeasurementHistoryEntry) -> Void
    let returnToHome: () -> Void
    var showsBackHeader: Bool = true
    var deleteHistory: (() async throws -> Void)? = nil

    @State private var showingClearConfirmation: Bool = false
    @State private var selectedEntryForDetails: MeasurementHistoryEntry? = nil
    @State private var selectedRitualWindow: HistoryRitualSummary.Window = .fourteenDays

    private var groupedGames: [(gameID: String, name: String, latest: MeasurementHistoryEntry, entries: [MeasurementHistoryEntry])] {
        let grouped = Dictionary(grouping: entries, by: { $0.resolvedContext.context.gameID })
        return grouped.compactMap { gameID, items in
            guard let latest = items.max(by: { $0.completedAt < $1.completedAt }) else { return nil }
            let sortedItems = items.sorted(by: { $0.completedAt > $1.completedAt })
            return (gameID: gameID, name: gameName(latest), latest: latest, entries: sortedItems)
        }
        .sorted(by: { $0.latest.completedAt > $1.latest.completedAt })
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Cabeçalho da Tela Nomeada
                NolaggyNamedScreenHeader(
                    title: LocalizedStringKey("history.title"),
                    leadingAction: showsBackHeader ? returnToHome : nil,
                    leadingAccessibilityIdentifier: "history-back",
                    trailing: {
                        if !entries.isEmpty {
                            Button(action: { showingClearConfirmation = true }) {
                                Text(LocalizedStringKey("history.clear_all"))
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(NLColor.textSecondary)
                                    .frame(height: 44)
                            }
                            .accessibilityIdentifier("history-clear-all")
                        }
                    }
                )

                if entries.isEmpty {
                    emptyStateView
                        .padding(.horizontal, NLSpacing.md)
                        .padding(.top, 40)
                    NativeAdSlot(placement: .history)
                        .padding(.horizontal, NLSpacing.md)
                } else {
                    ritualWindowPicker
                        .padding(.horizontal, NLSpacing.md)

                    historyOverview
                        .padding(.horizontal, NLSpacing.md)

                    // Grupos por jogo
                    VStack(spacing: 24) {
                        ForEach(groupedGames, id: \.gameID) { group in
                            gameGroupSection(group: group)
                            if group.gameID == groupedGames.first?.gameID {
                                NativeAdSlot(placement: .history)
                            }
                        }

                        Text(LocalizedStringKey("history.device_storage_note"))
                            .font(.system(size: 10))
                            .foregroundStyle(NLColor.textTertiary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, NLSpacing.md)
                }

                Spacer(minLength: NLSpacing.xl)
            }
        }
        .background(NLColor.deep.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingClearConfirmation) {
            deleteConfirmationSheet
        }
        .sheet(item: $selectedEntryForDetails) { entry in
            MeasurementDetailsView(entry: entry, samples: [])
        }
    }

    // MARK: - Grupo por Jogo
    private func gameGroupSection(group: (gameID: String, name: String, latest: MeasurementHistoryEntry, entries: [MeasurementHistoryEntry])) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cabeçalho do Jogo
            HStack(spacing: 10) {
                catalogCoverView(for: group.latest)
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(NLColor.borderHairline, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(group.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(NLColor.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Image(systemName: iconName(for: group.latest.resolvedContext.context.platform))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(NLColor.textSecondary)

                        Text(verbatim: "·")
                            .font(.system(size: 10))
                            .foregroundStyle(NLColor.textTertiary)

                        Text(verbatim: checkCountLabel(group.entries.count))
                            .font(.system(size: 10))
                            .foregroundStyle(NLColor.textTertiary)
                    }
                    .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NLColor.textTertiary)
            }
            .padding(.top, 12)
            .padding(.bottom, 10)
            .contentShape(Rectangle())

            if let summary = HistoryRitualSummary(entries: group.entries, window: selectedRitualWindow), summary.hasEnoughEvidence {
                ritualSummary(summary)
                    .padding(.vertical, 12)
            }

            // Lista de Medições do Jogo
            VStack(spacing: 0) {
                ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                    historyItemRow(entry: entry, hasSeparator: index < group.entries.count - 1)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    /// Dá contexto ao histórico sem converter observações em previsão.
    private var historyOverview: some View {
        HStack(spacing: 0) {
            historyOverviewMetric(value: "\(entries.count)", label: LocalizedStringKey("history.overview.checks"))
            historyOverviewMetric(value: "\(entries.filter { !$0.isInconclusive && $0.readinessVerdict == .ready }.count)", label: LocalizedStringKey("history.overview.ready"))
            historyOverviewMetric(value: "\(groupedGames.count)", label: LocalizedStringKey("history.overview.games"))
        }
        .padding(.vertical, 18)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func historyOverviewMetric(value: String, label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(verbatim: value)
                .font(.system(size: 26, weight: .medium).monospacedDigit())
                .foregroundStyle(NLColor.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(NLColor.textTertiary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
    }

    private var ritualWindowPicker: some View {
        HStack(spacing: 8) {
            ForEach(HistoryRitualSummary.Window.allCases, id: \.rawValue) { window in
                Button {
                    selectedRitualWindow = window
                } label: {
                    Text(ritualWindowTitle(window))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(selectedRitualWindow == window ? NLColor.textPrimary : NLColor.textSecondary)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule()
                                .fill(selectedRitualWindow == window ? NLColor.backgroundRaised : NLColor.surface)
                        )
                        .overlay(Capsule().stroke(NLColor.borderStrong, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ritualWindowTitle(window))
                .accessibilityAddTraits(selectedRitualWindow == window ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func ritualSummary(_ summary: HistoryRitualSummary) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(String(format: AppLocalization.string("history.ritual.ready_count", comment: ""), summary.readyCount, summary.comparableCount))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(NLColor.textPrimary)
            Text(String(format: AppLocalization.string("history.ritual.breakdown", comment: ""), summary.cautionCount, summary.notReadyCount, summary.inconclusiveCount))
                .font(.system(size: 10))
                .foregroundStyle(NLColor.textTertiary)
        }
        .accessibilityElement(children: .combine)
    }

    private func ritualWindowTitle(_ window: HistoryRitualSummary.Window) -> String {
        let key: String = switch window {
        case .sevenDays: "history.ritual.window_7"
        case .fourteenDays: "history.ritual.window_14"
        case .thirtyDays: "history.ritual.window_30"
        }
        return AppLocalization.string(key, comment: "")
    }

    private func historyItemRow(entry: MeasurementHistoryEntry, hasSeparator: Bool) -> some View {
        Button(action: {
            selectedEntryForDetails = entry
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(colorForEntry(entry))
                            .frame(width: 7, height: 7)
                        Text(verdictTitleForEntry(entry))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(colorForEntry(entry))
                    .padding(.horizontal, 11)
                    .frame(height: 26)
                    .background(colorForEntry(entry).opacity(0.15), in: Capsule())

                    Spacer()

                    Text(entry.completedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundStyle(NLColor.textTertiary)
                }

                Text(verbatim: "\(formatPing(entry)) ms · \(formatJitter(entry)) ms jitter · \(formatLoss(entry))% \(AppLocalization.string("game_readiness.telemetry.loss", comment: ""))")
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(NLColor.textTertiary)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .overlay(hasSeparator ? Rectangle().fill(NLColor.borderStrong).frame(height: 1) : nil, alignment: .bottom)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(verdictTitleForEntry(entry)), \(entry.completedAt.formatted(date: .abbreviated, time: .shortened))")
    }

    private func checkCountLabel(_ count: Int) -> String {
        let key = count == 1 ? "history.check.singular" : "history.check.plural"
        return String(format: AppLocalization.string(key, comment: ""), count)
    }

    // MARK: - Estado Vazio (Mockup 06)
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .stroke(NLColor.borderStrong, lineWidth: 1)
                    .frame(width: 55, height: 55)

                Text(verbatim: "—")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(NLColor.textTertiary)
            }
            .padding(.bottom, 12)

            Text(LocalizedStringKey("history.empty.title"))
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(NLColor.textPrimary)

            Text(LocalizedStringKey("history.empty.subtitle"))
                .font(.system(size: 14))
                .foregroundStyle(NLColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.bottom, 20)

            Button(action: returnToHome) {
                Text(LocalizedStringKey("history.empty.go_home"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(NLColor.textPrimary)
                    .padding(.horizontal, 20)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(NLColor.borderStrong, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("history-empty-home")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Bottom Sheet de Limpeza
    private var deleteConfirmationSheet: some View {
        VStack(spacing: 0) {
            Text(LocalizedStringKey("history.sheet.delete_title"))
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(NLColor.textPrimary)
                .padding(.top, NLSpacing.md)
                .padding(.bottom, 8)

            Text(LocalizedStringKey("history.sheet.delete_message"))
                .font(.system(size: 14))
                .foregroundStyle(NLColor.textSecondary)
                .padding(.bottom, 24)

            HStack(spacing: 12) {
                Button(action: { showingClearConfirmation = false }) {
                    Text(LocalizedStringKey("common.cancel"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(NLColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(NLColor.borderStrong, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("history-delete-cancel")

                Button(action: {
                    showingClearConfirmation = false
                    Task {
                        try? await deleteHistory?()
                    }
                }) {
                    Text(LocalizedStringKey("history.sheet.delete_confirm"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(NLColor.coralSolar, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("history-delete-confirm")
            }
            .padding(.horizontal, NLSpacing.md)
            .padding(.bottom, NLSpacing.lg)
        }
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
        .background(NLColor.backgroundRaised.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers
    private func iconName(for platform: Platform) -> String {
        switch platform {
        case .iphone: return "iphone"
        case .playstation: return "playstation.logo"
        case .xbox: return "xbox.logo"
        case .pc: return "display"
        case .nintendo: return "gamecontroller.fill"
        }
    }

    private func symbolForEntry(_ entry: MeasurementHistoryEntry) -> String {
        if entry.isInconclusive { return "—" }
        switch entry.readinessVerdict {
        case .ready: return "●"
        case .caution, .notReady: return "▲"
        case .inconclusive, .none: return "—"
        }
    }

    private func colorForEntry(_ entry: MeasurementHistoryEntry) -> Color {
        if entry.isInconclusive { return NLColor.textTertiary }
        switch entry.readinessVerdict {
        case .ready: return NLColor.semanticReady
        case .caution: return NLColor.semanticCaution
        case .notReady: return NLColor.semanticNotReady
        case .inconclusive, .none: return NLColor.textTertiary
        }
    }

    private func verdictTitleForEntry(_ entry: MeasurementHistoryEntry) -> String {
        if entry.isInconclusive {
            return AppLocalization.string("game_readiness.verdict.inconclusive.headline", comment: "")
        }
        if let verdict = entry.readinessVerdict {
            switch verdict {
            case .ready:
                return AppLocalization.string("game_readiness.verdict.ready.headline", comment: "")
            case .caution:
                return AppLocalization.string("game_readiness.verdict.caution.headline", comment: "")
            case .notReady:
                return AppLocalization.string("game_readiness.verdict.not_ready.headline", comment: "")
            case .inconclusive:
                return AppLocalization.string("game_readiness.verdict.inconclusive.headline", comment: "")
            }
        }
        return AppLocalization.string("game_readiness.verdict.ready.headline", comment: "")
    }

    private func formatPing(_ entry: MeasurementHistoryEntry) -> String {
        guard let p50 = entry.metrics?.p50Milliseconds else { return "—" }
        return "\(Int(p50.rounded()))"
    }

    private func formatJitter(_ entry: MeasurementHistoryEntry) -> String {
        guard let jitter = entry.metrics?.jitterMilliseconds else { return "—" }
        return "\(Int(jitter.rounded()))"
    }

    private func formatLoss(_ entry: MeasurementHistoryEntry) -> String {
        guard let loss = entry.metrics?.packetLossPercentage else { return "—" }
        if loss <= 0.05 { return "0" }
        return String(format: "%.1f", loss)
    }

    private func catalogCoverView(for entry: MeasurementHistoryEntry) -> some View {
        let game = catalogGame(entry) ?? CatalogMeasurementJourney.Game(
            id: entry.resolvedContext.context.gameID,
            name: gameName(entry),
            context: entry.resolvedContext.context,
            profileID: .battleRoyaleCompetitive
        )
        return VerifiedGameArtwork(game: game, aspectRatio: 38 / 46)
    }
}
