import SwiftUI

/// Hero da Home do LagCheck — Gauge circular com estética direta do MeasurementPulse (da medição).
/// Apresenta trilho fino nativo, arco Coral Solar com pulso interno (pulseCore) e ondas dinâmicas.
/// No centro: ação "TESTAR AGORA". Se nenhum jogo estiver selecionado, exibe "CONEXÃO GERAL".
public struct HomeCircularPulseGaugeHero: View {
    public let selectedGameName: String?
    public let regionName: String
    public let isMeasuring: Bool
    public let onStartCheck: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing: Bool = false

    private let pulseDiameter: CGFloat = 175
    private let strokeWidth: CGFloat = NLSizing.measurementPulseStrokeWidth

    public init(
        selectedGameName: String?,
        regionName: String,
        isMeasuring: Bool = false,
        onStartCheck: @escaping () -> Void
    ) {
        self.selectedGameName = selectedGameName
        self.regionName = regionName
        self.isMeasuring = isMeasuring
        self.onStartCheck = onStartCheck
    }

    public var body: some View {
        VStack(spacing: NLSpacing.sm) {
            ZStack {
                // Ondas Pulsantes Concêntricas (acompanhando o ritmo do gauge)
                if !reduceMotion {
                    ForEach(0..<2, id: \.self) { index in
                        Circle()
                            .stroke(
                                NLColor.accentPrimary.opacity(isMeasuring ? 0.35 : 0.20),
                                lineWidth: 1.5
                            )
                            .frame(width: pulseDiameter, height: pulseDiameter)
                            .scaleEffect(isPulsing ? 1.38 : 1.0)
                            .opacity(isPulsing ? 0.0 : 0.45)
                            .animation(
                                .easeOut(duration: isMeasuring ? 1.2 : 2.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * (isMeasuring ? 0.5 : 0.9)),
                                value: isPulsing
                            )
                    }
                }

                // Trilho Base do Gauge (mesmo de MeasurementPulse)
                Circle()
                    .stroke(NLColor.borderSubtle, lineWidth: strokeWidth)
                    .frame(width: pulseDiameter, height: pulseDiameter)

                // Arco Ativo Coral Solar (mesmo estilo e acabamento de MeasurementPulse)
                Circle()
                    .trim(from: 0, to: isMeasuring ? 0.85 : 0.66)
                    .stroke(
                        NLColor.accentPrimary,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(isMeasuring ? (isPulsing ? 270 : -90) : -90))
                    .frame(width: pulseDiameter, height: pulseDiameter)
                    .animation(
                        isMeasuring
                            ? .linear(duration: 1.4).repeatForever(autoreverses: false)
                            : .smooth(duration: 0.35),
                        value: isMeasuring
                    )

                // Núcleo com Pulso Interno (pulseCore)
                Circle()
                    .fill(NLColor.accentPrimary.opacity(0.12))
                    .frame(width: pulseDiameter - 40, height: pulseDiameter - 40)
                    .scaleEffect(reduceMotion ? 1.0 : (isPulsing ? 1.0 : 0.94))
                    .opacity(isPulsing ? 1.0 : 0.7)
                    .animation(
                        NLMotion.measurementPulse,
                        value: isPulsing
                    )

                // Botão de Toque Central
                Button(action: {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    onStartCheck()
                }) {
                    VStack(spacing: 4) {
                        if isMeasuring {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(NLColor.accentPrimary)
                                .scaleEffect(1.2)
                                .padding(.bottom, 2)

                            Text(LocalizedStringKey("home.gauge.measuring"))
                                .font(NLTypography.subheadline.weight(.heavy))
                                .foregroundStyle(NLColor.textPrimary)
                                .tracking(0.6)
                        } else {
                            // Texto Dominante "TESTAR AGORA"
                            Text(LocalizedStringKey("home.gauge.test_now"))
                                .font(.system(size: 17, weight: .heavy, design: .default))
                                .foregroundStyle(NLColor.textPrimary)
                                .tracking(0.8)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)

                            // Subtítulo do Contexto (Jogo selecionado ou Conexão Geral)
                            if let game = selectedGameName, !game.isEmpty {
                                Text(game.uppercased())
                                    .font(NLTypography.captionStrong)
                                    .foregroundStyle(NLColor.accentPrimary)
                                    .lineLimit(1)
                                    .padding(.horizontal, 8)
                            } else {
                                Text(LocalizedStringKey("generic_gaming.short_name"))
                                    .font(NLTypography.captionStrong)
                                    .foregroundStyle(NLColor.textSecondary)
                                    .lineLimit(1)
                                    .padding(.horizontal, 8)
                            }

                            // Rota / Região de referência sutil
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(NLColor.semanticReady)
                                    .frame(width: 4, height: 4)
                                Text(regionName)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(NLColor.textTertiary)
                            }
                        }
                    }
                    .frame(width: pulseDiameter - 48, height: pulseDiameter - 48)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isMeasuring)
                .accessibilityIdentifier("home-cta-start-lagcheck")
                .accessibilityLabel(Text(LocalizedStringKey("home.gauge.test_now")))
            }
            .frame(width: pulseDiameter + 48, height: pulseDiameter + 48)
            .onAppear {
                isPulsing = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NLSpacing.xs)
    }
}
