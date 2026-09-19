import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Seções temáticas para a biblioteca de jogos estilo Netflix (Decisão 24 / Refinamento de UX).
public enum NetflixCatalogRow: CaseIterable, Identifiable, Sendable {
    case trending
    case battleRoyale
    case tacticalFPS
    case mobaStrategy
    case sportsSurvival

    public var id: String { String(describing: self) }

    public var titleKey: String {
        switch self {
        case .trending: return "netflix.shelf.trending"
        case .battleRoyale: return "netflix.shelf.battle_royale"
        case .tacticalFPS: return "netflix.shelf.fps"
        case .mobaStrategy: return "netflix.shelf.moba"
        case .sportsSurvival: return "netflix.shelf.sports_survival"
        }
    }

    public func games(from allGames: [CatalogMeasurementJourney.Game], rankedPopular: [CatalogMeasurementJourney.Game]) -> [CatalogMeasurementJourney.Game] {
        switch self {
        case .trending:
            return Array(rankedPopular.prefix(10))
        case .battleRoyale:
            let ids: Set<String> = ["fortnite", "warzone", "apex-legends", "free-fire", "pubg-mobile", "blood-strike"]
            return allGames.filter { ids.contains($0.id) }
        case .tacticalFPS:
            let ids: Set<String> = ["cs2", "valorant", "rainbow-six", "call-of-duty-mobile"]
            return allGames.filter { ids.contains($0.id) }
        case .mobaStrategy:
            let ids: Set<String> = ["league-of-legends", "wild-rift", "dota2", "brawl-stars"]
            return allGames.filter { ids.contains($0.id) }
        case .sportsSurvival:
            let ids: Set<String> = ["eafc", "rocket-league", "minecraft", "roblox", "palworld", "rust"]
            return allGames.filter { ids.contains($0.id) }
        }
    }
}

// MARK: - Hero Billboard Cinematográfico estilo Netflix

public struct NetflixHeroBillboard: View {
    public let game: CatalogMeasurementJourney.Game
    public let category: String
    public let onSelect: () -> Void

    public init(game: CatalogMeasurementJourney.Game, category: String, onSelect: @escaping () -> Void) {
        self.game = game
        self.category = category
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .bottom) {
                // Arte do jogo em escala exata preenchendo o card
                VerifiedGameArtwork(game: game)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Gradientes cinematográficos de fusão com fundo escuro
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black.opacity(0.35), location: 0.35),
                        .init(color: .black.opacity(0.85), location: 0.72),
                        .init(color: .black.opacity(0.98), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Informações e Ações
                VStack(spacing: NLSpacing.xs) {
                    HStack(spacing: NLSpacing.xs) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(NLColor.accentPrimary)

                        Text(LocalizedStringKey("netflix.hero.badge"))
                            .font(NLTypography.captionStrong)
                            .tracking(1.2)
                            .foregroundStyle(NLColor.accentPrimary)

                        Text("•")
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textTertiary)

                        Text(category)
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textSecondary)
                    }

                    Text(game.name)
                        .font(NLTypography.displayTitle)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)

                    HStack(spacing: NLSpacing.xs) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(LocalizedStringKey("netflix.hero.view_details"))
                            .font(NLTypography.bodyEmphasis)
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, NLSpacing.lg)
                    .padding(.vertical, 8)
                    .background(Color.white, in: Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                    .padding(.top, NLSpacing.xxs)
                }
                .padding(.horizontal, NLSpacing.md)
                .padding(.bottom, NLSpacing.md)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: NLRadius.hero))
            .overlay(RoundedRectangle(cornerRadius: NLRadius.hero).stroke(NLColor.borderStrong, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, NLSpacing.md)
    }
}

// MARK: - Pôster Vertical estilo Netflix (2:3)

public struct NetflixPosterCard: View {
    public let game: CatalogMeasurementJourney.Game
    public let onSelect: () -> Void

    public init(game: CatalogMeasurementJourney.Game, onSelect: @escaping () -> Void) {
        self.game = game
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .bottomLeading) {
                VerifiedGameArtwork(game: game)
                    .frame(width: 115, height: 165)

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.4),
                        .init(color: .black.opacity(0.7), location: 0.75),
                        .init(color: .black.opacity(0.95), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(game.name)
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(NLSpacing.xs)
                    .shadow(color: .black, radius: 2, x: 0, y: 1)
            }
            .frame(width: 115, height: 165)
            .clipShape(RoundedRectangle(cornerRadius: NLRadius.controlMedium))
            .overlay(RoundedRectangle(cornerRadius: NLRadius.controlMedium).stroke(NLColor.borderStrong, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Fileira de Prateleira Horizontal estilo Netflix

public struct NetflixShelfRow: View {
    public let title: String
    public let games: [CatalogMeasurementJourney.Game]
    public let onSelect: (CatalogMeasurementJourney.Game) -> Void

    public init(
        title: String,
        games: [CatalogMeasurementJourney.Game],
        onSelect: @escaping (CatalogMeasurementJourney.Game) -> Void
    ) {
        self.title = title
        self.games = games
        self.onSelect = onSelect
    }

    public var body: some View {
        if !games.isEmpty {
            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                Text(title)
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)
                    .padding(.horizontal, NLSpacing.md)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: NLSpacing.sm) {
                        ForEach(games, id: \.id) { game in
                            NetflixPosterCard(game: game) {
                                onSelect(game)
                            }
                        }
                    }
                    .padding(.horizontal, NLSpacing.md)
                }
            }
        }
    }
}

// MARK: - Grade de Busca estilo Netflix

public struct NetflixSearchGrid: View {
    public let games: [CatalogMeasurementJourney.Game]
    public let onSelect: (CatalogMeasurementJourney.Game) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 105, maximum: 130), spacing: NLSpacing.sm)
    ]

    public init(games: [CatalogMeasurementJourney.Game], onSelect: @escaping (CatalogMeasurementJourney.Game) -> Void) {
        self.games = games
        self.onSelect = onSelect
    }

    public var body: some View {
        LazyVGrid(columns: columns, spacing: NLSpacing.md) {
            ForEach(games, id: \.id) { game in
                NetflixPosterCard(game: game) {
                    onSelect(game)
                }
            }
        }
        .padding(.horizontal, NLSpacing.md)
    }
}
