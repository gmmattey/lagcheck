import SwiftUI
import NolaggyDomain
import NolaggyDesign

/// Sheet para definir ou alterar o Nick Gamer local para o Duelo de Host (Decisão 112).
/// Salvo estritamente no dispositivo via AppStorage (UserDefaults) — sem login, sem conta e sem servidor.
public struct HostDuelNickSheet: View {
    @AppStorage("lagcheck_gamer_nick") private var savedNick: String = ""
    @State private var currentNick: String = ""
    @Environment(\.dismiss) private var dismiss

    public let onConfirm: (String) -> Void

    public init(onConfirm: @escaping (String) -> Void) {
        self.onConfirm = onConfirm
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Indicador de arrasto
            Capsule()
                .fill(NLColor.hairline)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 6) {
                Text("SEU NICK NO LOBBY")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(NLColor.textTertiary)
                    .tracking(1.0)

                Text("Como quer aparecer no duelo?")
                    .font(NLTypography.screenTitle)
                    .foregroundStyle(NLColor.textPrimary)

                Text("Fica salvo só no seu aparelho. Sem conta, sem login.")
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
            }
            .padding(.top, 4)

            // Campo de Nick com profundidade
            TextField("Ex: Luiz, FalleN, Coringa", text: $currentNick)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(NLColor.textPrimary)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .submitLabel(.done)
                .onSubmit { confirm() }

            HStack(spacing: 10) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancelar")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(NLColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: { confirm() }) {
                    Text("Gerar Desafio")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(NLColor.gamerPurple, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(NLColor.deep.ignoresSafeArea())
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.hidden)
        .onAppear {
            currentNick = savedNick
        }
    }

    private func confirm() {
        let trimmed = String(currentNick.trimmingCharacters(in: .whitespacesAndNewlines).prefix(16))
        savedNick = trimmed
        dismiss()
        onConfirm(trimmed)
    }
}
