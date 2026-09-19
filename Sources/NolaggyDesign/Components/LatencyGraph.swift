import SwiftUI

/// Série visual de RTTs já recebidos. Não estima nem preenche amostras ausentes.
/// Apresenta uma linha em onda animada fluida ao iniciar a medição e curvas suaves (Bézier spline)
/// conforme os pacotes são recebidos.
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

                    // Área preenchida sutilmente sob a curva de medição
                    smoothArea(for: values, maximum: maximum, size: geometry.size)
                        .fill(
                            LinearGradient(
                                colors: [NLColor.accentPrimary.opacity(0.22), NLColor.accentPrimary.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Curva comparativa de repouso (durante fase de carga)
                    if comparisonValues.count >= 2 {
                        smoothLine(for: comparisonValues, maximum: maximum, size: geometry.size)
                            .stroke(NLColor.accentPrimary.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    }

                    // Linha em onda suave de latência atual
                    smoothLine(for: values, maximum: maximum, size: geometry.size)
                        .stroke(NLColor.accentPrimary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }
                .animation(.smooth(duration: 0.35), value: values)
            } else {
                // Linha em onda animada ao ser iniciado (indicador de varredura contínua)
                VStack(spacing: NLSpacing.xs) {
                    ScanningWaveLine()
                        .frame(height: 56)

                    Text(awaitingLabel)
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(height: 100)
        .accessibilityLabel(accessibilityLabel)
    }

    private func smoothLine(for values: [Double], maximum: Double, size: CGSize) -> Path {
        let points = points(for: values, maximum: maximum, size: size)
        return Path { path in
            guard let first = points.first else { return }
            path.move(to: first)

            if points.count == 2 {
                path.addLine(to: points[1])
                return
            }

            for i in 0..<(points.count - 1) {
                let p0 = i > 0 ? points[i - 1] : points[i]
                let p1 = points[i]
                let p2 = points[i + 1]
                let p3 = (i + 2 < points.count) ? points[i + 2] : p2

                let cp1 = CGPoint(
                    x: p1.x + (p2.x - p0.x) / 6.0,
                    y: p1.y + (p2.y - p0.y) / 6.0
                )
                let cp2 = CGPoint(
                    x: p2.x - (p3.x - p1.x) / 6.0,
                    y: p2.y - (p3.y - p1.y) / 6.0
                )

                path.addCurve(to: p2, control1: cp1, control2: cp2)
            }
        }
    }

    private func smoothArea(for values: [Double], maximum: Double, size: CGSize) -> Path {
        var path = smoothLine(for: values, maximum: maximum, size: size)
        if let lastPoint = points(for: values, maximum: maximum, size: size).last,
           let firstPoint = points(for: values, maximum: maximum, size: size).first {
            path.addLine(to: CGPoint(x: lastPoint.x, y: size.height))
            path.addLine(to: CGPoint(x: firstPoint.x, y: size.height))
            path.closeSubpath()
        }
        return path
    }

    private func points(for values: [Double], maximum: Double, size: CGSize) -> [CGPoint] {
        values.enumerated().map { index, value in
            let x = size.width * Double(index) / Double(max(values.count - 1, 1))
            let normalizedY = size.height * (1.0 - (value / maximum) * 0.82 - 0.08)
            let clampedY = max(4.0, min(size.height - 4.0, normalizedY))
            return CGPoint(x: x, y: clampedY)
        }
    }
}

/// Onda senoidal fluida em animação contínua exibida ao ser iniciado o LagCheck
private struct ScanningWaveLine: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                var path = Path()
                let midY = size.height * 0.5
                let amplitude = size.height * 0.28
                let wavelength = max(size.width * 0.4, 80)
                let phase = CGFloat(time * 3.2)

                for x in stride(from: 0.0, through: Double(size.width), by: 2.0) {
                    let relativeX = CGFloat(x) / wavelength
                    let y = midY + sin(relativeX * 2.0 * .pi - phase) * amplitude
                    if x == 0 {
                        path.move(to: CGPoint(x: CGFloat(x), y: y))
                    } else {
                        path.addLine(to: CGPoint(x: CGFloat(x), y: y))
                    }
                }

                context.stroke(
                    path,
                    with: .color(NLColor.accentPrimary.opacity(0.85)),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }
}

