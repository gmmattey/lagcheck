import SwiftUI
import NolaggyDesign
import UIKit
@preconcurrency import UserNotifications
import NolaggyApplication
import NolaggyDomain
import NolaggyInfrastructure

@main
struct NolaggyApp: App {
    @UIApplicationDelegateAdaptor(ReminderAppDelegate.self) private var reminderDelegate
    @AppStorage(AppLocalization.selectedLanguageKey) private var selectedLanguage: String = AppLanguage.system.rawValue
    private let historyRepository: any MeasurementHistoryRepository
    private let regionalPreferenceRepository: any RegionalPreferenceRepository
    private let catalogRepository: RemoteSyncedCatalogRepository
    private let analyticsCollectionPreference: AnalyticsCollectionPreference
    private let analyticsTracker: any AnalyticsTracker
    @State private var catalogState: CatalogState
    @Environment(\.scenePhase) private var scenePhase

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
        let analyticsCollectionPreference = AnalyticsCollectionPreference()
        self.analyticsCollectionPreference = analyticsCollectionPreference
        FirebaseAnalyticsRuntime.configure(collectionEnabled: analyticsCollectionPreference.isCollectionEnabled)
        analyticsTracker = CollectionGatedAnalyticsTracker(
            preference: analyticsCollectionPreference,
            tracker: CompositeAnalyticsTracker(trackers: [
                CloudflareWorkerAnalyticsTracker(),
                FirebaseAnalyticsTracker()
            ])
        )
        let base = DebugCatalogBase.envelopeData() ?? Data()
        catalogRepository = RemoteSyncedCatalogRepository(bundled: BundledCatalogRepository(envelopeData: base))
        if (UITestFixtures.isEnabled("-ui-fixture-confirmed-region") || UITestFixtures.isEnabled("-ui-fixture-inconclusive-history")),
           let data = DebugCatalogBase.envelopeData(),
           let payload = try? RemoteCatalogVerifier.decodeBundled(data) {
            _catalogState = State(initialValue: .ready(payload))
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
            .onOpenURL { url in
                handleInternalAnalyticsControl(url)
            }
            .task { IOSAdConsent.shared.updateForLaunchOrForeground() }
            .onChange(of: scenePhase, initial: false) { _, phase in
                if phase == .active { IOSAdConsent.shared.updateForLaunchOrForeground() }
            }
            .task {
                // A fixture mantém o mesmo catálogo assinado e a mesma jornada da
                // aplicação durante uma prova determinística de ciclo de vida em UI test.
                guard !UITestFixtures.isEnabled("-ui-fixture-confirmed-region"),
                      !UITestFixtures.isEnabled("-ui-fixture-inconclusive-history") else { return }
                await loadCatalogForHome()
            }
        }
    }

    @MainActor
    private func loadCatalogForHome() async {
        do {
            let payload = try await catalogRepository.loadLocal()
            catalogState = .ready(payload)

            // Indexa jogos no CoreSpotlight em background não-bloqueante (Decisão 76)
            let coordinator = SpotlightIndexCoordinator(indexer: AppleCoreSpotlightIndexer())
            await coordinator.indexCatalogGames(games: payload.games)

            if let updated = await catalogRepository.syncIfNeeded(),
               updated.catalogVersion != payload.catalogVersion {
                catalogState = .ready(updated)
                await coordinator.indexCatalogGames(games: updated.games)
            }
        } catch {
            // Sem base válida não existe descoberta nem sessão; a Home segue
            // navegável e a feature apresenta indisponibilidade explícita.
            catalogState = .unavailable
        }
    }

    private func handleInternalAnalyticsControl(_ url: URL) {
        guard url.scheme == "lagcheck", url.host == "internal", url.path == "/analytics",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let collection = components.queryItems?.first(where: { $0.name == "collection" })?.value
        else { return }

        switch collection.lowercased() {
        case "off":
            analyticsCollectionPreference.setOwnerExcluded(true)
        case "on":
            analyticsCollectionPreference.setOwnerExcluded(false)
        default:
            return
        }

        FirebaseAnalyticsRuntime.setCollectionEnabled(analyticsCollectionPreference.isCollectionEnabled)
    }
}

extension Notification.Name { static let lagCheckReminderOpened = Notification.Name("lagCheckReminderOpened") }

final class ReminderAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let gameID = response.notification.request.content.userInfo["gameID"] as? String {
            UserDefaults.standard.set(gameID, forKey: "pendingPreMatchReminderGameID")
            NotificationCenter.default.post(name: .lagCheckReminderOpened, object: nil, userInfo: ["gameID": gameID])
        }
        completionHandler()
    }
}

private enum CatalogState {
    case loading
    case ready(RemoteCatalogPayload)
    case unavailable

    var payload: RemoteCatalogPayload? {
        guard case let .ready(payload) = self else { return nil }
        return payload
    }

    var usesBundledBase: Bool {
        false
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
        return try? RemoteCatalogVerifier.decodeBundled(data)
    }()
}

private struct RegionalSelectionFixtureHost: View {
    @State private var presentation: RegionalSelectionPresentation
    @State private var returnedHome = false

    @State private var routeMap = RouteMapController()

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
                routeMap: routeMap,
                presentation: $presentation,
                onRetry: { presentation = .confirming },
                onBackOrCancel: { returnedHome = true }
            )
        }
    }
}
