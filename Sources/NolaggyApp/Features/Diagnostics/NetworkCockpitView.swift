import SwiftUI
import UIKit
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain
import NolaggyInfrastructure

/// Cockpit de Rede ("Dados da Rede do Jogador" — Decisão 56).
/// Reúne todos os parâmetros técnicos da conexão local e de borda WAN que interessam
/// ao jogador para configurar consoles, PC, abrir portas ou contestar a operadora.
/// Consome o `SharedNetworkTelemetryService` como fonte única da verdade ao vivo.
public struct NetworkCockpitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @ObservedObject private var telemetry = SharedNetworkTelemetryService.shared

    @State private var showPublicIP: Bool = false
    @State private var copyFeedback: Bool = false
    @State private var exportPDFURL: URL? = nil
    @State private var showingPDFShareSheet: Bool = false

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
                // Header e status geral ao vivo
                summaryHeader

                // Card 1: Conexão Local e Primeiro Salto
                localNetworkCard

                // Card 2: Borda WAN, NAT e CGNAT
                wanTopologyCard

                // Card 3: Prontidão para Casos de Uso Gamer
                useCasesCard

                // Card 4: Ações Práticas (Exportar PDF e Copiar)
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
        .sheet(isPresented: $showingPDFShareSheet) {
            if let url = exportPDFURL {
                ShareSheet(items: [url])
            }
        }
        .task {
            await telemetry.refreshTelemetry()
        }
    }

    // MARK: - Summary Header Ao Vivo
    private var summaryHeader: some View {
        VStack(spacing: NLSpacing.xs) {
            HStack(spacing: 8) {
                Circle()
                    .fill(telemetry.isWiFi ? NLColor.scoreExcellent : NLColor.accentPrimary)
                    .frame(width: 8, height: 8)

                Text(telemetry.connectionKindText)
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)

                Spacer()

                if telemetry.isProbing {
                    HStack(spacing: 4) {
                        ProgressView().scaleEffect(0.7)
                        Text(LocalizedStringKey("network_cockpit.probing"))
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textTertiary)
                    }
                } else {
                    Button(action: {
                        Task { await telemetry.refreshTelemetry(force: true) }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .bold))
                            Text(LocalizedStringKey("network_cockpit.refresh_live"))
                                .font(NLTypography.captionStrong)
                        }
                        .foregroundStyle(NLColor.accentPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(NLColor.accentPrimarySubtle, in: Capsule())
                    }
                }
            }

            Text(LocalizedStringKey("network_cockpit.subtitle"))
                .font(NLTypography.footnote)
                .foregroundStyle(NLColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NLSpacing.xs)
    }

    // MARK: - Card 1: Salto Local
    private var localNetworkCard: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            HStack {
                Image(systemName: telemetry.isWiFi ? "wifi" : "antenna.radiowaves.left.and.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NLColor.accentPrimary)
                Text(LocalizedStringKey("network_cockpit.local_network.title"))
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.textPrimary)
                Spacer()
                if telemetry.isWiFi {
                    Text(telemetry.wifiBand)
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
                value: telemetry.localIP ?? "—",
                isMonospaced: true,
                canCopy: telemetry.localIP != nil
            )

            dataRow(
                label: LocalizedStringKey("network_cockpit.gateway_ip"),
                value: telemetry.gatewayIP ?? "—",
                isMonospaced: true,
                canCopy: telemetry.gatewayIP != nil
            )

            if let rtt = telemetry.gatewayRTTMs {
                dataRow(
                    label: LocalizedStringKey("network_cockpit.gateway_rtt"),
                    value: "\(Int(round(rtt))) ms",
                    isMonospaced: true,
                    statusColor: rtt <= 5.0 ? NLColor.scoreExcellent : (rtt <= 15.0 ? NLColor.scoreUnstable : NLColor.coralSolarRed)
                )
            }

            if let gw = telemetry.gatewayIP, telemetry.isWiFi {
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
                if telemetry.isProbing {
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
                            if let ip = telemetry.natTopology?.publicIP {
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

    // MARK: - Card 3: Prontidão para Casos de Uso Gamer
    private var useCasesCard: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NLColor.accentPrimary)
                Text(LocalizedStringKey("network_cockpit.use_cases.title"))
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.textPrimary)
                Spacer()
            }

            Divider().overlay(NLColor.borderHairline)

            VStack(spacing: NLSpacing.sm) {
                // Caso 1: Streaming de Jogos (Cloud Gaming)
                useCaseRow(
                    icon: "tv.and.mediabox",
                    title: LocalizedStringKey("network_cockpit.use_case.cloud_gaming"),
                    subtitle: cloudGamingMotivator,
                    status: cloudGamingStatus
                )

                Divider().overlay(NLColor.borderHairline)

                // Caso 2: Áudio Multiplayer (Chat de Voz)
                useCaseRow(
                    icon: "headphones",
                    title: LocalizedStringKey("network_cockpit.use_case.voice_chat"),
                    subtitle: voiceChatMotivator,
                    status: voiceChatStatus
                )

                Divider().overlay(NLColor.borderHairline)

                // Caso 3: Multiplayer Competitivo (FPS/MOBA)
                useCaseRow(
                    icon: "target",
                    title: LocalizedStringKey("network_cockpit.use_case.competitive_fps"),
                    subtitle: competitiveFPSMotivator,
                    status: competitiveFPSStatus
                )

                Divider().overlay(NLColor.borderHairline)

                // Caso 4: Transmissão ao Vivo (Live Stream)
                useCaseRow(
                    icon: "antenna.radiowaves.left.and.right",
                    title: LocalizedStringKey("network_cockpit.use_case.live_stream"),
                    subtitle: liveStreamMotivator,
                    status: liveStreamStatus
                )
            }
        }
        .padding(NLSpacing.md)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(NLColor.borderHairline, lineWidth: 1)
        )
    }

    private func useCaseRow(
        icon: String,
        title: LocalizedStringKey,
        subtitle: String,
        status: (badge: String, color: Color)
    ) -> some View {
        HStack(alignment: .center, spacing: NLSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(status.color)
                .frame(width: 28, height: 28)
                .background(status.color.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(NLTypography.callout.weight(.semibold))
                    .foregroundStyle(NLColor.textPrimary)

                Text(subtitle)
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Text(status.badge)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(status.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(status.color.opacity(0.15), in: Capsule())
        }
    }

    // MARK: - Card 4: Ações Práticas (Exportar PDF & Copiar)
    private var actionsCard: some View {
        VStack(spacing: NLSpacing.sm) {
            // Botão Principal: Exportar PDF Customizado
            Button(action: exportNetworkPDF) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                    Text(LocalizedStringKey("network_cockpit.export_pdf"))
                        .font(NLTypography.bodyEmphasis)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .foregroundStyle(.white)
                .background(NLColor.coralSolar, in: RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityIdentifier("cockpit-export-pdf")

            // Botão Secundário: Copiar Relatório Texto
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

    // MARK: - Lógicas de Diagnóstico de Casos de Uso
    private var cloudGamingStatus: (badge: String, color: Color) {
        let rtt = telemetry.gatewayRTTMs ?? 99
        let is5G = telemetry.isWiFi && telemetry.wifiBand.contains("5")
        if rtt <= 4.0 && is5G {
            return ("EXCELENTE", NLColor.scoreExcellent)
        } else if rtt <= 10.0 {
            return ("BOM", NLColor.scoreUnstable)
        } else {
            return ("ATENÇÃO", NLColor.coralSolarRed)
        }
    }

    private var voiceChatStatus: (badge: String, color: Color) {
        let rtt = telemetry.gatewayRTTMs ?? 99
        if rtt <= 8.0 {
            return ("EXCELENTE", NLColor.scoreExcellent)
        } else if rtt <= 20.0 {
            return ("BOM", NLColor.scoreUnstable)
        } else {
            return ("INSTÁVEL", NLColor.coralSolarRed)
        }
    }

    private var competitiveFPSStatus: (badge: String, color: Color) {
        let nat = telemetry.natTopology
        let isStrict = nat?.natType == .type3Strict
        let hasDoubleNAT = nat?.doubleNATStatus == .suspectOrDetected
        let rtt = telemetry.gatewayRTTMs ?? 99

        if !isStrict && !hasDoubleNAT && rtt <= 5.0 {
            return ("EXCELENTE", NLColor.scoreExcellent)
        } else if !isStrict && rtt <= 15.0 {
            return ("BOM", NLColor.scoreUnstable)
        } else {
            return ("ATENÇÃO", NLColor.coralSolarRed)
        }
    }

    private var liveStreamStatus: (badge: String, color: Color) {
        let rtt = telemetry.gatewayRTTMs ?? 99
        if rtt <= 6.0 && telemetry.isWiFi && telemetry.wifiBand.contains("5") {
            return ("EXCELENTE", NLColor.scoreExcellent)
        } else if rtt <= 15.0 {
            return ("BOM", NLColor.scoreUnstable)
        } else {
            return ("ATENÇÃO", NLColor.coralSolarRed)
        }
    }

    private var cloudGamingMotivator: String {
        guard let rtt = telemetry.gatewayRTTMs else {
            return "Aguardando leitura de resposta do roteador..."
        }
        let rttInt = Int(round(rtt))
        let is5G = telemetry.isWiFi && telemetry.wifiBand.contains("5")
        if rtt <= 4.0 && is5G {
            return "Wi-Fi 5 GHz e gateway veloz (\(rttInt) ms) para streaming contínuo sem engasgos."
        } else if !is5G && telemetry.isWiFi {
            return "Mude para o Wi-Fi 5 GHz para evitar pixelização e travadas no streaming."
        } else if rtt > 10.0 {
            return "Latência local elevada (\(rttInt) ms): aproxime-se do roteador para reduzir o atraso nos comandos."
        } else {
            return "Latência aceitável (\(rttInt) ms): mantenha proximidade do roteador."
        }
    }

    private var voiceChatMotivator: String {
        guard let rtt = telemetry.gatewayRTTMs else {
            return "Aguardando leitura de conexão local..."
        }
        let rttInt = Int(round(rtt))
        if rtt <= 8.0 {
            return "Latência baixa (\(rttInt) ms): áudio claro e sem cortes no chat de voz."
        } else if rtt > 20.0 {
            return "Alta latência no roteador (\(rttInt) ms): conecte via cabo para evitar voz robótica ou atraso."
        } else {
            return "Latência moderada (\(rttInt) ms): chamadas estáveis com pequeno retardo."
        }
    }

    private var competitiveFPSMotivator: String {
        let nat = telemetry.natTopology
        let isStrict = nat?.natType == .type3Strict
        let hasDoubleNAT = nat?.doubleNATStatus == .suspectOrDetected
        guard let rtt = telemetry.gatewayRTTMs else {
            return "Aguardando diagnóstico de NAT e rota local..."
        }
        let rttInt = Int(round(rtt))
        if isStrict {
            return "NAT Tipo 3: habilite UPnP no roteador para liberar matchmaking e salas com amigos."
        } else if hasDoubleNAT {
            return "Duplo NAT detectado: coloque o modem da operadora em modo bridge."
        } else if rtt > 15.0 {
            return "Latência local elevada (\(rttInt) ms): use cabo ou Wi-Fi 5 GHz para garantir registro imediato de tiros."
        } else if rtt <= 5.0 {
            return "NAT favorável e rota veloz (\(rttInt) ms): sinal verde para ranqueada."
        } else {
            return "Conexão estável (\(rttInt) ms): sem restrições severas de rede."
        }
    }

    private var liveStreamMotivator: String {
        guard let rtt = telemetry.gatewayRTTMs else {
            return "Aguardando verificação do canal de rede..."
        }
        let rttInt = Int(round(rtt))
        let is5G = telemetry.isWiFi && telemetry.wifiBand.contains("5")
        if rtt <= 6.0 && is5G {
            return "Wi-Fi 5 GHz e estabilidade alta: upload contínuo sem perda de quadros."
        } else if !is5G && telemetry.isWiFi {
            return "Wi-Fi 2.4 GHz: use cabo Ethernet para evitar quedas no bitrate da live."
        } else if rtt > 15.0 {
            return "Instabilidade no gateway (\(rttInt) ms): risco de buffering na transmissão."
        } else {
            return "Estabilidade regular (\(rttInt) ms): pause downloads pesados durante a transmissão."
        }
    }

    // MARK: - Propriedades Computadas de Exibição
    private var natTypeDisplay: String {
        guard let nat = telemetry.natTopology else { return telemetry.isProbing ? "Aferindo..." : "—" }
        switch nat.natType {
        case .type1Open: return "Tipo 1 (Aberto)"
        case .type2Moderate: return "Tipo 2 (Moderado)"
        case .type3Strict: return "Tipo 3 (Estrito)"
        case .inconclusive: return "Inconclusivo"
        }
    }

    private var natTypeColor: Color {
        guard let nat = telemetry.natTopology else { return NLColor.textSecondary }
        switch nat.natType {
        case .type1Open: return NLColor.scoreExcellent
        case .type2Moderate: return NLColor.scoreUnstable
        case .type3Strict: return NLColor.coralSolarRed
        case .inconclusive: return NLColor.textSecondary
        }
    }

    private var cgnatDisplay: String {
        guard let nat = telemetry.natTopology else { return telemetry.isProbing ? "Aferindo..." : "—" }
        switch nat.cgnatStatus {
        case .notDetected: return "Livre (IP Público Real)"
        case .detected: return "Detectado (RFC 6598)"
        case .inconclusive: return "Inconclusivo"
        }
    }

    private var cgnatColor: Color {
        guard let nat = telemetry.natTopology else { return NLColor.textSecondary }
        switch nat.cgnatStatus {
        case .notDetected: return NLColor.scoreExcellent
        case .detected: return NLColor.coralSolarRed
        case .inconclusive: return NLColor.textSecondary
        }
    }

    private var doubleNATDisplay: String {
        guard let nat = telemetry.natTopology else { return telemetry.isProbing ? "Aferindo..." : "—" }
        switch nat.doubleNATStatus {
        case .notDetected: return "Não detectado"
        case .suspectOrDetected: return "Detectado (2 Roteadores)"
        case .inconclusive: return "Inconclusivo"
        }
    }

    private var doubleNATColor: Color {
        guard let nat = telemetry.natTopology else { return NLColor.textSecondary }
        switch nat.doubleNATStatus {
        case .notDetected: return NLColor.scoreExcellent
        case .suspectOrDetected: return NLColor.coralSolarRed
        case .inconclusive: return NLColor.textSecondary
        }
    }

    private var publicIPDisplay: String {
        guard let nat = telemetry.natTopology else { return "—" }
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

    // MARK: - Ações de Exportação e Cópia
    private func exportNetworkPDF() {
        let useCasesList: [(title: String, icon: String, status: String, color: UIColor, note: String)] = [
            ("Streaming de Jogos (Cloud Gaming)", "tv.and.mediabox", cloudGamingStatus.badge, cloudGamingStatus.color == NLColor.scoreExcellent ? UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1) : UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1), "Xbox Cloud Gaming, GeForce NOW, PS Remote Play"),
            ("Áudio Multiplayer (Chat de Voz)", "headphones", voiceChatStatus.badge, voiceChatStatus.color == NLColor.scoreExcellent ? UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1) : UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1), "Discord, Party Chat PSN e Xbox Live sem voz robótica"),
            ("Multiplayer Competitivo (FPS/MOBA)", "target", competitiveFPSStatus.badge, competitiveFPSStatus.color == NLColor.scoreExcellent ? UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1) : UIColor(red: 255/255, green: 90/255, blue: 54/255, alpha: 1), "CS2, Valorant, Fortnite com matchmaking direto sem restrição de NAT"),
            ("Transmissão ao Vivo (Live Stream)", "antenna.radiowaves.left.and.right", liveStreamStatus.badge, liveStreamStatus.color == NLColor.scoreExcellent ? UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1) : UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1), "Twitch, YouTube Gaming com taxa de quadros e bitrate estáveis")
        ]

        if let pdfURL = LagCheckPDFExporter.generateNetworkReportPDF(
            interfaceName: telemetry.connectionKindText,
            isWiFi: telemetry.isWiFi,
            wifiBand: telemetry.wifiBand,
            localIP: telemetry.localIP,
            gatewayIP: telemetry.gatewayIP,
            gatewayRTTMs: telemetry.gatewayRTTMs,
            natTypeDisplay: natTypeDisplay,
            cgnatDisplay: cgnatDisplay,
            doubleNATDisplay: doubleNATDisplay,
            publicIPDisplay: publicIPDisplay,
            useCases: useCasesList
        ) {
            self.exportPDFURL = pdfURL
            self.showingPDFShareSheet = true
        }
    }

    private func copyReportToClipboard() {
        let report = """
        [Relatório de Rede — LagCheck]
        • Interface: \(telemetry.connectionKindText)
        • IP Local: \(telemetry.localIP ?? "—")
        • Gateway (Roteador): \(telemetry.gatewayIP ?? "—") (RTT: \(telemetry.gatewayRTTMs.map { "\(Int(round($0))) ms" } ?? "—"))
        • NAT: \(natTypeDisplay)
        • CGNAT: \(cgnatDisplay)
        • Duplo NAT: \(doubleNATDisplay)
        • IP Público: \(telemetry.natTopology?.publicIPMasked ?? "—")
        • Casos de Uso:
          - Cloud Gaming: \(cloudGamingStatus.badge)
          - Chat de Voz: \(voiceChatStatus.badge)
          - FPS Competitivo: \(competitiveFPSStatus.badge)
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
