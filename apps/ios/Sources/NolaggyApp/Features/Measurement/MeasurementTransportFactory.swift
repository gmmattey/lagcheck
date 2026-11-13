import Foundation
import NolaggyApplication
import NolaggyDomain
import NolaggyInfrastructure

/// Único lugar que escolhe adaptadores reais, no-op de simulador e fixtures.
/// Não altera algoritmo, plano de probes ou contratos da sessão.
enum MeasurementTransportFactory {
    /// Aparelho: sempre rede real. Simulador: no-op, exceto em DEBUG com
    /// `-simulator-real-network`, que usa os mesmos adaptadores UDP reais do
    /// aparelho (para validar o mapa de medição com sondas de verdade).
    static var usesRealNetwork: Bool {
        #if !targetEnvironment(simulator)
        return true
        #elseif DEBUG
        return ProcessInfo.processInfo.arguments.contains("-simulator-real-network")
        #else
        return false
        #endif
    }

    static func quickCheckTransport() -> any MeasurementTransport {
        usesRealNetwork ? NWConnectionMeasurementTransport() : NoopMeasurementTransport(completionDelay: .seconds(15))
    }

    static func pathObserver() -> any NetworkPathObserver {
        UITestFixtures.isEnabled("-ui-fixture-confirmed-region") ? NoopNetworkPathObserver() : NWPathMonitorNetworkPathObserver()
    }

    /// `onEvent` recebe envios e respostas reais da pré-leitura (mapa de medição).
    /// Fixtures e simulador não emitem eventos: nada se move sem sonda real.
    static func regionalPreReadCollector(onEvent: RegionalPreReadEventHandler? = nil) -> any RegionalPreReadCollecting {
        if UITestFixtures.isEnabled("-ui-fixture-confirmed-region") { return ConfirmedRegionalPreReadFixture() }
        return usesRealNetwork ? NWRegionalPreReadCollector(onEvent: onEvent) : NoopRegionalPreReadCollector()
    }

    static func quickCheckPlan(for context: ResolvedMeasurementContext) -> QuickCheckPlan {
        QuickCheckPlan(endpoint: MeasurementEndpoint(
            host: context.destination.host,
            port: context.destination.port,
            protocolKind: context.destination.protocolKind
        ))
    }

    static func deepCheckCoordinator(historyRepository: any MeasurementHistoryRepository) -> DeepCheckSessionCoordinator {
        if UITestFixtures.isEnabled("-ui-fixture-cellular-consent") {
            return DeepCheckSessionCoordinator(
                transport: NoopMeasurementTransport(),
                loadTransport: NoopLoadTransport(),
                pathObserver: NoopNetworkPathObserver(),
                wifiAvailability: CellularConsentFixtureAvailability(),
                historyRepository: historyRepository
            )
        }
        if usesRealNetwork {
            return DeepCheckSessionCoordinator(transport: NWConnectionMeasurementTransport(), loadTransport: URLSessionLoadTransport(), pathObserver: NWPathMonitorNetworkPathObserver(), wifiAvailability: NWPathWiFiAvailability(), historyRepository: historyRepository)
        }
        return DeepCheckSessionCoordinator(transport: NoopMeasurementTransport(), loadTransport: NoopLoadTransport(), pathObserver: NoopNetworkPathObserver(), wifiAvailability: NoopWiFiAvailability(), historyRepository: historyRepository)
    }
}

/// Fixture restrita a DEBUG para exercitar o ponto de consentimento antes de
/// qualquer transporte. Não simula uma medição nem produz resultado.
private struct CellularConsentFixtureAvailability: WiFiAvailability {
    func isWiFiAvailable() async -> Bool { false }
    func isCellularAvailable() async -> Bool { true }
    func currentInterface() async -> NetworkInterfaceType { .cellular }
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
