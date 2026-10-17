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
    public let gameID: String?
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

    private enum ShareDestination: Identifiable {
        case discord(items: [Any])
        case whatsApp(items: [Any])
        case link(items: [Any])
        case pdf(items: [Any])

        var id: String {
            switch self {
            case .discord: return "discord"
            case .whatsApp: return "whatsApp"
            case .link: return "link"
            case .pdf: return "pdf"
            }
        }

        var items: [Any] {
            switch self {
            case .discord(let items), .whatsApp(let items), .link(let items), .pdf(let items):
                return items
            }
        }
    }

    @State private var activeShareDestination: ShareDestination? = nil
    @State private var preparedShareCardURL: URL? = nil
    @State private var shareCardPreparationFailed = false
    @State private var shareCardPreparationAttempt = 0
    @State private var preparedSharePreview: UIImage? = nil

    private struct ShareCardSnapshot: Equatable, Sendable {
        let gameID: String?
        let gameName: String
        let regionName: String
        let verdict: GameReadinessVerdict
        let pingMs: Double?
        let jitterMs: Double?
        let packetLossPercentage: Double?
        let bufferbloatGradeText: String?
        let isWiFi: Bool
        let localeIdentifier: String
        let measurementIdentity: String

        var cacheKey: String {
            "\(gameID ?? "")|\(gameName)|\(regionName)|\(verdict.rawValue)|\(pingMs ?? -1)|\(jitterMs ?? -1)|\(packetLossPercentage ?? -1)|\(bufferbloatGradeText ?? "—")|\(isWiFi)|\(localeIdentifier)|\(measurementIdentity)"
        }
    }

    public init(
        result: DeepCheckResult?,
        profileID: QualityProfileID = .battleRoyaleCompetitive,
        gameID: String? = nil,
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
        self.gameID = gameID
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
            VStack(alignment: .leading, spacing: 0) {
                // Top bar: Fechar e Contexto
                HStack {
                    Button(action: exit) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(NLColor.textPrimary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("check-completo-back")
                    .background(
                        Button(action: exit) {
                            Text("measurement-back")
                        }
                        .frame(width: 0, height: 0)
                        .opacity(0.001)
                        .accessibilityIdentifier("measurement-back")
                    )

                    Spacer()

                    Text(verbatim: regionFriendlyName.isEmpty ? "\(gameName) · \(platform.displayName)" : "\(gameName) · \(platform.displayName) · \(regionFriendlyName)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(NLColor.textTertiary)
                        .accessibilityIdentifier("check-completo-context")
                }
                .frame(height: 52)

                // Veredito Protagonista (Mockup 04)
                VStack(alignment: .leading, spacing: 0) {
                    Text(LocalizedStringKey("result.kicker"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(NLColor.textTertiary)
                        .padding(.top, 36)
                        .padding(.bottom, 13)

                    HStack(spacing: 10) {
                        VerdictIndicatorBadge(verdict: evaluation.verdict, size: 18)
                        Text(LocalizedStringKey(evaluation.headlineKey))
                            .font(.system(size: 42, weight: .black))
                            .accessibilityIdentifier("check-completo-verdict")
                    }
                    .foregroundStyle(colorForVerdict(evaluation.verdict))
                    .fixedSize(horizontal: false, vertical: true)

                    Text(LocalizedStringKey(evaluation.subtitleKey))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(NLColor.textPrimary)
                        .lineSpacing(4)
                        .padding(.top, 19)

                    // No Android a prévia já confirma o que será compartilhado
                    // antes de a pessoa entrar na telemetria. Mantemos a mesma
                    // ordem sem tornar o preparo um bloqueio do resultado.
                    if evaluation.verdict != .inconclusive {
                        sharePreview(evaluation: evaluation)
                            .padding(.top, 22)
                    }

                    // Métricas inline em tipografia monoespaçada
                    HStack(spacing: 6) {
                        Text(verbatim: "\(formattedMs(evaluation.pingMs)) ms")
                            .font(.system(size: 11, weight: .semibold).monospacedDigit())
                            .foregroundStyle(NLColor.textPrimary)

                        Text(verbatim: "·")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(NLColor.textTertiary)

                        Text(verbatim: "\(formattedMs(evaluation.jitterMs)) ms jitter")
                            .font(.system(size: 11, weight: .semibold).monospacedDigit())
                            .foregroundStyle(NLColor.textPrimary)

                        Text(verbatim: "·")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(NLColor.textTertiary)

                        Text(verbatim: "\(formattedLoss(evaluation.packetLossPercentage))% \(AppLocalization.string("game_readiness.telemetry.loss", comment: ""))")
                            .font(.system(size: 11, weight: .semibold).monospacedDigit())
                            .foregroundStyle(NLColor.textPrimary)
                    }
                    .padding(.top, 22)
                    .background(
                        HStack(spacing: 0) {
                            Text("PING")
                            Text("JITTER")
                            Text(LocalizedStringKey("game_readiness.telemetry.loss"))
                        }
                        .frame(width: 0, height: 0)
                        .opacity(0.001)
                        .clipped()
                    )

                    if let grade = evaluation.metrics?.loadImpact?.bufferbloatGrade {
                        HStack(spacing: 6) {
                            Text(LocalizedStringKey("result.bufferbloat.label"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(NLColor.textTertiary)
                            Text(verbatim: "\(grade.rawValue)")
                                .font(.system(size: 11, weight: .heavy).monospacedDigit())
                                .foregroundStyle(
                                    (grade == .aPlus || grade == .a || grade == .b)
                                        ? colorForVerdict(.ready)
                                        : ((grade == .c) ? NLColor.cautionYellow : NLColor.coralSolar)
                                )
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(NLColor.surface, in: Capsule())
                        .overlay(Capsule().stroke(NLColor.borderStrong, lineWidth: 1))
                        .padding(.top, 12)
                    }

                    // Card: O que mais pesou
                    VStack(alignment: .leading, spacing: 5) {
                        Text(LocalizedStringKey("result.weight_card.title"))
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(NLColor.textTertiary)
                            .textCase(.uppercase)

                        Text(weightText(evaluation: evaluation))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(NLColor.textPrimary)
                    }
                    .padding(15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .padding(.top, 27)
                }

                // Ações do Resultado
                actionsSection(evaluation: evaluation)
                NativeAdSlot(placement: .result)
            }
            .padding(.horizontal, NLSpacing.md)
            .padding(.bottom, NLSpacing.xl)
        }
        .background(NLColor.deep.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $activeShareDestination) { destination in
            ShareSheet(items: destination.items)
        }
        .task(id: "\(shareCardSnapshot(evaluation: evaluation)?.cacheKey ?? "inconclusive"):\(shareCardPreparationAttempt)") {
            preparedShareCardURL = nil
            preparedSharePreview = nil
            shareCardPreparationFailed = false
            guard let snapshot = shareCardSnapshot(evaluation: evaluation) else { return }
            // Deixa a manchete do veredito chegar à tela antes de ocupar CPU com o renderer.
            await Task.yield()
            guard !Task.isCancelled else { return }
            let cardURL = await Task.detached(priority: .utility) {
                LagCheckDiscordCardExporter.prepareDiscordShareCard(
                    snapshotKey: snapshot.cacheKey,
                    gameID: snapshot.gameID,
                    gameName: snapshot.gameName,
                    regionName: snapshot.regionName,
                    verdict: snapshot.verdict,
                    pingMs: snapshot.pingMs,
                    jitterMs: snapshot.jitterMs,
                    packetLossPercentage: snapshot.packetLossPercentage,
                    bufferbloatGradeText: snapshot.bufferbloatGradeText,
                    isWiFi: snapshot.isWiFi
                )
            }.value
            guard !Task.isCancelled else { return }
            preparedShareCardURL = cardURL
            shareCardPreparationFailed = cardURL == nil
            preparedSharePreview = cardURL.flatMap { UIImage(contentsOfFile: $0.path) }
        }
    }

    private func verdictSymbol(for verdict: GameReadinessVerdict) -> String {
        switch verdict {
        case .ready: return "●"
        case .caution, .notReady: return "▲"
        case .inconclusive: return "—"
        }
    }

    private func sharePreview(evaluation: GameReadinessEvaluation) -> some View {
        let a11yLabel: String
        if shareCardPreparationFailed {
            a11yLabel = AppLocalization.string("share.card.failed", comment: "")
        } else if preparedSharePreview != nil {
            a11yLabel = "\(AppLocalization.string("share.card.ready", comment: "")): \(AppLocalization.string(evaluation.headlineKey, comment: "")), \(gameName), \(regionFriendlyName)"
        } else {
            a11yLabel = AppLocalization.string("share.card.preparing", comment: "")
        }

        return Group {
            if shareCardPreparationFailed {
                Button {
                    preparedShareCardURL = nil
                    preparedSharePreview = nil
                    shareCardPreparationFailed = false
                    shareCardPreparationAttempt += 1
                } label: {
                    VStack(spacing: 8) {
                        Text(AppLocalization.string("share.card.failed", comment: ""))
                        Text(AppLocalization.string("share.card.retry", comment: ""))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(NLColor.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("check-completo-share-preview")
                .accessibilityHint(AppLocalization.string("share.card.retry", comment: ""))
            } else {
                Button {
                    guard let preparedShareCardURL, FileManager.default.fileExists(atPath: preparedShareCardURL.path) else {
                        shareCardPreparationFailed = true
                        return
                    }
                    activeShareDestination = .link(items: [preparedShareCardURL])
                } label: {
                    Group {
                        if let preparedSharePreview {
                            Image(uiImage: preparedSharePreview).resizable().scaledToFit()
                        } else {
                            RoundedRectangle(cornerRadius: NLRadius.sm, style: .continuous).fill(NLColor.surface)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(preparedSharePreview == nil)
                .accessibilityIdentifier("check-completo-share-preview")
                .accessibilityHint(AppLocalization.string("share.card.open_hint", comment: ""))
            }
        }
        .frame(maxWidth: 360)
        .aspectRatio(1200.0 / 630.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: NLRadius.sm, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.sm, style: .continuous).stroke(NLColor.borderSubtle, lineWidth: 1))
        .accessibilityLabel(a11yLabel)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func weightText(evaluation: GameReadinessEvaluation) -> String {
        if let firstFinding = evaluation.findings.first {
            return AppLocalization.string(firstFinding.labelKey, comment: "")
        }
        if evaluation.verdict == .ready {
            return AppLocalization.string("result.weight.stable_route", comment: "")
        }
        return AppLocalization.string("result.weight.jitter_oscillation", comment: "")
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
                    .font(NLTypography.metricsNumber)
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

    // MARK: - 5.1 Oportunidade de Maior Impacto (Decisão 56 / Ajuste de Produto)

    private func platformOptimizationSection(evaluation: GameReadinessEvaluation) -> some View {
        let targetPlatform = activePlatformForTips ?? platform
        let topOptimization = HighImpactOptimizationEvaluator.evaluateSingleTopOptimization(
            targetPlatform: targetPlatform,
            evaluation: evaluation,
            isWiFi: isWiFi
        )

        return VStack(alignment: .leading, spacing: NLSpacing.sm) {
            HStack {
                Text(LocalizedStringKey("game_readiness.single_optimization.header"))
                    .font(NLTypography.sectionHeader)
                    .foregroundStyle(NLColor.textTertiary)
                    .textCase(.uppercase)

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

            singleImpactOptimizationCard(optimization: topOptimization)
        }
    }

    private func singleImpactOptimizationCard(optimization: HighImpactOptimization) -> some View {
        HStack(alignment: .top, spacing: NLSpacing.sm) {
            Image(systemName: optimization.systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(optimization.isCritical ? NLColor.coralSolar : NLColor.scoreExcellent)
                .frame(width: 34, height: 34)
                .background((optimization.isCritical ? NLColor.coralSolar : NLColor.scoreExcellent).opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(optimization.title)
                        .font(NLTypography.headline)
                        .foregroundStyle(NLColor.textPrimary)

                    Spacer(minLength: 4)

                    Text(optimization.impactBadge.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(optimization.isCritical ? NLColor.coralSolar : NLColor.scoreExcellent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((optimization.isCritical ? NLColor.coralSolar : NLColor.scoreExcellent).opacity(0.15), in: Capsule())
                }

                Text(optimization.instruction)
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(NLSpacing.md)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                .stroke(optimization.isCritical ? NLColor.coralSolar.opacity(0.35) : NLColor.borderHairline, lineWidth: 1)
        }
    }

    private func exportResultPDF(evaluation: GameReadinessEvaluation) {
        let topOpt = HighImpactOptimizationEvaluator.evaluateSingleTopOptimization(
            targetPlatform: activePlatformForTips ?? platform,
            evaluation: evaluation,
            isWiFi: isWiFi
        )
        let uiColor: UIColor
        switch evaluation.verdict {
        case .ready: uiColor = UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1)
        case .caution: uiColor = UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1)
        case .notReady: uiColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1)
        case .inconclusive: uiColor = .lightGray
        }

        let scoreStr = result.map { "\($0.restResult.finalScore)" } ?? "—"
        let bufferbloatGrade = evaluation.findings.contains(where: { $0.kind == .loadDegradation }) ? "Degradado" : "Estável"

        if let pdfURL = LagCheckPDFExporter.generateMeasurementResultPDF(
            gameName: gameName,
            platformName: (activePlatformForTips ?? platform).displayName,
            regionName: regionFriendlyName,
            verdictHeadline: AppLocalization.string(evaluation.headlineKey, comment: ""),
            verdictColor: uiColor,
            verdictSubtitle: AppLocalization.string(evaluation.subtitleKey, comment: ""),
            scoreText: scoreStr,
            pingMs: evaluation.pingMs,
            jitterMs: evaluation.jitterMs,
            lossPercentage: evaluation.packetLossPercentage,
            bufferbloatGrade: bufferbloatGrade,
            topOptimization: topOpt.instruction,
            optimizationSeverity: topOpt.impactBadge
        ) {
            self.activeShareDestination = .pdf(items: [pdfURL])
        }
    }

    private func shareToDiscord(evaluation: GameReadinessEvaluation) {
        Task { @MainActor in
            if let cardURL = await shareCardURL(evaluation: evaluation) {
            let quote = LagCheckDiscordCardExporter.gamerQuote(for: evaluation.verdict)
            let shareText = "🎮 LagCheck · \(gameName)\n\(quote)\nhttps://lagcheck.signallq.com"
            if let image = UIImage(contentsOfFile: cardURL.path) {
                UIPasteboard.general.image = image
                self.activeShareDestination = .discord(items: [image, shareText])
            } else {
                self.activeShareDestination = .discord(items: [cardURL, shareText])
            }
        }
        }
    }

    private func shareToWhatsApp(evaluation: GameReadinessEvaluation) {
        Task { @MainActor in
            if let cardURL = await shareCardURL(evaluation: evaluation) {
            let pingStr = evaluation.pingMs.map { "\(Int(round($0))) ms" } ?? "—"
            let jitterStr = evaluation.jitterMs.map { String(format: "%.1f ms", $0) } ?? "—"
            let lossStr = evaluation.packetLossPercentage.map { String(format: "%.1f%%", $0) } ?? "—"
            let quote = LagCheckDiscordCardExporter.gamerQuote(for: evaluation.verdict)

            let pingLabel = AppLocalization.string("game_readiness.telemetry.ping", comment: "")
            let jitterLabel = AppLocalization.string("quick_check.result.jitter", comment: "")
            let lossLabel = AppLocalization.string("result.weight.packet_loss", comment: "")
            let verdictLabel = AppLocalization.string(evaluation.headlineKey, comment: "")

            let whatsappText = """
            🎮 *LagCheck — \(gameName)*
            *\(AppLocalization.string("result.weight.title", comment: "")):* \(verdictLabel)
            ⏱ *\(pingLabel):* \(pingStr) | *\(jitterLabel):* \(jitterStr) | *\(lossLabel):* \(lossStr)
            \(quote)
            https://lagcheck.signallq.com
            """

            if let image = UIImage(contentsOfFile: cardURL.path) {
                UIPasteboard.general.image = image
                self.activeShareDestination = .whatsApp(items: [image, whatsappText])
            } else {
                self.activeShareDestination = .whatsApp(items: [cardURL, whatsappText])
            }
        }
        }
    }

    // MARK: - 6. Ações

    private func actionsSection(evaluation: GameReadinessEvaluation) -> some View {
        VStack(spacing: 10) {
            // A ação que recoloca a pessoa no Check vem antes da exploração.
            Button(action: retry) {
                Text(LocalizedStringKey("result.retest_button"))
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(NLColor.gamerPurple, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("check-completo-primary-action")

            Button(action: showDetails) {
                Text(LocalizedStringKey("result.details_button"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(NLColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(NLColor.borderStrong, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("check-completo-details")

            // Ações Utilitárias Compactas: Discord, WhatsApp e PDF separados
            HStack(spacing: 8) {
                if evaluation.verdict != .inconclusive {
                // Botão Discord com ícone oficial
                Button(action: { shareToDiscord(evaluation: evaluation) }) {
                    HStack(spacing: 6) {
                        DiscordLogo(size: 15)
                        Text(verbatim: "Discord")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(Color(red: 88/255, green: 101/255, blue: 242/255))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(NLColor.borderStrong, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("check-completo-discord-share")
                .accessibilityValue(shareCardAccessibilityValue)
                .disabled(preparedShareCardURL == nil)

                // Botão WhatsApp com ícone oficial
                Button(action: { shareToWhatsApp(evaluation: evaluation) }) {
                    HStack(spacing: 6) {
                        WhatsAppLogo(size: 15)
                        Text(verbatim: "WhatsApp")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(Color(red: 37/255, green: 211/255, blue: 102/255))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(NLColor.borderStrong, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("check-completo-whatsapp-share")
                .accessibilityValue(shareCardAccessibilityValue)
                .disabled(preparedShareCardURL == nil)
                }

                // Botão PDF
                Button(action: { exportResultPDF(evaluation: evaluation) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 13, weight: .medium))
                        Text(verbatim: "PDF")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(NLColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(NLColor.borderStrong, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("check-completo-export-pdf")
            }
            .padding(.top, 4)
        }
        .padding(.top, 24)
    }

    // MARK: - Helpers & Formatação

    private func formattedMs(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value.rounded()))"
    }

    private var shareCardAccessibilityValue: String {
        if preparedShareCardURL != nil { return AppLocalization.string("share.card.ready", comment: "") }
        if shareCardPreparationFailed { return AppLocalization.string("share.card.failed", comment: "") }
        return AppLocalization.string("share.card.preparing", comment: "")
    }

    private func shareCardSnapshot(evaluation: GameReadinessEvaluation) -> ShareCardSnapshot? {
        guard evaluation.verdict != .inconclusive, let result else { return nil }
        return ShareCardSnapshot(
            gameID: gameID,
            gameName: gameName,
            regionName: regionFriendlyName,
            verdict: evaluation.verdict,
            pingMs: evaluation.pingMs,
            jitterMs: evaluation.jitterMs,
            packetLossPercentage: evaluation.packetLossPercentage,
            bufferbloatGradeText: evaluation.metrics?.loadImpact?.bufferbloatGrade.rawValue,
            isWiFi: isWiFi,
            localeIdentifier: AppLocalization.locale.identifier,
            measurementIdentity: measurementIdentity(for: result)
        )
    }

    private func measurementIdentity(for result: DeepCheckResult) -> String {
        let data = (try? JSONEncoder().encode(result)) ?? Data()
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in data { hash ^= UInt64(byte); hash &*= 1_099_511_628_211 }
        return String(hash, radix: 16)
    }

    @MainActor
    private func shareCardURL(evaluation: GameReadinessEvaluation) async -> URL? {
        if let preparedShareCardURL { return preparedShareCardURL }
        return preparedShareCardURL
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
