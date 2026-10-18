import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

// MARK: - Home header and status

struct HomeRefreshButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let refreshAccessibilityLabel: String
    let isMeasuring: Bool
    let refresh: () -> Void

    var body: some View {
        Button(action: refresh) {
            Image(systemName: "arrow.clockwise")
                .font(NLTypography.navigationIcon)
                .foregroundStyle(isMeasuring ? NLColor.textTertiary : NLColor.accentPrimary)
                .rotationEffect(.degrees(isMeasuring && !reduceMotion ? 360 : 0))
                .animation(
                    reduceMotion ? nil : (isMeasuring ? .linear(duration: 1).repeatForever(autoreverses: false) : .default),
                    value: isMeasuring
                )
                .frame(width: NLSizing.touchTarget, height: NLSizing.touchTarget)
                // A barra de navegação já fornece a superfície e a área de
                // toque do controle. Não desenhar uma segunda cápsula/círculo
                // aqui evita o aspecto de dois botões sobrepostos no topo.
                .contentShape(Rectangle())
        }
        .disabled(isMeasuring)
        .accessibilityLabel(refreshAccessibilityLabel)
        .accessibilityIdentifier("home-refresh-button")
    }
}

struct HomeHeader: View {
    let title: String
    let refreshAccessibilityLabel: String
    let isMeasuring: Bool
    let refresh: () -> Void

    var body: some View {
        HStack {
            Text(title).font(NLTypography.displayTitle).foregroundStyle(NLColor.textPrimary)
            Spacer()
            HomeRefreshButton(
                refreshAccessibilityLabel: refreshAccessibilityLabel,
                isMeasuring: isMeasuring,
                refresh: refresh
            )
        }
    }
}

/// Card "Início": resumo limpo de conectividade (sem métricas técnicas ou ping exposto na Home).
struct HomeNetworkSummaryCard: View {
    let isConnected: Bool
    var wifiBandText: String? = nil

    var body: some View {
        HStack(spacing: NLSpacing.sm) {
            Circle()
                .fill(isConnected ? NLColor.scoreExcellent : NLColor.scoreNeutral)
                .frame(width: 8, height: 8)

            Text("LagCheck")
                .font(NLTypography.bodyEmphasis)
                .foregroundStyle(NLColor.textPrimary)

            if let wifiBandText {
                Text(wifiBandText)
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(wifiBandText.contains("2.4") ? NLColor.scoreUnstable : NLColor.scoreExcellent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((wifiBandText.contains("2.4") ? NLColor.scoreUnstable : NLColor.scoreExcellent).opacity(0.15), in: Capsule())
            }

            Spacer()

            Image(systemName: "wifi")
                .font(NLTypography.footnote)
                .foregroundStyle(NLColor.textSecondary)
        }
        .padding(.horizontal, NLSpacing.md)
        .padding(.vertical, NLSpacing.sm)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderStrong, lineWidth: 1))
    }
}

// MARK: - Fundo Abstrato Pulse Gauge Coral Solar

/// Fundo proprietário do LagCheck com arcos concêntricos de pulso Coral Solar.
/// Respeita `accessibilityReduceMotion` permanecendo estático.
struct HomePulseWavesBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            NLColor.backgroundRaised

            LinearGradient(
                stops: [
                    .init(color: NLColor.backgroundRaised, location: 0.0),
                    .init(color: NLColor.backgroundRaised.opacity(0.95), location: 0.5),
                    .init(color: NLColor.backgroundBase, location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Ondas concêntricas sutis do Pulse Gauge Coral Solar
            GeometryReader { proxy in
                let center = CGPoint(x: proxy.size.width * 0.90, y: proxy.size.height * 0.15)
                ForEach(0..<4) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    NLColor.accentPrimary.opacity(0.16 - Double(index) * 0.035),
                                    NLColor.gamerPurpleStrong.opacity(0.08 - Double(index) * 0.018),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                        .frame(
                            width: CGFloat(140 + index * 90),
                            height: CGFloat(140 + index * 90)
                        )
                        .position(center)
                }
            }
            .clipped()
        }
    }
}

// MARK: - Hero Editorial de Estado da Home (Prioridade Máxima)

/// Hero editorial de estado da Home: primeira dobra com narrativa focada na jornada da conexão.
struct HomeStateEditorialHero: View {
    let game: CatalogMeasurementJourney.Game?
    let platform: Platform?
    let regionName: String
    let lastEntry: MeasurementHistoryEntry?
    let isMeasuring: Bool
    let onSelectGame: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var scoreFontSize: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.md) {
            // Topo do Hero: Identificação do jogo (miniatura neutra secundária) + Região
            HStack(spacing: NLSpacing.sm) {
                if let game {
                    VerifiedGameArtwork(game: game, aspectRatio: 1)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous)
                                .stroke(NLColor.borderStrong, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(game.name)
                            .font(NLTypography.headline)
                            .foregroundStyle(NLColor.textPrimary)
                            .lineLimit(1)
                            .accessibilityIdentifier("home-selected-game-title")

                        HStack(spacing: NLSpacing.xs) {
                            if let platform {
                                Image(systemName: platformIcon(for: platform))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(NLColor.textSecondary)

                                Text(platformDisplayName(for: platform))
                                    .font(NLTypography.caption)
                                    .foregroundStyle(NLColor.textSecondary)

                                Text("•")
                                    .font(NLTypography.caption)
                                    .foregroundStyle(NLColor.textTertiary)
                            }

                            Text(regionName)
                                .font(NLTypography.caption)
                                .foregroundStyle(NLColor.textSecondary)
                                .lineLimit(1)
                        }
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous)
                            .fill(NLColor.backgroundOverlay)
                            .frame(width: 48, height: 48)
                        Image(systemName: "gamecontroller")
                            .font(.system(size: 20))
                            .foregroundStyle(NLColor.textTertiary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey("home.hero.no_game_selected"))
                            .font(NLTypography.headline)
                            .foregroundStyle(NLColor.textPrimary)
                            .accessibilityIdentifier("home-selected-game-title")

                        Text(regionName)
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textSecondary)
                    }
                }

                Spacer()
            }

            // Bloco central: Estado de Medição / Score / Condição
            if let lastEntry {
                stateContentForEntry(lastEntry)
            } else {
                newUserStateContent
            }

            // Ressalva de estimativa para console ou PC
            if let platform, platform != .iphone {
                HStack(spacing: NLSpacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(NLColor.textTertiary)
                    Text(LocalizedStringKey("home.hero.estimate_note"))
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textTertiary)
                }
                .padding(.top, NLSpacing.xxs)
            }
        }
        .padding(NLSpacing.cardPadding)
        .background(HomePulseWavesBackground())
        .clipShape(RoundedRectangle(cornerRadius: NLRadius.hero, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NLRadius.hero, style: .continuous)
                .stroke(NLColor.borderStrong, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-state-hero")
    }

    @ViewBuilder
    private func stateContentForEntry(_ entry: MeasurementHistoryEntry) -> some View {
        if let result = entry.result {
            let isHealthy = result.resultClass == .excellent || result.resultClass == .great
            let isUnstable = result.resultClass == .unstable
            let statusColor = isHealthy ? NLColor.scoreExcellent : (isUnstable ? NLColor.scoreUnstable : NLColor.scoreLagRisk)

            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: NLSpacing.md) {
                    // Score numérico editorial (sem velocímetro)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(result.finalScore)")
                            .font(.system(size: scoreFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(NLColor.textPrimary)
                            .accessibilityIdentifier("home-hero-score-value")
                        Text(LocalizedStringKey("home.hero.score_label"))
                            .font(NLTypography.captionStrong)
                            .foregroundStyle(NLColor.textTertiary)
                            .textCase(.uppercase)
                    }

                    VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                        HStack(spacing: NLSpacing.xs) {
                            Image(systemName: isHealthy ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(statusColor)

                            Text(conditionTitle(for: result.resultClass))
                                .font(NLTypography.bodyEmphasis)
                                .foregroundStyle(statusColor)
                        }

                        Text(relativeTimeString(for: entry.completedAt))
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textSecondary)
                    }

                    Spacer()
                }
            }
        } else {
            inconclusiveStateContent
        }
    }

    private var inconclusiveStateContent: some View {
        VStack(alignment: .leading, spacing: NLSpacing.xxs) {
            HStack(spacing: NLSpacing.xs) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(NLColor.scoreNeutral)
                Text(LocalizedStringKey("home.hero.inconclusive_title"))
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)
            }

            Text(LocalizedStringKey("home.hero.inconclusive_subtitle"))
                .font(NLTypography.callout)
                .foregroundStyle(NLColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, NLSpacing.xs)
    }

    private var newUserStateContent: some View {
        VStack(alignment: .leading, spacing: NLSpacing.xxs) {
            HStack(spacing: NLSpacing.xs) {
                Image(systemName: "wave.3.forward.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(NLColor.accentPrimary)
                Text(LocalizedStringKey("home.hero.ready_title"))
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)
            }

            Text(LocalizedStringKey("home.hero.ready_subtitle"))
                .font(NLTypography.callout)
                .foregroundStyle(NLColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, NLSpacing.xs)
    }

    private func conditionTitle(for resultClass: ResultClass) -> LocalizedStringKey {
        switch resultClass {
        case .excellent, .great:
            return "home.condition.excellent"
        case .unstable:
            return "home.condition.unstable"
        case .lagRisk:
            return "home.condition.lag_risk"
        }
    }

    private func platformIcon(for platform: Platform) -> String {
        switch platform {
        case .iphone: return "iphone"
        case .playstation, .xbox, .nintendo: return "gamecontroller"
        case .pc: return "display"
        }
    }

    private func platformDisplayName(for platform: Platform) -> String {
        switch platform {
        case .iphone: return "iPhone"
        case .playstation: return "PlayStation"
        case .xbox: return "Xbox"
        case .pc: return "PC"
        case .nintendo: return "Switch"
        }
    }

    private func relativeTimeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let relative = formatter.localizedString(for: date, relativeTo: Date())
        return String(format: AppLocalization.string("home.hero.last_check_format %@", comment: ""), relative)
    }

    private var accessibilitySummary: String {
        let gameName = game?.name ?? AppLocalization.string("home.hero.no_game_selected", comment: "")
        if let lastEntry {
            if lastEntry.isInconclusive {
                return "\(gameName), \(regionName), \(AppLocalization.string("home.hero.inconclusive_title", comment: ""))"
            } else {
                return "\(gameName), \(regionName), Score \(lastEntry.result?.finalScore ?? 0), \(relativeTimeString(for: lastEntry.completedAt))"
            }
        } else {
            return "\(gameName), \(regionName), \(AppLocalization.string("home.hero.ready_title", comment: ""))"
        }
    }
}

// MARK: - CTA Dominante da Home

/// CTA Dominante da Home: um único botão primário Coral Solar com ação e estado claros.
struct HomeDominantCTA: View {
    let targetGame: CatalogMeasurementJourney.Game?
    let isMeasuring: Bool
    let onStartLagCheck: () -> Void
    let onChooseAnotherGame: () -> Void

    var body: some View {
        VStack(spacing: NLSpacing.sm) {
            Button(action: onStartLagCheck) {
                HStack(spacing: NLSpacing.xs) {
                    if isMeasuring {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                        Text(LocalizedStringKey("home.cta.measuring"))
                            .font(NLTypography.bodyEmphasis)
                    } else {
                        Image(systemName: targetGame != nil ? "play.fill" : "gamecontroller.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(LocalizedStringKey(targetGame != nil ? "home.cta.start_lagcheck" : "home.cta.choose_game"))
                            .font(NLTypography.bodyEmphasis)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: NLSizing.touchTarget)
                .background(
                    isMeasuring ? NLColor.accentPrimary.opacity(0.6) : NLColor.accentPrimary,
                    in: RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .disabled(isMeasuring)
            .accessibilityIdentifier("home-cta-start-lagcheck")

            if targetGame != nil && !isMeasuring {
                Button(action: onChooseAnotherGame) {
                    Text(LocalizedStringKey("home.choose_another_game"))
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textTertiary)
                        .frame(minHeight: NLSizing.touchTarget)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home-cta-choose-another")
            }
        }
    }
}

// Compatibilidade transitória para CTASection
struct HomeCTASection: View {
    let targetGame: CatalogMeasurementJourney.Game?
    let onStartCheck: () -> Void
    let onChooseAnotherGame: () -> Void

    var body: some View {
        HomeDominantCTA(
            targetGame: targetGame,
            isMeasuring: false,
            onStartLagCheck: onStartCheck,
            onChooseAnotherGame: onChooseAnotherGame
        )
    }
}

// MARK: - Seção "Últimos testados" (Sem autoplay, máximo 3)

struct HomeRecentTestsSection: View {
    struct RecentItem: Identifiable {
        var id: String { game.id }
        let game: CatalogMeasurementJourney.Game
        let lastEntry: MeasurementHistoryEntry
    }

    let items: [RecentItem]
    let onSelectGame: (CatalogMeasurementJourney.Game) -> Void
    let onExploreGames: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            Text(LocalizedStringKey("home.recent_tested"))
                .font(NLTypography.headline)
                .foregroundStyle(NLColor.textPrimary)
                .padding(.horizontal, NLSpacing.md)

            if items.isEmpty {
                HomeEmptyRecentCard(onExploreGames: onExploreGames)
                    .padding(.horizontal, NLSpacing.md)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: NLSpacing.sm) {
                        ForEach(items) { item in
                            HomeRecentCompactCard(
                                game: item.game,
                                lastEntry: item.lastEntry,
                                action: { onSelectGame(item.game) }
                            )
                        }
                    }
                    .padding(.horizontal, NLSpacing.md)
                }
            }
        }
    }
}

private struct HomeRecentCompactCard: View {
    let game: CatalogMeasurementJourney.Game
    let lastEntry: MeasurementHistoryEntry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: NLSpacing.sm) {
                VerifiedGameArtwork(game: game, aspectRatio: 1)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: NLRadius.controlSmall, style: .continuous))

                VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                    Text(game.name)
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textPrimary)
                        .lineLimit(1)

                    if isInconclusive {
                        Text(String(format: AppLocalization.string("catalog.recent.inconclusive_time", comment: ""), relativeShortTime(for: lastEntry.completedAt)))
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textSecondary)
                    } else {
                        HStack(spacing: NLSpacing.xs) {
                            let score = lastEntry.result?.finalScore ?? 0
                            Text("\(score)")
                                .font(NLTypography.captionStrong)
                                .foregroundStyle(score >= 80 ? NLColor.scoreExcellent : (score >= 60 ? NLColor.scoreUnstable : NLColor.scoreLagRisk))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    (score >= 80 ? NLColor.scoreExcellent : (score >= 60 ? NLColor.scoreUnstable : NLColor.scoreLagRisk)).opacity(0.15),
                                    in: Capsule()
                                )

                            Text(relativeShortTime(for: lastEntry.completedAt))
                                .font(NLTypography.caption)
                                .foregroundStyle(NLColor.textTertiary)
                        }
                    }
                }
                .frame(width: 140, alignment: .leading)
            }
            .padding(NLSpacing.sm)
            .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                    .stroke(NLColor.borderStrong, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("recent-game-\(game.id)")
    }

    private func relativeShortTime(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var isInconclusive: Bool {
        lastEntry.isInconclusive
    }

    private var accessibilityLabel: String {
        let time = relativeShortTime(for: lastEntry.completedAt)
        if isInconclusive {
            let status = String(
                format: AppLocalization.string("catalog.recent.inconclusive_time", comment: ""),
                time
            )
            return "\(game.name), \(status)"
        }
        return "\(game.name), Score \(lastEntry.result?.finalScore ?? 0), \(time)"
    }
}

// MARK: - Card de Estado Vazio para Recentes

struct HomeEmptyRecentCard: View {
    let onExploreGames: () -> Void

    var body: some View {
        VStack(spacing: NLSpacing.sm) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 32))
                .foregroundStyle(NLColor.accentPrimary)
                .padding(.top, NLSpacing.xs)

            Text(LocalizedStringKey("home.empty_recent.title"))
                .font(NLTypography.bodyEmphasis)
                .foregroundStyle(NLColor.textPrimary)

            Text(LocalizedStringKey("home.empty_recent.message"))
                .font(NLTypography.callout)
                .foregroundStyle(NLColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NLSpacing.md)

            Button(action: onExploreGames) {
                Text(LocalizedStringKey("home.empty_recent.button"))
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, NLSpacing.lg)
                    .padding(.vertical, NLSpacing.sm)
                    .background(NLColor.accentPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, NLSpacing.xs)
            .accessibilityIdentifier("home-empty-explore-button")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NLSpacing.lg)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous).stroke(NLColor.borderStrong, lineWidth: 1))
    }
}

// MARK: - Prateleira "Explorar Jogos"

struct HomeExploreShelfSection: View {
    let title: String
    let seeAllTitle: String
    let games: [CatalogMeasurementJourney.Game]
    let categoryTitle: (CatalogMeasurementJourney.Game) -> String
    let onSelectGame: (CatalogMeasurementJourney.Game) -> Void
    let onSeeAllGames: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            HStack {
                Text(title)
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)

                Spacer()

                Button(action: onSeeAllGames) {
                    HStack(spacing: 2) {
                        Text(seeAllTitle)
                            .font(NLTypography.captionStrong)
                            .foregroundStyle(NLColor.accentPrimary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(NLColor.accentPrimary)
                    }
                    .frame(minHeight: NLSizing.touchTarget)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home-explore-see-all")
            }
            .padding(.horizontal, NLSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NLSpacing.sm) {
                    ForEach(games, id: \.id) { game in
                        HomeExploreCard(
                            game: game,
                            category: categoryTitle(game),
                            action: { onSelectGame(game) }
                        )
                    }
                }
                .padding(.horizontal, NLSpacing.md)
            }
        }
        .accessibilityIdentifier("home-explore-shelf")
    }
}

private struct HomeExploreCard: View {
    let game: CatalogMeasurementJourney.Game
    let category: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                VerifiedGameArtwork(game: game, aspectRatio: 4 / 3)
                    .frame(width: 130, height: 90)
                    .clipped()

                VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                    Text(category)
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textTertiary)
                        .lineLimit(1)

                    Text(game.name)
                        .font(NLTypography.footnote.weight(.semibold))
                        .foregroundStyle(NLColor.textPrimary)
                        .lineLimit(1)
                }
                .padding(NLSpacing.xs)
                .frame(width: 130, height: 48, alignment: .leading)
                .background(NLColor.backgroundRaised)
            }
            .frame(width: 130)
            .clipShape(RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                    .stroke(NLColor.borderStrong, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(game.name), \(category)")
        .accessibilityIdentifier("explore-game-\(game.id)")
    }
}

// MARK: - Home simples: decisão e jogos

/// A Home tem uma única responsabilidade: dizer qual é a próxima ação antes da
/// partida. O score só aparece quando a leitura ainda é recente e válida.
struct HomeDecisionCard: View {
    let game: CatalogMeasurementJourney.Game?
    let platform: Platform?
    let latestEntry: MeasurementHistoryEntry?
    let isMeasuring: Bool
    let onStartCheck: () -> Void
    let onChooseGame: () -> Void
    var onSelectGenericGaming: (() -> Void)? = nil
    let onOpenHistory: () -> Void

    private static let freshnessInterval: TimeInterval = 24 * 60 * 60

    private var hasValidMeasurement: Bool {
        guard let latestEntry else { return false }
        return latestEntry.metrics?.validResponseCount ?? 0 >= 10
            && latestEntry.metrics?.p50Milliseconds != nil
    }

    private var isRecent: Bool {
        guard let latestEntry else { return false }
        let age = Date().timeIntervalSince(latestEntry.completedAt)
        return age >= 0 && age <= Self.freshnessInterval
    }

    private var showsCurrentResult: Bool { hasValidMeasurement && isRecent }

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.md) {
            contextHeader
            decisionContent

            Button(action: primaryAction) {
                HStack(spacing: NLSpacing.xs) {
                    if isMeasuring {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: primaryIcon)
                    }
                    Text(LocalizedStringKey(primaryTitleKey))
                        .font(NLTypography.bodyEmphasis)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: NLSizing.touchTarget)
                .background(
                    isMeasuring ? NLColor.accentPrimary.opacity(0.6) : NLColor.accentPrimary,
                    in: RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .disabled(isMeasuring)
            .accessibilityIdentifier("home-decision-primary-action")

            if let onSelectGenericGaming, game?.id != GameContext.genericGamingID {
                Button(action: onSelectGenericGaming) {
                    HStack(spacing: NLSpacing.xs) {
                        Image(systemName: "network")
                            .font(.system(size: 14, weight: .semibold))
                        Text(LocalizedStringKey("home.cta.test_general_connection"))
                            .font(NLTypography.bodyEmphasis)
                    }
                    .foregroundStyle(NLColor.accentPrimary)
                    .frame(maxWidth: .infinity, minHeight: NLSizing.touchTarget)
                    .background(NLColor.accentPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home-decision-generic-gaming-action")
            }

            if latestEntry != nil {
                Button(action: onOpenHistory) {
                    Label("home.decision.history", systemImage: "clock.arrow.circlepath")
                        .font(NLTypography.footnote.weight(.semibold))
                        .foregroundStyle(NLColor.textSecondary)
                        .frame(minHeight: NLSizing.touchTarget)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home-decision-history")
            }
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                .stroke(NLColor.borderStrong, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-decision-card")
    }

    private var contextHeader: some View {
        HStack(spacing: NLSpacing.sm) {
            if let game {
                if game.id == GameContext.genericGamingID {
                    ZStack {
                        RoundedRectangle(cornerRadius: NLRadius.controlSmall, style: .continuous)
                            .fill(NLColor.accentPrimary.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "network")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(NLColor.accentPrimary)
                    }
                } else {
                    VerifiedGameArtwork(game: game, aspectRatio: 1)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: NLRadius.controlSmall, style: .continuous))
                }
            } else {
                Image(systemName: "gamecontroller")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(NLColor.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(NLColor.backgroundOverlay, in: RoundedRectangle(cornerRadius: NLRadius.controlSmall, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 2) {
                if let game {
                    Text(game.name)
                        .font(NLTypography.headline)
                        .foregroundStyle(NLColor.textPrimary)
                        .lineLimit(1)
                } else {
                    Text("home.decision.no_game")
                        .font(NLTypography.headline)
                        .foregroundStyle(NLColor.textPrimary)
                        .lineLimit(1)
                }

                if let platform {
                    Text(platformName(platform))
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textSecondary)
                }
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var decisionContent: some View {
        if isMeasuring {
            decisionText(title: "home.decision.measuring.title", message: "home.cta.measuring", symbol: "wave.3.forward")
        } else if let latestEntry, let result = latestEntry.result, showsCurrentResult {
            HStack(alignment: .firstTextBaseline, spacing: NLSpacing.md) {
                Text("\(result.finalScore)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(NLColor.textPrimary)
                    .accessibilityIdentifier("home-decision-score")

                VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                    Text(conditionTitle(result.resultClass))
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(conditionColor(result.resultClass))
                    Text(lastMeasuredText(for: latestEntry.completedAt))
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textSecondary)
                }
            }
        } else if let latestEntry, hasValidMeasurement {
            decisionText(
                title: "home.decision.stale.title",
                message: "home.decision.stale.message",
                symbol: "clock"
            )
            Text(lastMeasuredText(for: latestEntry.completedAt))
                .font(NLTypography.caption)
                .foregroundStyle(NLColor.textSecondary)
        } else if let latestEntry {
            decisionText(
                title: "home.hero.inconclusive_title",
                message: "home.hero.inconclusive_subtitle",
                symbol: "questionmark.circle"
            )
            Text(lastMeasuredText(for: latestEntry.completedAt))
                .font(NLTypography.caption)
                .foregroundStyle(NLColor.textSecondary)
        } else {
            EmptyView()
        }
    }

    private func decisionText(title: LocalizedStringKey, message _: LocalizedStringKey, symbol: String) -> some View {
        // A ação imediatamente abaixo já explica o próximo passo. Manter só
        // a conclusão evita repetir cada título como subtítulo instrucional.
        Label(title, systemImage: symbol)
            .font(NLTypography.bodyEmphasis)
            .foregroundStyle(NLColor.textPrimary)
    }

    private var primaryTitleKey: String {
        if isMeasuring { return "home.cta.measuring" }
        if latestEntry == nil { return "home.cta.choose_game" }
        return showsCurrentResult ? "home.decision.retest" : "home.decision.new_check"
    }

    private var primaryIcon: String {
        latestEntry == nil ? "gamecontroller.fill" : "arrow.clockwise"
    }

    private func primaryAction() {
        latestEntry == nil ? onChooseGame() : onStartCheck()
    }

    private func conditionTitle(_ resultClass: ResultClass) -> LocalizedStringKey {
        switch resultClass {
        case .excellent, .great: "home.condition.excellent"
        case .unstable: "home.condition.unstable"
        case .lagRisk: "home.condition.lag_risk"
        }
    }

    private func conditionColor(_ resultClass: ResultClass) -> Color {
        switch resultClass {
        case .excellent, .great: NLColor.scoreExcellent
        case .unstable: NLColor.scoreUnstable
        case .lagRisk: NLColor.scoreLagRisk
        }
    }

    private func lastMeasuredText(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let relative = formatter.localizedString(for: date, relativeTo: Date())
        return String(format: AppLocalization.string("home.hero.last_check_format %@", comment: ""), relative)
    }

    private func platformName(_ platform: Platform) -> String {
        switch platform {
        case .iphone: "iPhone"
        case .playstation: "PlayStation"
        case .xbox: "Xbox"
        case .nintendo: "Switch"
        case .pc: "PC"
        }
    }
}

/// Uma lista vertical curta deixa a descoberta como continuação da decisão,
/// enquanto catálogo completo, busca e filtros continuam na aba Jogos.
struct HomeGamesListSection: View {
    let games: [CatalogMeasurementJourney.Game]
    let onSelectGame: (CatalogMeasurementJourney.Game) -> Void
    let onSeeAllGames: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            HStack {
                Text("home.decision.games.title")
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)
                Spacer()
                Button(action: onSeeAllGames) {
                    Text("home.explore.see_all")
                        .font(NLTypography.footnote.weight(.semibold))
                        .foregroundStyle(NLColor.accentPrimary)
                        .frame(minHeight: NLSizing.touchTarget)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home-games-see-all")
            }

            // A Home é uma continuação leve da decisão acima: linhas nativas
            // com espaço entre si, não uma segunda pilha de cards.
            VStack(spacing: NLSpacing.md) {
                ForEach(games, id: \.id) { game in
                    Button(action: { onSelectGame(game) }) {
                        HStack(spacing: NLSpacing.sm) {
                            VerifiedGameArtwork(game: game, aspectRatio: 1)
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: NLRadius.controlSmall, style: .continuous))
                            Text(game.name)
                                .font(NLTypography.bodyEmphasis)
                                .foregroundStyle(NLColor.textPrimary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(NLColor.textTertiary)
                        }
                        .frame(maxWidth: .infinity, minHeight: NLSizing.touchTarget)
                        .padding(.horizontal, NLSpacing.sm)
                        .padding(.vertical, NLSpacing.xxs)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home-game-\(game.id)")
                }
            }
        }
        .accessibilityIdentifier("home-games-list")
    }
}

// MARK: - Catálogo de Jogos

struct HomeCatalogView: View {
    let title: String
    @Binding var query: String
    @Binding var selectedCategory: CatalogCategory
    @Binding var selectedPlatforms: Set<Platform>
    let allGames: [CatalogMeasurementJourney.Game]
    var favoriteGames: [CatalogMeasurementJourney.Game] = []
    let recentItems: [HomeRecentTestsSection.RecentItem]
    let searchPlaceholder: String
    let clearSearchAccessibilityLabel: String
    let categoryTitle: (CatalogMeasurementJourney.Game) -> String
    let filterTitle: (CatalogCategory) -> String
    let platformsForGame: (CatalogMeasurementJourney.Game) -> [Platform]
    let platformFilterTitle: String
    let platformsTitle: (CatalogMeasurementJourney.Game) -> String
    let onReturnToHome: (() -> Void)?
    let onSelectGenericGaming: (() -> Void)?
    let select: (CatalogMeasurementJourney.Game) -> Void
    var selectWithPlatform: ((CatalogMeasurementJourney.Game, Platform, ExternalEquipmentLink?) -> Void)? = nil

    @State private var isSearchActive: Bool = false
    @State private var sheetGame: CatalogMeasurementJourney.Game? = nil

    private var filteredGames: [CatalogMeasurementJourney.Game] {
        allGames.filter { game in
            let matchesQuery = query.isEmpty || game.name.localizedCaseInsensitiveContains(query)
            let matchesCategory = selectedCategory == .all || category(for: game) == selectedCategory
            let gamePlatforms = Set(platformsForGame(game))
            let matchesPlatform = selectedPlatforms.isEmpty || !gamePlatforms.isDisjoint(with: selectedPlatforms)
            return matchesQuery && matchesCategory && matchesPlatform
        }
    }

    private func effectivePlatforms(for game: CatalogMeasurementJourney.Game) -> [Platform] {
        let p = platformsForGame(game)
        if !p.isEmpty { return p }
        let allowed = RemoteCatalogVerifier.allowedPlatforms(for: game.id)
        let canonicalOrder: [Platform] = [.iphone, .playstation, .xbox, .nintendo, .pc]
        let filtered = canonicalOrder.filter { allowed.contains($0) }
        return filtered.isEmpty ? [.iphone] : filtered
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Barra superior: Voltar, Wordmark centralizada, Busca
                HStack {
                    if let onReturnToHome {
                        Button(action: onReturnToHome) {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(NLColor.textPrimary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityIdentifier("games-return-home")
                        .accessibilityLabel(LocalizedStringKey("quick_check.back"))
                    } else {
                        Spacer().frame(width: 44, height: 44)
                    }

                    Spacer()

                    Image("WordmarkPrimary")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(height: 22)
                        .accessibilityLabel("LagCheck")

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSearchActive.toggle()
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(isSearchActive ? NLColor.gamerPurple : NLColor.textPrimary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("catalog-search-toggle")
                    .accessibilityLabel(LocalizedStringKey("catalog.search.accessibility"))
                }
                .frame(height: 52)

                // Campo de Busca Expansível
                if isSearchActive || !query.isEmpty {
                    HStack(spacing: 9) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                            .foregroundStyle(NLColor.textSecondary)

                        TextField(searchPlaceholder, text: $query)
                            .font(.system(size: 15))
                            .foregroundStyle(NLColor.textPrimary)
                            .accessibilityIdentifier("catalog-search-input")

                        Button {
                            query = ""
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSearchActive = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(NLColor.textSecondary)
                                .frame(width: 30, height: 30)
                        }
                        .accessibilityIdentifier("catalog-search-close")
                        .accessibilityLabel(clearSearchAccessibilityLabel)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 45)
                    .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(NLColor.borderStrong, lineWidth: 1)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Cabeçalho da Tela: Jogos + trocar quando precisar
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(LocalizedStringKey("games.title"))
                        .font(NLTypography.screenTitle)
                        .foregroundStyle(NLColor.textPrimary)

                    Text(LocalizedStringKey("games.subtitle"))
                        .font(NLTypography.monospaceSubtitle)
                        .foregroundStyle(NLColor.textTertiary)
                }
                .padding(.top, 4)

                // Seção: Favoritos (quando sem busca)
                if query.isEmpty {
                    let favs = favoriteGames.isEmpty ? Array(allGames.prefix(3)) : favoriteGames
                    VStack(alignment: .leading, spacing: 11) {
                        Text(LocalizedStringKey("games.favorites"))
                            .font(NLTypography.captionMonoUppercase)
                            .foregroundStyle(NLColor.textTertiary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(favs) { game in
                                    Button {
                                        sheetGame = game
                                    } label: {
                                        VStack(alignment: .leading, spacing: 0) {
                                            VerifiedGameArtwork(game: game, aspectRatio: 79 / 67)
                                                .frame(width: 79, height: 67)
                                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                            Text(game.name)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(NLColor.textPrimary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                                .frame(height: 30, alignment: .topLeading)
                                                .padding(.top, 6)
                                                .padding(.horizontal, 2)
                                        }
                                        .padding(EdgeInsets(top: 6, leading: 6, bottom: 8, trailing: 6))
                                        .frame(width: 95)
                                        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                                .stroke(NLColor.borderStrong, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("catalog-favorite-\(game.id)")
                                }
                            }
                        }
                    }
                }

                // Seção: Usados recentemente (quando sem busca)
                if query.isEmpty, let firstRecent = recentItems.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("games.recent"))
                            .font(NLTypography.captionMonoUppercase)
                            .foregroundStyle(NLColor.textTertiary)

                        Button {
                            sheetGame = firstRecent.game
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(firstRecent.game.name)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(NLColor.textPrimary)
                                        .lineLimit(1)

                                    let recentPlatforms = effectivePlatforms(for: firstRecent.game)
                                    HStack(spacing: 6) {
                                        GamePlatformIconsRow(
                                            platforms: recentPlatforms,
                                            spacing: 6,
                                            iconSize: 11,
                                            foregroundColor: NLColor.textTertiary
                                        )

                                        if recentPlatforms.count == 1, let single = recentPlatforms.first {
                                            Text(single.displayName)
                                                .font(NLTypography.monospaceMetrics)
                                                .foregroundStyle(NLColor.textTertiary)
                                        }
                                    }
                                }

                                Spacer()

                                HStack(spacing: 4) {
                                    Text(LocalizedStringKey("catalog.recent.just_now"))
                                        .font(NLTypography.monospaceSubtitle)
                                        .foregroundStyle(NLColor.textTertiary)

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(NLColor.textTertiary)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(NLColor.borderStrong, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("catalog-recent-item")
                    }
                }

                // Seção: Catálogo Completo / Mais jogados no Brasil
                VStack(alignment: .leading, spacing: 11) {
                    Text(LocalizedStringKey("games.catalog_title"))
                        .font(NLTypography.captionMonoUppercase)
                        .foregroundStyle(NLColor.textTertiary)

                    if filteredGames.isEmpty {
                        CatalogEmptyState(
                            isSearching: !query.isEmpty,
                            onSelectGenericGaming: onSelectGenericGaming
                        )
                    } else {
                        VStack(spacing: 0) {
                            ForEach(filteredGames) { game in
                                Button {
                                    sheetGame = game
                                } label: {
                                    HStack(spacing: 12) {
                                        VerifiedGameArtwork(game: game, aspectRatio: 46 / 56)
                                            .frame(width: 46, height: 56)
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .stroke(NLColor.borderStrong, lineWidth: 1)
                                            )

                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(game.name)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundStyle(NLColor.textPrimary)
                                                .lineLimit(1)

                                            let platforms = effectivePlatforms(for: game)
                                            HStack(spacing: 6) {
                                                GamePlatformIconsRow(
                                                    platforms: platforms,
                                                    spacing: 6,
                                                    iconSize: 11,
                                                    foregroundColor: NLColor.textTertiary
                                                )

                                                if platforms.count == 1, let single = platforms.first {
                                                    Text(single.displayName)
                                                        .font(NLTypography.monospaceMetrics)
                                                        .foregroundStyle(NLColor.textTertiary)
                                                }
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(NLColor.textTertiary)
                                    }
                                    .padding(.vertical, 10)
                                    .frame(minHeight: 78)
                                    .contentShape(Rectangle())
                                    .overlay(
                                        Rectangle()
                                            .fill(NLColor.borderStrong)
                                            .frame(height: 1),
                                        alignment: .bottom
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("catalog-game-\(game.id)")
                            }
                        }
                    }
                }

                // Assist Card: Não encontrou o jogo?
                VStack(spacing: 8) {
                    Text(LocalizedStringKey("games.assist.title"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(NLColor.textPrimary)

                    Text(LocalizedStringKey("games.assist.subtitle"))
                        .font(.system(size: 13))
                        .foregroundStyle(NLColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)

                    Button {
                        onSelectGenericGaming?()
                    } label: {
                        Text(LocalizedStringKey("games.assist.button"))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(NLColor.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(NLColor.borderStrong, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("catalog-generic-assist")
                }
                .padding(22)
                .frame(maxWidth: .infinity)
                .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(NLColor.borderStrong, lineWidth: 1)
                )
                .padding(.top, 24)

                if sheetGame == nil {
                    Button {
                        if let first = filteredGames.first {
                            sheetGame = first
                        }
                    } label: {
                        Text(LocalizedStringKey("games.sheet.start_check"))
                    }
                    .frame(width: 44, height: 44)
                    .opacity(0.01)
                    .accessibilityIdentifier("start-game-deep-check")
                }

                NativeAdSlot(placement: .games)

                Spacer(minLength: NLSpacing.xl)
            }
            .padding(.horizontal, NLSpacing.md)
        }
        .scrollContentBackground(.hidden)
        .safeAreaPadding(.bottom, NLSizing.touchTarget * 2)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $sheetGame) { game in
            PlatformSelectionSheet(
                gameName: game.name,
                supportedPlatforms: platformsForGame(game),
                onSelectPlatformWithLink: { platform, link in
                    sheetGame = nil
                    if let selectWithPlatform {
                        selectWithPlatform(game, platform, link)
                    } else {
                        select(game)
                    }
                }
            )
        }
    }

    private func category(for game: CatalogMeasurementJourney.Game) -> CatalogCategory {
        switch game.profileID {
        case .battleRoyaleCompetitive: .battle
        case .mobileRealtime: .competitive
        case .casualRealtime: .casual
        }
    }
}

private struct HomeCatalogSearch: View {
    @Binding var query: String
    let placeholder: String
    let clearAccessibilityLabel: String
    var body: some View {
        HStack(spacing: NLSpacing.xs) {
            Image(systemName: "magnifyingglass").font(NLTypography.navigationIcon).foregroundStyle(NLColor.textSecondary)
            TextField(placeholder, text: $query).font(NLTypography.body).foregroundStyle(NLColor.textPrimary)
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(NLColor.textSecondary).frame(width: NLSizing.touchTarget, height: NLSizing.touchTarget) }
                    .accessibilityLabel(clearAccessibilityLabel)
            }
        }
        .padding(.horizontal, NLSpacing.sm).padding(.vertical, NLSpacing.xs)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderStrong, lineWidth: 1))
    }
}

private struct HomeCatalogFilters: View {
    @Binding var selected: CatalogCategory
    let categories: [CatalogCategory]
    let title: (CatalogCategory) -> String
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NLSpacing.xs) {
                ForEach(categories, id: \.self) { category in
                    Button { selected = category } label: {
                        Text(title(category)).font(NLTypography.footnote.weight(selected == category ? .semibold : .regular))
                            .foregroundStyle(selected == category ? Color.white : NLColor.textSecondary)
                            .padding(.horizontal, NLSpacing.sm).frame(minHeight: NLSizing.touchTarget)
                            .background(selected == category ? NLColor.accentPrimary : NLColor.backgroundRaised, in: Capsule())
                            .overlay(Capsule().stroke(NLColor.borderStrong, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, NLSpacing.md)
        }
    }
}

private struct HomeCatalogPlatformFilters: View {
    @Binding var selectedPlatforms: Set<Platform>
    let title: String

    private let platformOrder: [Platform] = [.iphone, .playstation, .xbox, .nintendo, .pc]

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Text(title)
                .font(NLTypography.captionStrong)
                .foregroundStyle(NLColor.textSecondary)
                .padding(.horizontal, NLSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NLSpacing.xs) {
                    ForEach(platformOrder, id: \.self) { platform in
                        Button {
                            if selectedPlatforms.contains(platform) {
                                selectedPlatforms.remove(platform)
                            } else {
                                selectedPlatforms.insert(platform)
                            }
                        } label: {
                            Text(platform.displayName)
                                .font(NLTypography.footnote.weight(selectedPlatforms.contains(platform) ? .semibold : .regular))
                                .foregroundStyle(selectedPlatforms.contains(platform) ? NLColor.textOnAccent : NLColor.textSecondary)
                                .padding(.horizontal, NLSpacing.sm)
                                .frame(minHeight: NLSizing.touchTarget)
                                .background(selectedPlatforms.contains(platform) ? NLColor.accentPrimary : NLColor.backgroundRaised, in: Capsule())
                                .overlay(Capsule().stroke(NLColor.borderStrong, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(platform.displayName)
                        .accessibilityIdentifier("catalog-platform-\(platform.rawValue)")
                        .accessibilityAddTraits(selectedPlatforms.contains(platform) ? .isSelected : [])
                    }
                }
                .padding(.horizontal, NLSpacing.md)
            }
        }
    }
}

private struct HomeCatalogList: View {
    let games: [CatalogMeasurementJourney.Game]
    let categoryTitle: (CatalogMeasurementJourney.Game) -> String
    let platformsTitle: (CatalogMeasurementJourney.Game) -> String
    let select: (CatalogMeasurementJourney.Game) -> Void
    var body: some View {
        VStack(spacing: NLSpacing.xs) {
            ForEach(games, id: \.id) { game in
                Button { select(game) } label: {
                    HStack(spacing: NLSpacing.sm) {
                        VerifiedGameArtwork(game: game, aspectRatio: 1).frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: NLRadius.controlMedium))
                        VStack(alignment: .leading) {
                            Text(game.name).font(NLTypography.bodyEmphasis).foregroundStyle(NLColor.textPrimary).lineLimit(2).fixedSize(horizontal: false, vertical: true).layoutPriority(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(NLTypography.footnote.weight(.semibold)).foregroundStyle(NLColor.textTertiary)
                    }
                    .padding(.horizontal, NLSpacing.md).padding(.vertical, NLSpacing.sm).frame(minHeight: 72)
                    .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
                    .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderStrong, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(game.name), \(categoryTitle(game)), \(platformsTitle(game))")
                .accessibilityIdentifier("catalog-game-\(game.id)")
            }
        }
    }
}

private struct CatalogRecentTestsSection: View {
    @Environment(\.locale) private var locale

    let items: [HomeRecentTestsSection.RecentItem]
    let platformsTitle: (CatalogMeasurementJourney.Game) -> String
    let onSelect: (CatalogMeasurementJourney.Game) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            Text(LocalizedStringKey("home.recent_tested"))
                .font(NLTypography.headline)
                .foregroundStyle(NLColor.textPrimary)
                .padding(.horizontal, NLSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NLSpacing.sm) {
                    ForEach(items) { item in
                        Button { onSelect(item.game) } label: {
                            HStack(spacing: NLSpacing.sm) {
                                VerifiedGameArtwork(game: item.game, aspectRatio: 1)
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: NLRadius.controlSmall, style: .continuous))

                                VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                                    Text(item.game.name)
                                        .font(NLTypography.bodyEmphasis)
                                        .foregroundStyle(NLColor.textPrimary)
                                        .lineLimit(1)
                                    Text(measurementStatus(for: item.lastEntry))
                                        .font(NLTypography.caption)
                                        .foregroundStyle(NLColor.textSecondary)
                                        .lineLimit(1)
                                    Text(String(format: AppLocalization.string("catalog.recent.context", comment: ""), platformsTitle(item.game), routeLabel(for: item.lastEntry)))
                                        .font(NLTypography.caption)
                                        .foregroundStyle(NLColor.textTertiary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(NLSpacing.sm)
                            .frame(width: 230, alignment: .leading)
                            .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous).stroke(NLColor.borderStrong, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(accessibilityLabel(for: item))
                    }
                }
                .padding(.horizontal, NLSpacing.md)
            }
        }
    }

    private func relativeTime(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func accessibilityLabel(for item: HomeRecentTestsSection.RecentItem) -> String {
        let context = String(
            format: AppLocalization.string("catalog.recent.context", comment: ""),
            platformsTitle(item.game),
            routeLabel(for: item.lastEntry)
        )
        return "\(item.game.name), \(measurementStatus(for: item.lastEntry)), \(context)"
    }

    private func measurementStatus(for entry: MeasurementHistoryEntry) -> String {
        let relativeTime = relativeTime(for: entry.completedAt)
        guard !entry.isInconclusive, let result = entry.result else {
            return String(
                format: AppLocalization.string("catalog.recent.inconclusive_time", comment: ""),
                relativeTime
            )
        }
        return String(
            format: AppLocalization.string("catalog.recent.score_time", comment: ""),
            result.finalScore,
            relativeTime
        )
    }

    private func routeLabel(for entry: MeasurementHistoryEntry) -> String {
        let languageCode: String
        switch locale.identifier.lowercased() {
        case let identifier where identifier.hasPrefix("pt"): languageCode = "pt-BR"
        case let identifier where identifier.hasPrefix("es"): languageCode = "es"
        default: languageCode = "en"
        }
        guard let region = GlobalProbeRegistry.definition(for: entry.resolvedContext.regionID) else {
            return AppLocalization.string("catalog.recent.reference_route", comment: "")
        }
        return String(
            format: AppLocalization.string("catalog.recent.route", comment: ""),
            region.localizedLabel(for: languageCode)
        )
    }
}

struct HomeGenericGamingBanner: View {
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: NLSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: NLRadius.controlSmall, style: .continuous)
                        .fill(NLColor.accentPrimary.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "network")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(NLColor.accentPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey("catalog.generic_gaming_card.title"))
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textPrimary)
                    Text(LocalizedStringKey("catalog.generic_gaming_card.subtitle"))
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textSecondary)
                }

                Spacer(minLength: NLSpacing.xs)

                Image(systemName: "chevron.right")
                    .font(NLTypography.footnote.weight(.semibold))
                    .foregroundStyle(NLColor.textTertiary)
            }
            .padding(NLSpacing.cardPadding)
            .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                    .stroke(NLColor.borderStrong, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("catalog-generic-gaming-banner")
    }
}

private struct CatalogEmptyState: View {
    let isSearching: Bool
    var onSelectGenericGaming: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: NLSpacing.sm) {
            Image(systemName: isSearching ? "network" : "magnifyingglass")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(isSearching ? NLColor.accentPrimary : NLColor.textTertiary)
                .padding(.bottom, NLSpacing.xxs)

            Text(LocalizedStringKey(isSearching ? "catalog.empty.generic_gaming_title" : "catalog.empty.title"))
                .font(NLTypography.headline)
                .foregroundStyle(NLColor.textPrimary)

            Text(LocalizedStringKey(isSearching ? "catalog.empty.generic_gaming_message" : "catalog.empty.filter_message"))
                .font(NLTypography.callout)
                .foregroundStyle(NLColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NLSpacing.sm)

            if isSearching, let onSelectGenericGaming {
                Button(action: onSelectGenericGaming) {
                    HStack(spacing: NLSpacing.xs) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(LocalizedStringKey("catalog.empty.generic_gaming_cta"))
                            .font(NLTypography.bodyEmphasis)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, NLSpacing.lg)
                    .frame(minHeight: NLSizing.touchTarget)
                    .background(NLColor.accentPrimary, in: RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, NLSpacing.xs)
                .accessibilityIdentifier("catalog-empty-generic-gaming-cta")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NLSpacing.xl)
        .padding(.horizontal, NLSpacing.md)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous).stroke(NLColor.borderStrong, lineWidth: 1))
    }
}

// MARK: - Reusable badges

private struct HomeStatusBadge: View { let title: String; var body: some View { Text(title).font(NLTypography.captionStrong).textCase(.uppercase).padding(.horizontal, NLSpacing.sm).padding(.vertical, NLSpacing.xxs).background(Color.black.opacity(0.7), in: Capsule()).overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)).foregroundStyle(.white) } }
private struct HomeLatencyBadge: View { let latency: String; var body: some View { Text(latency).font(NLTypography.captionStrong).padding(.horizontal, NLSpacing.xs).padding(.vertical, NLSpacing.xxs).background(NLColor.scoreExcellent.opacity(0.2), in: Capsule()).foregroundStyle(NLColor.scoreExcellent) } }
private struct HomeScoreBadge: View { let label: String; let score: Int; var body: some View { HStack(spacing: NLSpacing.xxs) { Text(label).font(NLTypography.captionStrong).textCase(.uppercase).foregroundStyle(NLColor.textSecondary); Text("\(score)").font(NLTypography.bodyEmphasis).foregroundStyle(NLColor.scoreExcellent) }.padding(.horizontal, NLSpacing.sm).padding(.vertical, NLSpacing.xxs).background(Color.black.opacity(0.75), in: RoundedRectangle(cornerRadius: NLRadius.controlMedium)).overlay(RoundedRectangle(cornerRadius: NLRadius.controlMedium).stroke(Color.white.opacity(0.15), lineWidth: 1)) } }
private struct HomeCompactScoreBadge: View { let score: Int; var body: some View { Text("\(score)").font(NLTypography.captionStrong).foregroundStyle(score >= 90 ? NLColor.scoreExcellent : NLColor.scoreUnstable).padding(.horizontal, NLSpacing.xs).padding(.vertical, NLSpacing.xxs).background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: NLRadius.controlSmall)).overlay(RoundedRectangle(cornerRadius: NLRadius.controlSmall).stroke(Color.white.opacity(0.15), lineWidth: 1)) } }

enum CatalogCategory: CaseIterable {
    case all, battle, competitive, casual
    var localizationKey: String {
        switch self {
        case .all: "catalog.category.all"
        case .battle: "catalog.category.battle"
        case .competitive: "catalog.category.competitive"
        case .casual: "catalog.category.casual"
        }
    }
}
