import SwiftUI
import NolaggyDesign
import NolaggyDomain

/// Tela de resultado do Quick Check (doc 01 §7.4): a conclusão vem antes das
/// métricas, seguida de causa e recomendação já interpretadas pelo domínio.
extension QuickCheckFeatureView {
    func resultView(result: QualityResult) -> some View {
        let profile = selectedRegionalContext?.profileID ?? .battleRoyaleCompetitive
        let interpretation = ResultInterpreter.interpret(result, profile: profile)
        let headline = NSLocalizedString(interpretation.headlineKey.rawValue, comment: "")
        let scoreAccessibilityDescription = String(
            format: NSLocalizedString("quick_check.result.score_accessibility", comment: ""),
            interpretation.score,
            headline
        )
        return ScrollView {
            VStack(spacing: NLSpacing.xl) {
                VStack(spacing: NLSpacing.sm) {
                    NolaggyScore(
                        outcome: .revealed(
                            score: interpretation.score,
                            classification: scoreClassification(for: interpretation.scoreBand)
                        ),
                        style: .standard,
                        classificationLabel: localized(interpretation.headlineKey.rawValue),
                        accessibilityDescription: scoreAccessibilityDescription
                    )

                    Text(localized(interpretation.conclusionKey.rawValue))
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(localized(interpretation.explanationKey.rawValue))
                        .font(NLTypography.callout)
                        .foregroundStyle(NLColor.textSecondary)
                        .multilineTextAlignment(.center)

                    Text("\(selectedGameName) · iPhone")
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textTertiary)
                    Text(selectedRegionRouteSubtitle)
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textTertiary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 1) {
                    MetricRow(
                        label: "quick_check.result.ping",
                        value: milliseconds(interpretation.metrics.p50Milliseconds),
                        unit: "ms",
                        isPrimaryCause: interpretation.primaryCauseKey == .highLatency,
                        scoreColor: insightColor(for: interpretation.primaryCauseKey)
                    )
                    Divider().overlay(NLColor.borderSubtle)
                    MetricRow(
                        label: "quick_check.result.jitter",
                        value: milliseconds(interpretation.metrics.jitterMilliseconds),
                        unit: "ms",
                        isPrimaryCause: interpretation.primaryCauseKey == .highJitter,
                        scoreColor: insightColor(for: interpretation.primaryCauseKey)
                    )
                    Divider().overlay(NLColor.borderSubtle)
                    MetricRow(
                        label: "quick_check.result.loss",
                        value: percentage(interpretation.metrics.packetLossPercentage),
                        isPrimaryCause: interpretation.primaryCauseKey == .packetLoss,
                        scoreColor: insightColor(for: interpretation.primaryCauseKey)
                    )
                    Divider().overlay(NLColor.borderSubtle)
                    MetricRow(
                        label: "quick_check.result.spikes",
                        value: String(interpretation.metrics.spikeCount),
                        isPrimaryCause: interpretation.primaryCauseKey == .severeSpikes,
                        scoreColor: insightColor(for: interpretation.primaryCauseKey)
                    )
                }
                .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
                .overlay { RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline) }
                .padding(.top, NLSpacing.resultConclusionToMetrics - NLSpacing.xl)

                InsightBanner(
                    tone: insightTone(for: interpretation.primaryCauseKey),
                    message: localized(interpretation.insightKey.rawValue),
                    icon: insightIcon(for: interpretation.primaryCauseKey)
                )

                // Com risco ou instabilidade, a ação que explica a causa (Deep
                // Check) é mais útil agora do que testar de novo — ela vira a
                // ação primária. Em resultado saudável, testar de novo continua
                // sendo o caminho mais provável e permanece em destaque.
                if interpretation.scoreBand == .unstable || interpretation.scoreBand == .lagRisk {
                    PrimaryButton(title: "quick_check.result.deep_check", action: { openDeepCheck() })
                        .accessibilityIdentifier("deep-check-open")

                    HStack(spacing: NLSpacing.sm) {
                        secondaryResultAction("quick_check.result.retry", identifier: "quick-check-retry", action: restart)
                        secondaryResultAction("quick_check.result.details", identifier: "quick-check-details") { showingDetails = true }
                    }
                } else {
                    PrimaryButton(title: "quick_check.result.retry", action: restart)
                        .accessibilityIdentifier("quick-check-retry")

                    HStack(spacing: NLSpacing.sm) {
                        secondaryResultAction("quick_check.result.details", identifier: "quick-check-details") { showingDetails = true }
                        secondaryResultAction("quick_check.result.deep_check", identifier: "deep-check-open") { openDeepCheck() }
                    }
                }
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.lg)
            .toolbar(.hidden, for: .tabBar)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NolaggyBackButton(action: back, accessibilityIdentifier: "quick-check-back")
                }
            }
        }
    }

    func secondaryResultAction(_ title: LocalizedStringKey, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(NLTypography.callout.weight(.semibold))
                .foregroundStyle(NLColor.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: NLSizing.touchTarget)
                .overlay { Capsule().stroke(NLColor.borderStrong, lineWidth: NLStroke.hairline) }
        }
        .accessibilityIdentifier(identifier)
    }

    func scoreClassification(for resultClass: ResultClass) -> NLScoreClassification {
        switch resultClass {
        case .excellent: .excellent
        case .great: .great
        case .unstable: .unstable
        case .lagRisk: .lagRisk
        }
    }

    func insightTone(for cause: ResultPrimaryCauseKey) -> InsightBanner.Tone {
        switch cause {
        case .stableConnection: .positive
        case .packetLoss, .highLatency, .severeSpikes, .highJitter: .risk
        }
    }

    func insightIcon(for cause: ResultPrimaryCauseKey) -> Image {
        switch cause {
        case .stableConnection: Image(systemName: "checkmark.circle")
        case .packetLoss, .highLatency, .severeSpikes, .highJitter: Image(systemName: "exclamationmark.triangle")
        }
    }

    func insightColor(for cause: ResultPrimaryCauseKey) -> Color {
        switch cause {
        case .stableConnection: NLColor.scoreExcellent
        case .packetLoss, .highLatency, .severeSpikes, .highJitter: NLColor.scoreLagRisk
        }
    }
}
