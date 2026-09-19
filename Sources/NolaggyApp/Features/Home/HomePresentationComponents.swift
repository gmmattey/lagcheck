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

// MARK: - CTA Principal da Home

struct HomeCTASection: View {
    let targetGame: CatalogMeasurementJourney.Game?
    let onStartCheck: () -> Void
    let onChooseAnotherGame: () -> Void

    var body: some View {
        VStack(spacing: NLSpacing.sm) {
            if let targetGame {
                HStack(spacing: NLSpacing.xs) {
                    Image(systemName: "target")
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.accentPrimary)
                    Text(String(format: NSLocalizedString("home.start_for_game %@", comment: ""), targetGame.name))
                        .font(NLTypography.captionStrong)
                        .foregroundStyle(NLColor.textSecondary)
                }
            }

            PrimaryButton(
                title: "home.cta.start_lagcheck",
                action: onStartCheck
            )
            .accessibilityIdentifier("home-cta-start-lagcheck")

            if targetGame != nil {
                Button(action: onChooseAnotherGame) {
                    Text(LocalizedStringKey("home.choose_another_game"))
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Carrossel de Últimos Jogos Testados (Sem dados técnicos)

struct HomeRecentCarouselSection: View {
    let title: String
    let games: [CatalogMeasurementJourney.Game]
    let categoryTitle: (CatalogMeasurementJourney.Game) -> String
    let select: (CatalogMeasurementJourney.Game) -> Void
    let onExploreGames: () -> Void

    @State private var currentIndex: Int = 0
    private let timer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            Text(title)
                .font(NLTypography.headline)
                .foregroundStyle(NLColor.textPrimary)
                .padding(.horizontal, NLSpacing.md)

            if games.isEmpty {
                HomeEmptyRecentCard(onExploreGames: onExploreGames)
                    .padding(.horizontal, NLSpacing.md)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                        HomeRecentCard(
                            game: game,
                            category: categoryTitle(game),
                            action: { select(game) }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: games.count > 1 ? .automatic : .never))
                .frame(height: 200)
                .onReceive(timer) { _ in
                    guard games.count > 1 else { return }
                    withAnimation(.easeInOut(duration: 0.6)) {
                        currentIndex = (currentIndex + 1) % games.count
                    }
                }
            }
        }
    }
}

private struct HomeRecentCard: View {
    let game: CatalogMeasurementJourney.Game
    let category: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                GameArtwork(image: nil, sourceRecordID: nil, title: game.name, aspectRatio: 16 / 9)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black.opacity(0.35), location: 0.4),
                        .init(color: .black.opacity(0.85), location: 0.75),
                        .init(color: .black.opacity(0.96), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: NLSpacing.xs) {
                    HStack {
                        Text(category)
                            .font(NLTypography.captionStrong)
                            .textCase(.uppercase)
                            .foregroundStyle(NLColor.accentPrimary)

                        Spacer()

                        Text(LocalizedStringKey("home.last_tested"))
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textSecondary)
                            .padding(.horizontal, NLSpacing.xs)
                            .padding(.vertical, 2)
                            .background(NLColor.backgroundRaised.opacity(0.85), in: Capsule())
                    }

                    Text(game.name)
                        .font(NLTypography.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .padding(NLSpacing.md)
            }
            .clipShape(RoundedRectangle(cornerRadius: NLRadius.hero))
            .overlay(RoundedRectangle(cornerRadius: NLRadius.hero).stroke(NLColor.borderStrong, lineWidth: 1))
            .padding(.horizontal, NLSpacing.md)
        }
        .buttonStyle(.plain)
    }
}

private struct HomeEmptyRecentCard: View {
    let onExploreGames: () -> Void

    var body: some View {
        VStack(spacing: NLSpacing.sm) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 36))
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NLSpacing.lg)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderStrong, lineWidth: 1))
    }
}

// MARK: - Prateleira de Jogos Populares (Automática por dados reais)

struct HomePopularShelfSection: View {
    let title: String
    let games: [CatalogMeasurementJourney.Game]
    let categoryTitle: (CatalogMeasurementJourney.Game) -> String
    let select: (CatalogMeasurementJourney.Game) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            Text(title)
                .font(NLTypography.headline)
                .foregroundStyle(NLColor.textPrimary)
                .padding(.horizontal, NLSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NLSpacing.sm) {
                    ForEach(games, id: \.id) { game in
                        HomePopularShelfCard(
                            game: game,
                            category: categoryTitle(game),
                            action: { select(game) }
                        )
                    }
                }
                .padding(.horizontal, NLSpacing.md)
            }
        }
    }
}

private struct HomePopularShelfCard: View {
    let game: CatalogMeasurementJourney.Game
    let category: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                GameArtwork(image: nil, sourceRecordID: nil, title: game.name, aspectRatio: 150 / 100)
                    .frame(width: 150, height: 100)
                    .clipped()

                VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                    Text(category)
                        .font(NLTypography.captionStrong)
                        .textCase(.uppercase)
                        .foregroundStyle(NLColor.textSecondary)
                        .lineLimit(1)

                    Text(game.name)
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textPrimary)
                        .lineLimit(1)
                }
                .padding(NLSpacing.xs)
                .frame(width: 150, height: 56, alignment: .leading)
                .background(NLColor.backgroundRaised)
            }
            .frame(width: 150)
            .clipShape(RoundedRectangle(cornerRadius: NLRadius.card))
            .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderStrong, lineWidth: 1))
        }
        .buttonStyle(.plain)
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
