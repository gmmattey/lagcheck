import SwiftUI
import NolaggyApplication
import NolaggyDomain
import NolaggyInfrastructure

@main
struct NolaggyApp: App {
    @AppStorage(AppLocalization.selectedLanguageKey) private var selectedLanguage: String = AppLanguage.system.rawValue
    private let historyRepository: any MeasurementHistoryRepository
    private let regionalPreferenceRepository: any RegionalPreferenceRepository
    private let catalogRepository: RemoteCatalogRepository
    private let analyticsTracker: any AnalyticsTracker
    @State private var catalogState: CatalogState

    private var currentLanguage: AppLanguage {
        AppLanguage(rawValue: selectedLanguage) ?? .system
    }

    private var currentLocale: Locale {
        currentLanguage.locale
    }

    init() {
        // Cada cenário de UI começa no idioma do sistema. Diferente de passar
        // `-app_selected_language system`, isto não cria uma camada de
        // argumentos que impeça a pessoa de trocar de idioma durante o teste.
        if UITestFixtures.isEnabled(UITestFixtures.resetLanguageArgument) {
            UserDefaults.standard.removeObject(forKey: AppLocalization.selectedLanguageKey)
        }
        historyRepository = (try? SwiftDataMeasurementHistoryRepository()) ?? NoopMeasurementHistoryRepository()
        regionalPreferenceRepository = UserDefaultsRegionalPreferenceRepository()
        analyticsTracker = CloudflareWorkerAnalyticsTracker()
        let base = DebugCatalogBase.envelopeData() ?? Data()
        catalogRepository = RemoteCatalogRepository(
            baseEnvelopeData: base,
            fetcher: URLSessionRemoteCatalogFetcher(url: URL(string: "https://nolaggy-deep-check.buildealabs.workers.dev/v1/catalog.json")!),
            cache: UserDefaultsRemoteCatalogCache()
        )
        if (UITestFixtures.isEnabled("-ui-fixture-confirmed-region") || UITestFixtures.isEnabled("-ui-fixture-inconclusive-history")),
           let data = DebugCatalogBase.envelopeData(),
           let payload = try? RemoteCatalogVerifier.verifyAndDecode(envelopeData: data) {
            _catalogState = State(initialValue: .ready(LoadedRemoteCatalog(payload: payload, source: .bundledBase)))
        } else {
            _catalogState = State(initialValue: .loading)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let regionalPresentation = RegionalSelectionUITestFixture.presentation {
                    RegionalSelectionFixtureHost(presentation: regionalPresentation)
                } else if UITestFixtures.isEnabled("-ui-fixture-deep-standalone") {
                    DeepCheckFeatureView(
                        resolvedContext: try! PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "BR", platform: .iphone)),
                        gameName: "Fortnite",
                        historyRepository: historyRepository,
                        analyticsTracker: analyticsTracker
                    )
                } else {
                    QuickCheckFeatureView(
                        historyRepository: historyRepository,
                        regionalPreferenceRepository: regionalPreferenceRepository,
                        remoteCatalog: catalogState.payload,
                        usesCatalogFallback: catalogState.usesBundledBase,
                        analyticsTracker: analyticsTracker
                    )
                }
            }
            .environment(\.locale, currentLocale)
            .task {
                // A fixture mantém o mesmo catálogo assinado e a mesma jornada da
                // aplicação, mas não permite que o refresh remoto recompose a Home
                // durante uma prova determinística de ciclo de vida em UI test.
                guard !UITestFixtures.isEnabled("-ui-fixture-confirmed-region"),
                      !UITestFixtures.isEnabled("-ui-fixture-inconclusive-history") else { return }
                await loadCatalogForHome()
                await catalogRepository.refreshIfDue()
                await loadCatalogForHome()
            }
        }
    }

    @MainActor
    private func loadCatalogForHome() async {
        do {
            let loaded = try await catalogRepository.loadedCatalogForLaunch()
            catalogState = .ready(loaded)
        } catch {
            // Sem base válida não existe descoberta nem sessão; a Home segue
            // navegável e a feature apresenta indisponibilidade explícita.
            catalogState = .unavailable
        }
    }
}

private enum CatalogState {
    case loading
    case ready(LoadedRemoteCatalog)
    case unavailable

    var payload: RemoteCatalogPayload? {
        guard case let .ready(loaded) = self else { return nil }
        return loaded.payload
    }

    var usesBundledBase: Bool {
        guard case let .ready(loaded) = self else { return false }
        return loaded.source == .bundledBase
    }
}

/// A seleção regional não tem mais telas intermediárias de sugestão/escolha
/// manual — é sempre automática (ver `RegionalPreferenceRepository` para o
/// override persistido em Configurações). Só restam dois estados visuais
/// nesta jornada: carregando e "nenhum candidato viável".
private enum RegionalSelectionUITestFixture {
    static var presentation: RegionalSelectionPresentation? {
        if UITestFixtures.isEnabled("-ui-fixture-regional-confirming") { return .confirming }
        if UITestFixtures.isEnabled("-ui-fixture-regional-no-viable") { return .noViableCandidate }
        return nil
    }

    static let catalog: RemoteCatalogPayload? = {
        guard let data = DebugCatalogBase.envelopeData() else { return nil }
        return try? RemoteCatalogVerifier.verifyAndDecode(envelopeData: data)
    }()
}

private struct RegionalSelectionFixtureHost: View {
    @State private var presentation: RegionalSelectionPresentation
    @State private var returnedHome = false

    init(presentation: RegionalSelectionPresentation) {
        _presentation = State(initialValue: presentation)
    }

    var body: some View {
        if returnedHome {
            QuickCheckFeatureView(
                remoteCatalog: RegionalSelectionUITestFixture.catalog,
                usesCatalogFallback: true
            )
        } else {
            RegionalSelectionFeatureView(
                gameTitle: "Fortnite",
                presentation: $presentation,
                onRetry: { presentation = .confirming },
                onBackOrCancel: { returnedHome = true }
            )
        }
    }
}
