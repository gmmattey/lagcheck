import SwiftUI

/// Faixa compacta de compatibilidade da sessão (Decisão 35/36).
/// Apresenta Multiplayer, Calls e Streaming em uma única faixa coesa (sem card soup).
/// Sem números, percentuais ou textos explicativos visíveis; acessibilidade completa via VoiceOver.
public struct SessionCompatibilityStrip: View {
    public enum State: Sendable {
        case check
        case attention
        case neutral
    }

    private let multiplayerState: State
    private let callsState: State
    private let streamingState: State

    public init(
        multiplayer: State,
        calls: State,
        streaming: State = .neutral
    ) {
        self.multiplayerState = multiplayer
        self.callsState = calls
        self.streamingState = streaming
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Item 1: Multiplayer
            itemCell(
                icon: "gamecontroller.fill",
                title: String(localized: "check_completo.compat.multiplayer", defaultValue: "Multiplayer"),
                state: multiplayerState,
                accessibilityLabel: multiplayerAccessibilityLabel
            )

            divider()

            // Item 2: Calls
            itemCell(
                icon: "mic.fill",
                title: String(localized: "check_completo.compat.calls", defaultValue: "Calls"),
                state: callsState,
                accessibilityLabel: callsAccessibilityLabel
            )

            divider()

            // Item 3: Streaming
            itemCell(
                icon: "dot.radiowaves.left.and.right",
                title: String(localized: "check_completo.compat.streaming", defaultValue: "Streaming"),
                state: streamingState,
                accessibilityLabel: streamingAccessibilityLabel
            )
        }
        .frame(minHeight: NLSizing.touchTarget)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                .stroke(NLColor.borderSubtle, lineWidth: 0.5)
        }
    }

    private func itemCell(
        icon: String,
        title: String,
        state: State,
        accessibilityLabel: String
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(iconColor(for: state))
                .frame(width: 14)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(NLColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Spacer(minLength: 1)

            stateIndicator(for: state)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, NLSpacing.sm)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private func divider() -> some View {
        Rectangle()
            .fill(NLColor.borderSubtle)
            .frame(width: 0.5, height: 24)
    }

    @ViewBuilder
    private func stateIndicator(for state: State) -> some View {
        switch state {
        case .check:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(NLColor.scoreExcellent)
        case .attention:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(NLColor.coralSolarRed)
        case .neutral:
            Image(systemName: "minus.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(NLColor.textTertiary)
        }
    }

    private func iconColor(for state: State) -> Color {
        switch state {
        case .check:
            return NLColor.scoreExcellent
        case .attention:
            return NLColor.coralSolarRed
        case .neutral:
            return NLColor.textSecondary
        }
    }

    // MARK: - VoiceOver Accessibility Labels

    private var multiplayerAccessibilityLabel: String {
        switch multiplayerState {
        case .check:
            return String(localized: "check_completo.compat.multiplayer.a11y.check", defaultValue: "Multiplayer: condições compatíveis observadas.")
        case .attention:
            return String(localized: "check_completo.compat.multiplayer.a11y.attention", defaultValue: "Multiplayer: há uma condição na rede que pode afetar a conexão.")
        case .neutral:
            return String(localized: "check_completo.compat.multiplayer.a11y.neutral", defaultValue: "Multiplayer: não avaliado.")
        }
    }

    private var callsAccessibilityLabel: String {
        switch callsState {
        case .check:
            return String(localized: "check_completo.compat.calls.a11y.check", defaultValue: "Calls: condições compatíveis observadas.")
        case .attention:
            return String(localized: "check_completo.compat.calls.a11y.attention", defaultValue: "Calls: há uma condição na rede que pode afetar a conexão.")
        case .neutral:
            return String(localized: "check_completo.compat.calls.a11y.neutral", defaultValue: "Calls: não avaliado.")
        }
    }

    private var streamingAccessibilityLabel: String {
        String(localized: "check_completo.compat.streaming.a11y.neutral", defaultValue: "Streaming: não avaliado.")
    }
}
