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

    var favoriteGamesList: [CatalogMeasurementJourney.Game] {
        let store = FavoriteGamesStore.shared
        let favIDs = store.favoriteGameIDs
        let nonGenericGames = availableGames.filter { $0.id != GameContext.genericGamingID }
        var result: [CatalogMeasurementJourney.Game] = []
        for id in favIDs {
            if let g = nonGenericGames.first(where: { $0.id == id }) {
                result.append(g)
            }
        }
        if result.isEmpty {
            return Array(nonGenericGames.prefix(4))
        }
        return Array(result.prefix(4))
    }

    var currentHomeGame: CatalogMeasurementJourney.Game {
        if let target = targetGameForCTA {
            return target
        }
        if let latest = latestHistoryEntry, let g = availableGames.first(where: { $0.id == latest.resolvedContext.context.gameID }) {
            return g
        }
        if let fortnite = availableGames.first(where: { $0.id == "fortnite" }) {
            return fortnite
        }
        return availableGames.first ?? CatalogMeasurementJourney.genericGamingGame(
            market: "BR",
            platform: .iphone,
            declaredExternalLink: nil,
            localizedName: localizedString("generic_gaming.name")
        )
    }

    var currentHomeSubtitle: String {
        let platformName = effectivePlatform?.displayName ?? Platform.iphone.displayName
        let networkName: String
        switch liveNetworkSignal.connection {
        case .offline:
            networkName = localizedString("network.offline")
        case .cellular:
            networkName = localizedString("network.cellular")
        case .wifi(let band, _):
            networkName = (band == .fiveGHz) ? "Wi-Fi 5 GHz" : "Wi-Fi"
        }
        return "\(platformName) · \(networkName)"
    }

    func latestResultSummaryText(_ entry: MeasurementHistoryEntry) -> String {
        if entry.isInconclusive {
            return localizedString("game_readiness.verdict.inconclusive.headline")
        }
        if let verdict = entry.readinessVerdict {
            switch verdict {
            case .ready:
                return localizedString("game_readiness.verdict.ready.headline")
            case .caution:
                return localizedString("game_readiness.verdict.caution.headline")
            case .notReady:
                return localizedString("game_readiness.verdict.not_ready.headline")
            case .inconclusive:
                return localizedString("game_readiness.verdict.inconclusive.headline")
            }
        }
        return localizedString("game_readiness.verdict.inconclusive.headline")
    }

    func latestResultSymbol(_ entry: MeasurementHistoryEntry) -> String {
        if entry.isInconclusive {
            return "—"
        }
        switch entry.readinessVerdict {
        case .ready:
            return "●"
        case .caution, .notReady:
            return "▲"
        case .inconclusive, .none:
            return "—"
        }
    }

    func latestResultColor(_ entry: MeasurementHistoryEntry) -> Color {
        if entry.isInconclusive {
            return NLColor.textSecondary
        }
        switch entry.readinessVerdict {
        case .ready:
            return NLColor.semanticReady
        case .caution:
            return NLColor.semanticCaution
        case .notReady:
            return NLColor.semanticNotReady
        case .inconclusive, .none:
            return NLColor.textSecondary
        }
    }

    func relativeTimeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var discoveryView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                if remoteCatalog == nil {
                    catalogUnavailable
                        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                        .padding(.top, 96)
                } else {
                    // Dobra Superior Hero: Atmosfera épica de jogos (mesma da web) + Gauge Circular Cockpit
                    ZStack(alignment: .top) {
                        Image("HeroTopGames")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 390)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    stops: [
                                        .init(color: NLColor.deep.opacity(0.85), location: 0),
                                        .init(color: NLColor.deep.opacity(0.20), location: 0.35),
                                        .init(color: NLColor.deep.opacity(0.70), location: 0.72),
                                        .init(color: NLColor.deep, location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        VStack(spacing: 0) {
                            // Pílula de sinal de rede e cockpit
                            LiveNetworkSignalCapsule(signal: liveNetworkSignal) {
                                showingCockpit = true
                            }
                            .padding(.top, 56)
                            .padding(.bottom, 16)

                            // Gauge Circular Oficial de Pulso (Decisão 113) com "TESTAR" minimalista no centro
                            HomeCircularPulseGaugeHero(
                                selectedGameName: nil,
                                regionName: effectivePlatform?.displayName ?? "SP",
                                isMeasuring: false,
                                onStartCheck: {
                                    handlePrimaryCTA()
                                }
                            )
                            .accessibilityIdentifier("home-circular-gauge-hero")
                            .padding(.bottom, 14)

                            // Linha com último resultado verificado (clicável para abrir detalhes)
                            Group {
                                if let latest = latestHistoryEntry {
                                    Button {
                                        completedEntry = latest
                                        showingDetails = true
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(verbatim: latestResultSymbol(latest))
                                                .foregroundStyle(latestResultColor(latest))
                                                .fontWeight(.heavy)
                                            Text(latestResultSummaryText(latest))
                                                .fontWeight(.semibold)
                                            Text(verbatim: "·")
                                            Text(relativeTimeString(for: latest.completedAt))
                                        }
                                        .font(NLTypography.monospaceSubtitle)
                                        .foregroundStyle(NLColor.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("home-last-result")
                                } else {
                                    Text(LocalizedStringKey("home.last_check.empty"))
                                        .font(NLTypography.monospaceSubtitle)
                                        .foregroundStyle(NLColor.textTertiary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                }
                            }
                            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                            .padding(.bottom, NLSpacing.md)
                        }
                    }

                    // Seção Inferior: Jogos Favoritos com Disparo em 1 Toque (Decisão 113)
                    if !favoriteGamesList.isEmpty {
                        HomeFavoriteGamesRail(
                            favoriteGames: favoriteGamesList,
                            selectedGameID: selectedGameID,
                            onSelectGame: { game in
                                selectedGameID = game.id
                                startCatalogCheckDirectly(for: game)
                            },
                            onManageFavorites: {
                                openGamesFromHome()
                            }
                        )
                        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                        .padding(.top, 12)
                        .padding(.bottom, NLSpacing.lg)
                    }

                    NativeAdSlot(placement: .home)
                        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .ignoresSafeArea(edges: .top)
        .safeAreaPadding(.bottom, NLSizing.touchTarget * 2)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
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

    /// Plataforma configurada pelo usuário, ou da última medição relevante, ou iPhone por padrão.
    var effectivePlatform: Platform? {
        preferredGamingPlatform ?? lastHistoryEntryForEffectiveGame?.resolvedContext.context.platform ?? .iphone
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

    /// Jogo alvo para o botão CTA principal: o explicitamente selecionado pelo jogador.
    /// Se nil (desmarcado), a Home assume teste direto de Conexão Geral (rota de referência neutra).
    var targetGameForCTA: CatalogMeasurementJourney.Game? {
        guard let explicitID = selectedGameID, explicitID != GameContext.genericGamingID else {
            return nil
        }
        return availableGames.first(where: { $0.id == explicitID })
    }

    func selectGame(_ game: CatalogMeasurementJourney.Game) {
        analyticsTracker.track(.gameSelected(gameID: game.id))
        selectedGameID = game.id
        startCheckDirectly(for: game)
    }

    func selectGenericGaming() {
        selectedGameID = nil
        startGeneralGamingCheckDirectly()
    }

    func handlePrimaryCTA() {
        startGeneralGamingCheckDirectly()
    }

    /// A Home dispara o Deep Check direto em 1 toque (Decisão 56).
    func startLagCheckFromCTA() {
        let game = targetGameForCTA ?? currentHomeGame
        if game.id != GameContext.genericGamingID {
            selectedGameID = game.id
            startCatalogCheckDirectly(for: game)
        } else {
            startGeneralGamingCheckDirectly()
        }
    }

    /// Inicia diretamente a medição da rota neutra de referência em 1 toque (Decisões 49, 54 e 56).
    func startGeneralGamingCheckFromCTA() {
        startGeneralGamingCheckDirectly()
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
        // Decisão 50: sem rota resolvida ainda, não se inventa uma cidade específica.
        let regionalName = selectedRegionFriendlyName.isEmpty
            ? AppLocalization.string("settings.region.automatic", comment: "")
            : selectedRegionFriendlyName

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
            liveNetworkSignal = LiveNetworkSignal(
                connection: .wifi(band: .standard, gatewayRTTMs: telemetry.gatewayRTTMedianMs),
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
            allGames: availableGames,
            recentItems: recentTestedItems.filter { recent in
                availableGames.contains(where: { $0.id == recent.game.id })
            },
            searchPlaceholder: localizedString("catalog.search.placeholder"),
            clearSearchAccessibilityLabel: localizedString("catalog.search.close"),
            onReturnToHome: gamesReturnToHome ? {
                selectedTab = .home
            } : nil,
            onSelectGenericGaming: {
                startGeneralGamingCheckFromGames()
            },
            select: { game in
                selectedGameID = game.id
                startCatalogCheckDirectly(for: game)
            }
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
