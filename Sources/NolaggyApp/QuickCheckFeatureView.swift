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
    @State var showingSettings = false
    @State var activeCover: ActiveCover?
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
            transport: QuickCheckTransportComposition.make(),
            pathObserver: MeasurementPathObserverComposition.make(),
            historyRepository: historyRepository
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    switch destination {
                    case .home:
                        measurementJourney
                    case .history:
                        HistoryView(
                            entries: history,
                            gameName: gameName(for:),
                            retry: retryFromHistory,
                            returnToHome: { destination = .home },
                            openSettings: { showingSettings = true }
                        )
                    }
                }
            }
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
                        destination = .history
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .background else { return }
            Task { @MainActor in
                await coordinator.appDidEnterBackground()
                activeCover = nil
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
                MeasurementDetailsView(entry: completedEntry, samples: partialSamples)
            }
        }
        .fullScreenCover(item: $activeCover, onDismiss: { Task { await loadHistory() } }) { cover in
            switch cover {
            case .deep:
                if let selectedRegionalContext {
                    DeepCheckFeatureView(
                        resolvedContext: selectedRegionalContext,
                        gameName: gameName(forGameID: selectedRegionalContext.context.gameID),
                        historyRepository: historyRepository
                    )
                }
            case .regional:
                EmptyView()
            }
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
            if showsSearch {
                NolaggyAppHeader(
                    openSettings: { showingSettings = true },
                    openSearch: { openGameSearch() }
                )
            } else {
                NolaggyAppHeader(openSettings: { showingSettings = true })
            }
        } else {
            NolaggyBackHeader(action: back, accessibilityIdentifier: "quick-check-back")
        }
    }

    func retest(_ entry: MeasurementHistoryEntry) {
        guard availableGames.contains(where: { $0.id == entry.resolvedContext.context.gameID }) else { return }
        selectedGameID = entry.resolvedContext.context.gameID
        selectedRegionalContext = entry.resolvedContext
        start()
    }

    /// Início da jornada: resolve o contexto e dispara a seleção regional, que
    /// é sempre automática (ou aplica a preferência manual salva em
    /// Configurações). Não há tela de confirmação nem segundo toque — assim
    /// que um candidato é decidido, a medição já começa.
    func start() {
        guard let remoteCatalog, let context else {
            return
        }
        let snapshot: RegionalSelectionSnapshot
        do {
            snapshot = try CatalogMeasurementJourney.regionalSnapshot(for: context, in: remoteCatalog)
        } catch {
            return
        }
        regionalPresentation = .confirming
        showingRegionalSelection = true
        Task { @MainActor in
            // Deixa a transição de apresentação ser renderizada antes da
            // pré-leitura. Em fixtures o coletor pode concluir no mesmo turno
            // do MainActor; sem separar a tarefa, a cobertura não recebe o
            // estado de carregamento para apresentar.
            await Task.yield()
            let manualRegionID = await regionalPreferenceRepository.manualRegionID()
            await performRegionalPreRead(snapshot: snapshot, manualRegionID: manualRegionID)
        }
    }

    func performRegionalPreRead(snapshot: RegionalSelectionSnapshot, manualRegionID: String? = nil) async {
        let decision: RegionalSelectionDecision
        do {
            decision = try await coordinator.selectRegionalCandidate(
                snapshot: snapshot,
                using: RegionalPreReadCoordinator(collector: RegionalPreReadTransportComposition.make()),
                manualRegionID: manualRegionID
            )
        } catch RegionalSelectionError.manualCandidateNotAllowed where manualRegionID != nil {
            // A preferência salva em Configurações não existe neste contexto
            // (jogo/mercado/plataforma diferente); cai para automático em vez
            // de falhar a sessão inteira por causa de uma preferência antiga.
            await performRegionalPreRead(snapshot: snapshot, manualRegionID: nil)
            return
        } catch {
            return
        }
        switch decision {
        case let .selected(selection):
            startQuickCheck(resolvedContext: selection.selected.resolvedContext)
        case .inconclusive:
            regionalPresentation = .noViableCandidate
        }
    }

    func retryRegionalPreRead() {
        guard let remoteCatalog, let context,
              let snapshot = try? CatalogMeasurementJourney.regionalSnapshot(for: context, in: remoteCatalog) else { return }
        regionalPresentation = .confirming
        Task { @MainActor in
            let manualRegionID = await regionalPreferenceRepository.manualRegionID()
            await performRegionalPreRead(snapshot: snapshot, manualRegionID: manualRegionID)
        }
    }

    func cancelRegionalSelection() {
        Task { @MainActor in
            await coordinator.cancelRegionalPreRead()
            activeCover = nil
            showingRegionalSelection = false
        }
    }

    func startQuickCheck(resolvedContext: ResolvedMeasurementContext) {
        Task { @MainActor in
            selectedRegionalContext = resolvedContext
            activeCover = nil
            showingRegionalSelection = false
            do {
                let plan = QuickCheckPlan(
                    endpoint: MeasurementEndpoint(
                        host: resolvedContext.destination.host,
                        port: resolvedContext.destination.port
                    )
                )
                _ = try await coordinator.startQuickCheck(resolvedContext: resolvedContext, plan: plan)
                presentation = .measuring
                await awaitTerminalState()
            } catch {
                return
            }
        }
    }

    func restart() {
        completedEntry = nil
        partialSamples = []
        selectedRegionalContext = nil
        presentation = .context
    }

    func back() {
        Task { @MainActor in
            if let session = await coordinator.currentSession() {
                await coordinator.cancel(id: session.id)
                presentation = .cancelled(.userInitiated)
            } else {
                presentation = .context
            }
        }
    }

    func awaitTerminalState() async {
        while true {
            if let progress = await coordinator.measurementProgress() {
                partialSamples = progress.receivedSamples
            }
            // Uma única leitura do estado da sessão: derivar `next` e o `entry`
            // dela evita duas chamadas separadas ao ator divergirem entre si.
            let state = await coordinator.sessionState()
            let next = QuickCheckPresentationMapper.map(state)
            if next != .measuring {
                if case let .completed(_, _, entry?) = state {
                    // completedEntry (e as amostras finais) precisam estar prontos
                    // ANTES de `presentation` virar `.result` — só isso libera o
                    // botão "Ver detalhes" na tela. Se a ordem fosse invertida,
                    // um toque rápido logo após o resultado podia abrir a folha
                    // de detalhes com `completedEntry` ainda nulo: sheet vazia,
                    // sem conteúdo e sem botão de voltar.
                    completedEntry = entry
                    partialSamples = await coordinator.completedProbeSamples()
                    await loadHistory()
                }
                presentation = next
                return
            }
            try? await Task.sleep(for: .milliseconds(100))
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

    func loadHistory() async {
        guard !usesUIFixture else { return }
        history = (try? await historyRepository.loadHistory()) ?? []
    }

    func retryFromHistory(_ entry: MeasurementHistoryEntry) {
        destination = .home
        // Mesmo caminho do reteste a partir da última medição na Home: usa
        // exatamente o jogo da entrada (nunca infere outro) e já inicia a
        // medição — "Testar novamente" não deveria só devolver para a Home.
        retest(entry)
    }

    func gameName(for entry: MeasurementHistoryEntry) -> String {
        gameName(forGameID: entry.resolvedContext.context.gameID)
    }

    func gameName(forGameID gameID: String) -> String {
        availableGames.first(where: { $0.id == gameID })?.name
            ?? NSLocalizedString("game.unknown", comment: "")
    }

    func deleteHistory() async throws {
        try await historyRepository.deleteAll()
        await loadHistory()
    }

    func loadRegionalPreference() async {
        manualRegionID = await regionalPreferenceRepository.manualRegionID()
    }

    func selectRegionPreference(_ candidate: RegionalReferenceCandidate) {
        let newValue = candidate.id == RegionalPreferenceIdentifiers.automatic ? nil : candidate.id
        manualRegionID = newValue
        Task { await regionalPreferenceRepository.setManualRegionID(newValue) }
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
}

private extension RemoteCatalogResolution {
    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }
}

/// Em iPhone físico, Debug e Release usam a medição UDP real. O simulador usa
/// Noop porque não é evidência de rede; fixtures de UI são escolhidas apenas
/// por argumentos explícitos de inicialização.
private enum QuickCheckTransportComposition {
    static func make() -> any MeasurementTransport {
        #if !targetEnvironment(simulator)
        NWConnectionMeasurementTransport()
        #else
        NoopMeasurementTransport(completionDelay: .seconds(15))
        #endif
    }
}

private enum MeasurementPathObserverComposition {
    static func make() -> any NetworkPathObserver {
        if UITestFixtures.isEnabled("-ui-fixture-confirmed-region") {
            return NoopNetworkPathObserver()
        }
        return NWPathMonitorNetworkPathObserver()
    }
}

private enum RegionalPreReadTransportComposition {
    static func make() -> any RegionalPreReadCollecting {
        if UITestFixtures.isEnabled("-ui-fixture-confirmed-region") {
            return ConfirmedRegionalPreReadFixture()
        }
        #if !targetEnvironment(simulator)
        return NWRegionalPreReadCollector()
        #else
        return NoopRegionalPreReadCollector()
        #endif
    }
}

private struct ConfirmedRegionalPreReadFixture: RegionalPreReadCollecting {
    func collect(candidate: RegionalSelectionCandidate) async -> [RegionalPreReadSample] {
        [20, 21, 22].map { RegionalPreReadSample(outcome: .received, roundTripMilliseconds: Double($0)) }
    }
}

private struct NoopRegionalPreReadCollector: RegionalPreReadCollecting {
    func collect(candidate: RegionalSelectionCandidate) async -> [RegionalPreReadSample] {
        Array(repeating: RegionalPreReadSample(outcome: .timeout), count: 3)
    }
}

enum ActiveCover: String, Identifiable { case deep, regional; var id: String { rawValue } }
