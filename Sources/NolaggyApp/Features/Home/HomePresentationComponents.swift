import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

// MARK: - Home header and status

struct HomeHeader: View {
    let title: String
    let refreshAccessibilityLabel: String
    let isMeasuring: Bool
    let refresh: () -> Void

    var body: some View {
        HStack {
            Text(title).font(NLTypography.displayTitle).foregroundStyle(NLColor.textPrimary)
            Spacer()
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
}

/// Card "Início": resume o veredito da medição como uma rota animada
/// (aparelho → Wi-Fi → rede → jogo), sem expor dado técnico de rota ou do
/// servidor testado — isso vive só na tela de Detalhes de cada jogo.
struct HomeNetworkStatusCard: View {
    let title: String
    let color: Color
    let latency: String
    let isMeasuring: Bool

    private static let routeSymbols = ["iphone", "wifi", "network", "gamecontroller.fill"]

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.md) {
            HStack(spacing: NLSpacing.xs) {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(title).font(NLTypography.bodyEmphasis).foregroundStyle(NLColor.textPrimary)
                Spacer()
                Text(latency).font(NLTypography.bodyEmphasis.monospacedDigit()).foregroundStyle(isMeasuring ? NLColor.textSecondary : color)
            }
            HStack(spacing: 0) {
                ForEach(Array(Self.routeSymbols.enumerated()), id: \.offset) { index, symbol in
                    routeNode(symbol: symbol)
                    if index < Self.routeSymbols.count - 1 { routeSegment }
                }
            }
        }
        .padding(NLSpacing.md)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderStrong, lineWidth: 1))
        .animation(.easeInOut(duration: 0.4), value: isMeasuring)
    }

    private func routeNode(symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(isMeasuring ? NLColor.textSecondary : color)
            .frame(width: 26, height: 26)
            .background(NLColor.backgroundBase, in: Circle())
            .overlay(Circle().stroke(isMeasuring ? NLColor.borderStrong : color, lineWidth: 1))
    }

    private var routeSegment: some View {
        Rectangle()
            .fill(isMeasuring ? NLColor.borderStrong : color)
            .frame(height: 3)
            .clipShape(Capsule())
    }
}

// MARK: - Editorial game sections

struct HomeHeroSection: View {
    let title: String
    let games: [CatalogMeasurementJourney.Game]
    let categoryTitle: (CatalogMeasurementJourney.Game) -> String
    let statusTitle: (CatalogMeasurementJourney.Game) -> String
    let latency: (CatalogMeasurementJourney.Game) -> String?
    let score: (CatalogMeasurementJourney.Game) -> Int?
    let scoreLabel: String
    let detail: String
    let select: (CatalogMeasurementJourney.Game) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            Text(title).font(NLTypography.headline).foregroundStyle(NLColor.textPrimary).padding(.horizontal, NLSpacing.md)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NLSpacing.sm) {
                    ForEach(games, id: \.id) { game in
                        HomeHeroCard(game: game, category: categoryTitle(game), status: statusTitle(game), latency: latency(game), score: score(game), scoreLabel: scoreLabel, detail: detail) {
                            select(game)
                        }
                    }
                }
                .padding(.horizontal, NLSpacing.md)
            }
        }
    }
}

private struct HomeHeroCard: View {
    let game: CatalogMeasurementJourney.Game
    let category: String
    let status: String
    let latency: String?
    let score: Int?
    let scoreLabel: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                GameArtwork(image: nil, sourceRecordID: nil, title: game.name, aspectRatio: 340 / 240).frame(width: 340, height: 240).clipped()
                LinearGradient(colors: [.black, .black.opacity(0.45), .clear], startPoint: .bottom, endPoint: .top)
                VStack {
                    HStack(alignment: .top) {
                        HStack(spacing: NLSpacing.xs) {
                            HomeStatusBadge(title: status)
                            if let latency { HomeLatencyBadge(latency: latency) }
                        }
                        Spacer()
                        if let score { HomeScoreBadge(label: scoreLabel, score: score) }
                    }
                    .padding(NLSpacing.sm)
                    Spacer()
                    VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                        Text(category).font(NLTypography.captionStrong).foregroundStyle(NLColor.scoreExcellent)
                        Text(game.name).font(NLTypography.headline).foregroundStyle(.white).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                        Text(detail).font(NLTypography.footnote).foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(NLSpacing.md)
                }
            }
            .frame(width: 340, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: NLRadius.hero))
            .overlay(RoundedRectangle(cornerRadius: NLRadius.hero).stroke(NLColor.borderStrong, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct HomeShelfSection: View {
    let title: String
    let games: [CatalogMeasurementJourney.Game]
    let categoryTitle: (CatalogMeasurementJourney.Game) -> String
    let detail: (CatalogMeasurementJourney.Game) -> String
    let detailColor: (CatalogMeasurementJourney.Game) -> Color
    let score: (CatalogMeasurementJourney.Game) -> Int?
    let select: (CatalogMeasurementJourney.Game) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            Text(title).font(NLTypography.headline).foregroundStyle(NLColor.textPrimary).padding(.horizontal, NLSpacing.md)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NLSpacing.sm) {
                    ForEach(games, id: \.id) { game in
                        HomeShelfCard(game: game, category: categoryTitle(game), detail: detail(game), detailColor: detailColor(game), score: score(game)) { select(game) }
                    }
                }
                .padding(.horizontal, NLSpacing.md)
            }
        }
    }
}

private struct HomeShelfCard: View {
    let game: CatalogMeasurementJourney.Game
    let category: String
    let detail: String
    let detailColor: Color
    let score: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                GameArtwork(image: nil, sourceRecordID: nil, title: game.name, aspectRatio: 150 / 190).frame(width: 150, height: 190).clipped()
                LinearGradient(colors: [.black, .black.opacity(0.5), .clear], startPoint: .bottom, endPoint: .top)
                VStack {
                    HStack { Spacer(); if let score { HomeCompactScoreBadge(score: score) } }.padding(NLSpacing.xs)
                    Spacer()
                    VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                        Text(category).font(NLTypography.captionStrong).textCase(.uppercase).foregroundStyle(NLColor.textSecondary)
                        Text(game.name).font(NLTypography.bodyEmphasis).foregroundStyle(.white).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                        Text(detail).font(NLTypography.caption).foregroundStyle(detailColor)
                    }
                    .padding(NLSpacing.sm)
                }
            }
            .frame(width: 150, height: 190)
            .clipShape(RoundedRectangle(cornerRadius: NLRadius.card))
            .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderStrong, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct HomeGameListSection: View {
    let title: String
    let games: [CatalogMeasurementJourney.Game]
    let categoryTitle: (CatalogMeasurementJourney.Game) -> String
    let platform: String
    let scoreState: (CatalogMeasurementJourney.Game) -> GameRowView.ScoreState
    let select: (CatalogMeasurementJourney.Game) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            Text(title).font(NLTypography.headline).foregroundStyle(NLColor.textPrimary)
            VStack(spacing: 0) {
                ForEach(games, id: \.id) { game in
                    GameRowView(title: game.name, category: categoryTitle(game), platform: platform, scoreState: scoreState(game)) { select(game) }
                        .accessibilityIdentifier("catalog-game-\(game.id)")
                        .padding(.horizontal, NLSpacing.md).padding(.vertical, NLSpacing.xs)
                    if game.id != games.last?.id { Divider().overlay(NLColor.borderSubtle).padding(.leading, 72) }
                }
            }
            .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
            .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderStrong, lineWidth: 1))
        }
    }
}

// MARK: - Catalog

struct HomeCatalogView: View {
    let title: String
    @Binding var query: String
    @Binding var selectedCategory: CatalogCategory
    let categories: [CatalogCategory]
    let games: [CatalogMeasurementJourney.Game]
    let searchPlaceholder: String
    let clearSearchAccessibilityLabel: String
    let categoryTitle: (CatalogCategory) -> String
    let gameCategoryTitle: (CatalogMeasurementJourney.Game) -> String
    let scoreState: (CatalogMeasurementJourney.Game) -> GameRowView.ScoreState
    let score: (CatalogMeasurementJourney.Game) -> Int?
    let latency: (CatalogMeasurementJourney.Game) -> String?
    let inconclusiveAccessibilityLabel: String
    let select: (CatalogMeasurementJourney.Game) -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: NLSpacing.md) {
                Text(title).font(NLTypography.displayTitle).foregroundStyle(NLColor.textPrimary).padding(.horizontal, NLSpacing.md).padding(.top, NLSpacing.xs)
                HomeCatalogSearch(query: $query, placeholder: searchPlaceholder, clearAccessibilityLabel: clearSearchAccessibilityLabel).padding(.horizontal, NLSpacing.md)
                HomeCatalogFilters(selected: $selectedCategory, categories: categories, title: categoryTitle)
                HomeCatalogList(games: games, categoryTitle: gameCategoryTitle, scoreState: scoreState, score: score, latency: latency, inconclusiveAccessibilityLabel: inconclusiveAccessibilityLabel, select: select)
                    .padding(.horizontal, NLSpacing.md).padding(.bottom, NLSpacing.xl)
            }
        }
        .scrollContentBackground(.hidden)
        .safeAreaPadding(.bottom, NLSpacing.md)
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
                        VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                            Text(game.name).font(NLTypography.bodyEmphasis).foregroundStyle(NLColor.textPrimary).lineLimit(2).fixedSize(horizontal: false, vertical: true).layoutPriority(1)
                            Text(categoryTitle(game)).font(NLTypography.caption).foregroundStyle(NLColor.textSecondary)
                        }
                        Spacer()
                        HStack(spacing: NLSpacing.xs) {
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
