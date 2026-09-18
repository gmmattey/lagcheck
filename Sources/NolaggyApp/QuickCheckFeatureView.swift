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
        usesUIFixture = UITestFixtures.isEnabled(UITestFixtures.launchArgument)
        let fixture = usesUIFixture ? UITestFixtures.validEntry : nil
        let measuringFixture = UITestFixtures.isEnabled("-ui-fixture-measuring")
        _presentation = State(initialValue: measuringFixture ? .measuring : (fixture.map { .result($0.result) } ?? .context))
        _completedEntry = State(initialValue: fixture)
        _history = State(initialValue: fixture.map { [$0] } ?? [])
        _partialSamples = State(initialValue: fixture == nil ? [] : UITestFixtures.validSamples)
        // Uma entrada preserva o contexto resolvido que produziu seu score.
        // A fixture de resultado precisa mantê-lo também para que a jornada
        // Quick resultado → Deep use o mesmo contexto, não um catálogo inferido.
        _selectedRegionalContext = State(initialValue: fixture?.resolvedContext)
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
                            onStartDeepCheck: {
                                if let resolved = resolveGameContext(game) {
                                    openDeepCheck(resolvedContext: resolved)
                                }
                            }
                        )
                    }
            }
            .tabItem {
                Label("Início", systemImage: "house.fill")
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
                            onStartDeepCheck: {
                                if let resolved = resolveGameContext(game) {
                                    openDeepCheck(resolvedContext: resolved)
                                }
                            }
                        )
                    }
            }
            .tabItem {
                Label("Jogos", systemImage: "gamecontroller.fill")
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
                Label("history.title", systemImage: "clock.arrow.circlepath")
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
                Label("Ajustes", systemImage: "gearshape.fill")
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
        Locale.current.identifier.lowercased().hasPrefix("pt") ? "pt-BR" : "en"
    }

    var regionCandidates: [RegionalReferenceCandidate] {
        guard let remoteCatalog else { return [] }
        let automatic = RegionalReferenceCandidate(
            id: RegionalPreferenceIdentifiers.automatic,
            label: NSLocalizedString("settings.region.automatic", comment: "")
        )
        let regions = remoteCatalog.regions.map { region in
            RegionalReferenceCandidate(id: region.id, label: region.label[regionLanguage] ?? region.id)
        }
        return [automatic] + regions
    }

    func resolveGameContext(_ game: CatalogMeasurementJourney.Game) -> ResolvedMeasurementContext? {
        guard let remoteCatalog else { return nil }
        if case let .available(resolved) = try? RemoteCatalogVerifier.resolve(game.context, in: remoteCatalog) {
            return resolved
        }
        return nil
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
