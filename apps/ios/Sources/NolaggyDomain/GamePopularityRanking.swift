import Foundation

/// Automação para ordenação dos jogos mais populares do momento.
/// Combina a base editorial oficial (métricas reais de avaliações globais na App Store / Metacritic)
/// com o interesse de uso do usuário no aparelho de forma determinística.
public enum GamePopularityRanking {
    
    public static func popularityWeight(for gameID: String, localTestCount: Int = 0) -> Double {
        let editorial = GameEditorialRegistry.editorial(for: gameID)
        let reviewCounts = editorial?.ratings.compactMap(\.reviewCount).map { Double($0) } ?? []
        let maxReviews = reviewCounts.max() ?? 150_000.0
        
        // Ponderação: número de reviews oficiais na App Store + impulso de engajamento local
        return maxReviews + (Double(localTestCount) * 500_000.0)
    }

    public static func popularGames(
        from games: [String],
        localHistory: [String] = []
    ) -> [String] {
        let testCounts = Dictionary(grouping: localHistory, by: { $0 }).mapValues { $0.count }
        return games.sorted { g1, g2 in
            let score1 = popularityWeight(for: g1, localTestCount: testCounts[g1] ?? 0)
            let score2 = popularityWeight(for: g2, localTestCount: testCounts[g2] ?? 0)
            return score1 > score2
        }
    }
}
