import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Componentes da Home redesenhada segundo a Dark Competitive UI (Decisões 50 e 51).
/// Headline imersiva "PRONTO PRA JOGAR?", painel protagonista com artwork amplo,
/// CTA Coral Solar dominante [ FAZER CHECK ], status discreto em linha única e trilho rápido SEUS JOGOS.

// MARK: - Hero Principal Dark Competitive

public struct DarkCompetitiveHeroCard: View {
    let game: CatalogMeasurementJourney.Game?
    let platform: Platform?
    let regionFriendlyName: String
    let latestEntry: MeasurementHistoryEntry?
    let isMeasuring: Bool
    let onStartCheck: () -> Void
    let onTestGeneralConnection: (() -> Void)?
    let onOpenHistory: () -> Void

    public init(
        game: CatalogMeasurementJourney.Game?,
        platform: Platform?,
        regionFriendlyName: String,
        latestEntry: MeasurementHistoryEntry?,
        isMeasuring: Bool,
        onStartCheck: @escaping () -> Void,
        onTestGeneralConnection: (() -> Void)? = nil,
        onOpenHistory: @escaping () -> Void
    ) {
        self.game = game
        self.platform = platform
        self.regionFriendlyName = regionFriendlyName
        self.latestEntry = latestEntry
        self.isMeasuring = isMeasuring
        self.onStartCheck = onStartCheck
        self.onTestGeneralConnection = onTestGeneralConnection
        self.onOpenHistory = onOpenHistory
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.md) {
            // Artwork do jogo protagonista
            if let game {
                ZStack(alignment: .bottomLeading) {
                    if game.id == GameContext.genericGamingID {
                        ZStack {
                            NLColor.surface
                            VStack(spacing: NLSpacing.xs) {
                                Image(systemName: "network")
                                    .font(.system(size: 44, weight: .semibold))
                                    .foregroundStyle(NLColor.coralSolar)
                                Text(LocalizedStringKey("generic_gaming.route_reference"))
                                    .font(NLTypography.caption)
                                    .foregroundStyle(NLColor.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, NLSpacing.md)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: NLRadius.cardLarge, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: NLRadius.cardLarge, style: .continuous)
                                .stroke(NLColor.borderHairline, lineWidth: 1)
                        )
                    } else {
                        VerifiedGameArtwork(game: game, aspectRatio: 16 / 9)
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: NLRadius.cardLarge, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: NLRadius.cardLarge, style: .continuous)
                                    .stroke(NLColor.borderHairline, lineWidth: 1)
                            )
                    }

                    // Gradiente escuro na base para legibilidade
                    LinearGradient(
                        colors: [.clear, NLColor.deep.opacity(0.85), NLColor.deep],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .frame(height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: NLRadius.cardLarge, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(game.name.uppercased())
                            .font(NLTypography.heroGameTitle)
                            .foregroundStyle(NLColor.textPrimary)

                        HStack(spacing: NLSpacing.xxs) {
                            Text(regionFriendlyName)
                            if let platform {
                                Text("·")
                                Text(platform.displayName)
                            }
                        }
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textSecondary)
                    }
                    .padding(NLSpacing.md)
                }
            } else {
                // Estado neutro sem jogo selecionado
                VStack(spacing: NLSpacing.sm) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(NLColor.textTertiary)
                    Text(LocalizedStringKey("home.hero.ready_title"))
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.cardLarge, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: NLRadius.cardLarge, style: .continuous)
                        .stroke(NLColor.borderHairline, lineWidth: 1)
                )
            }

            // Botão Dominante de Ação Coral Solar [ FAZER CHECK ] (Sem ⚡)
            Button(action: onStartCheck) {
                HStack(spacing: NLSpacing.xs) {
                    if isMeasuring {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(LocalizedStringKey("home.cta.start_check"))
                        .font(NLTypography.ctaButton)
                        .tracking(NLTypography.ctaTracking)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    isMeasuring ? NLColor.coralSolar.opacity(0.6) : NLColor.coralSolar,
                    in: RoundedRectangle(cornerRadius: NLRadius.button, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .disabled(isMeasuring)
            .accessibilityIdentifier("home-decision-primary-action")

            // Ação Direta para Verificar Conexão Geral (Sem Selecionar Jogo)
            if let onTestGeneralConnection, game?.id != GameContext.genericGamingID {
                Button(action: onTestGeneralConnection) {
                    HStack(spacing: NLSpacing.xs) {
                        Image(systemName: "network")
                            .font(.system(size: 14, weight: .semibold))
                        Text(LocalizedStringKey("home.cta.test_general_connection"))
                            .font(NLTypography.ctaButton)
                            .tracking(NLTypography.ctaTracking)
                    }
                    .foregroundStyle(NLColor.coralSolar)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(NLColor.controlOverlay, in: RoundedRectangle(cornerRadius: NLRadius.button, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: NLRadius.button, style: .continuous)
                            .stroke(NLColor.borderHairline, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isMeasuring)
                .accessibilityIdentifier("home-decision-generic-gaming-action")
            }

            // Linha única discreta com dot de status do último check
            Button(action: onOpenHistory) {
                HStack(spacing: NLSpacing.xs) {
                    Circle()
                        .fill(lastStatusDotColor)
                        .frame(width: 8, height: 8)

                    Text(lastCheckStatusText)
                        .font(NLTypography.statusLine)
                        .foregroundStyle(NLColor.textSecondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NLColor.textTertiary)
                }
                .padding(.horizontal, NLSpacing.xxs)
                .frame(minHeight: NLSizing.touchTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(LocalizedStringKey("history.title")))
            .accessibilityIdentifier("home-decision-history")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-decision-card")
    }

    private var lastReadinessEvaluation: GameReadinessEvaluation? {
        guard let entry = latestEntry else { return nil }
        let profile = game?.profileID ?? .battleRoyaleCompetitive
        return GameReadinessEvaluator.evaluate(
            qualityResult: entry.result,
            loadImpact: nil,
            profile: profile
        )
    }

    private var lastStatusDotColor: Color {
        guard let eval = lastReadinessEvaluation else {
            return NLColor.textTertiary
        }
        switch eval.verdict {
        case .ready: return NLColor.semanticReady
        case .caution: return NLColor.semanticCaution
        case .notReady: return NLColor.semanticNotReady
        case .inconclusive: return NLColor.textSecondary
        }
    }

    private var lastCheckStatusText: String {
        guard let entry = latestEntry, let eval = lastReadinessEvaluation else {
            return AppLocalization.string("home.last_check.empty", comment: "")
        }
        if eval.verdict == .inconclusive {
            return AppLocalization.string("check_completo.verdict.inconclusive", comment: "")
        }
        let condition: String
        switch eval.verdict {
        case .ready:
            condition = AppLocalization.string("home.condition.excellent", comment: "")
        case .caution:
            condition = AppLocalization.string("home.condition.unstable", comment: "")
        case .notReady:
            condition = AppLocalization.string("home.condition.lag_risk", comment: "")
        case .inconclusive:
            condition = AppLocalization.string("check_completo.verdict.inconclusive", comment: "")
        }

        let p50Text: String
        if let p50 = eval.pingMs {
            p50Text = " · \(Int(p50.rounded())) ms"
        } else {
            p50Text = ""
        }

        let relativeTime = relativeTimeString(for: entry.completedAt)
        return "\(condition)\(p50Text) · \(relativeTime)"
    }

    private func relativeTimeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Trilho Rápido SEUS JOGOS

public struct DarkCompetitiveQuickRail: View {
    let games: [CatalogMeasurementJourney.Game]
    let selectedGameID: String?
    let onSelectGame: (CatalogMeasurementJourney.Game) -> Void
    let onSelectGenericGaming: (() -> Void)?
    let onSeeAllGames: () -> Void

    public init(
        games: [CatalogMeasurementJourney.Game],
        selectedGameID: String?,
        onSelectGame: @escaping (CatalogMeasurementJourney.Game) -> Void,
        onSelectGenericGaming: (() -> Void)? = nil,
        onSeeAllGames: @escaping () -> Void
    ) {
        self.games = games
        self.selectedGameID = selectedGameID
        self.onSelectGame = onSelectGame
        self.onSelectGenericGaming = onSelectGenericGaming
        self.onSeeAllGames = onSeeAllGames
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            HStack {
                Text(LocalizedStringKey("home.quick_rail.title"))
                    .font(NLTypography.sectionHeader)
                    .foregroundStyle(NLColor.textTertiary)
                    .textCase(.uppercase)

                Spacer()

                Button(action: onSeeAllGames) {
                    HStack(spacing: 2) {
                        Text(LocalizedStringKey("home.quick_rail.see_all"))
                        Image(systemName: "chevron.right")
                    }
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.textSecondary)
                    .frame(minHeight: NLSizing.touchTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home-see-all-games")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NLSpacing.sm) {
                    // Card fixo para Conexão Geral (Sem Selecionar Jogo)
                    if let onSelectGenericGaming {
                        let isGenericSelected = (selectedGameID == GameContext.genericGamingID)
                        Button(action: onSelectGenericGaming) {
                            VStack(spacing: NLSpacing.xxs) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous)
                                        .fill(isGenericSelected ? NLColor.coralSolar.opacity(0.15) : NLColor.panel)
                                        .frame(width: 72, height: 72)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous)
                                                .stroke(
                                                    isGenericSelected ? NLColor.coralSolar : NLColor.borderHairline,
                                                    lineWidth: isGenericSelected ? 2 : 1
                                                )
                                        )
                                    Image(systemName: "network")
                                        .font(.system(size: 26, weight: .bold))
                                        .foregroundStyle(isGenericSelected ? NLColor.coralSolar : NLColor.textSecondary)
                                }

                                Text(LocalizedStringKey("generic_gaming.short_name"))
                                    .font(NLTypography.captionStrong)
                                    .foregroundStyle(isGenericSelected ? NLColor.textPrimary : NLColor.textSecondary)
                                    .lineLimit(1)
                                    .frame(width: 72)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home-quick-rail-generic-gaming")
                    }

                    ForEach(games) { game in
                        let isSelected = (game.id == selectedGameID)
                        Button {
                            onSelectGame(game)
                        } label: {
                            VStack(spacing: NLSpacing.xxs) {
                                VerifiedGameArtwork(game: game, aspectRatio: 1)
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous)
                                            .stroke(
                                                isSelected ? NLColor.coralSolar : NLColor.borderHairline,
                                                lineWidth: isSelected ? 2 : 1
                                            )
                                    )

                                Text(game.name)
                                    .font(NLTypography.captionStrong)
                                    .foregroundStyle(isSelected ? NLColor.textPrimary : NLColor.textSecondary)
                                    .lineLimit(1)
                                    .frame(width: 72)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home-game-\(game.id)")
                    }

                    // Card final para explorar catálogo
                    Button(action: onSeeAllGames) {
                        VStack(spacing: NLSpacing.xxs) {
                            ZStack {
                                RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous)
                                    .fill(NLColor.panel)
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous)
                                            .stroke(NLColor.borderHairline, lineWidth: 1)
                                    )
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(NLColor.coralSolar)
                            }

                            Text(LocalizedStringKey("home.quick_rail.more"))
                                .font(NLTypography.caption)
                                .foregroundStyle(NLColor.textTertiary)
                                .frame(width: 72)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home-quick-rail-explore")
                }
            }
        }
        .accessibilityIdentifier("home-games-list")
    }
}
