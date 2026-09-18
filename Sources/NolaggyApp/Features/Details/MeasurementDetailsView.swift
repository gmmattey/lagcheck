import SwiftUI
import NolaggyDesign
import NolaggyDomain

struct MeasurementDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: MeasurementHistoryEntry
    /// Só existe para a medição recém-concluída; o histórico não persiste série bruta.
    let samples: [ProbeSample]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NLSpacing.lg) {
                VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                    Text("details.reference_region")
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textTertiary)
                    Text("quick_check.measuring.region")
                        .font(NLTypography.callout)
                        .foregroundStyle(NLColor.textSecondary)
                    Text("details.measured_target")
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textTertiary)
                    Text(strategyLabel)
                        .font(NLTypography.callout)
                        .foregroundStyle(NLColor.textSecondary)
                }

                LatencyGraph(
                    values: samples.sorted { $0.sequence < $1.sequence }.compactMap(\.roundTripMilliseconds),
                    awaitingLabel: "details.history_graph_unavailable",
                    accessibilityLabel: graphAccessibilitySummary
                )
                .frame(height: NLSizing.detailsGraphHeight)

                if let deepCheck = entry.deepCheck {
                    deepComparison(deepCheck)
                }

                metricList
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.lg)
        }
        .background(NolaggyScreenBackground())
        .navigationTitle(Text("details.title"))
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NolaggyBackButton(action: { dismiss() }, accessibilityIdentifier: "measurement-details-back")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var metricList: some View {
        VStack(spacing: 1) {
            detailRow("details.p50", milliseconds(entry.result.metrics.p50Milliseconds))
            detailRow("details.p95", milliseconds(entry.result.metrics.p95Milliseconds))
            detailRow("details.p99", milliseconds(entry.result.metrics.p99Milliseconds))
            detailRow("quick_check.result.jitter", milliseconds(entry.result.metrics.jitterMilliseconds))
            detailRow("quick_check.result.loss", percentage(entry.result.metrics.packetLossPercentage))
            detailRow("quick_check.result.spikes", String(entry.result.metrics.spikeCount))
            detailRow("details.worst_spike", milliseconds(entry.result.metrics.worstSpikeMilliseconds))
            detailRow("details.spike_rate", percentage(entry.result.metrics.spikeRatePercentage))
            detailRow("details.confidence", confidenceLabel)
            detailRow("details.profile", entry.resolvedContext.profileID.rawValue)
            detailRow("details.rule_version", entry.profileRuleVersion)
        }
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay { RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline) }
    }

    private func deepComparison(_ deepCheck: DeepCheckResult) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            Label(
                deepCheck.metrics.loadImpact?.classification == .material ? "deep_check.result.impact_material" : "deep_check.result.impact",
                systemImage: deepCheck.metrics.loadImpact?.classification == .material ? "exclamationmark.triangle" : "arrow.left.arrow.right"
            )
                .font(NLTypography.bodyEmphasis)
                .foregroundStyle(deepCheck.metrics.loadImpact?.classification == .material ? NLColor.scoreLagRisk : NLColor.textPrimary)
            if let impact = deepCheck.metrics.loadImpact {
                Text(impact.classification == .material ? "deep_check.result.impact_material_explanation" : "deep_check.result.impact_explanation")
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                MetricRow(
                    label: "quick_check.result.ping",
                    value: milliseconds(deepCheck.metrics.rest.p50Milliseconds),
                    unit: "ms",
                    style: .loadComparison,
                    loadValue: milliseconds(deepCheck.metrics.load?.p50Milliseconds)
                )
                MetricRow(
                    label: "deep_check.result.impact",
                    value: String(format: NSLocalizedString("deep_check.result.impact_value", comment: ""), Int(impact.increaseMilliseconds.rounded())),
                    style: .detailed
                )
            } else {
                Text("deep_check.result.load_unavailable")
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
            }
        }
        .padding(NLSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay { RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline) }
    }

    private func detailRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(spacing: 1) {
            MetricRow(label: label, value: value, style: .detailed)
            Divider().overlay(NLColor.borderSubtle)
        }
    }

    private var strategyKey: String { "details.target.generic_region" }
    private var confidenceKey: String { "details.confidence.medium" }
    private var strategyLabel: String { NSLocalizedString(strategyKey, comment: "") }
    private var confidenceLabel: String { NSLocalizedString(confidenceKey, comment: "") }
    private var graphAccessibilitySummary: String {
        let metrics = entry.result.metrics
        return String(
            format: NSLocalizedString("details.graph_accessibility", comment: ""),
            Int((metrics.p50Milliseconds ?? 0).rounded()),
            Int((metrics.worstSpikeMilliseconds ?? 0).rounded()),
            metrics.spikeCount
        )
    }
    private func milliseconds(_ value: Double?) -> String { value.map { "\(Int($0.rounded())) ms" } ?? "—" }
    private func percentage(_ value: Double) -> String { "\(Int(value.rounded()))%" }
}
