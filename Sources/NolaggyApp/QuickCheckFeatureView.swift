import SwiftUI
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
    @State var selectedTab: AppTab = .home
    @State var showingSettings = false
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
    @State var evaluatedScores: [String: MeasurementEvaluation] = [:]
    @State var isBackgroundMeasuring = false
    @State var backgroundMeasurementFailed = false
    @State var selectedGameForDetails: CatalogMeasurementJourney.Game?
    @State var gameForPlatformSelection: CatalogMeasurementJourney.Game?

    let historyRepository: any MeasurementHistoryRepository
    let regionalPreferenceRepository: any RegionalPreferenceRepository
    let remoteCatalog: RemoteCatalogPayload?
    let usesCatalogFallback: Bool
    let usesUIFixture: Bool
    let appConfiguration: NolaggyAppConfiguration

    /// Jogo efetivamente relevante agora: a escolha explícita do usuário, ou,
    /// só na ausência de qualquer histórico (primeiro uso), o primeiro jogo do
    /// catálogo — para que a primeira abertura ainda tenha um caminho rápido.
    /// Com histórico e sem escolha explícita, a Home não compete consigo
    /// mesma: a última medição é a única oferta primária.
    var effectiveGameID: String? {
        selectedGameID ?? (history.isEmpty ? availableGames.first?.id : nil)
    }

    var context: GameContext? {
        availableGames.first(where: { $0.id == effectiveGameID })?.context
    }

    init(
        historyRepository: any MeasurementHistoryRepository = NoopMeasurementHistoryRepository(),
        regionalPreferenceRepository: any RegionalPreferenceRepository = NoopRegionalPreferenceRepository(),
        remoteCatalog: RemoteCatalogPayload? = nil,
        usesCatalogFallback: Bool = false,
        appConfiguration: NolaggyAppConfiguration = NolaggyAppConfiguration()
    ) {
        self.historyRepository = historyRepository
        self.regionalPreferenceRepository = regionalPreferenceRepository
        self.remoteCatalog = remoteCatalog
        self.usesCatalogFallback = usesCatalogFallback
        self.appConfiguration = appConfiguration
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
            initialPresentation = .result(fixture.result)
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
                                selectedTab = .history
                            }
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
                            onStartDeepCheck: { platform in
                                if let resolved = resolveGameContext(game, platform: platform) {
                                    openDeepCheck(resolvedContext: resolved, platform: platform)
                                }
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
                    .navigationDestination(item: $selectedGameForDetails) { game in
                        GameDetailView(
                            game: game,
                            scoreState: scoreState(for: game),
                            evaluation: evaluatedScores[game.id],
                            resolvedContext: resolveGameContext(game),
                            supportedPlatforms: supportedPlatforms(for: game),
                            gameHistory: history.filter { $0.resolvedContext.context.gameID == game.id },
                            onStartDeepCheck: { platform in
                                if let resolved = resolveGameContext(game, platform: platform) {
                                    openDeepCheck(resolvedContext: resolved, platform: platform)
                                }
                            }
                        )
                    }
            }
            .tabItem {
                Label(LocalizedStringKey("navigation.games"), systemImage: "gamecontroller.fill")
            }
            .tag(AppTab.games)

            // Tab 3: Histórico
            NavigationStack {
                HistoryView(
                    entries: history,
                    gameName: gameName(for:),
                    retry: retryFromHistory,
                    returnToHome: { selectedTab = .home },
                    openSettings: { selectedTab = .settings },
                    showsBackHeader: false
                )
                .background(NolaggyScreenBackground())
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
            }
            .tabItem {
                Label(LocalizedStringKey("history.title"), systemImage: "clock.arrow.circlepath")
            }
            .tag(AppTab.history)

            // Tab 4: Ajustes
            NavigationStack {
                SettingsView(
                    configuration: appConfiguration,
                    regionCandidates: regionCandidates,
                    manualRegionID: manualRegionID,
                    onSelectRegion: selectRegionPreference,
                    deleteHistory: deleteHistory,
                    showHistory: { selectedTab = .history },
                    showsBackHeader: false
                )
                .background(NolaggyScreenBackground())
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
            }
            .tabItem {
                Label(LocalizedStringKey("settings.title"), systemImage: "gearshape.fill")
            }
            .tag(AppTab.settings)
        }
        .tint(NLColor.accentPrimary)
        .toolbarBackground(NLColor.backgroundRaised.opacity(0.9), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .background else { return }
            Task { @MainActor in
                await coordinator.appDidEnterBackground()
                deepCheckDestination = nil
                showingRegionalSelection = false
                let next = QuickCheckPresentationMapper.map(await coordinator.sessionState())
                if next != .measuring {
                    presentation = next
                }
            }
        }
        .task { await loadHistory() }
        .task { await loadRegionalPreference() }
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
                historyRepository: historyRepository
            )
        }
        .sheet(item: $gameForPlatformSelection) { game in
            PlatformSelectionSheet(
                gameName: game.name,
                supportedPlatforms: supportedPlatforms(for: game),
                onSelectPlatform: { platform in
                    selectedGameID = game.id
                    if let resolved = resolveGameContext(game, platform: platform) {
                        startQuickCheck(resolvedContext: resolved)
                    }
                }
            )
        }
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
                NolaggyAppHeader(openSettings: { showingSettings = true })
        } else {
            NolaggyBackHeader(action: back, accessibilityIdentifier: "quick-check-back")
        }
    }

    func localized(_ key: String) -> LocalizedStringKey { LocalizedStringKey(key) }

    func localizedString(_ key: String) -> String { NSLocalizedString(key, comment: "") }

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
            label: NSLocalizedString("settings.region.automatic", comment: ""),
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
            return NSLocalizedString("quick_check.region.sao_paulo", comment: "")
        }
        return GlobalProbeRegistry.friendlyLabel(for: regionID, languageCode: regionLanguage)
    }

    var selectedRegionRouteSubtitle: String {
        String(format: NSLocalizedString("quick_check.measuring.region_format %@", comment: ""), selectedRegionFriendlyName)
    }

    func resolveGameContext(_ game: CatalogMeasurementJourney.Game, platform: Platform = .iphone) -> ResolvedMeasurementContext? {
        guard let remoteCatalog else { return nil }
        let selectedGameContext = GameContext(
            gameID: game.id,
            market: game.context.market,
            platform: platform,
            equipmentConnection: game.context.equipmentConnection
        )
        if case let .available(resolved) = try? RemoteCatalogVerifier.resolve(selectedGameContext, in: remoteCatalog) {
            return resolved
        }
        return nil
    }

    func supportedPlatforms(for game: CatalogMeasurementJourney.Game) -> [Platform] {
        guard let remoteCatalog,
              let catalogGame = remoteCatalog.games.first(where: { $0.id == game.id }) else {
            return []
        }
        let order: [Platform] = [.iphone, .playstation, .xbox, .nintendo, .pc]
        return order.filter { platform in
            let context = GameContext(
                gameID: game.id,
                market: game.context.market,
                platform: platform,
                equipmentConnection: game.context.equipmentConnection
            )
            guard catalogGame.contexts.contains(where: {
                $0.market == game.context.market
                    && $0.platforms.contains(platform)
                    && $0.availability == .available
                    && $0.measurement != nil
            }) else {
                return false
            }
            if case .available = try? RemoteCatalogVerifier.resolve(context, in: remoteCatalog) {
                return true
            }
            return false
        }
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
