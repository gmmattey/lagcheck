import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Tela de Resultado Canônica do Check Completo do LagCheck para iPhone (iOS 17+).
/// Apresenta veredito rápido, objetivo e com personalidade, sem termos de aplicativo genérico.
/// Composta por Contexto compacto, Hero de Veredito, Trilha Consolidada HIG,
/// Faixa de Compatibilidade da Sessão e Barra de Ações balanceadas.
public struct CheckCompletoResultView: View {
    public let result: DeepCheckResult?
    public let profileID: QualityProfileID
    public let gameName: String
    public let platform: Platform
    public let regionFriendlyName: String
    public let destinationKind: RouteDestinationKind
    public let isWiFi: Bool
    public let natSnapshot: NATTopologySnapshot?
    public let showDetails: () -> Void
    public let showBooster: () -> Void
    public let retry: () -> Void
    public let exit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        result: DeepCheckResult?,
        profileID: QualityProfileID = .battleRoyaleCompetitive,
        gameName: String,
        platform: Platform = .iphone,
        regionFriendlyName: String,
        destinationKind: RouteDestinationKind = .regionalReference,
        isWiFi: Bool = true,
        natSnapshot: NATTopologySnapshot? = nil,
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
        self.natSnapshot = natSnapshot
        self.showDetails = showDetails
        self.showBooster = showBooster
        self.retry = retry
        self.exit = exit
    }

    public var body: some View {
        let verdict = CheckCompletoResultEvaluator.evaluateVerdict(result: result, profile: profileID)
        let trailSnapshot = CheckCompletoResultEvaluator.evaluateTrail(result: result, profile: profileID)
        let compatSnapshot = CheckCompletoResultEvaluator.evaluateCompatibility(
            result: result,
            natSnapshot: natSnapshot,
            profile: profileID
        )

        ScrollView {
            VStack(spacing: NLSpacing.lg) {
                // 1. Contexto compacto no topo
                contextHeader

                // 2. Hero de Resultado (Score + Veredito sem parágrafo descritivo)
                heroSection(verdict: verdict)

                // 3. Trilha Consolidada HIG (5 nós verticais)
                ConsolidatedRouteTrailView(
                    isWiFi: isWiFi,
                    regionName: regionFriendlyName,
                    destinationKind: destinationKind,
                    networkState: mapTrailNodeState(trailSnapshot.networkState),
                    responseState: mapTrailNodeState(trailSnapshot.responseState),
                    deliveryState: mapTrailNodeState(trailSnapshot.deliveryState),
                    loadState: mapTrailNodeState(trailSnapshot.loadState),
                    regionState: mapTrailNodeState(trailSnapshot.regionState)
                )

                // 4. Faixa Compacta de Compatibilidade da Sessão
                SessionCompatibilityStrip(
                    multiplayer: mapCompatState(compatSnapshot.multiplayer),
                    calls: mapCompatState(compatSnapshot.calls),
                    streaming: mapCompatState(compatSnapshot.streaming)
                )

                // 5. Ações
                actionsSection(isValid: result != nil)
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.lg)
        }
        .background(NLColor.backgroundBase.ignoresSafeArea())
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

    // MARK: - 2. Hero de Resultado

    @ViewBuilder
    private func heroSection(verdict: CheckCompletoVerdict) -> some View {
        VStack(spacing: NLSpacing.xs) {
            if let result {
                // Score destacado apenas quando medição for válida
                let score = result.restResult.finalScore
                let scoreColor = colorForScore(score, band: result.restResult.resultClass)

                Text("\(score)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(scoreColor)
                    .accessibilityIdentifier("check-completo-score")
            }

            // Veredito curto e objetivo (sem parágrafo explicativo abaixo)
            Text(LocalizedStringKey(verdict.titleKey))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(NLColor.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("check-completo-verdict")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NLSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(heroAccessibilityLabel(verdict: verdict))
    }

    private func heroAccessibilityLabel(verdict: CheckCompletoVerdict) -> String {
        let verdictLocalized = NSLocalizedString(verdict.titleKey, comment: "")
        if let result {
            return String(
                localized: "quick_check.result.score_accessibility",
                defaultValue: "LagCheck Score %d, %@"
            )
            .replacingOccurrences(of: "%d", with: "\(result.restResult.finalScore)")
            .replacingOccurrences(of: "%@", with: verdictLocalized)
        } else {
            return verdictLocalized
        }
    }

    // MARK: - 5. Ações

    private func actionsSection(isValid: Bool) -> some View {
        VStack(spacing: NLSpacing.sm) {
            // Ação Primária Coral Solar: "Testar de novo" ou "Tentar de novo"
            PrimaryButton(
                title: isValid ? "check_completo.action.retest" : "check_completo.action.try_again",
                action: retry
            )
            .accessibilityIdentifier("check-completo-primary-action")

            // Ações Secundárias Discretas (exibidas somente com resultado válido)
            if isValid {
                HStack(spacing: NLSpacing.sm) {
                    secondaryActionButton(
                        titleKey: "check_completo.action.details",
                        identifier: "check-completo-details",
                        action: showDetails
                    )

                    secondaryActionButton(
                        titleKey: "check_completo.action.improve",
                        identifier: "check-completo-improve",
                        action: showBooster
                    )
                }
            }
        }
        .padding(.top, NLSpacing.xs)
    }

    private func secondaryActionButton(titleKey: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(LocalizedStringKey(titleKey))
                .font(NLTypography.callout.weight(.semibold))
                .foregroundStyle(NLColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: NLSizing.touchTarget)
                .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.button, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: NLRadius.button, style: .continuous)
                        .stroke(NLColor.borderSubtle, lineWidth: 0.5)
                }
        }
        .accessibilityIdentifier(identifier)
    }

    // MARK: - Mapeadores de Estado

    private func mapTrailNodeState(_ state: ConsolidatedTrailNodeState) -> ConsolidatedRouteTrailView.NodeState {
        switch state {
        case .check: return .check
        case .attention: return .attention
        case .neutral: return .neutral
        }
    }

    private func mapCompatState(_ state: SessionCompatibilityState) -> SessionCompatibilityStrip.State {
        switch state {
        case .check: return .check
        case .attention: return .attention
        case .neutral: return .neutral
        }
    }

    private func colorForScore(_ score: Int, band: ResultClass) -> Color {
        switch band {
        case .excellent, .great:
            return NLColor.scoreExcellent
        case .unstable:
            return NLColor.scoreUnstable
        case .lagRisk:
            return NLColor.coralSolarRed
        }
    }
}

// MARK: - Previews Canônicos dos 5 Estados

#Preview("1. Saudável · A rota segurou") {
    CheckCompletoResultView(
        result: makePreviewResult(score: 92, band: .excellent, p50: 22.0, loss: 0.0, loadDelta: 4.0),
        gameName: "Fortnite",
        platform: .iphone,
        regionFriendlyName: "São Paulo",
        isWiFi: true,
        natSnapshot: NATTopologySnapshot(natType: .type2Moderate, cgnatStatus: .notDetected, doubleNATStatus: .notDetected),
        retry: {}
    )
}

#Preview("2. Rota oscilou · Instabilidade geral") {
    CheckCompletoResultView(
        result: makePreviewResult(score: 74, band: .unstable, p50: 85.0, loss: 0.0, jitter: 24.0, loadDelta: 8.0),
        gameName: "Fortnite",
        platform: .playstation,
        regionFriendlyName: "São Paulo",
        isWiFi: true,
        natSnapshot: NATTopologySnapshot(natType: .type2Moderate, cgnatStatus: .notDetected, doubleNATStatus: .notDetected),
        retry: {}
    )
}

#Preview("3. Carga pesou · Impacto sob carga") {
    CheckCompletoResultView(
        result: makePreviewResult(score: 61, band: .unstable, p50: 28.0, loss: 0.0, loadDelta: 42.0),
        gameName: "Roblox",
        platform: .pc,
        regionFriendlyName: "São Paulo",
        isWiFi: true,
        natSnapshot: NATTopologySnapshot(natType: .type2Moderate, cgnatStatus: .notDetected, doubleNATStatus: .notDetected),
        retry: {}
    )
}

#Preview("4. Entrega falhou · Perda relevante") {
    CheckCompletoResultView(
        result: makePreviewResult(score: 48, band: .lagRisk, p50: 35.0, loss: 12.0, loadDelta: 6.0),
        gameName: "Minecraft",
        platform: .xbox,
        regionFriendlyName: "São Paulo",
        isWiFi: false,
        natSnapshot: NATTopologySnapshot(natType: .type3Strict, cgnatStatus: .detected, doubleNATStatus: .notDetected),
        retry: {}
    )
}

#Preview("5. Inconclusivo · Medição incompleta") {
    CheckCompletoResultView(
        result: nil,
        gameName: "Fortnite",
        platform: .iphone,
        regionFriendlyName: "São Paulo",
        isWiFi: true,
        natSnapshot: nil,
        retry: {}
    )
}

// MARK: - Preview Fixture Helper

private func makePreviewResult(
    score: Int,
    band: ResultClass,
    p50: Double,
    loss: Double = 0.0,
    jitter: Double = 2.0,
    loadDelta: Double = 5.0
) -> DeepCheckResult {
    let validCount = Int((30.0 * (1.0 - (loss / 100.0))).rounded())
    let timeoutCount = Int((30.0 * (loss / 100.0)).rounded())
    let restMetrics = QualityMetrics(
        validResponseCount: validCount,
        timeoutCount: timeoutCount,
        invalidResponseCount: 0,
        p50Milliseconds: p50,
        p95Milliseconds: p50 + 10,
        p99Milliseconds: p50 + 15,
        jitterMilliseconds: jitter,
        packetLossPercentage: loss,
        spikeCount: 0,
        severeSpikeCount: 0,
        spikeRatePercentage: 0,
        p95ToP50Ratio: 1.2,
        worstSpikeMilliseconds: p50 + 20,
        components: nil
    )
    let restResult = QualityResult(
        metrics: restMetrics,
        rawScore: score,
        finalScore: score,
        resultClass: band,
        appliedGuardrails: []
    )
    let loadImpact = DeepCheckLoadImpact(
        restP50Milliseconds: p50,
        loadP50Milliseconds: p50 + loadDelta
    )
    return DeepCheckResult(
        restResult: restResult,
        metrics: DeepCheckMetrics(rest: restMetrics, load: restMetrics, loadImpact: loadImpact)
    )
}
