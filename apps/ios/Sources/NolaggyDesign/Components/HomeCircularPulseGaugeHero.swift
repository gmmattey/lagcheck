import SwiftUI

/// Hero da Home do LagCheck — Mostrador de telemetria com ticks de precisão,
/// órbita fina em Roxo Gamer e núcleo elevado com profundidade (Decisão 129).
public struct HomeCircularPulseGaugeHero: View {
    public let selectedGameName: String?
    public let regionName: String
    public let isMeasuring: Bool
    public let onStartCheck: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing: Bool = false
    @State private var orbitRotation: Double = 0

    private let pulseDiameter: CGFloat = 216

    public init(
        selectedGameName: String? = nil,
        regionName: String = "",
        isMeasuring: Bool = false,
        onStartCheck: @escaping () -> Void
    ) {
        self.selectedGameName = selectedGameName
        self.regionName = regionName
        self.isMeasuring = isMeasuring
        self.onStartCheck = onStartCheck
    }

    public var body: some View {
        let orbitDiameter = pulseDiameter - 20
        let coreDiameter = pulseDiameter - 48

        VStack(spacing: NLSpacing.sm) {
            ZStack {
                // Pulso sutil de presença
                if !reduceMotion && !isMeasuring {
                    Circle()
                        .fill(NLColor.accentPrimary.opacity(isPulsing ? 0.0 : 0.12))
                        .frame(width: pulseDiameter - 16, height: pulseDiameter - 16)
                        .scaleEffect(isPulsing ? 1.24 : 1.0)
                        .animation(
                            .easeOut(duration: 3.0).repeatForever(autoreverses: false),
                            value: isPulsing
                        )
                }

                // 36 marcações radiais de mostrador
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let outerR = (min(size.width, size.height) - 8) / 2
                    for i in 0..<36 {
                        let angle = (Double(i) * 10.0 - 90.0) * .pi / 180.0
                        let isCardinal = i.isMultiple(of: 9)
                        let tickLen: CGFloat = isCardinal ? 7 : 4
                        let tickWidth: CGFloat = isCardinal ? 1.8 : 1.0
                        let color = isCardinal ? NLColor.textSecondary.opacity(0.55) : NLColor.textTertiary.opacity(0.35)
                        let start = CGPoint(
                            x: center.x + (outerR - tickLen) * cos(angle),
                            y: center.y + (outerR - tickLen) * sin(angle)
                        )
                        let end = CGPoint(
                            x: center.x + outerR * cos(angle),
                            y: center.y + outerR * sin(angle)
                        )
                        var path = Path()
                        path.move(to: start)
                        path.addLine(to: end)
                        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: tickWidth, lineCap: .round))
                    }
                }
                .frame(width: pulseDiameter, height: pulseDiameter)

                // Trilho fino contínuo da órbita
                Circle()
                    .stroke(NLColor.borderHairline, lineWidth: 1.2)
                    .frame(width: orbitDiameter, height: orbitDiameter)

                // Arco fino da órbita + ponto guia luminoso
                ZStack {
                    let sweepRatio: CGFloat = isMeasuring ? (110.0 / 360.0) : (72.0 / 360.0)
                    let tipAngleDegrees: Double = Double(sweepRatio) * 360.0 - 90.0

                    Circle()
                        .trim(from: 0, to: sweepRatio)
                        .stroke(
                            NLColor.accentPrimary.opacity(0.85),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: orbitDiameter, height: orbitDiameter)

                    ZStack {
                        Circle()
                            .fill(NLColor.accentPrimary.opacity(0.35))
                            .frame(width: 14, height: 14)
                        Circle()
                            .fill(NLColor.gamerPurpleLight)
                            .frame(width: 6.4, height: 6.4)
                    }
                    .offset(
                        x: (orbitDiameter / 2) * cos(tipAngleDegrees * .pi / 180.0),
                        y: (orbitDiameter / 2) * sin(tipAngleDegrees * .pi / 180.0)
                    )
                }
                .rotationEffect(.degrees(reduceMotion ? 0 : orbitRotation))

                // Núcleo Central Elevado (profundidade por camada + sombra, sem linha de contorno)
                Button(action: {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    onStartCheck()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [NLColor.panel, NLColor.surface],
                                    center: .center,
                                    startRadius: 4,
                                    endRadius: coreDiameter / 2
                                )
                            )
                            .overlay(
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [NLColor.accentPrimary.opacity(0.16), Color.clear],
                                            center: .center,
                                            startRadius: 2,
                                            endRadius: coreDiameter / 2
                                        )
                                    )
                            )
                            .shadow(color: NLShadow.floatColor, radius: 14, x: 0, y: 8)

                        VStack(spacing: 4) {
                            if isMeasuring {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(NLColor.gamerPurpleLight)
                                    .scaleEffect(1.1)
                                    .padding(.bottom, 2)

                                Text(LocalizedStringKey("home.gauge.measuring"))
                                    .font(NLTypography.statusLine)
                                    .foregroundStyle(NLColor.textPrimary)
                                    .tracking(0.6)
                            } else {
                                Text(LocalizedStringKey("home.gauge.test"))
                                    .font(NLTypography.headline)
                                    .foregroundStyle(Color.white)
                                    .tracking(1.8)
                            }
                        }
                    }
                    .frame(width: coreDiameter, height: coreDiameter)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isMeasuring)
                .accessibilityIdentifier("home-cta-start-lagcheck")
                .accessibilityLabel(Text(LocalizedStringKey("home.gauge.test_now")))
            }
            .frame(width: pulseDiameter + 40, height: pulseDiameter + 40)
            .onAppear {
                isPulsing = true
                if !reduceMotion {
                    withAnimation(.linear(duration: isMeasuring ? 1.4 : 9.0).repeatForever(autoreverses: false)) {
                        orbitRotation = 360
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NLSpacing.xs)
    }
}
