import Foundation
import SwiftUI
import Combine
import NolaggyDomain

/// Serviço centralizado e único da verdade para telemetria da rede local e borda WAN.
/// Garante que nenhuma tela (Cockpit, Home ou Export) mostre valores divergentes de RTT ou interface.
@MainActor
public final class SharedNetworkTelemetryService: ObservableObject {
    public static let shared = SharedNetworkTelemetryService()

    @Published public private(set) var localIP: String? = nil
    @Published public private(set) var gatewayIP: String? = nil
    @Published public private(set) var gatewayRTTMs: Double? = nil
    @Published public private(set) var wifiBand: String = "—"
    @Published public private(set) var connectionKindText: String = "Detectando..."
    @Published public private(set) var isWiFi: Bool = true
    @Published public private(set) var natTopology: NATTopologySnapshot? = nil
    @Published public private(set) var isProbing: Bool = false
    @Published public private(set) var lastUpdated: Date? = nil
    private var activeProbeTask: Task<Void, Never>? = nil

    public init() {}

    /// Atualiza toda a telemetria de forma determinística e atômica.
    public func refreshTelemetry(force: Bool = false) async {
        if let active = activeProbeTask, !force {
            await active.value
            return
        }

        let task = Task { @MainActor in
            self.isProbing = true
            let snapshot = await LocalNetworkTelemetrySnapshot.capture()
            let telemetry = snapshot.telemetry
            let presentation = LocalNetworkTelemetryPresentation(snapshot: snapshot)
            let local = snapshot.localIP
            self.localIP = local
            self.gatewayIP = snapshot.gatewayIP
            self.gatewayRTTMs = telemetry.gatewayRTTMedianMs
            self.isWiFi = telemetry.isWiFi
            self.wifiBand = presentation.wifiBand
            self.connectionKindText = presentation.connectionKind
            // Aferição de Topologia WAN via STUN
            let stunClient = StunProbeClient()
            self.natTopology = await stunClient.probeTopology(localIP: local)

            self.lastUpdated = Date()
            self.isProbing = false
        }

        self.activeProbeTask = task
        await task.value
        self.activeProbeTask = nil
    }

}
