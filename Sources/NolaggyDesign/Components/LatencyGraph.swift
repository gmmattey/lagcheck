import SwiftUI

/// Série visual de RTTs já recebidos. Não estima nem preenche amostras ausentes.
public struct LatencyGraph: View {
    private let values: [Double]
    private let awaitingLabel: LocalizedStringKey
    private let accessibilityLabel: String
    private let comparisonValues: [Double]

    public init(values: [Double], awaitingLabel: LocalizedStringKey, accessibilityLabel: String, comparisonValues: [Double] = []) {
        self.values = values
        self.awaitingLabel = awaitingLabel
        self.accessibilityLabel = accessibilityLabel
        self.comparisonValues = comparisonValues
    }

    public var body: some View {
        Group {
            if values.count >= 2 {
                GeometryReader { geometry in
                    let maximum = max(values.max() ?? 1, comparisonValues.max() ?? 1, 1)
                    if comparisonValues.count >= 2 {
                        line(for: comparisonValues, maximum: maximum, size: geometry.size)
                            .stroke(NLColor.accentPrimary.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    }
                    line(for: values, maximum: maximum, size: geometry.size)
                        .stroke(NLColor.accentPrimary, lineWidth: 2.5)
                }
            } else {
                Text(awaitingLabel)
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(height: 100)
        .accessibilityLabel(accessibilityLabel)
    }

    private func line(for values: [Double], maximum: Double, size: CGSize) -> Path {
        Path { path in
            for (index, value) in values.enumerated() {
                let x = size.width * Double(index) / Double(values.count - 1)
                let y = size.height * (1 - value / maximum)
                index == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
            }
        }
    }
}
