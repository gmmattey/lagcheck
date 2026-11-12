import SwiftUI

public struct MetricRow: View {
    public enum Style: Sendable { case summary, detailed, loadComparison }

    private let label: LocalizedStringKey
    private let value: String
    private let unit: String?
    private let icon: Image?
    private let style: Style
    private let isPrimaryCause: Bool
    private let loadValue: String?
    private let scoreColor: Color

    public init(label: LocalizedStringKey, value: String, unit: String? = nil, icon: Image? = nil, style: Style = .summary, isPrimaryCause: Bool = false, loadValue: String? = nil, scoreColor: Color = NLColor.scoreLagRisk) {
        self.label = label
        self.value = value
        self.unit = unit
        self.icon = icon
        self.style = style
        self.isPrimaryCause = isPrimaryCause
        self.loadValue = loadValue
        self.scoreColor = scoreColor
    }

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalContent
            verticalContent
        }
        .frame(minHeight: NLSizing.metricRowHeight)
        .padding(.horizontal, NLSpacing.cardPadding)
        .accessibilityElement(children: .combine)
    }

    private var horizontalContent: some View {
        HStack(spacing: NLSpacing.stackGapDefault) {
            leadingLabel
            Spacer(minLength: NLSpacing.sm)
            values(alignment: .trailing)
        }
    }

    private var verticalContent: some View {
        VStack(alignment: .leading, spacing: NLSpacing.xxs) {
            leadingLabel
            values(alignment: .leading)
        }
        .padding(.vertical, NLSpacing.sm)
    }

    private var leadingLabel: some View {
        HStack(spacing: NLSpacing.stackGapDefault) {
            if isPrimaryCause {
                Circle().fill(scoreColor).frame(width: 7, height: 7).accessibilityHidden(true)
            }
            if let icon {
                icon.foregroundStyle(NLColor.textSecondary).frame(width: NLSizing.iconSmall, height: NLSizing.iconSmall).accessibilityHidden(true)
            }
            Text(label).font(NLTypography.bodyEmphasis).foregroundStyle(NLColor.textPrimary)
        }
    }

    private func values(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: NLSpacing.xxs) {
            Text(formatted(value: value)).font(NLTypography.subheadlineSecondary).foregroundStyle(NLColor.textSecondary)
            if style == .loadComparison, let loadValue {
                Text(formatted(value: loadValue)).font(NLTypography.footnote).foregroundStyle(NLColor.textTertiary)
            }
        }
    }

    private func formatted(value: String) -> String { unit.map { "\(value) \($0)" } ?? value }
}

#Preview("Metric row") {
    VStack(spacing: 1) {
        MetricRow(label: "Ping", value: "24", unit: "ms", icon: Image(systemName: "waveform.path.ecg"))
        Divider().overlay(NLColor.borderSubtle)
        MetricRow(label: "Perda", value: "4", unit: "%", isPrimaryCause: true)
    }
    .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
    .padding()
    .background(NLColor.backgroundBase)
    .preferredColorScheme(.dark)
}
