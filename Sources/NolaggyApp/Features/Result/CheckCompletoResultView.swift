import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Tela de Resultado Canônica HIG Dark Competitive do LagCheck para iPhone (iOS 17+).
/// Adota a iniciativa unificada (Decisões 50 e 51):
/// - Veredito semântico protagonista (● PRONTO PARA RANKED / ▲ EU EVITARIA RANKED AGORA)
/// - Telemetria compacta em card de 3 colunas (PING / JITTER / PERDA)
/// - Barra de estabilidade contínua
/// - Checklist honesto "O que encontramos" sem acusações causais falsas
/// - Ação primária Coral Solar e link secundário para detalhes técnicos profundos
public struct CheckCompletoResultView: View {
    public let result: DeepCheckResult?
    public let profileID: QualityProfileID
    public let gameName: String
    public let platform: Platform
    public let regionFriendlyName: String
    public let destinationKind: RouteDestinationKind
    public let isWiFi: Bool
    public let showDetails: () -> Void
    public let showBooster: () -> Void
    public let retry: () -> Void
    public let exit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activePlatformForTips: Platform? = nil

    public init(
        result: DeepCheckResult?,
        profileID: QualityProfileID = .battleRoyaleCompetitive,
        gameName: String,
        platform: Platform = .iphone,
        regionFriendlyName: String,
        destinationKind: RouteDestinationKind = .regionalReference,
        isWiFi: Bool = true,
        showDetails: @escaping () -> Void = {},
        showBooster: @escaping () -> Void = {},
        retry: @escaping () -> Void,
        exit: @escaping () -> Void = {}
    ) {
        self.result = result
        self.profileID = profileID
        self.gameName = gameName
        self.platform = platform
        self.regionFriendlyName = regionFriendlyName
        self.destinationKind = destinationKind
        self.isWiFi = isWiFi
        self.showDetails = showDetails
        self.showBooster = showBooster
        self.retry = retry
        self.exit = exit
    }

    public var body: some View {
        let evaluation = GameReadinessEvaluator.evaluate(deepCheckResult: result, profile: profileID)

        ScrollView {
            VStack(spacing: NLSpacing.lg) {
                // 1. Contexto compacto
                contextHeader

                // 2. Veredito Protagonista (Verdict-First)
                verdictHero(evaluation: evaluation)

                // 3. Telemetria Compacta (Ping, Jitter, Perda)
                compactTelemetryRow(evaluation: evaluation)

                // 4. Barra de Estabilidade Contínua
                stabilitySection(evaluation: evaluation)

                // 5. Checklist honesto "O que encontramos"
                if !evaluation.findings.isEmpty {
                    findingsSection(findings: evaluation.findings)
                }

                // 5.1 Otimização para a Plataforma (Decisão 56)
                platformOptimizationSection(evaluation: evaluation)

                // 6. Ações
                actionsSection(verdict: evaluation.verdict)
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.md)
        }
        .background(NLColor.deep.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NolaggyBackButton(action: exit, accessibilityIdentifier: "check-completo-back")
            }
        }
    }

    // MARK: - 1. Contexto Compacto

    private var contextHeader: some View {
        VStack(spacing: NLSpacing.xxs) {
            Text("\(gameName) · \(platform.displayName) · \(regionFriendlyName)")
                .font(NLTypography.footnote)
                .foregroundStyle(NLColor.textSecondary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("check-completo-context")

            if platform != .iphone {
                Text(LocalizedStringKey("check_completo.context.estimate_footnote"))
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.textTertiary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("check-completo-estimate-footnote")
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - 2. Veredito Protagonista

    private func verdictHero(evaluation: GameReadinessEvaluation) -> some View {
        VStack(spacing: NLSpacing.xs) {
            HStack(spacing: 8) {
                Image(systemName: evaluation.verdict.symbolName)
                    .font(.system(size: 20, weight: .bold))
                Text(LocalizedStringKey(evaluation.headlineKey))
                    .font(.system(size: 22, weight: .heavy, design: .default))
            }
            .foregroundStyle(colorForVerdict(evaluation.verdict))
            .accessibilityIdentifier("check-completo-verdict")
            .padding(.vertical, 4)

            Text(LocalizedStringKey(evaluation.subtitleKey))
                .font(NLTypography.body)
                .foregroundStyle(NLColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NLSpacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NLSpacing.xs)
    }

    // MARK: - 3. Telemetria Compacta (3 Colunas)

    private func compactTelemetryRow(evaluation: GameReadinessEvaluation) -> some View {
        HStack(spacing: 0) {
            telemetryColumn(
                label: LocalizedStringKey("game_readiness.telemetry.ping"),
                value: formattedMs(evaluation.pingMs),
                unit: "ms"
            )

            dividerLine

            telemetryColumn(
                label: LocalizedStringKey("game_readiness.telemetry.jitter"),
                value: formattedMs(evaluation.jitterMs),
                unit: "ms"
            )

            dividerLine

            telemetryColumn(
                label: LocalizedStringKey("game_readiness.telemetry.loss"),
                value: formattedLoss(evaluation.packetLossPercentage),
                unit: "%"
            )
        }
        .padding(.vertical, NLSpacing.md)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                .stroke(NLColor.hairline, lineWidth: 1)
        }
    }

    private func telemetryColumn(label: LocalizedStringKey, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(NLTypography.captionStrong)
                .foregroundStyle(NLColor.textTertiary)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .default))
                    .monospacedDigit()
                    .foregroundStyle(NLColor.textPrimary)

                if value != "—" {
                    Text(unit)
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(NLColor.hairline)
            .frame(width: 1, height: 32)
    }

    // MARK: - 4. Barra de Estabilidade Contínua

    private func stabilitySection(evaluation: GameReadinessEvaluation) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            HStack {
                Text(LocalizedStringKey("game_readiness.stability.section_title"))
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.textTertiary)
                    .textCase(.uppercase)

                Spacer()

                Text(LocalizedStringKey(evaluation.stabilitySummaryKey))
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.textSecondary)
            }

            // Gauge Contínuo
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(NLColor.panel)
                        .frame(height: 6)

                    Capsule()
                        .fill(colorForVerdict(evaluation.verdict))
                        .frame(width: max(proxy.size.width * CGFloat(evaluation.stabilityRatio), 8), height: 6)
                        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8), value: evaluation.stabilityRatio)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, NLSpacing.xs)
    }

    // MARK: - 5. Checklist "O Que Encontramos"

    private func findingsSection(findings: [NetworkFinding]) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            Text(LocalizedStringKey("game_readiness.findings.section_title"))
                .font(NLTypography.sectionHeader)
                .foregroundStyle(NLColor.textTertiary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                ForEach(Array(findings.enumerated()), id: \.offset) { index, finding in
                    HStack(spacing: NLSpacing.sm) {
                        Image(systemName: iconForFindingSeverity(finding.severity))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(colorForFindingSeverity(finding.severity))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(finding.labelKey))
                                .font(NLTypography.callout.weight(.medium))
                                .foregroundStyle(NLColor.textPrimary)

                            if let detail = finding.detail {
                                Text(detail)
                                    .font(NLTypography.caption)
                                    .foregroundStyle(NLColor.textSecondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, NLSpacing.sm)
                    .padding(.horizontal, NLSpacing.md)

                    if index < findings.count - 1 {
                        Divider()
                            .overlay(NLColor.hairline)
                            .padding(.leading, 44)
                    }
                }
            }
            .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                    .stroke(NLColor.hairline, lineWidth: 1)
            }
        }
    }

    // MARK: - 5.1 Otimização para a Plataforma (Decisão 56)

    private func platformOptimizationSection(evaluation: GameReadinessEvaluation) -> some View {
        let targetPlatform = activePlatformForTips ?? platform

        return VStack(alignment: .leading, spacing: NLSpacing.sm) {
            HStack {
                Text(String(format: AppLocalization.string("platform_optimization.title", comment: ""), targetPlatform.displayName.uppercased()))
                    .font(NLTypography.sectionHeader)
                    .foregroundStyle(NLColor.textTertiary)

                Spacer()

                Menu {
                    ForEach(Platform.allCases, id: \.self) { p in
                        Button(action: { activePlatformForTips = p }) {
                            if (activePlatformForTips ?? platform) == p {
                                Label(p.displayName, systemImage: "checkmark")
                            } else {
                                Text(p.displayName)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(targetPlatform.displayName)
                            .font(NLTypography.captionStrong)
                            .foregroundStyle(NLColor.accentPrimary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(NLColor.accentPrimary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(NLColor.accentPrimarySubtle, in: Capsule())
                }
            }

            VStack(spacing: NLSpacing.sm) {
                // Nível 1: Você mesmo no seu setup
                optimizationLevelCard(
                    title: LocalizedStringKey("platform_optimization.level1.title"),
                    icon: "person.fill.checkmark",
                    iconColor: NLColor.scoreExcellent,
                    tip: level1Tip(for: targetPlatform, evaluation: evaluation)
                )

                // Nível 2: Com a operadora
                if let tip2 = level2Tip(for: targetPlatform, evaluation: evaluation) {
                    optimizationLevelCard(
                        title: LocalizedStringKey("platform_optimization.level2.title"),
                        icon: "phone.badge.waveform.fill",
                        iconColor: NLColor.scoreUnstable,
                        tip: tip2
                    )
                }

                // Nível 3: Equipamento / Roteador
                if let tip3 = level3Tip(for: targetPlatform, evaluation: evaluation) {
                    optimizationLevelCard(
                        title: LocalizedStringKey("platform_optimization.level3.title"),
                        icon: "router.fill",
                        iconColor: NLColor.coralSolar,
                        tip: tip3
                    )
                }
            }
        }
    }

    private func optimizationLevelCard(
        title: LocalizedStringKey,
        icon: String,
        iconColor: Color,
        tip: String
    ) -> some View {
        HStack(alignment: .top, spacing: NLSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
                .background(iconColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.textSecondary)

                Text(tip)
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(NLSpacing.md)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                .stroke(NLColor.borderHairline, lineWidth: 1)
        )
    }

    private func level1Tip(for targetPlatform: Platform, evaluation: GameReadinessEvaluation) -> String {
        let isConsoleOrPC = targetPlatform != .iphone
        if isConsoleOrPC && isWiFi {
            return "Conecte o \(targetPlatform.displayName) no cabo de rede Ethernet (Cat6) direto no roteador. O Wi-Fi é a causa número 1 de oscilação em consoles e PC."
        }
        if evaluation.findings.contains(where: { $0.kind == .natTopology }) {
            return "Ative o UPnP no seu roteador ou configure IP estático no \(targetPlatform.displayName) com DMZ para liberar as portas NAT."
        }
        if evaluation.findings.contains(where: { $0.kind == .latencySpikes }) {
            return "Feche downloads em segundo plano, torrents ou streaming na sua rede local enquanto joga."
        }
        return "Seu setup local está saudável. Mantenha os downloads pausados na rede durante a partida para garantir a latência mínima."
    }

    private func level2Tip(for targetPlatform: Platform, evaluation: GameReadinessEvaluation) -> String? {
        if evaluation.findings.contains(where: { $0.kind == .natTopology }) {
            return "Sua operadora pode estar roteando você por CGNAT (IP compartilhado). Peça no suporte da operadora: 'Preciso de IP público dinâmico ou IPv6 nativo para jogos online'."
        }
        if evaluation.findings.contains(where: { $0.kind == .packetLoss }) {
            return "Perda de pacotes na rota externa detectada. Solicite à operadora uma verificação de atenuação de sinal na sua fibra óptica."
        }
        if evaluation.findings.contains(where: { $0.kind == .highLatency }) {
            return "Latência base elevada para a rota do jogo. Consulte se a operadora possui rota direta otimizada para o data center."
        }
        return nil
    }

    private func level3Tip(for targetPlatform: Platform, evaluation: GameReadinessEvaluation) -> String? {
        if evaluation.findings.contains(where: { $0.kind == .loadDegradation }) {
            return "Sua conexão sofre oscilação sob uso simultâneo (Bufferbloat). A solução definitiva é um roteador próprio com suporte a SQM (CAKE/FQ-CoDel)."
        }
        if evaluation.verdict == .notReady {
            return "Se o modem da sua operadora for básico, colocá-lo em modo Bridge com um roteador Wi-Fi 6 de boa capacidade estabiliza a rota."
        }
        return nil
    }

    // MARK: - 6. Ações

    private func actionsSection(verdict: GameReadinessVerdict) -> some View {
        VStack(spacing: NLSpacing.sm) {
            // Ação Primária Coral Solar: [ TESTAR NOVAMENTE ]
            Button(action: retry) {
                Text(LocalizedStringKey("game_readiness.cta.retest"))
                    .font(NLTypography.headline.weight(.heavy))
                    .tracking(0.5)
                    .foregroundStyle(NLColor.deep)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: NLSizing.touchTarget)
                    .background(NLColor.coralSolar, in: RoundedRectangle(cornerRadius: NLRadius.button, style: .continuous))
            }
            .accessibilityIdentifier("check-completo-primary-action")

            // Ação Secundária: Entender minha conexão / Ver detalhes técnicos
            Button(action: showDetails) {
                Text(LocalizedStringKey(verdict == .ready ? "game_readiness.cta.understand_connection" : "game_readiness.cta.understand_problem"))
                    .font(NLTypography.callout.weight(.semibold))
                    .foregroundStyle(NLColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: NLSizing.touchTarget)
            }
            .accessibilityIdentifier("check-completo-details")

            // Se instável e booster disponível, link discreto
            if verdict == .caution || verdict == .notReady {
                Button(action: showBooster) {
                    Text(LocalizedStringKey("booster.cta.button"))
                        .font(NLTypography.footnote.weight(.medium))
                        .foregroundStyle(NLColor.textTertiary)
                        .padding(.vertical, 4)
                }
                .accessibilityIdentifier("check-completo-improve")
            }
        }
        .padding(.top, NLSpacing.xs)
    }

    // MARK: - Helpers & Formatação

    private func formattedMs(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value.rounded()))"
    }

    private func formattedLoss(_ loss: Double?) -> String {
        guard let loss else { return "—" }
        if loss <= 0.05 {
            return "0"
        }
        return String(format: "%.1f", loss)
    }

    private func colorForVerdict(_ verdict: GameReadinessVerdict) -> Color {
        switch verdict {
        case .ready: return NLColor.readyGreen
        case .caution: return NLColor.cautionYellow
        case .notReady: return NLColor.notReadyRed
        case .inconclusive: return NLColor.textTertiary
        }
    }

    private func colorForFindingSeverity(_ severity: NetworkFinding.Severity) -> Color {
        switch severity {
        case .positive: return NLColor.readyGreen
        case .warning: return NLColor.cautionYellow
        case .negative: return NLColor.notReadyRed
        case .neutral: return NLColor.textTertiary
        }
    }

    private func iconForFindingSeverity(_ severity: NetworkFinding.Severity) -> String {
        switch severity {
        case .positive: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .negative: return "xmark.circle.fill"
        case .neutral: return "info.circle.fill"
        }
    }
}
