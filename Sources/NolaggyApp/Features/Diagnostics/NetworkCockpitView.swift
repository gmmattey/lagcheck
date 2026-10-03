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
    @State private var selectedUseCase: GamerUseCase? = nil

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

                // Card 3: Casos de Uso
                useCasesCard

                // Card 4: Ações práticas
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
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: exportNetworkPDF) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: NLSizing.touchTarget, height: NLSizing.touchTarget)
                }
                .foregroundStyle(NLColor.accentPrimary)
                .accessibilityLabel(Text(LocalizedStringKey("network_cockpit.export_pdf")))
                .accessibilityIdentifier("cockpit-export-pdf")

                if showsDismissButton {
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
        .sheet(item: $selectedUseCase) { useCase in
            useCaseSheet(for: useCase)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: NLRadius.card)
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
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: NLRadius.card)
                .stroke(NLColor.borderHairline, lineWidth: 1)
        )
    }

    // MARK: - Card 3: Casos de Uso
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

            VStack(spacing: 0) {
                ForEach(Array(useCasePresentations.enumerated()), id: \.element.id) { index, presentation in
                    useCaseRow(presentation)
                    if index < useCasePresentations.count - 1 {
                        Divider().overlay(NLColor.borderHairline)
                    }
                }
            }
        }
        .padding(NLSpacing.md)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: NLRadius.card)
                .stroke(NLColor.borderHairline, lineWidth: 1)
        )
    }

    private func useCaseRow(_ presentation: UseCasePresentation) -> some View {
        Button { selectedUseCase = presentation.useCase } label: {
            HStack(spacing: NLSpacing.sm) {
                Image(systemName: presentation.useCase.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(presentation.assessment.color)
                    .frame(width: 28, height: 28)
                    .background(presentation.assessment.color.opacity(0.12), in: Circle())

                Text(LocalizedStringKey(presentation.useCase.titleKey))
                    .font(NLTypography.callout.weight(.semibold))
                    .foregroundStyle(NLColor.textPrimary)

                Spacer(minLength: NLSpacing.xs)

                Image(systemName: presentation.assessment.symbolName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(presentation.assessment.color)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(NLColor.textTertiary)
            }
            .frame(minHeight: NLSizing.touchTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(AppLocalization.string(presentation.useCase.titleKey, comment: "")), \(presentation.assessment.localizedBadge). \(AppLocalization.string("network_cockpit.use_case.view_reason", comment: ""))"))
        .accessibilityIdentifier("cockpit-use-case-\(presentation.useCase.rawValue)")
    }

    private func useCaseSheet(for useCase: GamerUseCase) -> some View {
        let assessment = assessment(for: useCase)
        return VStack(alignment: .leading, spacing: NLSpacing.md) {
            HStack(spacing: NLSpacing.sm) {
                Image(systemName: useCase.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(assessment.color)
                Text(LocalizedStringKey(useCase.titleKey))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(NLColor.textPrimary)
            }

            Label(assessment.localizedBadge, systemImage: assessment.symbolName)
                .font(NLTypography.callout.weight(.semibold))
                .foregroundStyle(assessment.color)

            Text(assessment.reason)
                .font(NLTypography.body)
                .foregroundStyle(NLColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(LocalizedStringKey("network_cockpit.use_case.scope_limit"))
                .font(NLTypography.footnote)
                .foregroundStyle(NLColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NLSpacing.lg)
        .presentationBackground(NLColor.surface)
    }

    // MARK: - Card 4: Ações práticas
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
                .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: NLRadius.button)
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

    // MARK: - Casos de uso (somente fatos locais observados)
    private var useCasePresentations: [UseCasePresentation] {
        GamerUseCase.allCases
            .map { UseCasePresentation(useCase: $0, assessment: assessment(for: $0)) }
            .sorted {
                $0.assessment.kind.sortOrder == $1.assessment.kind.sortOrder
                    ? $0.useCase.order < $1.useCase.order
                    : $0.assessment.kind.sortOrder < $1.assessment.kind.sortOrder
            }
    }

    private func assessment(for useCase: GamerUseCase) -> UseCaseAssessment {
        let rtt = telemetry.gatewayRTTMs.map { Int($0.rounded()) }
        let isConfirmed5GHz = telemetry.isWiFi && telemetry.wifiBand.contains("5")
        let isConfirmed24GHz = telemetry.isWiFi && telemetry.wifiBand.contains("2.4")

        switch useCase {
        case .cloudGaming:
            guard let rtt else { return .notAssessed }
            if isConfirmed5GHz && rtt <= 4 {
                return .favorable(AppLocalization.format("network_cockpit.use_case.reason.5ghz_low_rtt", rtt))
            }
            if isConfirmed24GHz {
                return .attention(AppLocalization.string("network_cockpit.use_case.reason.2_4ghz_confirmed"))
            }
            if rtt > 10 {
                return .attention(AppLocalization.format("network_cockpit.use_case.reason.high_local_rtt", rtt))
            }
            return .notAssessed
        case .voiceChat:
            switch VoiceChatSuitabilityEvaluator.assess(localGatewayRTTMilliseconds: telemetry.gatewayRTTMs) {
            case .favorable(let rtt):
                return .favorable(AppLocalization.format("network_cockpit.use_case.reason.low_local_rtt", rtt))
            case .attention(let rtt):
                return .attention(AppLocalization.format("network_cockpit.use_case.reason.high_local_rtt", rtt))
            case .notAssessed:
                return .notAssessed
            }
        case .multiplayer:
            guard let rtt, let topology = telemetry.natTopology else { return .notAssessed }
            if topology.natType == .type3Strict {
                return .attention(AppLocalization.string("network_cockpit.use_case.reason.strict_nat"))
            }
            if topology.doubleNATStatus == .suspectOrDetected {
                return .attention(AppLocalization.string("network_cockpit.use_case.reason.double_nat"))
            }
            if rtt > 15 {
                return .attention(AppLocalization.format("network_cockpit.use_case.reason.high_local_rtt", rtt))
            }
            if topology.natType != .inconclusive,
               topology.doubleNATStatus == .notDetected,
               rtt <= 5 {
                return .favorable(AppLocalization.format("network_cockpit.use_case.reason.favorable_nat_low_rtt", rtt))
            }
            return .notAssessed
        case .liveStream:
            guard let rtt else { return .notAssessed }
            if isConfirmed5GHz && rtt <= 6 {
                return .favorable(AppLocalization.format("network_cockpit.use_case.reason.5ghz_low_rtt", rtt))
            }
            if isConfirmed24GHz {
                return .attention(AppLocalization.string("network_cockpit.use_case.reason.2_4ghz_confirmed"))
            }
            if rtt > 15 {
                return .attention(AppLocalization.format("network_cockpit.use_case.reason.high_local_rtt", rtt))
            }
            return .notAssessed
        }
    }

    private enum GamerUseCase: String, CaseIterable, Identifiable {
        case cloudGaming
        case voiceChat
        case multiplayer
        case liveStream

        var id: String { rawValue }

        var order: Int {
            switch self {
            case .cloudGaming: return 0
            case .voiceChat: return 1
            case .multiplayer: return 2
            case .liveStream: return 3
            }
        }

        var titleKey: String {
            switch self {
            case .cloudGaming: return "network_cockpit.use_case.cloud_gaming"
            case .voiceChat: return "network_cockpit.use_case.voice_chat"
            case .multiplayer: return "network_cockpit.use_case.multiplayer"
            case .liveStream: return "network_cockpit.use_case.live_stream"
            }
        }

        var icon: String {
            switch self {
            case .cloudGaming: return "cloud.fill"
            case .voiceChat: return "mic.fill"
            case .multiplayer: return "person.3.fill"
            case .liveStream: return "dot.radiowaves.left.and.right"
            }
        }
    }

    private struct UseCasePresentation: Identifiable {
        let useCase: GamerUseCase
        let assessment: UseCaseAssessment
        var id: String { useCase.id }
    }

    private struct UseCaseAssessment {
        enum Kind {
            case favorable
            case attention
            case notAssessed

            var sortOrder: Int {
                switch self {
                case .favorable: return 0
                case .attention: return 1
                case .notAssessed: return 2
                }
            }
        }

        let kind: Kind
        let reason: String

        static var notAssessed: Self {
            Self(kind: .notAssessed, reason: AppLocalization.string("network_cockpit.use_case.reason.not_assessed"))
        }

        static func favorable(_ reason: String) -> Self { Self(kind: .favorable, reason: reason) }
        static func attention(_ reason: String) -> Self { Self(kind: .attention, reason: reason) }

        var color: Color {
            switch kind {
            case .favorable: return NLColor.scoreExcellent
            case .attention: return NLColor.cautionYellow
            case .notAssessed: return NLColor.textTertiary
            }
        }

        var symbolName: String {
            switch kind {
            case .favorable: return "checkmark.circle.fill"
            case .attention: return "exclamationmark.triangle.fill"
            case .notAssessed: return "minus.circle.fill"
            }
        }

        var localizedBadge: String {
            switch kind {
            case .favorable: return AppLocalization.string("network_cockpit.use_case.status.favorable")
            case .attention: return AppLocalization.string("network_cockpit.use_case.status.attention")
            case .notAssessed: return AppLocalization.string("network_cockpit.use_case.status.not_assessed")
            }
        }
    }

    // MARK: - Propriedades Computadas de Exibição
    private var natTypeDisplay: String {
        guard let nat = telemetry.natTopology else {
            return telemetry.isProbing ? AppLocalization.string("network_cockpit.probing_ellipsis") : "—"
        }
        switch nat.natType {
        case .type1Open: return AppLocalization.string("network_cockpit.nat.type1")
        case .type2Moderate: return AppLocalization.string("network_cockpit.nat.type2")
        case .type3Strict: return AppLocalization.string("network_cockpit.nat.type3")
        case .inconclusive: return AppLocalization.string("network_cockpit.nat.inconclusive")
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
        guard let nat = telemetry.natTopology else {
            return telemetry.isProbing ? AppLocalization.string("network_cockpit.probing_ellipsis") : "—"
        }
        switch nat.cgnatStatus {
        case .notDetected: return AppLocalization.string("network_cockpit.cgnat.free")
        case .detected: return AppLocalization.string("network_cockpit.cgnat.detected")
        case .inconclusive: return AppLocalization.string("network_cockpit.nat.inconclusive")
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
        guard let nat = telemetry.natTopology else {
            return telemetry.isProbing ? AppLocalization.string("network_cockpit.probing_ellipsis") : "—"
        }
        switch nat.doubleNATStatus {
        case .notDetected: return AppLocalization.string("network_cockpit.double_nat.not_detected")
        case .suspectOrDetected: return AppLocalization.string("network_cockpit.double_nat.detected")
        case .inconclusive: return AppLocalization.string("network_cockpit.nat.inconclusive")
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
        let useCasesList = useCasePresentations.map { presentation in
            (
                title: AppLocalization.string(presentation.useCase.titleKey),
                icon: presentation.useCase.icon,
                status: presentation.assessment.localizedBadge,
                color: uiColor(for: presentation.assessment.kind),
                note: presentation.assessment.reason
            )
        }

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

    private func uiColor(for kind: UseCaseAssessment.Kind) -> UIColor {
        switch kind {
        case .favorable: return UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1)
        case .attention: return UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1)
        case .notAssessed: return .lightGray
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
        • Casos de Uso (leitura local):
        \(useCasePresentations.map { "  - \(AppLocalization.string($0.useCase.titleKey)): \($0.assessment.localizedBadge)" }.joined(separator: "\n"))
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
