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
                VStack(alignment: .leading, spacing: NLSpacing.sm) {
                    VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                        Text("details.reference_region")
                            .font(NLTypography.footnote)
                            .foregroundStyle(NLColor.textTertiary)
                        Text("quick_check.measuring.region")
                            .font(NLTypography.callout)
                            .foregroundStyle(NLColor.textSecondary)
                    }
                    VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                        Text("details.measured_target")
                            .font(NLTypography.footnote)
                            .foregroundStyle(NLColor.textTertiary)
                        Text(strategyLabel)
                            .font(NLTypography.callout)
                            .foregroundStyle(NLColor.textSecondary)
                    }
                }

                if samples.count >= 2 {
                    LatencyGraph(
                        values: samples.sorted { $0.sequence < $1.sequence }.compactMap(\.roundTripMilliseconds),
                        awaitingLabel: "details.history_graph_unavailable",
                        accessibilityLabel: graphAccessibilitySummary,
                        isScanning: false
                    )
                    .frame(height: NLSizing.detailsGraphHeight)
                } else if let deepCheck = entry.deepCheck, let p50Rest = deepCheck.metrics.rest.p50Milliseconds {
                    let p95Rest = deepCheck.metrics.rest.p95Milliseconds ?? p50Rest
                    let p50Load = deepCheck.metrics.load?.p50Milliseconds ?? p50Rest
                    let p95Load = deepCheck.metrics.load?.p95Milliseconds ?? p95Rest
                    let p99Load = deepCheck.metrics.load?.p99Milliseconds ?? p95Load
                    let hasSpike = (deepCheck.metrics.rest.spikeCount > 0) || ((deepCheck.metrics.load?.spikeCount ?? 0) > 0)

                    VStack(alignment: .leading, spacing: NLSpacing.xs) {
                        PercentileChartView(
                            p50Rest: p50Rest,
                            p95Rest: p95Rest,
                            p50Load: p50Load,
                            p95Load: p95Load,
                            p99Load: p99Load,
                            hasSpike: hasSpike
                        )
                        .frame(height: 118)
                        .background(NLColor.surface)
                        .overlay(
                            Rectangle()
                                .stroke(NLColor.borderStrong, lineWidth: 1)
                        )

                        HStack {
                            Text(LocalizedStringKey("deep_check.graph.rest"))
                                .font(NLTypography.monospaceMetrics)
                                .foregroundStyle(NLColor.textTertiary)

                            Spacer()

                            Text(LocalizedStringKey("deep_check.graph.load"))
                                .font(NLTypography.monospaceMetrics)
                                .foregroundStyle(NLColor.textTertiary)
                        }
                    }
                } else {
                    LatencyGraph(
                        values: samples.sorted { $0.sequence < $1.sequence }.compactMap(\.roundTripMilliseconds),
                        awaitingLabel: "details.history_graph_unavailable",
                        accessibilityLabel: graphAccessibilitySummary,
                        isScanning: false
                    )
                    .frame(height: NLSizing.detailsGraphHeight)
                }

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
        .navigationBarTitleDisplayMode(.inline)
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
        let metrics = entry.metrics
        return VStack(spacing: 1) {
            detailRow("details.p50", milliseconds(metrics?.p50Milliseconds))
            detailRow("details.p95", milliseconds(metrics?.p95Milliseconds))
            detailRow("details.p99", milliseconds(metrics?.p99Milliseconds))
            detailRow("quick_check.result.jitter", milliseconds(metrics?.jitterMilliseconds))
            detailRow("quick_check.result.loss", percentage(metrics?.packetLossPercentage))
            detailRow("quick_check.result.spikes", metrics.map { String($0.spikeCount) } ?? "—")
            detailRow("details.worst_spike", milliseconds(metrics?.worstSpikeMilliseconds))
            detailRow("details.spike_rate", percentage(metrics?.spikeRatePercentage))
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
                    value: String(format: AppLocalization.string("deep_check.result.impact_value", comment: ""), Int(impact.increaseMilliseconds.rounded())),
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
    private var strategyLabel: String { AppLocalization.string(strategyKey, comment: "") }
    private var confidenceLabel: String { AppLocalization.string(confidenceKey, comment: "") }
    private var graphAccessibilitySummary: String {
        guard let metrics = entry.metrics else {
            return AppLocalization.string("details.history_graph_unavailable", comment: "")
        }
        return String(
            format: AppLocalization.string("details.graph_accessibility", comment: ""),
            Int((metrics.p50Milliseconds ?? 0).rounded()),
            Int((metrics.worstSpikeMilliseconds ?? 0).rounded()),
            metrics.spikeCount
        )
    }
    private func milliseconds(_ value: Double?) -> String { value.map { "\(Int($0.rounded())) ms" } ?? "—" }
    private func percentage(_ value: Double?) -> String { value.map { "\(Int($0.rounded()))%" } ?? "—" }
}
