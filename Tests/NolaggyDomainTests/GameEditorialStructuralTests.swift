import XCTest
@testable import NolaggyDomain

/// Testes estruturais em lote sobre todas as 20 entradas de
/// `GameEditorialRegistry.allEditorials` (Decisão 31), garantindo que nenhum
/// dado é inconsistente ou implausível, independentemente do jogo específico.
final class GameEditorialStructuralTests: XCTestCase {

    func testRegistryHasExactlyTwentyEntries() {
        XCTAssertEqual(GameEditorialRegistry.allEditorials.count, 20, "O registro editorial deve conter as 20 fichas auditadas do catálogo, todas com beacon medido.")
    }

    func testAllCatalogGameIDsMatchSignedCatalogAllowlist() {
        let signedCatalogGameIDs: Set<String> = [
            "fortnite", "call-of-duty-mobile", "free-fire", "pubg-mobile",
            "brawl-stars", "wild-rift", "roblox", "minecraft",
            "apex-legends", "blood-strike", "cs2", "dota2", "eafc",
            "league-of-legends", "palworld", "rainbow-six", "rocket-league",
            "rust", "valorant", "warzone"
        ]
        XCTAssertEqual(signedCatalogGameIDs.count, 20, "Todos os 20 jogos do catálogo devem ter beacon assinado.")
        for gameID in signedCatalogGameIDs {
            XCTAssertNotNil(
                GameEditorialRegistry.editorial(for: gameID),
                "Todo jogo do catálogo assinado (\(gameID)) deve ter uma ficha editorial correspondente por ID."
            )
        }
    }

    func testAllRatingURLsAreHTTPS() {
        for (gameID, editorial) in GameEditorialRegistry.allEditorials {
            for rating in editorial.ratings {
                XCTAssertTrue(
                    rating.referenceURL.hasPrefix("https://"),
                    "A URL de referência de \(rating.source.rawValue) para \(gameID) deve ser HTTPS."
                )
            }
        }
    }

    func testAllRatingScoresAreWithinDeclaredScale() {
        for (gameID, editorial) in GameEditorialRegistry.allEditorials {
            for rating in editorial.ratings {
                XCTAssertGreaterThan(rating.scale, 0.0, "Escala inválida para \(gameID)/\(rating.source.rawValue).")
                XCTAssertGreaterThan(rating.score, 0.0, "Nota deve ser positiva para \(gameID)/\(rating.source.rawValue).")
                XCTAssertLessThanOrEqual(rating.score, rating.scale, "Nota de \(gameID)/\(rating.source.rawValue) excede a escala declarada.")
                if let reviewCount = rating.reviewCount {
                    XCTAssertGreaterThan(reviewCount, 0, "Contagem de avaliações deve ser positiva para \(gameID)/\(rating.source.rawValue).")
                }
            }
        }
    }

    func testAllPlatformRequirementsArePositiveAndSane() {
        for (gameID, editorial) in GameEditorialRegistry.allEditorials {
            XCTAssertFalse(editorial.requirements.isEmpty, "\(gameID) deve ter ao menos um requisito de plataforma.")
            for requirement in editorial.requirements {
                XCTAssertGreaterThan(requirement.storageBytes, 0, "Armazenamento deve ser positivo para \(gameID)/\(requirement.platform.rawValue).")
                XCTAssertGreaterThan(requirement.memoryRAMBytes, 0, "RAM deve ser positiva para \(gameID)/\(requirement.platform.rawValue).")
                XCTAssertFalse(requirement.minimumOS.isEmpty, "SO mínimo não pode ser vazio para \(gameID)/\(requirement.platform.rawValue).")
                if let framerate = requirement.targetFramerate {
                    XCTAssertGreaterThan(framerate, 0, "Framerate alvo deve ser positivo para \(gameID)/\(requirement.platform.rawValue).")
                    XCTAssertLessThanOrEqual(framerate, 240, "Framerate alvo implausível para \(gameID)/\(requirement.platform.rawValue).")
                }
                // Sanidade grosseira: nenhum jogo declarado exige mais que 500 GB ou 128 GB de RAM.
                XCTAssertLessThan(requirement.storageBytes, 500_000_000_000, "Armazenamento implausível para \(gameID)/\(requirement.platform.rawValue).")
                XCTAssertLessThan(requirement.memoryRAMBytes, 128_000_000_000, "RAM implausível para \(gameID)/\(requirement.platform.rawValue).")
            }
        }
    }

    func testAllNetworkDemandsArePositiveAndInternallyConsistent() {
        for (gameID, editorial) in GameEditorialRegistry.allEditorials {
            let demands = editorial.networkDemands
            XCTAssertGreaterThan(demands.minDownloadMbps, 0.0, "Download mínimo deve ser positivo para \(gameID).")
            XCTAssertGreaterThan(demands.minUploadMbps, 0.0, "Upload mínimo deve ser positivo para \(gameID).")
            XCTAssertGreaterThan(demands.optimalPingMs, 0.0, "Ping ótimo deve ser positivo para \(gameID).")
            XCTAssertGreaterThan(demands.acceptablePingMs, 0.0, "Ping aceitável deve ser positivo para \(gameID).")
            XCTAssertGreaterThan(demands.maxJitterMs, 0.0, "Jitter máximo deve ser positivo para \(gameID).")
            XCTAssertGreaterThanOrEqual(demands.packetLossTolerancePct, 0.0, "Tolerância de perda de pacotes não pode ser negativa para \(gameID).")

            XCTAssertGreaterThanOrEqual(
                demands.acceptablePingMs, demands.optimalPingMs,
                "Ping aceitável deve ser >= ping ótimo para \(gameID) (a tolerância nunca pode ser mais rígida que o ideal)."
            )
        }
    }

    func testAllGameIDsAreLowercasedAndConsistentWithLookupKey() {
        for (key, _) in GameEditorialRegistry.allEditorials {
            XCTAssertEqual(key, key.lowercased(), "A chave do dicionário \(key) deve estar em minúsculas.")
            XCTAssertNotNil(
                GameEditorialRegistry.editorial(for: key.uppercased()),
                "O lookup case-insensitive deve funcionar para \(key)."
            )
        }
    }
}
