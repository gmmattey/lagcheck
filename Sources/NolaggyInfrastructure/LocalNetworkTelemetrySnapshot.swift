import Foundation
import NolaggyDomain

/// Leitura pontual usada pelo Cockpit.
///
/// iOS público não entrega a frequência Wi-Fi diretamente ao app. A
/// apresentação nunca transforma nome de SSID, RTT ou jitter em "2.4 GHz" ou
/// "5 GHz".
public struct LocalNetworkTelemetrySnapshot: Sendable {
    public let localIP: String?
    public let gatewayIP: String?
    public let telemetry: WiFiLocalTelemetry

    public init(localIP: String?, gatewayIP: String?, telemetry: WiFiLocalTelemetry) {
        self.localIP = localIP
        self.gatewayIP = gatewayIP
        self.telemetry = telemetry
    }

    public static func capture(
        sampleCount: Int = 3,
        timeoutPerSampleSeconds: TimeInterval = 0.3
    ) async -> Self {
        let prober = BSDWiFiLocalGatewayProber()
        let localIP = prober.resolveLocalIPv4()
        let gatewayIP = prober.resolveDefaultGatewayIPv4()
        let telemetry = await prober.probeLocalGateway(
            sampleCount: sampleCount,
            timeoutPerSampleSeconds: timeoutPerSampleSeconds
        )
        return Self(localIP: localIP, gatewayIP: gatewayIP, telemetry: telemetry)
    }
}

/// Contrato de apresentação para uma leitura local de rede.
/// Mantém o Cockpit coerente e deixa explícito quando a frequência não foi
/// observada pelo sistema.
public struct LocalNetworkTelemetryPresentation: Sendable, Equatable {
    public let connectionKind: String
    public let wifiBand: String
    public let gateway: String
    public let gatewayRTT: String

    public init(snapshot: LocalNetworkTelemetrySnapshot) {
        connectionKind = snapshot.telemetry.isWiFi ? "Wi-Fi" : "Dados Móveis (Celular)"
        wifiBand = snapshot.telemetry.isWiFi ? "Não confirmada" : "—"
        gateway = snapshot.gatewayIP ?? "—"
        gatewayRTT = snapshot.telemetry.gatewayRTTMedianMs.map { "\(Int($0.rounded())) ms" } ?? "N/D"
    }

    public var shortcutSummary: String {
        "\(connectionKind) | Frequência Wi-Fi: \(wifiBand) | Gateway: \(gateway) | Latência do roteador: \(gatewayRTT)"
    }
}
