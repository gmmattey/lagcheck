import Foundation

/// Gerencia a lista de jogos favoritos do jogador na Home do LagCheck (limite de 4 jogos).
/// Não inclui o jogo genérico e persiste a seleção em UserDefaults.
@MainActor
public final class FavoriteGamesStore: ObservableObject {
    public static let shared = FavoriteGamesStore()

    public static let maxFavorites: Int = 4
    private let userDefaultsKey = "lagcheck_favorite_game_ids"

    @Published public private(set) var favoriteGameIDs: [String] = []

    public init() {
        loadFavorites()
    }

    public func loadFavorites() {
        if let stored = UserDefaults.standard.stringArray(forKey: userDefaultsKey), !stored.isEmpty {
            self.favoriteGameIDs = Array(stored.prefix(Self.maxFavorites))
        } else {
            // Favoritos são uma escolha explícita da pessoa. Uma sugestão
            // editorial aqui faria a vitrine mentir quando ainda não há dados.
            self.favoriteGameIDs = []
        }
    }

    public func setFavorites(_ ids: [String]) {
        let trimmed = Array(ids.filter { $0 != "generic-gaming" }.prefix(Self.maxFavorites))
        self.favoriteGameIDs = trimmed
        UserDefaults.standard.set(trimmed, forKey: userDefaultsKey)
    }

    public func toggleFavorite(gameID: String) {
        guard gameID != "generic-gaming" else { return }
        var current = favoriteGameIDs
        if let index = current.firstIndex(of: gameID) {
            current.remove(at: index)
        } else {
            if current.count < Self.maxFavorites {
                current.append(gameID)
            }
        }
        setFavorites(current)
    }

    public func isFavorite(gameID: String) -> Bool {
        favoriteGameIDs.contains(gameID)
    }
}
