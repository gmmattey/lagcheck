import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Estado e composição da Home (Nova Jornada de Produto).
/// A Home agora é focada, calma e não executa testes automáticos em segundo plano.
/// Exibe o carrossel dos últimos jogos testados, o CTA principal e a prateleira de jogos populares automatizada.
extension QuickCheckFeatureView {
    var contextView: some View { discoveryView }

    var discoveryView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: NLSpacing.lg) {
                if remoteCatalog == nil {
                    catalogUnavailable
                        .padding(.horizontal, NLSpacing.md)
                        .padding(.top, NLSpacing.lg)
                } else {
                    // Carrossel dos últimos jogos testados
                    HomeRecentCarouselSection(
                        title: localizedString("home.recent_tested"),
                        games: recentGames,
                        categoryTitle: categoryTitle(for:),
                        select: { selectedGameForDetails = $0 },
                        onExploreGames: { selectedTab = .games }
                    )
                    .padding(.top, NLSpacing.sm)

                    // CTA Principal: Iniciar LagCheck
                    HomeCTASection(
                        targetGame: targetGameForCTA,
                        onStartCheck: startLagCheckFromCTA,
                        onChooseAnotherGame: { selectedTab = .games }
                    )

                    // Prateleira de Jogos Populares do Momento (Automação por dados reais)
                    HomePopularShelfSection(
                        title: localizedString("home.popular"),
                        games: popularGames,
                        categoryTitle: categoryTitle(for:),
                        select: { selectedGameForDetails = $0 }
                    )
                    .padding(.top, NLSpacing.xs)
                    .padding(.bottom, NLSpacing.xl)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .safeAreaPadding(.bottom, NLSpacing.md)
        .navigationTitle(localizedString("navigation.home"))
        .navigationBarTitleDisplayMode(.large)
    }

    var catalogUnavailable: some View {
        CatalogAvailabilityState(title: "catalog.unavailable.title", message: "catalog.unavailable.message")
            .accessibilityIdentifier("catalog-unavailable")
    }

    var availableGames: [CatalogMeasurementJourney.Game] {
        guard let remoteCatalog else { return [] }
        let market = CatalogMeasurementJourney.resolvedMarket(in: remoteCatalog)
        return CatalogMeasurementJourney.availableGames(in: remoteCatalog, market: market, platform: .iphone)
    }

    var selectedGameName: String {
        availableGames.first(where: { $0.id == effectiveGameID })?.name ?? "—"
    }

    /// Até os últimos 3 jogos medidos com entradas no histórico (sem duplicatas).
    var recentGames: [CatalogMeasurementJourney.Game] {
        var seen = Set<String>()
        var result: [CatalogMeasurementJourney.Game] = []
        for entry in history {
            let gid = entry.resolvedContext.context.gameID
            if !seen.contains(gid) {
                seen.insert(gid)
                if let g = availableGames.first(where: { $0.id == gid }) {
                    result.append(g)
                }
            }
            if result.count == 3 { break }
        }
        return result
    }

    /// Jogos mais populares do momento ordenados automaticamente por dados editoriais oficiais e engajamento.
    var popularGames: [CatalogMeasurementJourney.Game] {
        let historyGameIDs = history.map { $0.resolvedContext.context.gameID }
        let allIDs = availableGames.map(\.id)
        let rankedIDs = GamePopularityRanking.popularGames(from: allIDs, localHistory: historyGameIDs)
        let gameMap = Dictionary(uniqueKeysWithValues: availableGames.map { ($0.id, $0) })
        return rankedIDs.compactMap { gameMap[$0] }
    }

    /// Jogo alvo para o botão CTA principal: o último jogo testado, ou o primeiro disponível se novo usuário.
    var targetGameForCTA: CatalogMeasurementJourney.Game? {
        recentGames.first ?? popularGames.first ?? availableGames.first
    }

    /// Inicia o LagCheck perguntando a plataforma do jogo alvo a partir do CTA da Home.
    func startLagCheckFromCTA() {
        if let target = targetGameForCTA {
            gameForPlatformSelection = target
        } else {
            selectedTab = .games
        }
    }

    func category(for profile: QualityProfileID) -> CatalogCategory {
        switch profile {
        case .battleRoyaleCompetitive: .battle
        case .mobileRealtime: .mobile
        case .casualRealtime: .casual
        }
    }

    func categoryTitle(for game: CatalogMeasurementJourney.Game) -> String {
        localizedString(category(for: game.profileID).localizationKey)
    }

    private func gameScoreNumber(for game: CatalogMeasurementJourney.Game) -> Int? {
        guard case let .completed(result)? = evaluatedScores[game.id] else { return nil }
        return result.finalScore
    }

    private func gameScoreLatencyText(for game: CatalogMeasurementJourney.Game) -> String? {
        guard case let .completed(result)? = evaluatedScores[game.id], let latency = result.metrics.p50Milliseconds else { return nil }
        return "\(Int(latency.rounded())) ms"
    }

    // MARK: - Catálogo de Jogos (Aba Jogos estilo Netflix)

    var gamesCatalogView: some View {
        HomeCatalogView(
            title: localizedString("navigation.games"),
            query: $gameQuery,
            allGames: availableGames,
            popularGames: popularGames,
            searchPlaceholder: localizedString("catalog.search.placeholder"),
            clearSearchAccessibilityLabel: localizedString("catalog.search.close"),
            categoryTitle: categoryTitle(for:),
            select: { selectedGameForDetails = $0 }
        )
    }
}
