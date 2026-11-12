import SwiftUI
import NolaggyDomain

/// Componente visual do Isolador de Causa Raiz ("De Quem é a Culpa?").
/// Decisão 75 (Fase 2 / Item 5) e Decisão 64 ("O Gamer Não Lê").
/// Layout compacto, esportivo Dark Competitive UI com 3 nós claros e atestado direto.
public struct RootCauseIsolationView: View {
    private let report: RootCauseIsolationReport

    public init(report: RootCauseIsolationReport) {
        self.report = report
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            // Header: "DE QUEM É A CULPA?"
            HStack {
                Text(String(localized: "root_cause.title", defaultValue: "DE QUEM É A CULPA?"))
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1.2)
                
                Spacer()
                
                culpritBadge
            }

            // Grid dos 3 Probes Táticos
            VStack(spacing: NLSpacing.xs) {
                // Probe 1: Wi-Fi / Rede Local
                probeRow(
                    icon: "wifi",
                    title: String(localized: "root_cause.probe.wifi", defaultValue: "SEU WI-FI / SINAL"),
                    detail: localWiFiDetail,
                    status: localWiFiStatus
                )

                // Probe 2: Rota Operadora
                probeRow(
                    icon: "network",
                    title: String(localized: "root_cause.probe.isp", defaultValue: "ROTA DA OPERADORA"),
                    detail: ispDetail,
                    status: ispStatus
                )

                // Probe 3: Servidores do Jogo
                probeRow(
                    icon: "server.rack",
                    title: report.platformServiceName ?? String(localized: "root_cause.probe.platform", defaultValue: "SERVIDORES DO JOGO"),
                    detail: platformDetail,
                    status: platformStatus
                )
            }
            .padding(NLSpacing.sm)
            .background(NLColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: NLRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NLRadius.md, style: .continuous)
                    .stroke(NLColor.borderSubtle, lineWidth: 1)
            )
        }
    }

    // MARK: - Badges & Status

    private var culpritBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badgeColor)
                .frame(width: 8, height: 8)
            Text(badgeText)
                .font(NLTypography.caption)
                .bold()
                .foregroundStyle(badgeColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.12))
        .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch report.primaryCulprit {
        case .allClear:
            return NLColor.semanticReady
        case .localWiFi:
            return NLColor.semanticCaution
        case .internetProvider:
            return NLColor.semanticCaution
        case .gamePlatform:
            return NLColor.semanticCaution
        case .unobservable:
            return NLColor.textSecondary
        }
    }

    private var badgeText: String {
        switch report.primaryCulprit {
        case .allClear:
            return String(localized: "root_cause.culprit.all_clear", defaultValue: "TUDO LIMPO")
        case .localWiFi:
            return String(localized: "root_cause.culprit.local_wifi", defaultValue: "GARGALO NO WI-FI")
        case .internetProvider:
            return String(localized: "root_cause.culprit.isp", defaultValue: "INSTABILIDADE NA OPERADORA")
        case .gamePlatform:
            return String(localized: "root_cause.culprit.platform", defaultValue: "SERVIDORES EM ALERTA")
        case .unobservable:
            return String(localized: "root_cause.culprit.unobservable", defaultValue: "GATEWAY NÃO OBSERVÁVEL")
        }
    }

    // MARK: - Row Helper

    private func probeRow(icon: String, title: String, detail: String, status: ProbeStatus) -> some View {
        HStack(spacing: NLSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(NLColor.textSecondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(NLTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(NLColor.textPrimary)
                Text(detail)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(NLColor.textSecondary)
            }

            Spacer()

            Image(systemName: status.icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(status.color)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Computed Details

    private enum ProbeStatus {
        case clean, degraded, unobservable

        var icon: String {
            switch self {
            case .clean: return "checkmark.circle.fill"
            case .degraded: return "exclamationmark.triangle.fill"
            case .unobservable: return "minus.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .clean: return NLColor.semanticReady
            case .degraded: return NLColor.semanticCaution
            case .unobservable: return NLColor.textTertiary
            }
        }
    }

    private var localWiFiStatus: ProbeStatus {
        guard report.localGatewayObservable else { return .unobservable }
        if (report.localGatewayRTTMs ?? 0) > 15.0 || report.localGatewayPacketLoss > 2.0 {
            return .degraded
        }
        return .clean
    }

    private var localWiFiDetail: String {
        guard report.localGatewayObservable, let rtt = report.localGatewayRTTMs else {
            return String(localized: "root_cause.detail.no_gw", defaultValue: "Sem resposta UDP (firewall fechado)")
        }
        return String(format: "RTT %.1f ms · %.0f%% perda", rtt, report.localGatewayPacketLoss)
    }

    private var ispStatus: ProbeStatus {
        if report.wanPacketLoss > 1.0 || (report.wanJitterMs ?? 0) > 15.0 {
            return .degraded
        }
        return .clean
    }

    private var ispDetail: String {
        if let rtt = report.wanMedianRTTMs {
            return String(format: "P50 %.0f ms · Jitter %.1f ms", rtt, report.wanJitterMs ?? 0)
        }
        return String(localized: "root_cause.detail.wan_ok", defaultValue: "Borda Anycast OK")
    }

    private var platformStatus: ProbeStatus {
        report.platformDegraded ? .degraded : .clean
    }

    private var platformDetail: String {
        report.platformDegraded
            ? String(localized: "root_cause.detail.platform_issue", defaultValue: "Oscilações reportadas")
            : String(localized: "root_cause.detail.platform_ok", defaultValue: "Operacional / CDN OK")
    }
}
