import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

// MARK: - Home header and status

struct HomeRefreshButton: View {
    let refreshAccessibilityLabel: String
    let isMeasuring: Bool
    let refresh: () -> Void

    var body: some View {
        Button(action: refresh) {
            Image(systemName: "arrow.clockwise")
                .font(NLTypography.navigationIcon)
                .foregroundStyle(isMeasuring ? NLColor.textTertiary : NLColor.accentPrimary)
                .rotationEffect(.degrees(isMeasuring ? 360 : 0))
                .animation(isMeasuring ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isMeasuring)
                .frame(width: NLSizing.touchTarget, height: NLSizing.touchTarget)
                .background(NLColor.backgroundRaised, in: Circle())
                .overlay(Circle().stroke(NLColor.borderStrong, lineWidth: 1))
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
                                    NLColor.coralSolar.opacity(0.16 - Double(index) * 0.035),
                                    NLColor.coralSolarRed.opacity(0.08 - Double(index) * 0.018),
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
                    GameArtwork(image: nil, sourceRecordID: nil, title: game.name, aspectRatio: 1)
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
        let result = entry.result
        if result.metrics.validResponseCount == 0 {
            inconclusiveStateContent
        } else {
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
        return String(format: NSLocalizedString("home.hero.last_check_format %@", comment: ""), relative)
    }

    private var accessibilitySummary: String {
        let gameName = game?.name ?? NSLocalizedString("home.hero.no_game_selected", comment: "")
        if let lastEntry {
            if lastEntry.result.metrics.validResponseCount == 0 {
                return "\(gameName), \(regionName), \(NSLocalizedString("home.hero.inconclusive_title", comment: ""))"
            } else {
                return "\(gameName), \(regionName), Score \(lastEntry.result.finalScore), \(relativeTimeString(for: lastEntry.completedAt))"
            }
        } else {
            return "\(gameName), \(regionName), \(NSLocalizedString("home.hero.ready_title", comment: ""))"
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
                GameArtwork(image: nil, sourceRecordID: nil, title: game.name, aspectRatio: 1)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: NLRadius.controlSmall, style: .continuous))

                VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                    Text(game.name)
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: NLSpacing.xs) {
                        let score = lastEntry.result.finalScore
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
        .accessibilityLabel("\(game.name), Score \(lastEntry.result.finalScore)")
        .accessibilityIdentifier("recent-game-\(game.id)")
    }

    private func relativeShortTime(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
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
                GameArtwork(image: nil, sourceRecordID: nil, title: game.name, aspectRatio: 4 / 3)
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

// MARK: - Catalog (Biblioteca Estilo Netflix)

struct HomeCatalogView: View {
    let title: String
    @Binding var query: String
    let allGames: [CatalogMeasurementJourney.Game]
    let popularGames: [CatalogMeasurementJourney.Game]
    let searchPlaceholder: String
    let clearSearchAccessibilityLabel: String
    let categoryTitle: (CatalogMeasurementJourney.Game) -> String
    let select: (CatalogMeasurementJourney.Game) -> Void

    private var searchResults: [CatalogMeasurementJourney.Game] {
        guard !query.isEmpty else { return allGames }
        return allGames.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: NLSpacing.lg) {
                // Barra de busca no topo
                HomeCatalogSearch(
                    query: $query,
                    placeholder: searchPlaceholder,
                    clearAccessibilityLabel: clearSearchAccessibilityLabel
                )
                .padding(.horizontal, NLSpacing.md)
                .padding(.top, NLSpacing.xs)

                if query.isEmpty {
                    // 1. Destaque Principal Cinematográfico (Hero Billboard estilo Netflix)
                    if let heroGame = popularGames.first ?? allGames.first {
                        NetflixHeroBillboard(
                            game: heroGame,
                            category: categoryTitle(heroGame),
                            onSelect: { select(heroGame) }
                        )
                    }

                    // 2. Fileiras de Prateleiras Temáticas (Shelves estilo Netflix)
                    ForEach(NetflixCatalogRow.allCases) { row in
                        let rowGames = row.games(from: allGames, rankedPopular: popularGames)
                        NetflixShelfRow(
                            title: NSLocalizedString(row.titleKey, comment: ""),
                            games: rowGames,
                            onSelect: select
                        )
                    }
                } else {
                    // Modo Busca: Grade de pôsteres com os resultados
                    NetflixSearchGrid(
                        games: searchResults,
                        onSelect: select
                    )
                }

                Spacer(minLength: NLSpacing.xl)
            }
        }
        .scrollContentBackground(.hidden)
        .safeAreaPadding(.bottom, NLSpacing.md)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
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

private struct HomeCatalogList: View {
    let games: [CatalogMeasurementJourney.Game]
    let categoryTitle: (CatalogMeasurementJourney.Game) -> String
    let scoreState: (CatalogMeasurementJourney.Game) -> GameRowView.ScoreState
    let score: (CatalogMeasurementJourney.Game) -> Int?
    let latency: (CatalogMeasurementJourney.Game) -> String?
    let inconclusiveAccessibilityLabel: String
    let select: (CatalogMeasurementJourney.Game) -> Void
    var body: some View {
        VStack(spacing: 0) {
            ForEach(games, id: \.id) { game in
                Button { select(game) } label: {
                    HStack(spacing: NLSpacing.sm) {
                        GameArtwork(image: nil, sourceRecordID: nil, title: game.name, aspectRatio: 1).frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: NLRadius.controlMedium))
                        VStack(alignment: .leading, spacing: NLSpacing.xs) {
                            Text(game.name).font(NLTypography.bodyEmphasis).foregroundStyle(NLColor.textPrimary).lineLimit(2).fixedSize(horizontal: false, vertical: true).layoutPriority(1)
                            Text(categoryTitle(game)).font(NLTypography.caption).foregroundStyle(NLColor.textSecondary)
                        }
                        Spacer()
                        HStack(spacing: NLSpacing.sm) {
                            HomeCatalogScore(state: scoreState(game), score: score(game), latency: latency(game), inconclusiveAccessibilityLabel: inconclusiveAccessibilityLabel)
                            Image(systemName: "chevron.right").font(NLTypography.footnote.weight(.semibold)).foregroundStyle(NLColor.textTertiary)
                        }
                    }
                    .padding(.horizontal, NLSpacing.md).padding(.vertical, NLSpacing.sm).frame(minHeight: 64)
                }
                .buttonStyle(.plain).accessibilityIdentifier("catalog-game-\(game.id)")
                if game.id != games.last?.id { Divider().overlay(NLColor.borderSubtle).padding(.leading, 76) }
            }
        }
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderStrong, lineWidth: 1))
    }
}

private struct HomeCatalogScore: View {
    let state: GameRowView.ScoreState
    let score: Int?
    let latency: String?
    let inconclusiveAccessibilityLabel: String
    var body: some View {
        switch state {
        case .measuring:
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: NLColor.textTertiary)).frame(width: NLSizing.touchTarget, height: NLSizing.touchTarget)
        case .evaluated:
            if let score { VStack(alignment: .trailing, spacing: NLSpacing.xxs) { Text("\(score)").font(NLTypography.bodyEmphasis).foregroundStyle(score >= 90 ? NLColor.scoreExcellent : NLColor.scoreUnstable); if let latency { Text(latency).font(NLTypography.caption).foregroundStyle(NLColor.textSecondary) } } }
        case .inconclusive, .failed:
            Text("—").font(NLTypography.bodyEmphasis).foregroundStyle(NLColor.textTertiary).frame(width: NLSizing.touchTarget, height: NLSizing.touchTarget).accessibilityLabel(inconclusiveAccessibilityLabel)
        }
    }
}

// MARK: - Reusable badges

private struct HomeStatusBadge: View { let title: String; var body: some View { Text(title).font(NLTypography.captionStrong).textCase(.uppercase).padding(.horizontal, NLSpacing.sm).padding(.vertical, NLSpacing.xxs).background(Color.black.opacity(0.7), in: Capsule()).overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)).foregroundStyle(.white) } }
private struct HomeLatencyBadge: View { let latency: String; var body: some View { Text(latency).font(NLTypography.captionStrong).padding(.horizontal, NLSpacing.xs).padding(.vertical, NLSpacing.xxs).background(NLColor.scoreExcellent.opacity(0.2), in: Capsule()).foregroundStyle(NLColor.scoreExcellent) } }
private struct HomeScoreBadge: View { let label: String; let score: Int; var body: some View { HStack(spacing: NLSpacing.xxs) { Text(label).font(NLTypography.captionStrong).textCase(.uppercase).foregroundStyle(NLColor.textSecondary); Text("\(score)").font(NLTypography.bodyEmphasis).foregroundStyle(NLColor.scoreExcellent) }.padding(.horizontal, NLSpacing.sm).padding(.vertical, NLSpacing.xxs).background(Color.black.opacity(0.75), in: RoundedRectangle(cornerRadius: NLRadius.controlMedium)).overlay(RoundedRectangle(cornerRadius: NLRadius.controlMedium).stroke(Color.white.opacity(0.15), lineWidth: 1)) } }
private struct HomeCompactScoreBadge: View { let score: Int; var body: some View { Text("\(score)").font(NLTypography.captionStrong).foregroundStyle(score >= 90 ? NLColor.scoreExcellent : NLColor.scoreUnstable).padding(.horizontal, NLSpacing.xs).padding(.vertical, NLSpacing.xxs).background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: NLRadius.controlSmall)).overlay(RoundedRectangle(cornerRadius: NLRadius.controlSmall).stroke(Color.white.opacity(0.15), lineWidth: 1)) } }

enum CatalogCategory: CaseIterable {
    case all, battle, mobile, casual
    var localizationKey: String {
        switch self {
        case .all: "catalog.category.all"
        case .battle: "catalog.category.battle"
        case .mobile: "catalog.category.mobile"
        case .casual: "catalog.category.casual"
        }
    }
}
