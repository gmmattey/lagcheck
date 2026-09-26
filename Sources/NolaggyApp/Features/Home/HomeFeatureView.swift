import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain
import NolaggyInfrastructure

/// Estado e composição da Home (Nova Jornada de Produto).
/// A Home agora é focada, calma e não executa testes automáticos em segundo plano.
/// Exibe o carrossel dos últimos jogos testados, o CTA principal e a prateleira de jogos populares automatizada.
extension QuickCheckFeatureView {
    var contextView: some View { discoveryView }

    var discoveryView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: NLSpacing.lg) {
                // Topo minimalista: wordmark lagcheck à esquerda e menu … à direita
                NolaggyAppHeader(openSettings: { showingSettings = true })
                    .padding(.horizontal, NLSpacing.md)
                    .padding(.top, NLSpacing.xs)

                if remoteCatalog == nil {
                    catalogUnavailable
                        .padding(.horizontal, NLSpacing.md)
                        .padding(.top, NLSpacing.lg)
                } else {
                    // Headline imersiva
                    Text(LocalizedStringKey("home.hero.ready_for_ranked"))
                        .font(NLTypography.competitiveHero)
                        .foregroundStyle(NLColor.textPrimary)
                        .tracking(NLTypography.heroTracking)
                        .padding(.horizontal, NLSpacing.md)
                        .padding(.top, NLSpacing.xxs)

                    // Pílula de Telemetria de Rede Local ao Vivo (Decisão 54)
                    LiveNetworkSignalCapsule(signal: liveNetworkSignal)
                        .padding(.horizontal, NLSpacing.md)

                    // Hero Card Amplo do Jogo Protagonista
                    DarkCompetitiveHeroCard(
                        game: targetGameForCTA,
                        platform: effectivePlatform,
                        regionFriendlyName: selectedRegionFriendlyName,
                        latestEntry: lastHistoryEntryForEffectiveGame ?? latestHistoryEntry,
                        isMeasuring: presentation == .measuring,
                        onStartCheck: startLagCheckFromCTA,
                        onOpenHistory: { showingHistory = true }
                    )
                    .padding(.horizontal, NLSpacing.md)

                    // Trilho Rápido SEUS JOGOS
                    DarkCompetitiveQuickRail(
                        games: Array(homeGames.prefix(6)),
                        selectedGameID: targetGameForCTA?.id,
                        onSelectGame: { game in
                            selectedGameID = game.id
                        },
                        onSeeAllGames: openGamesFromHome
                    )
                    .padding(.horizontal, NLSpacing.md)
                    .padding(.top, NLSpacing.xs)
                    .padding(.bottom, NLSpacing.xl)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .safeAreaPadding(.bottom, NLSizing.touchTarget * 2)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await refreshLiveNetworkSignal()
        }
    }

    var catalogUnavailable: some View {
        CatalogAvailabilityState(title: "catalog.unavailable.title", message: "catalog.unavailable.message")
            .accessibilityIdentifier("catalog-unavailable")
    }

    var availableGames: [CatalogMeasurementJourney.Game] {
        guard let remoteCatalog else { return [] }
        let market = CatalogMeasurementJourney.resolvedMarket(in: remoteCatalog)
        var seen = Set<String>()
        return Platform.allCases
            .flatMap { CatalogMeasurementJourney.availableGames(in: remoteCatalog, market: market, platform: $0) }
            .filter { seen.insert($0.id).inserted }
    }

    var selectedGameName: String {
        if effectiveGameID == GameContext.genericGamingID {
            return localizedString("generic_gaming.name")
        }
        return availableGames.first(where: { $0.id == effectiveGameID })?.name ?? "—"
    }

    /// Plataforma da última medição relevante ou iPhone por padrão.
    var effectivePlatform: Platform? {
        lastHistoryEntryForEffectiveGame?.resolvedContext.context.platform ?? .iphone
    }

    /// A Home fala primeiro da última observação real, sem atribuir um score
    /// antigo ao jogo que a pessoa ainda nem escolheu nesta sessão.
    var latestHistoryEntry: MeasurementHistoryEntry? {
        history.max(by: { $0.completedAt < $1.completedAt })
    }

    var gameForLatestHistoryEntry: CatalogMeasurementJourney.Game? {
        guard let gameID = latestHistoryEntry?.resolvedContext.context.gameID else { return nil }
        if gameID == GameContext.genericGamingID {
            let market = remoteCatalog.map { CatalogMeasurementJourney.resolvedMarket(in: $0) } ?? "BR"
            let platform = latestHistoryEntry?.resolvedContext.context.platform ?? .iphone
            let link = latestHistoryEntry?.resolvedContext.context.declaredExternalLink
            return CatalogMeasurementJourney.genericGamingGame(
                market: market,
                platform: platform,
                declaredExternalLink: link,
                localizedName: localizedString("generic_gaming.name")
            )
        }
        return availableGames.first(where: { $0.id == gameID })
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
                if gid == GameContext.genericGamingID {
                    let market = remoteCatalog.map { CatalogMeasurementJourney.resolvedMarket(in: $0) } ?? "BR"
                    let g = CatalogMeasurementJourney.genericGamingGame(
                        market: market,
                        platform: entry.resolvedContext.context.platform,
                        declaredExternalLink: entry.resolvedContext.context.declaredExternalLink,
                        localizedName: localizedString("generic_gaming.name")
                    )
                    result.append(HomeRecentTestsSection.RecentItem(game: g, lastEntry: entry))
                } else if let g = availableGames.first(where: { $0.id == gid }) {
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

    /// A lista curta mantém o último jogo no começo e não transforma a Home
    /// em catálogo. A busca e os filtros pertencem exclusivamente à aba Jogos.
    var homeGames: [CatalogMeasurementJourney.Game] {
        var seen = Set<String>()
        return (recentTestedItems.map(\.game) + popularGames)
            .filter { seen.insert($0.id).inserted }
    }

    /// Jogo alvo para o botão CTA principal: o explicitamente selecionado, ou o último testado, ou o primeiro disponível.
    var targetGameForCTA: CatalogMeasurementJourney.Game? {
        if let explicitID = selectedGameID {
            if explicitID == GameContext.genericGamingID {
                let market = remoteCatalog.map { CatalogMeasurementJourney.resolvedMarket(in: $0) } ?? "BR"
                return CatalogMeasurementJourney.genericGamingGame(
                    market: market,
                    platform: .iphone,
                    declaredExternalLink: nil,
                    localizedName: localizedString("generic_gaming.name")
                )
            }
            if let found = availableGames.first(where: { $0.id == explicitID }) {
                return found
            }
        }
        return recentTestedItems.first?.game ?? popularGames.first ?? availableGames.first
    }

    func selectGame(_ game: CatalogMeasurementJourney.Game) {
        analyticsTracker.track(.gameSelected(gameID: game.id))
        selectedGameForDetails = game
    }

    func selectGenericGaming() {
        let market = remoteCatalog.map { CatalogMeasurementJourney.resolvedMarket(in: $0) } ?? "BR"
        let lastEntry = history.first(where: { $0.resolvedContext.context.gameID == GameContext.genericGamingID })
        let game = CatalogMeasurementJourney.genericGamingGame(
            market: market,
            platform: lastEntry?.resolvedContext.context.platform ?? .iphone,
            declaredExternalLink: lastEntry?.resolvedContext.context.declaredExternalLink,
            localizedName: localizedString("generic_gaming.name")
        )
        selectGame(game)
    }

    /// A Home encaminha à escolha explícita de plataforma e vínculo no detalhe
    /// do jogo. A medição começa somente pelo Deep Check daquele contexto.
    func startLagCheckFromCTA() {
        if let target = targetGameForCTA {
            selectGame(target)
        } else {
            openGamesFromHome()
        }
    }

    /// Abre o catálogo como continuação da Home. A aba mantém sua identidade
    /// de destino principal quando é escolhida diretamente na tab bar.
    func openGamesFromHome() {
        gamesReturnToHome = true
        selectedTab = .games
    }

    func category(for profile: QualityProfileID) -> CatalogCategory {
        switch profile {
        case .battleRoyaleCompetitive: .battle
        case .mobileRealtime: .competitive
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

    /// Atualiza pontualmente a telemetria passiva da rede local e status da rota para exibição na Home (Decisão 54).
    /// Não realiza sondagem contínua e não consome dados móveis nem bateria.
    func refreshLiveNetworkSignal() async {
        let availability = NWPathWiFiAvailability()
        let interface = await availability.currentInterface()
        let regionalName = selectedRegionFriendlyName.isEmpty ? "São Paulo" : selectedRegionFriendlyName

        switch interface {
        case .none:
            liveNetworkSignal = LiveNetworkSignal(
                connection: .offline,
                regionalRouteName: regionalName,
                isRegionalRouteOperational: false
            )
        case .cellular:
            liveNetworkSignal = LiveNetworkSignal(
                connection: .cellular(technology: "Móvel"),
                regionalRouteName: regionalName,
                isRegionalRouteOperational: true
            )
        case .wifi:
            let prober = BSDWiFiLocalGatewayProber()
            let telemetry = await prober.probeLocalGateway(sampleCount: 1, timeoutPerSampleSeconds: 0.3)
            let bandResult = WiFiBandEvaluator.evaluate(telemetry: telemetry)
            let band: LiveNetworkSignal.WiFiBand
            switch bandResult.diagnostic {
            case .confirmed5GHzOrHigher:
                band = .fiveGHz
            case .confirmed24GHz, .suspected24GHzContention:
                band = .twoPointFourGHz
            case .stableWiFi:
                band = .fiveGHz
            case .inconclusive:
                band = .standard
            }
            liveNetworkSignal = LiveNetworkSignal(
                connection: .wifi(band: band, gatewayRTTMs: telemetry.gatewayRTTMedianMs),
                regionalRouteName: regionalName,
                isRegionalRouteOperational: true
            )
        case .other:
            liveNetworkSignal = LiveNetworkSignal(
                connection: .wifi(band: .standard, gatewayRTTMs: nil),
                regionalRouteName: regionalName,
                isRegionalRouteOperational: true
            )
        }
    }

    // MARK: - Catálogo de Jogos (Aba Jogos)

    var gamesCatalogView: some View {
        HomeCatalogView(
            title: localizedString("navigation.games"),
            query: $gameQuery,
            selectedCategory: $selectedCategory,
            selectedPlatforms: $selectedPlatforms,
            allGames: availableGames,
            recentItems: recentTestedItems,
            searchPlaceholder: localizedString("catalog.search.placeholder"),
            clearSearchAccessibilityLabel: localizedString("catalog.search.close"),
            categoryTitle: categoryTitle(for:),
            filterTitle: { localizedString($0.localizationKey) },
            platformsForGame: supportedPlatforms(for:),
            platformFilterTitle: localizedString("catalog.platform_filter.title"),
            platformsTitle: { game in
                RemoteCatalogVerifier.allowedPlatforms(for: game.id)
                    .sorted { $0.rawValue < $1.rawValue }
                    .map(\.displayName)
                    .joined(separator: " · ")
            },
            onReturnToHome: gamesReturnToHome ? {
                selectedTab = .home
            } : nil,
            onSelectGenericGaming: {
                selectGenericGaming()
            },
            select: { selectGame($0) }
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
