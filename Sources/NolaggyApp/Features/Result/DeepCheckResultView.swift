import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Resultado puro do Deep Check. Recebe o snapshot final e callbacks; não
/// inicia, cancela nem interpreta transporte de rede.
struct DeepCheckResultView: View {
    let result: DeepCheckResult
    let availability: DeepCheckLoadAvailability
    let profileID: QualityProfileID
    let gameName: String
    let showDetails: () -> Void
    let showBooster: () -> Void
    let retry: () -> Void
    let exit: () -> Void

    var body: some View {
        let interpretation = ResultInterpreter.interpret(result.restResult, profile: profileID)
        ScrollView {
            VStack(spacing: NLSpacing.lg) {
                NolaggyScore(
                    outcome: .revealed(score: interpretation.score, classification: classification(interpretation.scoreBand)),
                    style: .standard,
                    classificationLabel: LocalizedStringKey(String(format: NSLocalizedString("deep_check.result.rest", comment: ""), NSLocalizedString(interpretation.headlineKey.rawValue, comment: ""))),
                    accessibilityDescription: String(format: NSLocalizedString("deep_check.result.rest", comment: ""), "LagCheck Score \(interpretation.score)")
                )
                measurementContext
                impactCard(result.metrics.loadImpact)
                if result.metrics.load != nil { comparisonRows(result.metrics) }
                PrimaryButton(title: "deep_check.result.details", action: showDetails)
                PrimaryButton(title: "booster.cta.button", style: .secondaryOutline, action: showBooster)
                PrimaryButton(title: "deep_check.result.retry", style: .secondaryOutline, action: retry)
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.lg)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NolaggyBackButton(action: exit, accessibilityIdentifier: "deep-check-result-back")
                }
            }
        }
    }

    private var measurementContext: some View {
        VStack(spacing: NLSpacing.xxs) {
            Text(String(format: NSLocalizedString("deep_check.measurement.title %@", comment: ""), gameName))
                .font(NLTypography.callout.weight(.semibold)).foregroundStyle(NLColor.textPrimary)
            Label("deep_check.measurement.context", systemImage: "mappin.and.ellipse")
                .font(NLTypography.footnote).foregroundStyle(NLColor.textTertiary)
        }.frame(maxWidth: .infinity)
    }

    private func impactCard(_ impact: DeepCheckLoadImpact?) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Label(impact.map(title) ?? "deep_check.result.load_unavailable_title", systemImage: impact.map(icon) ?? "exclamationmark.circle")
                .font(NLTypography.bodyEmphasis).foregroundStyle(impact.map(color) ?? NLColor.textPrimary)
            if let impact {
                Text(explanation(impact)).font(NLTypography.footnote).foregroundStyle(NLColor.textSecondary).fixedSize(horizontal: false, vertical: true)
                Text(String(format: NSLocalizedString("deep_check.result.impact_value", comment: ""), Int(impact.increaseMilliseconds.rounded())))
                    .font(NLTypography.headline).foregroundStyle(NLColor.accentPrimary)
            } else {
                Text(availability == .loadUnavailable ? "deep_check.result.load_unavailable" : "deep_check.result.comparison_unavailable")
                    .font(NLTypography.footnote).foregroundStyle(NLColor.textSecondary)
            }
        }
        .padding(NLSpacing.cardPadding).frame(maxWidth: .infinity, alignment: .leading)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay { RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline) }
    }

    private func comparisonRows(_ metrics: DeepCheckMetrics) -> some View {
        VStack(spacing: 1) {
            comparisonRow("quick_check.result.ping", rest: metrics.rest.p50Milliseconds, load: metrics.load?.p50Milliseconds)
            Divider().overlay(NLColor.borderSubtle)
            comparisonRow("quick_check.result.jitter", rest: metrics.rest.jitterMilliseconds, load: metrics.load?.jitterMilliseconds)
        }
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay { RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline) }
    }

    private func comparisonRow(_ label: LocalizedStringKey, rest: Double?, load: Double?) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.xxs) {
            Text(label).font(NLTypography.bodyEmphasis).foregroundStyle(NLColor.textPrimary)
            ViewThatFits(in: .horizontal) {
                HStack { value("deep_check.result.rest_value", rest); Spacer(); value("deep_check.result.load_value", load) }
                VStack(alignment: .leading, spacing: NLSpacing.xs) { value("deep_check.result.rest_value", rest); value("deep_check.result.load_value", load) }
            }
        }.padding(NLSpacing.cardPadding)
    }
    private func value(_ label: LocalizedStringKey, _ milliseconds: Double?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(NLTypography.caption).foregroundStyle(NLColor.textTertiary)
            Text(milliseconds.map { "\(Int($0.rounded())) ms" } ?? "—").font(NLTypography.callout).foregroundStyle(NLColor.textSecondary)
        }
    }
    private func classification(_ value: ResultClass) -> NLScoreClassification { switch value { case .excellent: .excellent; case .great: .great; case .unstable: .unstable; case .lagRisk: .lagRisk } }
    private func title(_ impact: DeepCheckLoadImpact) -> LocalizedStringKey { impact.classification == .material ? "deep_check.result.impact_material" : "deep_check.result.impact" }
    private func explanation(_ impact: DeepCheckLoadImpact) -> LocalizedStringKey { impact.classification == .material ? "deep_check.result.impact_material_explanation" : "deep_check.result.impact_explanation" }
    private func icon(_ impact: DeepCheckLoadImpact) -> String { impact.classification == .material ? "exclamationmark.triangle" : "arrow.left.arrow.right" }
    private func color(_ impact: DeepCheckLoadImpact) -> Color { impact.classification == .material ? NLColor.scoreLagRisk : NLColor.textPrimary }
}
