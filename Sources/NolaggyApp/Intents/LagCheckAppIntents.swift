import Foundation
import AppIntents
import UIKit
import NolaggyDomain
import NolaggyInfrastructure

/// Ação nativa do app Atalhos: Inicia a medição de conexão no LagCheck (Decisões 50 e 57).
@available(iOS 17.0, *)
public struct StartQuickCheckIntent: AppIntent {
    public static var title: LocalizedStringResource { "Testar Conexão no LagCheck" }
    public static var description: IntentDescription { "Abre o LagCheck e inicia a medição da rota e latência para jogos em 1 toque." }
    public static var openAppWhenRun: Bool { true }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        if let url = URL(string: "lagcheck://quicktest") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        return .result()
    }
}

/// Ação nativa do app Atalhos: Abre o Cockpit de Dados da Rede no LagCheck (Decisão 56).
@available(iOS 17.0, *)
public struct OpenNetworkCockpitIntent: AppIntent {
    public static var title: LocalizedStringResource { "Ver Dados da Rede no LagCheck" }
    public static var description: IntentDescription { "Abre o cockpit com diagnóstico de IP local, gateway, tipo de NAT e banda Wi-Fi." }
    public static var openAppWhenRun: Bool { true }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        if let url = URL(string: "lagcheck://network") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        return .result()
    }
}

/// Ação nativa do app Atalhos: Obtém a telemetria pontual da rede em segundo plano.
@available(iOS 17.0, *)
public struct GetNetworkTelemetryIntent: AppIntent {
    public static var title: LocalizedStringResource { "Obter Diagnóstico de Rede" }
    public static var description: IntentDescription { "Consulta o roteador local e retorna a latência de gateway e frequência Wi-Fi sem abrir o app." }
    public static var openAppWhenRun: Bool { false }

    public init() {}

    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let prober = BSDWiFiLocalGatewayProber()
        let sample = await prober.probeLocalGateway(sampleCount: 2, timeoutPerSampleSeconds: 0.3)
        let rttText = sample.gatewayRTTMedianMs.map { "\(Int(round($0))) ms" } ?? "N/D"
        let bandResult = WiFiBandEvaluator.evaluate(telemetry: sample)
        let bandText: String
        switch bandResult.diagnostic {
        case .confirmed5GHzOrHigher:
            bandText = "5 GHz"
        case .confirmed24GHz, .suspected24GHzContention:
            bandText = "2.4 GHz"
        case .stableWiFi:
            bandText = "Wi-Fi Estável"
        case .inconclusive:
            bandText = "Wi-Fi"
        }
        let summary = "Wi-Fi: \(bandText) | Latência do Roteador: \(rttText)"
        return .result(value: summary)
    }
}

/// Provedor nativo de atalhos do sistema (iOS 17+ AppShortcutsProvider).
/// Cadastra os atalhos automaticamente no aplicativo Atalhos da Apple, Spotlight e Siri.
@available(iOS 17.0, *)
public struct LagCheckShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartQuickCheckIntent(),
            phrases: [
                "Testar conexão no \(.applicationName)",
                "Medir rede no \(.applicationName)",
                "Iniciar teste no \(.applicationName)",
                "Test connection in \(.applicationName)",
                "Check ping in \(.applicationName)"
            ],
            shortTitle: "Testar Conexão",
            systemImageName: "speedometer"
        )

        AppShortcut(
            intent: OpenNetworkCockpitIntent(),
            phrases: [
                "Ver dados da rede no \(.applicationName)",
                "Abrir diagnóstico de rede no \(.applicationName)",
                "Show network data in \(.applicationName)"
            ],
            shortTitle: "Dados da Rede",
            systemImageName: "network"
        )

        AppShortcut(
            intent: GetNetworkTelemetryIntent(),
            phrases: [
                "Obter status da rede no \(.applicationName)",
                "Verificar Wi-Fi no \(.applicationName)",
                "Get network telemetry in \(.applicationName)"
            ],
            shortTitle: "Status da Rede",
            systemImageName: "wifi"
        )
    }
}
