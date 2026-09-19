import SwiftUI
import NolaggyDesign
import NolaggyDomain

struct DeepCheckDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    let result: DeepCheckResult
    let resolvedContext: ResolvedMeasurementContext
    let gameName: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NLSpacing.lg) {
                    measurementContext
                    if let impact = result.metrics.loadImpact { impactCard(impact) }
                    detailSection("deep_check.result.rest_value", metrics: result.metrics.rest)
                    if let load = result.metrics.load { detailSection("deep_check.result.load_value", metrics: load) }
                }
                .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                .padding(.vertical, NLSpacing.lg)
            }
            .background(NolaggyScreenBackground())
            .navigationTitle(Text("deep_check.result.details"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NolaggyBackButton(action: { dismiss() }, accessibilityIdentifier: "deep-check-details-back")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var measurementContext: some View {
        VStack(spacing: NLSpacing.xxs) {
            Text(String(format: AppLocalization.string("deep_check.measurement.title %@", comment: ""), gameName))
                .font(NLTypography.callout.weight(.semibold)).foregroundStyle(NLColor.textPrimary)
            Label("deep_check.measurement.context", systemImage: "mappin.and.ellipse")
                .font(NLTypography.footnote).foregroundStyle(NLColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func impactCard(_ impact: DeepCheckLoadImpact) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Label(impact.classification == .material ? "deep_check.result.impact_material" : "deep_check.result.impact", systemImage: impact.classification == .material ? "exclamationmark.triangle" : "arrow.left.arrow.right")
                .font(NLTypography.bodyEmphasis)
                .foregroundStyle(impact.classification == .material ? NLColor.scoreLagRisk : NLColor.textPrimary)
            Text(impact.classification == .material ? "deep_check.result.impact_material_explanation" : "deep_check.result.impact_explanation")
                .font(NLTypography.footnote).foregroundStyle(NLColor.textSecondary)
            Text(String(format: AppLocalization.string("deep_check.result.impact_value", comment: ""), Int(impact.increaseMilliseconds.rounded())))
                .font(NLTypography.headline).foregroundStyle(NLColor.accentPrimary)
        }
        .padding(NLSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
    }

    private func detailSection(_ title: LocalizedStringKey, metrics: QualityMetrics) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            Text(title).font(NLTypography.headline).foregroundStyle(NLColor.textPrimary)
            MetricRow(label: "details.p50", value: formatted(metrics.p50Milliseconds), unit: "ms", style: .detailed)
            MetricRow(label: "details.p95", value: formatted(metrics.p95Milliseconds), unit: "ms", style: .detailed)
            MetricRow(label: "details.p99", value: formatted(metrics.p99Milliseconds), unit: "ms", style: .detailed)
            MetricRow(label: "quick_check.result.jitter", value: formatted(metrics.jitterMilliseconds), unit: "ms", style: .detailed)
            MetricRow(label: "quick_check.result.loss", value: "\(Int(metrics.packetLossPercentage.rounded()))", unit: "%", style: .detailed)
            MetricRow(label: "quick_check.result.spikes", value: String(metrics.spikeCount), style: .detailed)
            MetricRow(label: "details.worst_spike", value: formatted(metrics.worstSpikeMilliseconds), unit: "ms", style: .detailed)
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
    }

    private func formatted(_ value: Double?) -> String { value.map { String(Int($0.rounded())) } ?? "—" }
}
