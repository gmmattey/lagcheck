import SwiftUI
import UIKit
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain
import NolaggyInfrastructure

/// Cockpit de Rede ("Dados da Rede do Jogador" — Decisão 56).
/// Reúne todos os parâmetros técnicos da conexão local e de borda WAN que interessam
/// ao jogador para configurar consoles, PC, abrir portas ou contestar a operadora.
public struct NetworkCockpitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var localIP: String? = nil
    @State private var gatewayIP: String? = nil
    @State private var gatewayRTTMs: Double? = nil
    @State private var wifiBand: String = "—"
    @State private var connectionKindText: String = "Detectando..."
    @State private var isWiFi: Bool = true
    @State private var natTopology: NATTopologySnapshot? = nil
    @State private var isProbing: Bool = true
    @State private var showPublicIP: Bool = false
    @State private var copyFeedback: Bool = false

    public let showsDismissButton: Bool

    public init(showsDismissButton: Bool = true) {
        self.showsDismissButton = showsDismissButton
    }

    public var body: some View {
        if showsDismissButton {
            NavigationStack {
                content
            }
            .preferredColorScheme(.dark)
        } else {
            content
                .preferredColorScheme(.dark)
        }
    }

    private var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: NLSpacing.lg) {
                // Header e status geral
                summaryHeader

                // Card 1: Conexão Local e Primeiro Salto
                localNetworkCard

                // Card 2: Borda WAN, NAT e CGNAT
                wanTopologyCard

                // Card 3: Ações Práticas
                actionsCard
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.md)
        }
        .background(NLColor.deep.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(LocalizedStringKey("network_cockpit.title"))
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)
            }
            if showsDismissButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(NLColor.textSecondary)
                    }
                    .accessibilityIdentifier("cockpit-dismiss")
                }
            }
        }
        .task {
            await loadNetworkDiagnostics()
        }
    }

    // MARK: - Summary Header
    private var summaryHeader: some View {
        VStack(spacing: NLSpacing.xs) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isWiFi ? NLColor.scoreExcellent : NLColor.accentPrimary)
                    .frame(width: 8, height: 8)
                Text(connectionKindText)
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)
            }

            Text(LocalizedStringKey("network_cockpit.subtitle"))
                .font(NLTypography.footnote)
                .foregroundStyle(NLColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NLSpacing.xs)
    }

    // MARK: - Card 1: Salto Local
    private var localNetworkCard: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            HStack {
                Image(systemName: isWiFi ? "wifi" : "antenna.radiowaves.left.and.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NLColor.accentPrimary)
                Text(LocalizedStringKey("network_cockpit.local_network.title"))
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.textPrimary)
                Spacer()
                if isWiFi {
                    Text(wifiBand)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(NLColor.accentPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(NLColor.accentPrimarySubtle, in: Capsule())
                }
            }

            Divider().overlay(NLColor.borderHairline)

            dataRow(
                label: LocalizedStringKey("network_cockpit.local_ip"),
                value: localIP ?? "—",
                isMonospaced: true,
                canCopy: localIP != nil
            )

            dataRow(
                label: LocalizedStringKey("network_cockpit.gateway_ip"),
                value: gatewayIP ?? "—",
                isMonospaced: true,
                canCopy: gatewayIP != nil
            )

            if let rtt = gatewayRTTMs {
                dataRow(
                    label: LocalizedStringKey("network_cockpit.gateway_rtt"),
                    value: "\(Int(round(rtt))) ms",
                    isMonospaced: true,
                    statusColor: rtt <= 5.0 ? NLColor.scoreExcellent : (rtt <= 15.0 ? NLColor.scoreUnstable : NLColor.coralSolarRed)
                )
            }

            if let gw = gatewayIP, isWiFi {
                Button(action: {
                    if let url = URL(string: "http://\(gw)") {
                        openURL(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12, weight: .semibold))
                        Text(LocalizedStringKey("network_cockpit.access_router"))
                            .font(NLTypography.captionStrong)
                    }
                    .foregroundStyle(NLColor.accentPrimary)
                    .padding(.top, 4)
                }
            }
        }
        .padding(NLSpacing.md)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(NLColor.borderHairline, lineWidth: 1)
        )
    }

    // MARK: - Card 2: Borda WAN, NAT e CGNAT
    private var wanTopologyCard: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            HStack {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NLColor.scoreExcellent)
                Text(LocalizedStringKey("network_cockpit.wan.title"))
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.textPrimary)
                Spacer()
                if isProbing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            Divider().overlay(NLColor.borderHairline)

            // Tipo de NAT
            dataRow(
                label: LocalizedStringKey("network_cockpit.nat_type"),
                value: natTypeDisplay,
                isMonospaced: false,
                statusColor: natTypeColor
            )

            // Status CGNAT
            dataRow(
                label: LocalizedStringKey("network_cockpit.cgnat_status"),
                value: cgnatDisplay,
                isMonospaced: false,
                statusColor: cgnatColor
            )

            // Duplo NAT
            dataRow(
                label: LocalizedStringKey("network_cockpit.double_nat"),
                value: doubleNATDisplay,
                isMonospaced: false,
                statusColor: doubleNATColor
            )

            // IP Público
            HStack {
                Text(LocalizedStringKey("network_cockpit.public_ip"))
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.textSecondary)
                Spacer()
                HStack(spacing: 8) {
                    Text(publicIPDisplay)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(NLColor.textPrimary)
                    Button(action: { showPublicIP.toggle() }) {
                        Image(systemName: showPublicIP ? "eye.slash" : "eye")
                            .font(.system(size: 13))
                            .foregroundStyle(NLColor.textTertiary)
                    }
                    if showPublicIP {
                        Button(action: {
                            if let ip = natTopology?.publicIP {
                                UIPasteboard.general.string = ip
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundStyle(NLColor.accentPrimary)
                        }
                    }
                }
            }
        }
        .padding(NLSpacing.md)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(NLColor.borderHairline, lineWidth: 1)
        )
    }

    // MARK: - Card 3: Ações Práticas
    private var actionsCard: some View {
        VStack(spacing: NLSpacing.sm) {
            Button(action: copyReportToClipboard) {
                HStack {
                    Image(systemName: copyFeedback ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 14, weight: .semibold))
                    Text(copyFeedback
                        ? LocalizedStringKey("network_cockpit.copied")
                        : LocalizedStringKey("network_cockpit.copy_report"))
                        .font(NLTypography.bodyEmphasis)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(NLColor.textPrimary)
                .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(NLColor.borderHairline, lineWidth: 1)
                )
            }
            .accessibilityIdentifier("cockpit-copy-report")

            Text(LocalizedStringKey("network_cockpit.copy_hint"))
                .font(NLTypography.caption)
                .foregroundStyle(NLColor.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Linha de Dado Genérica
    private func dataRow(
        label: LocalizedStringKey,
        value: String,
        isMonospaced: Bool = false,
        statusColor: Color? = nil,
        canCopy: Bool = false
    ) -> some View {
        HStack {
            Text(label)
                .font(NLTypography.caption)
                .foregroundStyle(NLColor.textSecondary)
            Spacer()
            HStack(spacing: 6) {
                Text(value)
                    .font(isMonospaced ? .system(size: 13, weight: .medium, design: .monospaced) : NLTypography.captionStrong)
                    .foregroundStyle(statusColor ?? NLColor.textPrimary)
                if canCopy {
                    Button(action: {
                        UIPasteboard.general.string = value
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundStyle(NLColor.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Propriedades Computadas de Exibição
    private var natTypeDisplay: String {
        guard let nat = natTopology else { return isProbing ? "Aferindo..." : "—" }
        switch nat.natType {
        case .type1Open: return "Tipo 1 (Aberto)"
        case .type2Moderate: return "Tipo 2 (Moderado)"
        case .type3Strict: return "Tipo 3 (Estrito)"
        case .inconclusive: return "Inconclusivo"
        }
    }

    private var natTypeColor: Color {
        guard let nat = natTopology else { return NLColor.textSecondary }
        switch nat.natType {
        case .type1Open: return NLColor.scoreExcellent
        case .type2Moderate: return NLColor.scoreUnstable
        case .type3Strict: return NLColor.coralSolarRed
        case .inconclusive: return NLColor.textSecondary
        }
    }

    private var cgnatDisplay: String {
        guard let nat = natTopology else { return isProbing ? "Aferindo..." : "—" }
        switch nat.cgnatStatus {
        case .notDetected: return "Livre (IP Público Real)"
        case .detected: return "Detectado (RFC 6598)"
        case .inconclusive: return "Inconclusivo"
        }
    }

    private var cgnatColor: Color {
        guard let nat = natTopology else { return NLColor.textSecondary }
        switch nat.cgnatStatus {
        case .notDetected: return NLColor.scoreExcellent
        case .detected: return NLColor.coralSolarRed
        case .inconclusive: return NLColor.textSecondary
        }
    }

    private var doubleNATDisplay: String {
        guard let nat = natTopology else { return isProbing ? "Aferindo..." : "—" }
        switch nat.doubleNATStatus {
        case .notDetected: return "Não detectado"
        case .suspectOrDetected: return "Detectado (2 Roteadores)"
        case .inconclusive: return "Inconclusivo"
        }
    }

    private var doubleNATColor: Color {
        guard let nat = natTopology else { return NLColor.textSecondary }
        switch nat.doubleNATStatus {
        case .notDetected: return NLColor.scoreExcellent
        case .suspectOrDetected: return NLColor.coralSolarRed
        case .inconclusive: return NLColor.textSecondary
        }
    }

    private var publicIPDisplay: String {
        guard let nat = natTopology else { return "—" }
        if let raw = nat.publicIP, !raw.isEmpty {
            return showPublicIP ? raw : (nat.publicIPMasked ?? maskIP(raw))
        }
        return nat.publicIPMasked ?? "—"
    }

    private func maskIP(_ ip: String) -> String {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return "•••.•••.•••" }
        return "\(parts[0]).\(parts[1]).•••.•••"
    }

    // MARK: - Ações e Diagnósticos
    private func loadNetworkDiagnostics() async {
        isProbing = true
        let prober = BSDWiFiLocalGatewayProber()
        localIP = prober.resolveLocalIPv4()
        gatewayIP = prober.resolveDefaultGatewayIPv4()

        let telemetry = await prober.probeLocalGateway(sampleCount: 3, timeoutPerSampleSeconds: 0.3)
        gatewayRTTMs = telemetry.gatewayRTTMedianMs
        isWiFi = telemetry.isWiFi

        if telemetry.isWiFi {
            let eval = WiFiBandEvaluator.evaluate(telemetry: telemetry)
            if eval.diagnostic.isSuspectOrConfirmed24GHz {
                wifiBand = "2.4 GHz"
                connectionKindText = "Wi-Fi (2.4 GHz)"
            } else {
                switch eval.diagnostic {
                case .confirmed5GHzOrHigher, .stableWiFi:
                    wifiBand = "5 GHz"
                    connectionKindText = "Wi-Fi (5 GHz)"
                case .inconclusive:
                    wifiBand = "Padrão"
                    connectionKindText = "Wi-Fi"
                default:
                    wifiBand = "Wi-Fi"
                    connectionKindText = "Wi-Fi"
                }
            }
        } else {
            connectionKindText = "Dados Móveis (Celular)"
        }

        // Executa sonda STUN para topologia WAN
        let stunClient = StunProbeClient()
        natTopology = await stunClient.probeTopology(localIP: localIP)
        isProbing = false
    }

    private func copyReportToClipboard() {
        let report = """
        [Relatório de Rede — LagCheck]
        • Interface: \(connectionKindText)
        • IP Local: \(localIP ?? "—")
        • Gateway (Roteador): \(gatewayIP ?? "—") (RTT: \(gatewayRTTMs.map { "\(Int(round($0))) ms" } ?? "—"))
        • NAT: \(natTypeDisplay)
        • CGNAT: \(cgnatDisplay)
        • Duplo NAT: \(doubleNATDisplay)
        • IP Público: \(natTopology?.publicIPMasked ?? "—")
        • Gerado em: \(Date().formatted(date: .abbreviated, time: .standard))
        """

        UIPasteboard.general.string = report
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        copyFeedback = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            copyFeedback = false
        }
    }
}
