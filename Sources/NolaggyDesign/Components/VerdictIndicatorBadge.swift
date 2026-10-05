import SwiftUI
import NolaggyDomain

/// Indicador tático de veredito de telemetria no padrão Dark Competitive UI (Decisão 73).
/// Substitui os glifos Unicode crus (●, ▲, —) por um componente de hardware/cockpit.
public struct VerdictIndicatorBadge: View {
    public let verdict: GameReadinessVerdict
    public var size: CGFloat = 16

    public init(verdict: GameReadinessVerdict, size: CGFloat = 16) {
        self.verdict = verdict
        self.size = size
    }

    public var body: some View {
        switch verdict {
        case .ready:
            // LED de telemetria verde travado com halo concêntrico de sinal
            ZStack {
                Circle()
                    .fill(NLColor.semanticReady.opacity(0.20))
                    .frame(width: size + 8, height: size + 8)

                Circle()
                    .strokeBorder(NLColor.semanticReady.opacity(0.55), lineWidth: 1.5)
                    .frame(width: size + 4, height: size + 4)

                Circle()
                    .fill(NLColor.semanticReady)
                    .frame(width: size, height: size)
            }
            .accessibilityLabel("Pronto")

        case .caution:
            // Micro-tag tática chanfrada / alerta em Âmbar com ícone geométrico interno
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(NLColor.semanticCaution.opacity(0.18))
                    .frame(width: size + 6, height: size + 6)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(NLColor.semanticCaution, lineWidth: 1.5)
                    .frame(width: size + 6, height: size + 6)

                Image(systemName: "exclamationmark")
                    .font(.system(size: size * 0.65, weight: .black))
                    .foregroundStyle(NLColor.semanticCaution)
            }
            .accessibilityLabel("Atenção")

        case .notReady:
            // Alerta crítico / corte em Coral Solar com ícone de escudo ou xmark
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(NLColor.semanticNotReady.opacity(0.20))
                    .frame(width: size + 6, height: size + 6)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(NLColor.semanticNotReady, lineWidth: 1.5)
                    .frame(width: size + 6, height: size + 6)

                Image(systemName: "xmark")
                    .font(.system(size: size * 0.60, weight: .black))
                    .foregroundStyle(NLColor.semanticNotReady)
            }
            .accessibilityLabel("Não recomendado")

        case .inconclusive:
            // Radar sem eco em Slate com traço técnico
            ZStack {
                Circle()
                    .strokeBorder(NLColor.textTertiary, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                    .frame(width: size + 4, height: size + 4)

                Rectangle()
                    .fill(NLColor.textTertiary)
                    .frame(width: size * 0.5, height: 2)
            }
            .accessibilityLabel("Inconclusivo")
        }
    }
}
