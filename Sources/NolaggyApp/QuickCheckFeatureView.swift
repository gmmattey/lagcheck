import SwiftUI
import CoreSpotlight
import Network
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain
import NolaggyInfrastructure

/// Casca da jornada de medição: hospeda Home, Histórico e Configurações na mesma
/// `NavigationStack`, e mantém o estado compartilhado que as features de
/// Home, Game/Measurement, Result, Status e Histórico consultam por extensão
/// (ver `Features/` neste alvo). Cada tela vive no seu próprio arquivo; este
/// arquivo concentra somente orquestração: estado, ciclo de vida e navegação.
struct QuickCheckFeatureView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.locale) var locale
    @State var presentation: QuickCheckPresentation = .context
    @State var coordinator: MeasurementSessionCoordinator
    @State var partialSamples: [ProbeSample] = []
    @State var completedEntry: MeasurementHistoryEntry?
    @State var history: [MeasurementHistoryEntry] = []
    @State var showingDetails = false
    @State var destination: AppDestination = .home
    @State var selectedTab: AppTab = ProcessInfo.processInfo.arguments.contains("-ui-fixture-games-tab") ? .games : .home
    /// A aba Jogos continua sendo um destino principal da tab bar. Quando a
    /// própria Home a abre como próximo passo, porém, oferecemos retorno
    /// explícito à Home sem criar uma segunda NavigationStack ou uma barra
    /// manual concorrendo com a barra nativa.
    @State var gamesReturnToHome = false
    @State var showingSettings = false
    @State var showingHistory = false
    @State var showingFavoritesSheet = false
    @State var deepCheckDestination: DeepCheckDestination?
    @State var showingRegionalSelection = false
    @State var manualRegionID: String?
    /// `nil` até o usuário escolher explicitamente um jogo (toque na vitrine
    /// ou reteste). Sem escolha explícita e com histórico, a Home não define
    /// um jogo "pronto para medir" sozinha — ver `effectiveGameID`.
    @State var selectedGameID: String?
    @State var selectedRegionalContext: ResolvedMeasurementContext?
    @State var regionalPresentation: RegionalSelectionPresentation = .confirming
    @State var gameQuery = ""
    @State var isGameSearchExpanded = false
    @State var selectedCategory: CatalogCategory = .all
    @State var selectedPlatforms: Set<Platform> = []
    @State var evaluatedScores: [String: MeasurementEvaluation] = [:]
    @State var isBackgroundMeasuring = false
    @State var backgroundMeasurementFailed = false
    @State var selectedGameForDetails: CatalogMeasurementJourney.Game?
    /// Contexto escolhido para uma nova leitura. No reteste ele preserva a
    /// plataforma e o vínculo externo declarados, mas nunca reutiliza a rota
    /// histórica: a região é resolvida novamente pelo catálogo atual.
    @State var requestedMeasurementContext: GameContext?
    @State var liveNetworkSignal: LiveNetworkSignal = LiveNetworkSignal()
    @State var showingCockpit = false
    @AppStorage("user_default_platform") var userPreferredPlatformRaw: String = ""
    @AppStorage(AppLocalization.selectedLanguageKey) var selectedLanguage: String = AppLanguage.system.rawValue
    @State private var hasTrackedAppOpen = false
    @State private var artworkLoaderReady = false

    var preferredGamingPlatform: Platform? {
        Platform(rawValue: userPreferredPlatformRaw)
    }

    let historyRepository: any MeasurementHistoryRepository
    let regionalPreferenceRepository: any RegionalPreferenceRepository
    let remoteCatalog: RemoteCatalogPayload?
    let usesCatalogFallback: Bool
    let usesUIFixture: Bool
    let appConfiguration: NolaggyAppConfiguration
    let analyticsTracker: any AnalyticsTracker

    /// Jogo efetivamente relevante agora: a escolha explícita do usuário, ou,
    /// só na ausência de qualquer histórico (primeiro uso), o primeiro jogo do
    /// catálogo — para que a primeira abertura ainda tenha um caminho rápido.
    /// Com histórico e sem escolha explícita, a Home não compete consigo
    /// mesma: a última medição é a única oferta primária.
    var effectiveGameID: String? {
        selectedGameID ?? (history.isEmpty ? availableGames.first?.id : nil)
    }

    var context: GameContext? {
        if effectiveGameID == GameContext.genericGamingID {
            let market = remoteCatalog.map { CatalogMeasurementJourney.resolvedMarket(in: $0) } ?? "BR"
            return GameContext.genericGaming(market: market, platform: .iphone, declaredExternalLink: nil)
        }
        return availableGames.first(where: { $0.id == effectiveGameID })?.context
    }

    init(
        historyRepository: any MeasurementHistoryRepository = NoopMeasurementHistoryRepository(),
        regionalPreferenceRepository: any RegionalPreferenceRepository = NoopRegionalPreferenceRepository(),
        remoteCatalog: RemoteCatalogPayload? = nil,
        usesCatalogFallback: Bool = false,
        appConfiguration: NolaggyAppConfiguration = NolaggyAppConfiguration(),
        analyticsTracker: any AnalyticsTracker = NoopAnalyticsTracker()
    ) {
        self.historyRepository = historyRepository
        self.regionalPreferenceRepository = regionalPreferenceRepository
        self.remoteCatalog = remoteCatalog
        self.usesCatalogFallback = usesCatalogFallback
        self.appConfiguration = appConfiguration
        self.analyticsTracker = analyticsTracker
        let measuringFixture = UITestFixtures.isEnabled("-ui-fixture-measuring")
        let inconclusiveFixture = UITestFixtures.isEnabled("-ui-fixture-inconclusive-history")
        let validResultFixture = UITestFixtures.isEnabled(UITestFixtures.launchArgument)
        usesUIFixture = validResultFixture || inconclusiveFixture
        let fixture = validResultFixture ? UITestFixtures.validEntry : nil

        let initialPresentation: QuickCheckPresentation
        let initialCompletedEntry: MeasurementHistoryEntry?
        let initialHistory: [MeasurementHistoryEntry]
        let initialPartialSamples: [ProbeSample]
        let initialSelectedRegionalContext: ResolvedMeasurementContext?

        if inconclusiveFixture {
            let entry = UITestFixtures.inconclusiveEntry
            initialPresentation = .context
            initialCompletedEntry = entry
            initialHistory = [entry]
            initialPartialSamples = []
            initialSelectedRegionalContext = entry.resolvedContext
        } else if let fixture {
            initialPresentation = .result(fixture.result!)
            initialCompletedEntry = fixture
            initialHistory = [fixture]
            initialPartialSamples = UITestFixtures.validSamples
            initialSelectedRegionalContext = fixture.resolvedContext
        } else if measuringFixture {
            initialPresentation = .measuring
            initialCompletedEntry = nil
            initialHistory = []
            initialPartialSamples = []
            initialSelectedRegionalContext = nil
        } else {
            initialPresentation = .context
            initialCompletedEntry = nil
            initialHistory = []
            initialPartialSamples = []
            initialSelectedRegionalContext = nil
        }

        _presentation = State(initialValue: initialPresentation)
        _completedEntry = State(initialValue: initialCompletedEntry)
        _history = State(initialValue: initialHistory)
        _partialSamples = State(initialValue: initialPartialSamples)
        // Uma entrada preserva o contexto resolvido que produziu seu score.
        // A fixture de resultado precisa mantê-lo também para que a jornada
        // Quick resultado → Deep use o mesmo contexto, não um catálogo inferido.
        _selectedRegionalContext = State(initialValue: initialSelectedRegionalContext)
        _coordinator = State(initialValue: MeasurementSessionCoordinator(
            transport: MeasurementTransportFactory.quickCheckTransport(),
            pathObserver: MeasurementTransportFactory.pathObserver(),
            historyRepository: historyRepository
        ))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Início
            NavigationStack {
                measurementJourney
                    .background(NolaggyScreenBackground())
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .navigationDestination(isPresented: $showingRegionalSelection) {
                        RegionalSelectionFeatureView(
                            gameTitle: selectedGameName,
                            presentation: $regionalPresentation,
                            onRetry: retryRegionalPreRead,
                            onBackOrCancel: cancelRegionalSelection
                        )
                        .toolbar(.hidden, for: .tabBar)
                    }
                    .navigationDestination(isPresented: $showingSettings) {
                        SettingsView(
                            configuration: appConfiguration,
                            regionCandidates: regionCandidates,
                            manualRegionID: manualRegionID,
                            onSelectRegion: selectRegionPreference,
                            deleteHistory: deleteHistory,
                            showHistory: {
                                showingSettings = false
                                showingHistory = true
                            },
                            selectedGameID: selectedGameID,
                            selectedGameName: selectedGameID.flatMap { id in availableGames.first(where: { $0.id == id })?.name },
                            onDismiss: {
                                showingSettings = false
                            }
                        )
                    }
                    .navigationDestination(isPresented: $showingHistory) {
                        HistoryView(
                            entries: history,
                            gameName: gameName(for:),
                            retry: retryFromHistory,
                            returnToHome: { showingHistory = false },
                            openSettings: {
                                showingHistory = false
                                showingSettings = true
                            },
                            showsBackHeader: true,
                            deleteHistory: deleteHistory
                        )
                    }
                    .navigationDestination(item: $selectedGameForDetails) { game in
                        GameDetailView(
                            game: game,
                            scoreState: scoreState(for: game),
                            evaluation: evaluatedScores[game.id],
                            resolvedContext: resolveGameContext(game),
                            supportedPlatforms: supportedPlatforms(for: game),
                            gameHistory: history.filter { $0.resolvedContext.context.gameID == game.id },
                            analyticsTracker: analyticsTracker,
                            onStartDeepCheck: { platform, externalLink in
                                if let resolved = resolveGameContext(game, platform: platform, declaredExternalLink: externalLink) {
                                    openDeepCheck(resolvedContext: resolved, platform: platform)
                                }
                            },
                            onOpenHistory: {
                                selectedGameForDetails = nil
                                showingHistory = true
                            }
                        )
                    }
            }
            .tabItem {
                Label(LocalizedStringKey("navigation.home"), systemImage: "house.fill")
            }
            .tag(AppTab.home)

            // Tab 2: Jogos
            NavigationStack {
                gamesCatalogView
                    .background(NolaggyScreenBackground())
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .navigationDestination(isPresented: $showingHistory) {
                        HistoryView(
                            entries: history,
                            gameName: gameName(for:),
                            retry: retryFromHistory,
                            returnToHome: { showingHistory = false },
                            openSettings: {
                                showingHistory = false
                                showingSettings = true
                            },
                            showsBackHeader: true,
                            deleteHistory: deleteHistory
                        )
                        .toolbar(.hidden, for: .tabBar)
                    }
                    .navigationDestination(item: $selectedGameForDetails) { game in
                        GameDetailView(
                            game: game,
                            scoreState: scoreState(for: game),
                            evaluation: evaluatedScores[game.id],
                            resolvedContext: resolveGameContext(game),
                            supportedPlatforms: supportedPlatforms(for: game),
                            gameHistory: history.filter { $0.resolvedContext.context.gameID == game.id },
                            analyticsTracker: analyticsTracker,
                            onStartDeepCheck: { platform, externalLink in
                                if let resolved = resolveGameContext(game, platform: platform, declaredExternalLink: externalLink) {
                                    openDeepCheck(resolvedContext: resolved, platform: platform)
                                }
                            },
                            onOpenHistory: {
                                selectedGameForDetails = nil
                                showingHistory = true
                            }
                        )
                    }
            }
            .tabItem {
                Label(LocalizedStringKey("navigation.games"), systemImage: "gamecontroller.fill")
            }
            .tag(AppTab.games)
        }
        .tint(NLColor.accentPrimary)
        .toolbarBackground(NLColor.backgroundRaised.opacity(0.9), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .preferredColorScheme(.dark)
        .onChange(of: selectedTab) { _, tab in
            // Ao sair da aba, uma entrada seguinte pela tab bar volta a ser um
            // destino de nível superior — portanto não herda um "Voltar" de
            // uma abertura anterior feita pela Home.
            if tab != .games {
                gamesReturnToHome = false
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { @MainActor in
                    await refreshLiveNetworkSignal()
                    _ = await PreMatchReminderStore.shared.revalidatePermission()
                }
            }
            guard phase == .background else { return }
            Task { @MainActor in
                await coordinator.appDidEnterBackground()
                // O Deep Check é descartado ao sair de primeiro plano. Fechar
                // a cobertura devolve a pessoa ao jogo escolhido, sem reter
                // resultado parcial nem deixar uma tela de medição órfã.
                deepCheckDestination = nil
                showingRegionalSelection = false
                let next = QuickCheckPresentationMapper.map(await coordinator.sessionState())
                if next != .measuring {
                    presentation = next
                }
            }
        }
        .task {
            if !hasTrackedAppOpen {
                hasTrackedAppOpen = true
                analyticsTracker.track(.appOpen)
            }
        }
        .environment(\.artworkDownloadsAllowed, artworkLoaderReady && !showingRegionalSelection && deepCheckDestination == nil && presentation != .measuring && scenePhase == .active)
        .task(id: showingRegionalSelection || deepCheckDestination != nil || presentation == .measuring || scenePhase != .active) {
            artworkLoaderReady = false
            let allowed = !showingRegionalSelection && deepCheckDestination == nil && presentation != .measuring && scenePhase == .active
            await VerifiedRemoteArtworkLoader.shared.setDownloadsEnabled(
                allowed
            )
            guard !Task.isCancelled else { return }
            artworkLoaderReady = allowed
        }
        .task { await loadHistory() }
        .task { await loadRegionalPreference() }
        .task {
            if ProcessInfo.processInfo.arguments.contains("-ui-fixture-games-tab") {
                selectedTab = .games
            }
        }
        .task {
            // Monitora o caminho de rede continuamente e reage a trocas (Wi-Fi, Celular, Offline)
            let stream = AsyncStream<Void> { continuation in
                let monitor = NWPathMonitor()
                let queue = DispatchQueue(label: "com.nolaggy.live-network-signal")
                monitor.pathUpdateHandler = { _ in
                    continuation.yield()
                }
                continuation.onTermination = { @Sendable _ in
                    monitor.cancel()
                }
                monitor.start(queue: queue)
            }
            for await _ in stream {
                await refreshLiveNetworkSignal()
            }
        }
        .sheet(isPresented: $showingDetails) {
            if let completedEntry {
                NavigationStack {
                    MeasurementDetailsView(entry: completedEntry, samples: partialSamples)
                }
            }
        }
        .fullScreenCover(item: $deepCheckDestination, onDismiss: { Task { await loadHistory() } }) { destination in
            DeepCheckFeatureView(
                resolvedContext: destination.resolvedContext,
                gameName: destination.gameName,
                historyRepository: historyRepository,
                analyticsTracker: analyticsTracker,
                onMeasurementCompleted: { samples, entry in
                    partialSamples = samples
                    if let entry {
                        completedEntry = entry
                    }
                }
            )
        }
        .sheet(isPresented: $showingCockpit) {
            NetworkCockpitView()
        }
        .onOpenURL { url in
            handleIncomingURL(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .lagCheckReminderOpened)) { note in
            guard let gameID = note.userInfo?["gameID"] as? String,
                  let game = availableGames.first(where: { $0.id == gameID }) else { return }
            selectedTab = .home
            selectedGameID = game.id
            presentation = .context
        }
        .onAppear { consumePendingPreMatchReminder() }
        .onChange(of: availableGames.map(\.id)) { _, ids in
            let reminder = PreMatchReminderStore.shared.value
            if reminder.enabled, let gameID = reminder.gameID, !ids.contains(gameID) { PreMatchReminderStore.shared.disable() }
            consumePendingPreMatchReminder()
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            guard let url = userActivity.webpageURL else { return }
            handleIncomingURL(url)
        }
        .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
            guard let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else { return }
            let prefix = "lagcheck.game."
            if identifier.hasPrefix(prefix) {
                let gameID = String(identifier.dropFirst(prefix.count))
                let encodedID = gameID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? gameID
                if let url = URL(string: "lagcheck://check?game=\(encodedID)") {
                    handleIncomingURL(url)
                }
            }
        }
    }

    /// Trata chamadas de deep link externas (esquema nativo ou Universal Links).
    /// Suporta:
    /// - `lagcheck://check?game=valorant` ou `https://lagcheck.signallq.com/check?game=valorant`: inicia o teste para o jogo.
    /// - `lagcheck://quicktest`: inicia o teste imediatamente em 1 toque na Home.
    /// - `lagcheck://network`: abre a aba de Dados da Rede (Cockpit).
    /// - `lagcheck://games`: navega para o catálogo de jogos.
    /// - `lagcheck://home`: navega para a tela inicial.
    func handleIncomingURL(_ url: URL) {
        guard let deepLink = DeepLinkParser.parse(url: url) else { return }

        switch deepLink {
        case let .quickCheck(gameID, platform, declaredExternalLink):
            selectedTab = .home
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000)
                if let gameID {
                    if let target = availableGames.first(where: { $0.id == gameID }) {
                        startCheckDirectly(for: target, platform: platform, declaredExternalLink: declaredExternalLink)
                    } else {
                        // Integridade diagnóstica (Decisão 50/76): Jogo desconhecido na URL
                        // NUNCA dispara teste silencioso de outro título; mantém na Home.
                    }
                } else {
                    // Sem parâmetro de jogo: inicia o check padrão da Home
                    startLagCheckFromCTA()
                }
            }
        case .gamesCatalog:
            selectedTab = .games
        case .networkCockpit:
            selectedTab = .home
            showingCockpit = true
        case .home:
            selectedTab = .home
        }
    }

    private func consumePendingPreMatchReminder() {
        guard let gameID = UserDefaults.standard.string(forKey: "pendingPreMatchReminderGameID"),
              let game = availableGames.first(where: { $0.id == gameID }) else { return }
        UserDefaults.standard.removeObject(forKey: "pendingPreMatchReminderGameID")
        selectedTab = .home; selectedGameID = game.id; presentation = .context
    }

    @ViewBuilder
    var measurementJourney: some View {
        switch presentation {
        case .context:
            contextView
        case .measuring:
            measurementView
        case let .result(result):
            resultView(result: result)
        case .inconclusive:
            statusView(kind: .inconclusive)
        case let .cancelled(reason):
            statusView(kind: .cancelled(reason))
        }
    }

    @ViewBuilder
    func header(title: LocalizedStringKey?, showsBack: Bool, showsSearch: Bool = false) -> some View {
        if !showsBack {
            NolaggyAppHeader(
                openSettings: { showingSettings = true }
            )
        } else {
            NolaggyBackHeader(action: back, accessibilityIdentifier: "measurement-back")
        }
    }

    func localized(_ key: String) -> LocalizedStringKey { LocalizedStringKey(key) }

    func localizedString(_ key: String) -> String { AppLocalization.string(key, comment: "") }

    func milliseconds(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(Int(value.rounded()))
    }

    func percentage(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    var regionLanguage: String {
        let ident = locale.identifier.lowercased()
        if ident.hasPrefix("pt") { return "pt-BR" }
        if ident.hasPrefix("es") { return "es" }
        return "en"
    }

    var regionCandidates: [RegionalReferenceCandidate] {
        guard remoteCatalog != nil else { return [] }
        let automatic = RegionalReferenceCandidate(
            id: RegionalPreferenceIdentifiers.automatic,
            label: AppLocalization.string("settings.region.automatic", comment: ""),
            continentKey: nil
        )
        let globalCandidates = GlobalProbeRegistry.allRegions.map { def in
            RegionalReferenceCandidate(
                id: def.id,
                label: def.localizedLabel(for: regionLanguage),
                continentKey: def.continent.localizationKey
            )
        }
        return [automatic] + globalCandidates
    }

    var selectedRegionFriendlyName: String {
        guard let regionID = selectedRegionalContext?.regionID else {
            return AppLocalization.string("quick_check.region.sao_paulo", comment: "")
        }
        return GlobalProbeRegistry.friendlyLabel(for: regionID, languageCode: regionLanguage)
    }

    var selectedRegionRouteSubtitle: String {
        String(format: AppLocalization.string("quick_check.measuring.region_format %@", comment: ""), selectedRegionFriendlyName)
    }

    func resolveGameContext(
        _ game: CatalogMeasurementJourney.Game,
        platform: Platform? = nil,
        declaredExternalLink: ExternalEquipmentLink? = nil
    ) -> ResolvedMeasurementContext? {
        guard let remoteCatalog else { return nil }

        // 1. Se uma plataforma específica foi solicitada, tenta ela primeiro
        if let platform {
            let context = GameContext(
                gameID: game.id,
                market: game.context.market,
                platform: platform,
                declaredExternalLink: platform == .iphone ? nil : declaredExternalLink
            )
            if case let .available(resolved) = try? RemoteCatalogVerifier.resolve(context, in: remoteCatalog) {
                return resolved
            }
        }

        // 2. Determina a melhor plataforma suportada automaticamente sem perguntar ao jogador:
        //    a) Preferência de plataforma global do jogador (se configurada)
        //    b) iPhone (se suportado pelo jogo)
        //    c) Plataforma nativa do game.context
        //    d) Qualquer plataforma suportada pelo catálogo (ex: PlayStation ou PC para Warzone/Valorant)
        var candidates: [Platform] = []
        if let preferred = preferredGamingPlatform {
            candidates.append(preferred)
        }
        candidates.append(.iphone)
        candidates.append(game.context.platform)
        candidates.append(contentsOf: supportedPlatforms(for: game))

        for candidate in candidates {
            let context = GameContext(
                gameID: game.id,
                market: game.context.market,
                platform: candidate,
                declaredExternalLink: candidate == .iphone ? nil : declaredExternalLink
            )
            if case let .available(resolved) = try? RemoteCatalogVerifier.resolve(context, in: remoteCatalog) {
                return resolved
            }
        }

        // 3. Fallback de resiliência: se o jogo existe no catálogo, usa o primeiro contexto disponível
        if let catalogGame = remoteCatalog.games.first(where: { $0.id == game.id }),
           let firstContext = catalogGame.contexts.first(where: { $0.market == game.context.market && $0.availability == .available }),
           let fallbackPlatform = firstContext.platforms.first {
            let context = GameContext(
                gameID: game.id,
                market: game.context.market,
                platform: fallbackPlatform,
                declaredExternalLink: fallbackPlatform == .iphone ? nil : declaredExternalLink
            )
            if case let .available(resolved) = try? RemoteCatalogVerifier.resolve(context, in: remoteCatalog) {
                return resolved
            }
        }

        return nil
    }

    func supportedPlatforms(for game: CatalogMeasurementJourney.Game) -> [Platform] {
        let order: [Platform] = [.iphone, .playstation, .xbox, .nintendo, .pc]
        if game.id == GameContext.genericGamingID {
            return order
        }
        guard let remoteCatalog,
              let catalogGame = remoteCatalog.games.first(where: { $0.id == game.id }) else {
            return []
        }
        return order.filter { platform in
            let context = GameContext(
                gameID: game.id,
                market: game.context.market,
                platform: platform,
                declaredExternalLink: nil
            )
            guard catalogGame.contexts.contains(where: {
                $0.market == game.context.market
                    && $0.platforms.contains(platform)
                    && $0.availability == .available
            }) else {
                return false
            }
            if case .available = try? RemoteCatalogVerifier.resolve(context, in: remoteCatalog) {
                return true
            }
            return false
        }
    }

    /// Inicia a medição de 1 toque diretamente para o jogo alvo sem abrir modal intermediário (Decisão 56).
    func startCheckDirectly(for game: CatalogMeasurementJourney.Game, platform: Platform? = nil, declaredExternalLink: ExternalEquipmentLink? = nil) {
        analyticsTracker.track(.gameSelected(gameID: game.id))
        if let resolved = resolveGameContext(game, platform: platform, declaredExternalLink: declaredExternalLink) {
            openDeepCheck(resolvedContext: resolved)
        } else {
            startGeneralGamingCheckDirectly()
        }
    }

    /// Inicia a medição de 1 toque diretamente da rota genérica de referência (Decisão 56).
    func startGeneralGamingCheckDirectly() {
        let market = remoteCatalog.map { CatalogMeasurementJourney.resolvedMarket(in: $0) } ?? "BR"
        let genericGame = CatalogMeasurementJourney.genericGamingGame(
            market: market,
            platform: preferredGamingPlatform ?? .iphone,
            declaredExternalLink: nil,
            localizedName: AppLocalization.string("generic_gaming.name", comment: "")
        )
        startCheckDirectly(for: genericGame)
    }
}

private extension RemoteCatalogResolution {
    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }
}

struct DeepCheckDestination: Identifiable {
    let id = UUID()
    let resolvedContext: ResolvedMeasurementContext
    let gameName: String
}
