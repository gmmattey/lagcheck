import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Seção da Home com a lista de Jogos Favoritos do usuário (até 4 jogos).
/// Não exibe o jogo genérico e permite inclusão/gerenciamento a partir do catálogo.
public struct HomeFavoriteGamesRail: View {
    let favoriteGames: [CatalogMeasurementJourney.Game]
    let selectedGameID: String?
    let onSelectGame: (CatalogMeasurementJourney.Game) -> Void
    let onManageFavorites: () -> Void

    public init(
        favoriteGames: [CatalogMeasurementJourney.Game],
        selectedGameID: String?,
        onSelectGame: @escaping (CatalogMeasurementJourney.Game) -> Void,
        onManageFavorites: @escaping () -> Void
    ) {
        self.favoriteGames = favoriteGames
        self.selectedGameID = selectedGameID
        self.onSelectGame = onSelectGame
        self.onManageFavorites = onManageFavorites
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            // Cabeçalho da Seção com Ação "Ver todos ›"
            HStack {
                Text(LocalizedStringKey("home.favorite_games.title"))
                    .font(NLTypography.sectionHeader)
                    .foregroundStyle(NLColor.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                Button(action: onManageFavorites) {
                    HStack(spacing: 2) {
                        Text(LocalizedStringKey("home.quick_rail.see_all"))
                            .font(.system(size: 13, weight: .semibold))
                        Text(verbatim: "›")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(NLColor.gamerPurpleLight)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home-favorite-games-manage")
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)

            // Trilho horizontal de pôsteres 3:4
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NLSpacing.sm) {
                    ForEach(favoriteGames) { game in
                        HomePosterGameCard(
                            game: game,
                            isSelected: game.id == selectedGameID,
                            onTap: { onSelectGame(game) }
                        )
                        .accessibilityIdentifier("home-favorite-game-\(game.id)")
                    }

                    if favoriteGames.count < FavoriteGamesStore.maxFavorites {
                        Button(action: onManageFavorites) {
                            VStack(spacing: NLSpacing.xs) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(NLColor.gamerPurpleLight)

                                Text(LocalizedStringKey("home.favorite_games.add"))
                                    .font(NLTypography.captionStrong)
                                    .foregroundStyle(NLColor.textSecondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 114, height: 152)
                            .background(
                                NLColor.surface,
                                in: RoundedRectangle(cornerRadius: NLRadius.md, style: .continuous)
                            )
                            .shadow(color: NLShadow.cardColor, radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home-favorite-game-add-slot")
                    }
                }
                .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                .padding(.vertical, 4)
            }
        }
    }
}

/// Trilho de jogos populares na Home (pôsteres 3:4, toque direto para testar).
public struct HomePopularGamesRail: View {
    let popularGames: [CatalogMeasurementJourney.Game]
    let selectedGameID: String?
    let onSelectGame: (CatalogMeasurementJourney.Game) -> Void
    let onSeeAll: () -> Void

    public init(
        popularGames: [CatalogMeasurementJourney.Game],
        selectedGameID: String?,
        onSelectGame: @escaping (CatalogMeasurementJourney.Game) -> Void,
        onSeeAll: @escaping () -> Void
    ) {
        self.popularGames = popularGames
        self.selectedGameID = selectedGameID
        self.onSelectGame = onSelectGame
        self.onSeeAll = onSeeAll
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            HStack {
                Text(LocalizedStringKey("home.popular"))
                    .font(NLTypography.sectionHeader)
                    .foregroundStyle(NLColor.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                Button(action: onSeeAll) {
                    HStack(spacing: 2) {
                        Text(LocalizedStringKey("home.quick_rail.see_all"))
                            .font(.system(size: 13, weight: .semibold))
                        Text(verbatim: "›")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(NLColor.gamerPurpleLight)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home-popular-games-see-all")
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NLSpacing.sm) {
                    ForEach(popularGames) { game in
                        HomePosterGameCard(
                            game: game,
                            isSelected: game.id == selectedGameID,
                            onTap: { onSelectGame(game) }
                        )
                        .accessibilityIdentifier("home-popular-game-\(game.id)")
                    }
                }
                .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                .padding(.vertical, 4)
            }
        }
    }
}

private struct HomePosterGameCard: View {
    let game: CatalogMeasurementJourney.Game
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                VerifiedGameArtwork(game: game, aspectRatio: 0.75)
                    .frame(width: 114, height: 152)

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .clear, location: 0.4),
                        .init(color: NLColor.backgroundBase.opacity(0.85), location: 0.75),
                        .init(color: NLColor.backgroundBase, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(game.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(NLColor.textPrimary)
                    .lineLimit(1)
                    .padding(NLSpacing.sm)
            }
            .frame(width: 114, height: 152)
            .clipShape(RoundedRectangle(cornerRadius: NLRadius.md, style: .continuous))
            .shadow(
                color: isSelected ? NLColor.accentPrimary.opacity(0.35) : NLShadow.cardColor,
                radius: isSelected ? 10 : 6,
                x: 0,
                y: isSelected ? 4 : 3
            )
        }
        .buttonStyle(.plain)
    }
}

/// Modal para o usuário selecionar seus até 4 jogos favoritos a partir do catálogo completo.
public struct FavoriteGamesSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let allGames: [CatalogMeasurementJourney.Game]
    @ObservedObject var store = FavoriteGamesStore.shared
    @State private var searchQuery: String = ""

    public init(allGames: [CatalogMeasurementJourney.Game]) {
        self.allGames = allGames.filter { $0.id != GameContext.genericGamingID }
    }

    private var filteredGames: [CatalogMeasurementJourney.Game] {
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return allGames
        }
        return allGames.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: NLSpacing.sm) {
                // Header com instrução
                Text(String(format: AppLocalization.string("home.favorite_games.selection_hint", comment: ""), store.favoriteGameIDs.count, FavoriteGamesStore.maxFavorites))
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.textSecondary)
                    .padding(.horizontal, NLSpacing.md)
                    .padding(.top, NLSpacing.xs)

                // Barra de Busca
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(NLColor.textTertiary)
                    TextField(LocalizedStringKey("catalog.search.placeholder"), text: $searchQuery)
                        .foregroundStyle(NLColor.textPrimary)
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(NLColor.textTertiary)
                        }
                    }
                }
                .padding(NLSpacing.sm)
                .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.md))
                .shadow(color: NLShadow.cardColor, radius: 6, x: 0, y: 3)
                .padding(.horizontal, NLSpacing.md)

                // Lista de Jogos
                List {
                    ForEach(filteredGames) { game in
                        let isFav = store.isFavorite(gameID: game.id)
                        let canAdd = store.favoriteGameIDs.count < FavoriteGamesStore.maxFavorites

                        Button(action: {
                            store.toggleFavorite(gameID: game.id)
                        }) {
                            HStack(spacing: NLSpacing.sm) {
                                VerifiedGameArtwork(game: game, aspectRatio: 1)
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                Text(game.name)
                                    .font(NLTypography.bodyEmphasis)
                                    .foregroundStyle(NLColor.textPrimary)

                                Spacer()

                                if isFav {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(NLColor.accentPrimary)
                                } else {
                                    Image(systemName: "circle")
                                        .font(.system(size: 20))
                                        .foregroundStyle(canAdd ? NLColor.textTertiary : NLColor.textDisabled)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!isFav && !canAdd)
                        .listRowBackground(NLColor.surface)
                        .listRowSeparatorTint(NLColor.borderHairline)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(NLColor.deep.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("home.favorite_games.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        Text(LocalizedStringKey("common.done"))
                            .font(NLTypography.headline)
                            .foregroundStyle(NLColor.accentPrimary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
