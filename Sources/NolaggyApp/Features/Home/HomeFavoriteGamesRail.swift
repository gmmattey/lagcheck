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
            // Cabeçalho da Seção com Ação de Gerenciar/Editar
            HStack {
                Text(LocalizedStringKey("home.favorite_games.title"))
                    .font(NLTypography.sectionHeader)
                    .foregroundStyle(NLColor.textTertiary)
                    .textCase(.uppercase)

                Spacer()

                Button(action: onManageFavorites) {
                    HStack(spacing: 3) {
                        Image(systemName: "pencil.line")
                            .font(.system(size: 11, weight: .semibold))
                        Text(LocalizedStringKey("home.favorite_games.edit"))
                    }
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.accentPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(NLColor.accentPrimarySubtle, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home-favorite-games-manage")
            }

            // Grid ou Linha com até 4 jogos favoritos
            HStack(spacing: NLSpacing.sm) {
                ForEach(favoriteGames) { game in
                    let isSelected = (game.id == selectedGameID)
                    Button {
                        onSelectGame(game)
                    } label: {
                        VStack(spacing: NLSpacing.xxs) {
                            ZStack(alignment: .topTrailing) {
                                VerifiedGameArtwork(game: game, aspectRatio: 1)
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous)
                                            .stroke(
                                                isSelected ? NLColor.coralSolar : NLColor.borderHairline,
                                                lineWidth: isSelected ? 2 : 1
                                            )
                                    )

                                if isSelected {
                                    Circle()
                                        .fill(NLColor.coralSolar)
                                        .frame(width: 8, height: 8)
                                        .padding(4)
                                }
                            }

                            Text(game.name)
                                .font(NLTypography.captionStrong)
                                .foregroundStyle(isSelected ? NLColor.textPrimary : NLColor.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home-favorite-game-\(game.id)")
                }

                // Slot de Adicionar Jogo caso tenha menos de 4
                if favoriteGames.count < FavoriteGamesStore.maxFavorites {
                    Button(action: onManageFavorites) {
                        VStack(spacing: NLSpacing.xxs) {
                            ZStack {
                                RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous)
                                    .fill(NLColor.panel)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: NLRadius.controlMedium, style: .continuous)
                                            .strokeBorder(
                                                NLColor.borderHairline,
                                                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                                            )
                                    )
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(NLColor.accentPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)

                            Text(LocalizedStringKey("home.favorite_games.add"))
                                .font(NLTypography.caption)
                                .foregroundStyle(NLColor.textTertiary)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home-favorite-game-add-slot")
                }
            }
        }
        .padding(.horizontal, NLSpacing.md)
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
                .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(NLColor.borderHairline, lineWidth: 1)
                )
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
                                        .foregroundStyle(NLColor.coralSolar)
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
