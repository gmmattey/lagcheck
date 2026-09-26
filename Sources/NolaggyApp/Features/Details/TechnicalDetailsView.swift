import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Folha técnica secundária ("Entender minha conexão / Ver detalhes técnicos").
/// Apresenta o Score numérico (0–100), percentis P50/P95/P99, impacto sob carga e telemetria profunda,
/// desonerando a tela principal de resultado (Decisões 50 e 51).
public struct TechnicalDetailsView: View {
    public let result: DeepCheckResult?
    public let gameName: String
    public let regionName: String
    public let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    public init(
        result: DeepCheckResult?,
        gameName: String,
        regionName: String,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.result = result
        self.gameName = gameName
        self.regionName = regionName
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NLSpacing.lg) {
                    if let result {
                        // 1. Score Numérico de Qualidade (0-100)
                        scoreCard(result: result)

                        // 2. Percentis de Latência (P50, P95, P99)
                        latencyPercentilesCard(metrics: result.restResult.metrics)

                        // 3. Comportamento sob Carga (Deep Check)
                        if let loadImpact = result.metrics.loadImpact {
                            loadImpactCard(impact: loadImpact)
                        }

                        // 4. Amostras UDP e Pacotes
                        samplesCard(metrics: result.restResult.metrics)
                    } else {
                        inconclusiveCard
                    }
                }
                .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                .padding(.vertical, NLSpacing.md)
            }
            .background(NLColor.deep.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("technical_details.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedStringKey("technical_details.close")) {
                        onDismiss()
                        dismiss()
                    }
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.coralSolar)
                    .accessibilityIdentifier("technical-details-close")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func scoreCard(result: DeepCheckResult) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Text(LocalizedStringKey("technical_details.quality_score"))
                .font(NLTypography.sectionHeader)
                .foregroundStyle(NLColor.textTertiary)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: NLSpacing.md) {
                Text("\(result.restResult.finalScore)")
                    .font(.system(size: 48, weight: .black, design: .default))
                    .monospacedDigit()
                    .foregroundStyle(NLColor.textPrimary)

                Text("/ 100")
                    .font(NLTypography.subheadline)
                    .foregroundStyle(NLColor.textTertiary)

                Spacer()

                Text(result.restResult.resultClass.rawValue.uppercased())
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(colorForClass(result.restResult.resultClass))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(colorForClass(result.restResult.resultClass).opacity(0.15), in: Capsule())
            }

            Text(LocalizedStringKey("technical_details.score_explanation"))
                .font(NLTypography.caption)
                .foregroundStyle(NLColor.textSecondary)
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                .stroke(NLColor.borderHairline, lineWidth: 1)
        )
    }

    private func latencyPercentilesCard(metrics: QualityMetrics) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            Text(LocalizedStringKey("technical_details.percentiles_title"))
                .font(NLTypography.sectionHeader)
                .foregroundStyle(NLColor.textTertiary)
                .textCase(.uppercase)

            HStack(spacing: NLSpacing.md) {
                percentileColumn(labelKey: "technical_details.p50_label", value: metrics.p50Milliseconds)
                Divider().background(NLColor.borderHairline)
                percentileColumn(labelKey: "technical_details.p95_label", value: metrics.p95Milliseconds)
                Divider().background(NLColor.borderHairline)
                percentileColumn(labelKey: "technical_details.p99_label", value: metrics.p99Milliseconds)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                .stroke(NLColor.borderHairline, lineWidth: 1)
        )
    }

    private func percentileColumn(labelKey: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(NLColor.textTertiary)

            if let value {
                Text("\(Int(value.rounded())) ms")
                    .font(NLTypography.metricsNumber)
                    .monospacedDigit()
                    .foregroundStyle(NLColor.textPrimary)
            } else {
                Text("—")
                    .font(NLTypography.metricsNumber)
                    .foregroundStyle(NLColor.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loadImpactCard(impact: DeepCheckLoadImpact) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Text(LocalizedStringKey("technical_details.load_impact_title"))
                .font(NLTypography.sectionHeader)
                .foregroundStyle(NLColor.textTertiary)
                .textCase(.uppercase)

            HStack(spacing: NLSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey("technical_details.rest_label"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(NLColor.textTertiary)
                    Text("\(Int(impact.restP50Milliseconds.rounded())) ms")
                        .font(NLTypography.metricsNumber)
                        .foregroundStyle(NLColor.textPrimary)
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(NLColor.textTertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey("technical_details.load_label"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(NLColor.textTertiary)
                    Text("\(Int(impact.loadP50Milliseconds.rounded())) ms")
                        .font(NLTypography.metricsNumber)
                        .foregroundStyle(impact.classification == .material ? NLColor.semanticCaution : NLColor.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(LocalizedStringKey("technical_details.delta_p50_label"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(NLColor.textTertiary)
                    Text(String(format: "+%.0f ms", impact.increaseMilliseconds))
                        .font(NLTypography.metricsNumber)
                        .foregroundStyle(impact.classification == .material ? NLColor.semanticCaution : NLColor.semanticReady)
                }
            }
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                .stroke(NLColor.borderHairline, lineWidth: 1)
        )
    }

    private func samplesCard(metrics: QualityMetrics) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Text(LocalizedStringKey("technical_details.udp_samples_title"))
                .font(NLTypography.sectionHeader)
                .foregroundStyle(NLColor.textTertiary)
                .textCase(.uppercase)

            HStack {
                Text(LocalizedStringKey("technical_details.valid_samples"))
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                Spacer()
                Text("\(metrics.validResponseCount) / 30")
                    .font(NLTypography.footnote.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(NLColor.textPrimary)
            }

            HStack {
                Text(LocalizedStringKey("technical_details.timeouts"))
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                Spacer()
                Text("\(metrics.timeoutCount)")
                    .font(NLTypography.footnote.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(metrics.timeoutCount > 0 ? NLColor.semanticNotReady : NLColor.textPrimary)
            }

            if metrics.spikeCount > 0 {
                HStack {
                    Text(LocalizedStringKey("technical_details.spikes_detected"))
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textSecondary)
                    Spacer()
                    Text("\(metrics.spikeCount)")
                        .font(NLTypography.footnote.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(NLColor.semanticCaution)
                }
            }
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                .stroke(NLColor.borderHairline, lineWidth: 1)
        )
    }

    private var inconclusiveCard: some View {
        VStack(spacing: NLSpacing.sm) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 32))
                .foregroundStyle(NLColor.textTertiary)
            Text(LocalizedStringKey("check_completo.verdict.inconclusive"))
                .font(NLTypography.bodyEmphasis)
                .foregroundStyle(NLColor.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(NLSpacing.lg)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
    }

    private func colorForClass(_ resultClass: ResultClass) -> Color {
        switch resultClass {
        case .excellent, .great: return NLColor.semanticReady
        case .unstable: return NLColor.semanticCaution
        case .lagRisk: return NLColor.semanticNotReady
        }
    }
}
