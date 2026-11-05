import SwiftUI
import NolaggyDomain
import NolaggyDesign

/// Sheet de Confirmação em 1 Toque quando o usuário abre um link de Duelo de Host (Decisão 112).
/// Dá a chance do jogador conferir o Wi-Fi antes de iniciar a medição do jogo.
public struct HostDuelInvitationSheet: View {
    public let duel: HostDuelPayload
    public let gameName: String
    public let onAccept: () -> Void
    public let onDecline: () -> Void

    @Environment(\.dismiss) private var dismiss

    public init(
        duel: HostDuelPayload,
        gameName: String,
        onAccept: @escaping () -> Void,
        onDecline: @escaping () -> Void
    ) {
        self.duel = duel
        self.gameName = gameName
        self.onAccept = onAccept
        self.onDecline = onDecline
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Indicador de arrasto
            Capsule()
                .fill(NLColor.hairline)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("\(gameName.uppercased()) • DUELO DE HOST")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(NLColor.gamerPurple)
                    .tracking(1.0)

                Text("Quem puxa a ranked?")
                    .font(NLTypography.screenTitle)
                    .foregroundStyle(NLColor.textPrimary)

                let name = duel.challengerNick.isEmpty ? "Seu Duo" : duel.challengerNick
                Text("\(name) quer decidir quem cria a sala no lobby.")
                    .font(NLTypography.callout)
                    .foregroundStyle(NLColor.textSecondary)
            }

            // Card de telemetria do desafiante com elevação e profundidade (sem bordas de tabela)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 8) {
                        Text(String(duel.challengerNick.prefix(1)).uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white)
                            .frame(width: 24, height: 24)
                            .background(NLColor.gamerPurple, in: Circle())

                        Text(duel.challengerNick.isEmpty ? "Desafiante" : duel.challengerNick)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(NLColor.textPrimary)
                    }

                    Spacer()

                    Text(verdictLabel(duel.verdict))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(colorForVerdict(duel.verdict))
                }

                HStack(alignment: .lastTextBaseline) {
                    Text("\(Int(round(duel.p50Ms)))")
                        .font(.system(size: 34, weight: .black, design: .monospaced))
                        .foregroundStyle(NLColor.textPrimary)
                    Text("ms")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NLColor.textSecondary)

                    Spacer()

                    Text("\(duel.packetLossPercent, specifier: "%.1f")% perda · \(Int(round(duel.jitterMs)))ms jitter")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(NLColor.textSecondary)
                }
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [NLColor.panel, NLColor.surface],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)

            // Linha de tempo restante
            HStack {
                let remainingMin = duel.remainingSeconds() / 60
                Text("Válido por mais \(max(1, remainingMin)) min")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(NLColor.textTertiary)

                Spacer()

                Text("Regra de host v1")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(NLColor.textTertiary)
            }
            .padding(.horizontal, 4)

            // Ações
            VStack(spacing: 10) {
                Button(action: {
                    dismiss()
                    onAccept()
                }) {
                    Text("Aceitar e Medir Minha Rota")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(NLColor.gamerPurple, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: {
                    dismiss()
                    onDecline()
                }) {
                    Text("Recusar Desafio")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(NLColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .background(NLColor.deep.ignoresSafeArea())
        .presentationDetents([.height(390)])
        .presentationDragIndicator(.hidden)
    }

    private func verdictLabel(_ verdict: GameReadinessVerdict) -> String {
        switch verdict {
        case .ready: return "● PRONTO"
        case .caution: return "▲ INSTÁVEL"
        case .notReady: return "▲ EVITAR"
        case .inconclusive: return "— INCONCLUSIVO"
        }
    }

    private func colorForVerdict(_ verdict: GameReadinessVerdict) -> Color {
        switch verdict {
        case .ready: return NLColor.scoreExcellent
        case .caution: return NLColor.cautionYellow
        case .notReady: return NLColor.coralSolar
        case .inconclusive: return NLColor.textSecondary
        }
    }
}
