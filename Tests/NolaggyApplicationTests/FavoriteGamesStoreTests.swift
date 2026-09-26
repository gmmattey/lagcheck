import XCTest
@testable import NolaggyApplication

@MainActor
final class FavoriteGamesStoreTests: XCTestCase {

    func testMaxFavoritesLimitIsEnforced() {
        let store = FavoriteGamesStore.shared
        store.setFavorites(["game1", "game2", "game3", "game4", "game5", "game6"])

        XCTAssertEqual(store.favoriteGameIDs.count, 4)
        XCTAssertEqual(store.favoriteGameIDs, ["game1", "game2", "game3", "game4"])
    }

    func testGenericGamingCannotBeFavorited() {
        let store = FavoriteGamesStore.shared
        store.setFavorites(["generic-gaming", "cs2", "valorant"])

        XCTAssertFalse(store.isFavorite(gameID: "generic-gaming"))
        XCTAssertTrue(store.isFavorite(gameID: "cs2"))
        XCTAssertTrue(store.isFavorite(gameID: "valorant"))
    }

    func testToggleFavorite() {
        let store = FavoriteGamesStore.shared
        store.setFavorites(["cs2", "valorant"])

        XCTAssertTrue(store.isFavorite(gameID: "cs2"))

        // Desmarcar
        store.toggleFavorite(gameID: "cs2")
        XCTAssertFalse(store.isFavorite(gameID: "cs2"))

        // Marcar novamente
        store.toggleFavorite(gameID: "cs2")
        XCTAssertTrue(store.isFavorite(gameID: "cs2"))
    }
}
