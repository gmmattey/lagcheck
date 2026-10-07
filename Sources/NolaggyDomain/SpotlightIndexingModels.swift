import Foundation

/// Item indexável para pesquisa rápida no sistema operacional (Spotlight / CoreSpotlight).
public struct SpotlightIndexableGame: Equatable, Sendable {
    public let gameID: String
    public let title: String
    public let summary: String
    public let keywords: [String]
    
    public init(
        gameID: String,
        title: String,
        summary: String,
        keywords: [String] = []
    ) {
        self.gameID = gameID
        self.title = title
        self.summary = summary
        self.keywords = keywords
    }
}

/// Protocolo abstrato para indexação de itens no sistema (CoreSpotlight).
public protocol SpotlightIndexing: Sendable {
    func indexGames(_ games: [SpotlightIndexableGame]) async throws
    func removeAllIndexedGames() async throws
}
