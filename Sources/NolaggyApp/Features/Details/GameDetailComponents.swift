import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

struct GameDetailPresentation {
    let scoreState: GameRowView.ScoreState
    let gameName: String

    var titleKey: LocalizedStringKey {
        switch scoreState {
        case let .evaluated(_, classification):
            switch classification {
            case .excellent: "game_detail.verdict.excellent.title"
            case .great: "game_detail.verdict.great.title"
            case .unstable: "game_detail.verdict.unstable.title"
            case .lagRisk: "game_detail.verdict.lag_risk.title"
            }
        case .measuring: "game_detail.verdict.measuring.title"
        case .inconclusive, .failed: "game_detail.verdict.inconclusive.title"
        }
    }

    var description: String {
        switch scoreState {
        case let .evaluated(_, classification):
            let key: String
            switch classification {
            case .excellent, .great: key = "game_detail.verdict.healthy.message %@"
            case .unstable: key = "game_detail.verdict.unstable.message %@"
            case .lagRisk: key = "game_detail.verdict.lag_risk.message %@"
            }
            return String(format: AppLocalization.string(key, comment: ""), gameName)
        case .measuring: return String(localized: "game_detail.verdict.measuring.message")
        case .inconclusive, .failed: return String(localized: "game_detail.verdict.inconclusive.message")
        }
    }
}

struct GameDetailScoreHeader: View {
    let scoreState: GameRowView.ScoreState
    var body: some View {
        VStack(spacing: NLSpacing.sm) {
            switch scoreState {
            case let .evaluated(score, classification):
                NolaggyScore(outcome: .revealed(score: score, classification: classification), style: .standard, showsGlow: false)
            case .measuring:
                ProgressView().scaleEffect(1.4).padding(.vertical, NLSpacing.xl)
                Text("quick_check.measuring.progress").font(NLTypography.captionStrong).foregroundStyle(NLColor.textSecondary)
            case .inconclusive, .failed:
                NolaggyScore(outcome: .inconclusive, style: .standard, showsGlow: false)
            }
        }
    }
}

struct GameDetailMeasurementScope: View {
    let platform: Platform
    let externalLink: ExternalEquipmentLink?

    var body: some View {
        Label {
            Text(scopeText)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: iconName)
                .accessibilityHidden(true)
        }
            .font(NLTypography.footnote)
            .foregroundStyle(NLColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, NLSpacing.xs)
            .accessibilityIdentifier("game-detail-measurement-scope")
    }

    private var iconName: String {
        switch platform {
        case .iphone: return "iphone"
        case .playstation: return "playstation.logo"
        case .xbox: return "xbox.logo"
        case .pc: return "display"
        case .nintendo: return "gamecontroller.fill"
        }
    }

    private var scopeText: String {
        switch platform {
        case .iphone:
            return AppLocalization.string("game_detail.scope.iphone", comment: "")
        case .playstation:
            return externalScope(for: "PlayStation")
        case .xbox:
            return externalScope(for: "Xbox")
        case .nintendo:
            return externalScope(for: "Nintendo Switch")
        case .pc:
            return externalScope(for: "PC")
        }
    }

    private func externalScope(for platformName: String) -> String {
        let connectionKey = externalLink == .wifi
            ? "game_detail.scope.external_wifi %@"
            : "game_detail.scope.external_cable %@"
        return String(format: AppLocalization.string(connectionKey, comment: ""), platformName)
    }
}

/// Contexto explícito antes da ação. A escolha de cabo representa um
/// equipamento externo conectado por Ethernet; ela nunca é tratada como
/// telemetria Wi-Fi do iPhone.
struct GameDetailMeasurementContextCard: View {
    let supportedPlatforms: [Platform]
    @Binding var selectedPlatform: Platform
    @Binding var selectedExternalLink: ExternalEquipmentLink?

    private var needsEquipmentConnection: Bool { selectedPlatform != .iphone }

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            Text(LocalizedStringKey("game_detail.context.platform_title"))
                .font(NLTypography.bodyEmphasis)
                .foregroundStyle(NLColor.textPrimary)

            PlatformSelectorRow(supportedPlatforms: supportedPlatforms, selectedPlatform: $selectedPlatform)

            if needsEquipmentConnection {
                Text(LocalizedStringKey("game_detail.context.connection_title"))
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)

                HStack(spacing: NLSpacing.xs) {
                    connectionButton(.wifi, titleKey: "game_detail.context.connection_wifi", icon: "wifi")
                    connectionButton(.ethernet, titleKey: "game_detail.context.connection_cable", icon: "cable.connector")
                }
            }
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline))
    }

    private func connectionButton(_ connection: ExternalEquipmentLink, titleKey: LocalizedStringKey, icon: String) -> some View {
        let isSelected = selectedExternalLink == connection
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            selectedExternalLink = connection
        } label: {
            Label(titleKey, systemImage: icon)
                .font(NLTypography.captionStrong)
                .foregroundStyle(isSelected ? NLColor.textPrimary : NLColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, NLSpacing.xs)
                .background(isSelected ? NLColor.accentPrimarySubtle : NLColor.backgroundBase, in: RoundedRectangle(cornerRadius: NLRadius.controlSmall))
                .overlay(RoundedRectangle(cornerRadius: NLRadius.controlSmall).stroke(isSelected ? NLColor.accentPrimary : NLColor.borderSubtle, lineWidth: isSelected ? 1.5 : NLStroke.hairline))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(titleKey)
        .accessibilityHint(Text(isSelected ? "game_detail.context.connection_selected" : "game_detail.context.connection_hint"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct GameDetailVerdictCard: View {
    let presentation: GameDetailPresentation
    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Text(presentation.titleKey).font(NLTypography.bodyEmphasis).foregroundStyle(NLColor.textPrimary)
            Text(presentation.description).font(NLTypography.callout).foregroundStyle(NLColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
    }
}

struct GameDetailMetricsCard: View {
    let metrics: QualityMetrics
    var body: some View {
        VStack(spacing: 1) {
            MetricRow(label: "quick_check.result.latency", value: milliseconds(metrics.p50Milliseconds), unit: "ms")
            MetricRow(label: "quick_check.result.jitter", value: milliseconds(metrics.jitterMilliseconds), unit: "ms")
            MetricRow(label: "quick_check.result.loss", value: "\(Int(metrics.packetLossPercentage.rounded()))", unit: "%")
        }
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
    }
    private func milliseconds(_ value: Double?) -> String { value.map { String(Int($0.rounded())) } ?? "—" }
}

// MARK: - Game detail hero

/// Banner com a arte gerada para o app e o nome do jogo selecionado.
struct GameDetailCinemaHeroBanner: View {
    let game: CatalogMeasurementJourney.Game

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if game.id == GameContext.genericGamingID {
                ZStack {
                    NLColor.backgroundRaised
                    LinearGradient(
                        colors: [NLColor.accentPrimary.opacity(0.35), NLColor.backgroundRaised],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "network")
                        .font(.system(size: 80, weight: .light))
                        .foregroundStyle(NLColor.accentPrimary.opacity(0.2))
                        .offset(x: 90, y: -15)
                }
                .frame(maxWidth: .infinity)
                .frame(height: NLSizing.gameDetailHeroHeight)
                .clipped()
            } else {
                // Artwork full-bleed
                VerifiedGameArtwork(game: game, aspectRatio: 16 / 9)
                    .frame(maxWidth: .infinity)
                    .frame(height: NLSizing.gameDetailHeroHeight)
                    .clipped()
            }

            // Gradiente cinematográfico sobre a imagem
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.45), location: 0.0),
                    .init(color: .clear, location: 0.25),
                    .init(color: .black.opacity(0.35), location: 0.5),
                    .init(color: .black.opacity(0.88), location: 0.82),
                    .init(color: .black, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // O título basta para orientar a escolha sem introduzir metadados
            // de terceiros antes de sua auditoria.
            Text(game.name)
                .font(.system(.title, design: .default, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.bottom, NLSpacing.md)
        }
    }
}

/// Linha horizontal de plataformas suportadas com seleção interativa no padrão HIG
struct GameDetailPlatformsRow: View {
    let supportedPlatforms: [Platform]
    @Binding var selectedPlatform: Platform

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Text(LocalizedStringKey("game_detail.section.supported_platforms"))
                .font(NLTypography.captionStrong)
                .textCase(.uppercase)
                .foregroundStyle(NLColor.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NLSpacing.xs) {
                    ForEach(supportedPlatforms, id: \.self) { platform in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedPlatform = platform
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: iconName(for: platform))
                                    .font(.system(size: 12, weight: .semibold))
                                Text(displayName(for: platform))
                                    .font(NLTypography.captionStrong)
                            }
                            .foregroundStyle(selectedPlatform == platform ? NLColor.textPrimary : NLColor.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selectedPlatform == platform ? Color.white.opacity(0.2) : NLColor.backgroundRaised,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        selectedPlatform == platform ? Color.white.opacity(0.35) : NLColor.borderSubtle,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func iconName(for platform: Platform) -> String {
        switch platform {
        case .iphone: return "iphone"
        case .playstation: return "gamecontroller"
        case .xbox: return "gamecontroller.fill"
        case .pc: return "display"
        case .nintendo: return "gamecontroller"
        }
    }

    private func displayName(for platform: Platform) -> String {
        switch platform {
        case .iphone: return "iPhone"
        case .playstation: return "PlayStation"
        case .xbox: return "Xbox"
        case .pc: return "PC"
        case .nintendo: return "Switch"
        }
    }
}

/// A tela do jogo mostra uma única leitura comparável ao contexto atual. A
/// linha do tempo completa pertence ao Histórico, que preserva os contextos.
struct GameDetailExclusiveHistoryCard: View {
    let entries: [MeasurementHistoryEntry]
    let selectedPlatform: Platform
    let selectedExternalLink: ExternalEquipmentLink?
    let onOpenHistory: () -> Void

    private var latestContextualEntry: MeasurementHistoryEntry? {
        entries
            .filter { entry in
                entry.resolvedContext.hasCompleteConnectionFacts
                    && entry.resolvedContext.context.platform == selectedPlatform
                    && entry.resolvedContext.context.declaredExternalLink == selectedExternalLink
                    && !entry.isInconclusive
            }
            .max(by: { $0.completedAt < $1.completedAt })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            HStack {
                Label(LocalizedStringKey("game_detail.section.latest_measurement"), systemImage: "clock.arrow.circlepath")
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)

                Spacer()

                Button(LocalizedStringKey("game_detail.section.open_history"), action: onOpenHistory)
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.accentPrimary)
                    .frame(minHeight: 44)
            }

            if let entry = latestContextualEntry {
                latestMeasurement(entry)
            } else {
                Text(LocalizedStringKey("game_detail.section.latest_empty"))
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, NLSpacing.xs)
            }
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: 1))
    }

    private func latestMeasurement(_ entry: MeasurementHistoryEntry) -> some View {
        HStack(spacing: NLSpacing.sm) {
            Circle()
                .fill(scoreColor(entry.result.resultClass))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(verdictTitle(entry.result.resultClass))
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.textPrimary)

                Text(formattedDate(entry.completedAt))
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(entry.result.finalScore)")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(scoreColor(entry.result.resultClass))

                Text(LocalizedStringKey("game_detail.history.score_label"))
                    .font(.system(size: 9, weight: .bold))
                    .textCase(.uppercase)
                    .foregroundStyle(NLColor.textTertiary)
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: NLRadius.controlSmall))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.controlSmall).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
    }

    private func scoreColor(_ resultClass: ResultClass) -> Color {
        switch resultClass {
        case .excellent, .great: return NLColor.scoreExcellent
        case .unstable: return NLColor.scoreUnstable
        case .lagRisk: return NLColor.scoreLagRisk
        }
    }

    private func verdictTitle(_ resultClass: ResultClass) -> LocalizedStringKey {
        switch resultClass {
        case .excellent: return "game_detail.verdict.excellent.title"
        case .great: return "game_detail.verdict.great.title"
        case .unstable: return "game_detail.verdict.unstable.title"
        case .lagRisk: return "game_detail.verdict.lag_risk.title"
        }
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.relative(presentation: .named))
    }
}

private extension MeasurementHistoryEntry {
    var isInconclusive: Bool { result.metrics.validResponseCount < 10 }
}

/// Acordeão com observações verificáveis da conexão e da plataforma.
/// Metas editoriais de jogos e topologia NAT não são expostas no corte 1.0.0.
struct GameDetailNetworkInformationAccordion: View {
    let platformHealth: PlatformHealth?
    let wifiBandDiagnostic: WiFiBandDiagnosticResult?
    let onStartDeepCheck: () -> Void

    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: NLSpacing.sm) {
                    Image(systemName: "network")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(NLColor.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(NLColor.backgroundBase, in: RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey("game_detail.section.network_information"))
                            .font(NLTypography.bodyEmphasis)
                            .foregroundStyle(NLColor.textPrimary)
                        Text(LocalizedStringKey("game_detail.section.network_information_subtitle"))
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(NLColor.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(NLSpacing.cardPadding)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: NLSpacing.md) {
                    Divider().overlay(NLColor.borderSubtle)

                    // Diagnóstico derivado da conexão observada no iPhone.
                    if let advice = wifiBandDiagnostic {
                        NetworkBandAdviceBanner(
                            title: LocalizedStringKey(advice.titleKey),
                            message: LocalizedStringKey(advice.messageKey),
                            badgeText: advice.diagnostic.isSuspectOrConfirmed24GHz ? "2.4 GHz" : nil,
                            style: advice.diagnostic.isSuspectOrConfirmed24GHz ? .warning : .positive,
                            iconName: advice.diagnostic.isSuspectOrConfirmed24GHz ? "antenna.radiowaves.left.and.right" : "wifi",
                            actionTitle: advice.actionKey.map { LocalizedStringKey($0) },
                            onAction: onStartDeepCheck
                        )
                    }

                    // Status operacional publicado pela plataforma, quando houver.
                    if let health = platformHealth, health.isIssueReported {
                        PlatformHealthBannerView(health: health)
                    }
                }
                .padding(.horizontal, NLSpacing.cardPadding)
                .padding(.bottom, NLSpacing.cardPadding)
            }
        }
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: 1))
    }

}
