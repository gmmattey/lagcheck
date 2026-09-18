import XCTest
@testable import NolaggyDomain

final class GameEditorialTests: XCTestCase {

    func testAllCatalogGamesHaveAuditEditorial() {
        let expectedGameIDs = [
            "fortnite", "call-of-duty-mobile", "free-fire", "pubg-mobile",
            "brawl-stars", "wild-rift", "roblox", "minecraft",
            "apex-legends", "blood-strike", "cs2", "dota2", "eafc",
            "league-of-legends", "palworld", "rainbow-six",
            "rocket-league", "rust", "valorant", "warzone"
        ]

        for gameID in expectedGameIDs {
            let editorial = GameEditorialRegistry.editorial(for: gameID)
            XCTAssertNotNil(editorial, "O jogo \(gameID) deve possuir metadados editoriais auditados cadastrados.")
            
            guard let editorial else { continue }
            XCTAssertFalse(editorial.publisher.isEmpty, "Publisher não pode ser vazio para \(gameID).")
            XCTAssertGreaterThan(editorial.releaseYear, 2000, "Ano de lançamento deve ser válido para \(gameID).")
            XCTAssertFalse(editorial.ratings.isEmpty, "Deve possuir ao menos uma avaliação oficial auditada para \(gameID).")
            XCTAssertFalse(editorial.requirements.isEmpty, "Deve possuir ao menos um requisito de plataforma para \(gameID).")
            
            // Valida que as notas possuem fontes auditáveis válidas
            for rating in editorial.ratings {
                XCTAssertGreaterThan(rating.score, 0.0)
                XCTAssertTrue(rating.referenceURL.starts(with: "https://"), "A URL de referência deve ser HTTPS válida para \(gameID).")
            }

            // Valida demandas de rede recomendadas
            XCTAssertGreaterThan(editorial.networkDemands.optimalPingMs, 0.0)
            XCTAssertGreaterThan(editorial.networkDemands.maxJitterMs, 0.0)
        }
    }

    func testLocalizedSummaryFallback() {
        guard let editorial = GameEditorialRegistry.editorial(for: "fortnite") else {
            XCTFail("Fortnite deve existir no registro")
            return
        }

        let pt = editorial.localizedSummary(localeIdentifier: "pt-BR")
        let en = editorial.localizedSummary(localeIdentifier: "en-US")

        XCTAssertFalse(pt.isEmpty)
        XCTAssertFalse(en.isEmpty)
        XCTAssertNotEqual(pt, en)
    }

    func testFormattedRatingsAndStorage() {
        guard let editorial = GameEditorialRegistry.editorial(for: "minecraft") else {
            XCTFail("Minecraft deve existir no registro")
            return
        }

        let metacritic = editorial.ratings.first(where: { $0.source == .metacriticCritic })
        XCTAssertEqual(metacritic?.formattedScore, "93")

        let req = editorial.requirement(for: .iphone)
        XCTAssertNotNil(req)
        XCTAssertTrue(req?.formattedStorage.contains("GB") == true)
        XCTAssertTrue(req?.formattedRAM.contains("GB RAM") == true)
    }
}
