import NolaggyApplication
import NolaggyDomain
import NolaggyInfrastructure

/// Único lugar que escolhe adaptadores reais, no-op de simulador e fixtures.
/// Não altera algoritmo, plano de probes ou contratos da sessão.
enum MeasurementTransportFactory {
    static func quickCheckTransport() -> any MeasurementTransport {
        #if !targetEnvironment(simulator)
        NWConnectionMeasurementTransport()
        #else
        NoopMeasurementTransport(completionDelay: .seconds(15))
        #endif
    }

    static func pathObserver() -> any NetworkPathObserver {
        UITestFixtures.isEnabled("-ui-fixture-confirmed-region") ? NoopNetworkPathObserver() : NWPathMonitorNetworkPathObserver()
    }

    static func regionalPreReadCollector() -> any RegionalPreReadCollecting {
        if UITestFixtures.isEnabled("-ui-fixture-confirmed-region") { return ConfirmedRegionalPreReadFixture() }
        #if !targetEnvironment(simulator)
        return NWRegionalPreReadCollector()
        #else
        return NoopRegionalPreReadCollector()
        #endif
    }

    static func quickCheckPlan(for context: ResolvedMeasurementContext) -> QuickCheckPlan {
        QuickCheckPlan(endpoint: MeasurementEndpoint(
            host: context.destination.host,
            port: context.destination.port,
            protocolKind: context.probeProtocol
        ))
    }

    static func deepCheckCoordinator(historyRepository: any MeasurementHistoryRepository) -> DeepCheckSessionCoordinator {
        #if !targetEnvironment(simulator)
        DeepCheckSessionCoordinator(transport: NWConnectionMeasurementTransport(), loadTransport: URLSessionLoadTransport(), pathObserver: NWPathMonitorNetworkPathObserver(), wifiAvailability: NWPathWiFiAvailability(), historyRepository: historyRepository)
        #else
        DeepCheckSessionCoordinator(transport: NoopMeasurementTransport(), loadTransport: NoopLoadTransport(), pathObserver: NoopNetworkPathObserver(), wifiAvailability: NoopWiFiAvailability(), historyRepository: historyRepository)
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
