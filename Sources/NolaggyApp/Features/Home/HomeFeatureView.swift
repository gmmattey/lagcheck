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
                    // 1. Hero editorial de estado (Prioridade Máxima)
                    HomeStateEditorialHero(
                        game: targetGameForCTA,
                        platform: effectivePlatform,
                        regionName: selectedRegionFriendlyName,
                        lastEntry: lastHistoryEntryForEffectiveGame,
                        isMeasuring: presentation == .measuring,
                        onSelectGame: { selectedTab = .games }
                    )
                    .padding(.horizontal, NLSpacing.md)
                    .padding(.top, NLSpacing.xs)

                    // 2. CTA Dominante: Iniciar LagCheck ou Escolher Jogo
                    HomeDominantCTA(
                        targetGame: targetGameForCTA,
                        isMeasuring: presentation == .measuring,
                        onStartLagCheck: startLagCheckFromCTA,
                        onChooseAnotherGame: { selectedTab = .games }
                    )
                    .padding(.horizontal, NLSpacing.md)

                    // 3. Seção "Últimos testados" (Sem autoplay, até 3 jogos)
                    HomeRecentTestsSection(
                        items: recentTestedItems,
                        onSelectGame: { selectedGameForDetails = $0 },
                        onExploreGames: { selectedTab = .games }
                    )
                    .padding(.top, NLSpacing.xs)

                    // 4. Seção "Explorar jogos" (Prateleira discreta com link "Ver todos os jogos")
                    HomeExploreShelfSection(
                        title: localizedString("home.explore.title"),
                        seeAllTitle: localizedString("home.explore.see_all"),
                        games: popularGames,
                        categoryTitle: categoryTitle(for:),
                        onSelectGame: { selectedGameForDetails = $0 },
                        onSeeAllGames: { selectedTab = .games }
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HomeRefreshButton(
                    refreshAccessibilityLabel: localizedString("home.last_tested"),
                    isMeasuring: presentation == .measuring,
                    refresh: {
                        startLagCheckFromCTA()
                    }
                )
            }
        }
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

    /// Plataforma da última medição relevante ou iPhone por padrão.
    var effectivePlatform: Platform? {
        lastHistoryEntryForEffectiveGame?.resolvedContext.context.platform ?? .iphone
    }

    /// Última entrada de histórico para o jogo ativo (ou a mais recente geral se nenhum jogo filtrado).
    var lastHistoryEntryForEffectiveGame: MeasurementHistoryEntry? {
        if let target = targetGameForCTA {
            return history.first(where: { $0.resolvedContext.context.gameID == target.id })
        }
        return history.first
    }

    /// Até os últimos 3 jogos medidos com entradas no histórico (sem duplicatas).
    var recentTestedItems: [HomeRecentTestsSection.RecentItem] {
        var seen = Set<String>()
        var result: [HomeRecentTestsSection.RecentItem] = []
        for entry in history {
            let gid = entry.resolvedContext.context.gameID
            if !seen.contains(gid) {
                seen.insert(gid)
                if let g = availableGames.first(where: { $0.id == gid }) {
                    result.append(HomeRecentTestsSection.RecentItem(game: g, lastEntry: entry))
                }
            }
            if result.count == 3 { break }
        }
        return result
    }

    /// Jogos disponíveis em formato recente para compatibilidade.
    var recentGames: [CatalogMeasurementJourney.Game] {
        recentTestedItems.map(\.game)
    }

    /// Jogos mais populares do momento ordenados por dados editoriais oficiais.
    var popularGames: [CatalogMeasurementJourney.Game] {
        let historyGameIDs = history.map { $0.resolvedContext.context.gameID }
        let allIDs = availableGames.map(\.id)
        let rankedIDs = GamePopularityRanking.popularGames(from: allIDs, localHistory: historyGameIDs)
        let gameMap = Dictionary(uniqueKeysWithValues: availableGames.map { ($0.id, $0) })
        return rankedIDs.compactMap { gameMap[$0] }
    }

    /// Jogo alvo para o botão CTA principal: o explicitamente selecionado, ou o último testado, ou o primeiro disponível.
    var targetGameForCTA: CatalogMeasurementJourney.Game? {
        if let explicitID = selectedGameID, let found = availableGames.first(where: { $0.id == explicitID }) {
            return found
        }
        return recentTestedItems.first?.game ?? popularGames.first ?? availableGames.first
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

    // MARK: - Catálogo de Jogos (Aba Jogos)

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

// MARK: - SwiftUI Previews de Todos os Estados da Home

#Preview("Home - 1. Novo Usuário (Sem Histórico)") {
    let context = GameContext(gameID: "fortnite", market: "br", platform: .iphone)
    let game = CatalogMeasurementJourney.Game(id: "fortnite", name: "Fortnite", context: context, profileID: .battleRoyaleCompetitive)

    return NavigationStack {
        VStack(spacing: NLSpacing.lg) {
            HomeStateEditorialHero(
                game: game,
                platform: .iphone,
                regionName: "São Paulo · Brasil",
                lastEntry: nil,
                isMeasuring: false,
                onSelectGame: {}
            )
            .padding(.horizontal, NLSpacing.md)

            HomeDominantCTA(
                targetGame: game,
                isMeasuring: false,
                onStartLagCheck: {},
                onChooseAnotherGame: {}
            )
            .padding(.horizontal, NLSpacing.md)

            HomeRecentTestsSection(
                items: [],
                onSelectGame: { _ in },
                onExploreGames: {}
            )
        }
        .padding(.top, NLSpacing.md)
        .background(NLColor.backgroundBase)
        .navigationTitle("Início")
    }
    .preferredColorScheme(.dark)
}

#Preview("Home - 2. Última Medição Saudável") {
    let entry = UITestFixtures.validEntry
    let game = CatalogMeasurementJourney.Game(id: "fortnite", name: "Fortnite", context: entry.resolvedContext.context, profileID: .battleRoyaleCompetitive)

    return NavigationStack {
        VStack(spacing: NLSpacing.lg) {
            HomeStateEditorialHero(
                game: game,
                platform: .iphone,
                regionName: "São Paulo · Brasil",
                lastEntry: entry,
                isMeasuring: false,
                onSelectGame: {}
            )
            .padding(.horizontal, NLSpacing.md)

            HomeDominantCTA(
                targetGame: game,
                isMeasuring: false,
                onStartLagCheck: {},
                onChooseAnotherGame: {}
            )
            .padding(.horizontal, NLSpacing.md)

            HomeRecentTestsSection(
                items: [HomeRecentTestsSection.RecentItem(game: game, lastEntry: entry)],
                onSelectGame: { _ in },
                onExploreGames: {}
            )
        }
        .padding(.top, NLSpacing.md)
        .background(NLColor.backgroundBase)
        .navigationTitle("Início")
    }
    .preferredColorScheme(.dark)
}

#Preview("Home - 3. Última Medição Instável") {
    let base = UITestFixtures.validEntry
    let unstableMetrics = QualityMetrics(
        validResponseCount: 30, timeoutCount: 3, invalidResponseCount: 0,
        p50Milliseconds: 65, p95Milliseconds: 140, p99Milliseconds: 180, jitterMilliseconds: 18,
        packetLossPercentage: 3.5, spikeCount: 4, severeSpikeCount: 1, spikeRatePercentage: 12.0,
        p95ToP50Ratio: 2.1, worstSpikeMilliseconds: 210, components: nil
    )
    let entry = MeasurementHistoryEntry(
        completedAt: Date().addingTimeInterval(-1800),
        resolvedContext: base.resolvedContext,
        profileRuleVersion: base.profileRuleVersion,
        result: QualityResult(
            metrics: unstableMetrics,
            rawScore: 58,
            finalScore: 58,
            resultClass: .unstable,
            appliedGuardrails: [.severeSpikes]
        ),
        primaryCause: .highJitter
    )
    let game = CatalogMeasurementJourney.Game(id: "warzone", name: "Call of Duty: Warzone", context: base.resolvedContext.context, profileID: .battleRoyaleCompetitive)

    return NavigationStack {
        VStack(spacing: NLSpacing.lg) {
            HomeStateEditorialHero(
                game: game,
                platform: .playstation,
                regionName: "São Paulo · Brasil",
                lastEntry: entry,
                isMeasuring: false,
                onSelectGame: {}
            )
            .padding(.horizontal, NLSpacing.md)

            HomeDominantCTA(
                targetGame: game,
                isMeasuring: false,
                onStartLagCheck: {},
                onChooseAnotherGame: {}
            )
            .padding(.horizontal, NLSpacing.md)
        }
        .padding(.top, NLSpacing.md)
        .background(NLColor.backgroundBase)
        .navigationTitle("Início")
    }
    .preferredColorScheme(.dark)
}

#Preview("Home - 4. Medição em Andamento") {
    let context = GameContext(gameID: "fortnite", market: "br", platform: .iphone)
    let game = CatalogMeasurementJourney.Game(id: "fortnite", name: "Fortnite", context: context, profileID: .battleRoyaleCompetitive)

    return NavigationStack {
        VStack(spacing: NLSpacing.lg) {
            HomeStateEditorialHero(
                game: game,
                platform: .iphone,
                regionName: "São Paulo · Brasil",
                lastEntry: nil,
                isMeasuring: true,
                onSelectGame: {}
            )
            .padding(.horizontal, NLSpacing.md)

            HomeDominantCTA(
                targetGame: game,
                isMeasuring: true,
                onStartLagCheck: {},
                onChooseAnotherGame: {}
            )
            .padding(.horizontal, NLSpacing.md)
        }
        .padding(.top, NLSpacing.md)
        .background(NLColor.backgroundBase)
        .navigationTitle("Início")
    }
    .preferredColorScheme(.dark)
}

#Preview("Home - 5. Catálogo Indisponível") {
    NavigationStack {
        CatalogAvailabilityState(title: "catalog.unavailable.title", message: "catalog.unavailable.message")
            .padding(.horizontal, NLSpacing.md)
            .padding(.top, NLSpacing.lg)
            .navigationTitle("Início")
    }
    .preferredColorScheme(.dark)
}

#Preview("Home - 6. Última Medição Inconclusiva") {
    let base = UITestFixtures.validEntry
    let metrics = QualityMetrics(
        validResponseCount: 0, timeoutCount: 30, invalidResponseCount: 0,
        p50Milliseconds: nil, p95Milliseconds: nil, p99Milliseconds: nil, jitterMilliseconds: nil,
        packetLossPercentage: 100.0, spikeCount: 0, severeSpikeCount: 0, spikeRatePercentage: 0.0,
        p95ToP50Ratio: nil, worstSpikeMilliseconds: nil, components: nil
    )
    let entry = MeasurementHistoryEntry(
        completedAt: Date().addingTimeInterval(-600),
        resolvedContext: base.resolvedContext,
        profileRuleVersion: base.profileRuleVersion,
        result: QualityResult(
            metrics: metrics,
            rawScore: 0,
            finalScore: 0,
            resultClass: .unstable,
            appliedGuardrails: []
        ),
        primaryCause: .packetLoss
    )
    let game = CatalogMeasurementJourney.Game(id: "fortnite", name: "Fortnite", context: base.resolvedContext.context, profileID: .battleRoyaleCompetitive)

    return NavigationStack {
        VStack(spacing: NLSpacing.lg) {
            HomeStateEditorialHero(
                game: game,
                platform: .iphone,
                regionName: "São Paulo · Brasil",
                lastEntry: entry,
                isMeasuring: false,
                onSelectGame: {}
            )
            .padding(.horizontal, NLSpacing.md)

            HomeDominantCTA(
                targetGame: game,
                isMeasuring: false,
                onStartLagCheck: {},
                onChooseAnotherGame: {}
            )
            .padding(.horizontal, NLSpacing.md)
        }
        .padding(.top, NLSpacing.md)
        .background(NLColor.backgroundBase)
        .navigationTitle("Início")
    }
    .preferredColorScheme(.dark)
}
