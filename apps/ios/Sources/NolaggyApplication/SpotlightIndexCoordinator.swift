import Foundation
import NolaggyDomain

/// Coordenador de aplicação para indexação de títulos do catálogo no Spotlight (Decisão 76).
public final class SpotlightIndexCoordinator: Sendable {
    private let indexer: any SpotlightIndexing
    
    public init(indexer: any SpotlightIndexing) {
        self.indexer = indexer
    }
    
    /// Converte os jogos do catálogo e seus metadados editoriais em itens pesquisáveis.
    public func indexCatalogGames(
        games: [RemoteCatalogGame],
        languageCode: String = "pt-BR"
    ) async {
        let items: [SpotlightIndexableGame] = games.map { game in
            let editorial = GameEditorialRegistry.editorial(for: game.id)
            let desc = editorial?.summary[languageCode] ?? editorial?.summary["en"] ?? "Medir ping e estabilidade para \(game.name)"
            
            var keywords = [
                game.name,
                game.id,
                "ping",
                "lag",
                "rota",
                "ranked",
                "conexao",
                "ms",
                "servidor",
                "packet loss",
                "bufferbloat"
            ]
            if let publisher = editorial?.publisher {
                keywords.append(publisher)
            }
            
            return SpotlightIndexableGame(
                gameID: game.id,
                title: "LagCheck: \(game.name)",
                summary: desc,
                keywords: keywords
            )
        }
        
        do {
            try await indexer.indexGames(items)
        } catch {
            // Indexação em background é não-bloqueante; falha silenciosa permitida
        }
    }
}
