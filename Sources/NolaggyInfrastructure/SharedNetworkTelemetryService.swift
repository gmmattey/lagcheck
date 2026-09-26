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
            let prober = BSDWiFiLocalGatewayProber()
            let local = prober.resolveLocalIPv4()
            let gw = prober.resolveDefaultGatewayIPv4()
            self.localIP = local
            self.gatewayIP = gw

            let telemetry = await prober.probeLocalGateway(sampleCount: 3, timeoutPerSampleSeconds: 0.3)
            self.gatewayRTTMs = telemetry.gatewayRTTMedianMs
            self.isWiFi = telemetry.isWiFi

            if telemetry.isWiFi {
                let eval = WiFiBandEvaluator.evaluate(telemetry: telemetry)
                if eval.diagnostic.isSuspectOrConfirmed24GHz {
                    self.wifiBand = "2.4 GHz"
                    self.connectionKindText = "Wi-Fi (2.4 GHz)"
                } else {
                    switch eval.diagnostic {
                    case .confirmed5GHzOrHigher, .stableWiFi:
                        self.wifiBand = "5 GHz"
                        self.connectionKindText = "Wi-Fi (5 GHz)"
                    case .inconclusive:
                        self.wifiBand = "Padrão"
                        self.connectionKindText = "Wi-Fi"
                    default:
                        self.wifiBand = "Wi-Fi"
                        self.connectionKindText = "Wi-Fi"
                    }
                }
            } else {
                self.wifiBand = "—"
                self.connectionKindText = "Dados Móveis (Celular)"
            }

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
