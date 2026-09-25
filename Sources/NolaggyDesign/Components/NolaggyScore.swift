import SwiftUI

public enum NLScoreClassification: String, CaseIterable, Sendable {
    case excellent
    case great
    case unstable
    case lagRisk

    public var label: LocalizedStringKey {
        switch self {
        case .excellent: "score.classification.excellent"
        case .great: "score.classification.great"
        case .unstable: "score.classification.unstable"
        case .lagRisk: "score.classification.lag_risk"
        }
    }

    var color: Color {
        switch self {
        case .excellent, .great: NLColor.scoreExcellent
        case .unstable: NLColor.scoreUnstable
        case .lagRisk: NLColor.scoreLagRisk
        }
    }

    var subtleColor: Color {
        switch self {
        case .excellent, .great: NLColor.scoreExcellentSubtle
        case .unstable: NLColor.scoreUnstableSubtle
        case .lagRisk: NLColor.scoreLagRiskSubtle
        }
    }
}

public struct NolaggyScore: View {
    public enum Style: Sendable { case hero, standard, compact }
    public enum Outcome: Sendable {
        case revealed(score: Int, classification: NLScoreClassification)
        case inconclusive
        case cancelled
    }

    private let outcome: Outcome
    private let style: Style
    private let summary: String?
    private let classificationLabel: LocalizedStringKey?
    private let accessibilityDescriptionOverride: String?
    private let showsGlow: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ScaledMetric(relativeTo: .largeTitle) private var scoreDisplaySize: CGFloat = 64
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        outcome: Outcome,
        style: Style = .standard,
        summary: String? = nil,
        classificationLabel: LocalizedStringKey? = nil,
        accessibilityDescription: String? = nil,
        showsGlow: Bool = true
    ) {
        self.outcome = outcome
        self.style = style
        self.summary = summary
        self.classificationLabel = classificationLabel
        self.accessibilityDescriptionOverride = accessibilityDescription
        self.showsGlow = showsGlow
    }

    public var body: some View {
        VStack(spacing: NLSpacing.sm) {
            scoreRing
            if style != .compact {
                VStack(spacing: NLSpacing.xs) {
                    Text(classificationLabel ?? label)
                        .font(NLTypography.headline)
                        .foregroundStyle(scoreColor)
                        .multilineTextAlignment(.center)
                    if let summary {
                        Text(summary)
                            .font(NLTypography.body)
                            .foregroundStyle(NLColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescriptionOverride.map(Text.init) ?? defaultAccessibilityDescription)
        .animation(reduceMotion ? nil : NLMotion.scoreReveal, value: outcomeDescription)
    }

    private var scoreRing: some View {
        ZStack {
            Circle().stroke(NLColor.borderSubtle, lineWidth: strokeWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(scoreText)
                .font(scoreFont)
                .foregroundStyle(NLColor.textPrimary)
        }
        .frame(width: scaledDiameter, height: scaledDiameter)
        .shadow(color: glowColor, radius: reduceTransparency ? 0 : NLSpacing.xxl)
        .overlay {
            if reduceTransparency {
                Circle().stroke(NLColor.borderStrong, lineWidth: 1)
            }
        }
    }

    private var diameter: CGFloat {
        switch style {
        case .compact: NLSizing.NolaggyScoreRing.compact
        case .standard: NLSizing.NolaggyScoreRing.standard
        case .hero: NLSizing.NolaggyScoreRing.hero
        }
    }

    private var strokeWidth: CGFloat {
        switch style {
        case .compact: NLSizing.NolaggyScoreRing.compactStroke
        case .standard: NLSizing.NolaggyScoreRing.standardStroke
        case .hero: NLSizing.NolaggyScoreRing.heroStroke
        }
    }

    private var scaledDiameter: CGFloat {
        guard style != .compact, dynamicTypeSize.isAccessibilitySize else { return diameter }
        return diameter * 1.35
    }

    private var scoreFont: Font {
        style == .compact ? NLTypography.subheadline : .system(size: scoreDisplaySize, weight: .bold, design: .rounded)
    }
    private var scoreText: String { if case let .revealed(score, _) = outcome { String(score) } else { "—" } }
    private var progress: CGFloat { if case let .revealed(score, _) = outcome { CGFloat(min(max(score, 0), 100)) / 100 } else { 0 } }
    private var label: LocalizedStringKey {
        switch outcome {
        case let .revealed(_, classification): classification.label
        case .inconclusive: "score.outcome.inconclusive"
        case .cancelled: "score.outcome.cancelled"
        }
    }
    private var scoreColor: Color {
        if case let .revealed(_, classification) = outcome {
            return classification.color
        }
        return NLColor.scoreNeutral
    }
    private var glowColor: Color { showsGlow && !reduceTransparency ? scoreColor.opacity(0.24) : .clear }
    private var outcomeDescription: String {
        switch outcome {
        case let .revealed(score, classification): "\(score)-\(classification.rawValue)"
        case .inconclusive: "inconclusive"
        case .cancelled: "cancelled"
        }
    }
    private var defaultAccessibilityDescription: Text {
        switch outcome {
        case let .revealed(score, classification):
            Text("score.accessibility.title") + Text(" \(score), ") + Text(classification.label) + (summary.map { Text(", \($0)") } ?? Text(""))
        case .inconclusive: Text("score.accessibility.inconclusive")
        case .cancelled: Text("score.accessibility.cancelled")
        }
    }
}

#Preview("Score") {
    VStack(spacing: NLSpacing.xl) {
        NolaggyScore(outcome: .revealed(score: 92, classification: .excellent), summary: "Pronto para jogar.")
        NolaggyScore(
            outcome: .revealed(score: 88, classification: .great),
            classificationLabel: "Great",
            accessibilityDescription: "LagCheck Score 88, Great, looking good to play now."
        )
        NolaggyScore(outcome: .revealed(score: 58, classification: .lagRisk), style: .compact)
    }
    .padding()
    .background(NLColor.backgroundBase)
    .preferredColorScheme(.dark)
}
