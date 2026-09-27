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
    let retry: (MeasurementHistoryEntry) -> Void
    let returnToHome: () -> Void
    let openSettings: () -> Void
    var showsBackHeader: Bool = true
    var deleteHistory: (() async throws -> Void)? = nil

    @State private var showingClearConfirmation: Bool = false
    @State private var selectedEntryForDetails: MeasurementHistoryEntry? = nil

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
                } else {
                    // Grupos por jogo
                    VStack(spacing: 24) {
                        ForEach(groupedGames, id: \.gameID) { group in
                            gameGroupSection(group: group)
                        }

                        Text(LocalizedStringKey("history.device_storage_note"))
                            .font(.system(size: 10, design: .monospaced))
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
                    .frame(width: 38, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(NLColor.borderStrong, lineWidth: 1)
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

                        Text(LocalizedStringKey("history.last_platform"))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(NLColor.textTertiary)
                    }
                    .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NLColor.textTertiary)
            }
            .padding(.bottom, 10)
            .contentShape(Rectangle())
            .overlay(
                Rectangle()
                    .fill(NLColor.borderStrong)
                    .frame(height: 1),
                alignment: .bottom
            )

            // Lista de Medições do Jogo
            VStack(spacing: 0) {
                ForEach(group.entries) { entry in
                    historyItemRow(entry: entry)
                }
            }
        }
    }

    private func historyItemRow(entry: MeasurementHistoryEntry) -> some View {
        Button(action: {
            selectedEntryForDetails = entry
        }) {
            HStack(alignment: .center, spacing: 10) {
                Text(symbolForEntry(entry))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(colorForEntry(entry))
                    .frame(width: 15, alignment: .leading)

                VStack(alignment: .leading, spacing: 3) {
                    Text(verdictTitleForEntry(entry))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(NLColor.textPrimary)

                    Text(entry.completedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundStyle(NLColor.textTertiary)

                    // Métricas inline
                    Text(verbatim: "\(formatPing(entry)) ms · \(formatJitter(entry)) ms jitter · \(formatLoss(entry))% perda")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(NLColor.textTertiary)
                        .padding(.top, 2)
                }

                Spacer()

                // Ícone da plataforma correspondente ao teste
                Image(systemName: iconName(for: entry.resolvedContext.context.platform))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(NLColor.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(NLColor.borderHairline, lineWidth: 1)
                    )
                    .accessibilityLabel(entry.resolvedContext.context.platform.displayName)
            }
            .padding(.vertical, 11)
            .frame(minHeight: 66)
            .contentShape(Rectangle())
            .overlay(
                Rectangle()
                    .fill(NLColor.borderStrong)
                    .frame(height: 1),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Estado Vazio (Mockup 06)
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .stroke(NLColor.borderStrong, lineWidth: 1)
                    .frame(width: 55, height: 55)

                Text(verbatim: "—")
                    .font(.system(size: 22, weight: .regular, design: .monospaced))
                    .foregroundStyle(NLColor.textTertiary)
            }
            .padding(.bottom, 12)

            Text(LocalizedStringKey("history.empty.title"))
                .font(.system(size: 25, weight: .bold, design: .rounded))
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
                .font(.system(size: 20, weight: .bold, design: .rounded))
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
        guard let p50 = entry.result.metrics.p50Milliseconds else { return "—" }
        return "\(Int(p50.rounded()))"
    }

    private func formatJitter(_ entry: MeasurementHistoryEntry) -> String {
        guard let jitter = entry.result.metrics.jitterMilliseconds else { return "—" }
        return "\(Int(jitter.rounded()))"
    }

    private func formatLoss(_ entry: MeasurementHistoryEntry) -> String {
        let loss = entry.result.metrics.packetLossPercentage
        if loss <= 0.05 { return "0" }
        return String(format: "%.1f", loss)
    }

    private func catalogCoverView(for entry: MeasurementHistoryEntry) -> some View {
        let dummyGame = CatalogMeasurementJourney.Game(
            id: entry.resolvedContext.context.gameID,
            name: gameName(entry),
            context: entry.resolvedContext.context,
            profileID: .battleRoyaleCompetitive
        )
        return VerifiedGameArtwork(game: dummyGame, aspectRatio: 38 / 46)
    }
}
