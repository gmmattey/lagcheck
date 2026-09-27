import SwiftUI

/// Botão de ação oficial do LagCheck Design System (DESIGN.md / kit-components.css).
/// Botão primário: largura cheia, Roxo Gamer, alto contraste, raio de 17px e sombra de ação.
/// Botão crítico/destrutivo: Coral Solar reservado para atenção, erro ou exclusão.
/// Botão secundário/atalho: transparente ou bordado; nunca compete com o primário.
/// Um CTA primário por viewport para a mesma ação.
public struct PrimaryButton: View {
    public enum Style: Sendable {
        /// Ação primária em Roxo Gamer (#7C3AED) com sombra de ação
        case filled
        /// Ação destrutiva ou de atenção crítica em Coral Solar (#FF5A36)
        case filledCritical
        /// Ação secundária com fundo transparente e contorno sutil
        case secondaryOutline
    }

    private let title: LocalizedStringKey
    private let style: Style
    private let icon: Image?
    private let isLoading: Bool
    private let isEnabled: Bool
    private let accessibilityIdentifier: String?
    private let action: () -> Void

    public init(
        title: LocalizedStringKey,
        style: Style = .filled,
        icon: Image? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: NLSpacing.primaryButtonIconGap) {
                if isLoading {
                    ProgressView().tint(foregroundColor)
                } else {
                    if let icon { icon.imageScale(.medium) }
                    Text(title)
                        .font(NLTypography.ctaButton)
                        .tracking(NLTypography.ctaTracking)
                }
            }
            .foregroundStyle(foregroundColor)
            .frame(minWidth: NLSizing.primaryButtonMinWidth, maxWidth: .infinity, minHeight: NLSizing.primaryButtonHeight)
            .padding(.horizontal, NLSpacing.md)
        }
        .buttonStyle(PrimaryButtonStyle(style: style, isEnabled: isEnabled && !isLoading))
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(Text(title))
        .accessibilityIdentifierIfPresent(accessibilityIdentifier)
    }

    private var foregroundColor: Color {
        style == .secondaryOutline ? NLColor.textPrimary : NLColor.textOnAccent
    }
}

private extension View {
    @ViewBuilder
    func accessibilityIdentifierIfPresent(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    let style: PrimaryButton.Style
    let isEnabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && isEnabled

        configuration.label
            .background(
                backgroundColor(isPressed: isPressed),
                in: RoundedRectangle(cornerRadius: NLRadius.lg, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: NLRadius.lg, style: .continuous)
                    .stroke(borderColor, lineWidth: style == .secondaryOutline ? 1 : 0)
            }
            .shadow(
                color: (style == .filled && isEnabled) ? NLShadow.actionColor : Color.clear,
                radius: NLShadow.actionRadius,
                x: 0,
                y: NLShadow.actionYOffset
            )
            .opacity(isEnabled ? 1 : 0.55)
            .scaleEffect(isPressed ? 0.98 : 1)
            .animation(reduceMotion ? nil : NLMotion.buttonPress, value: isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        switch style {
        case .filled:
            return isPressed ? NLColor.accentPrimaryStrong : NLColor.accentPrimary
        case .filledCritical:
            return isPressed ? NLColor.coralSolarStrong : NLColor.coralSolar
        case .secondaryOutline:
            return isPressed ? NLColor.controlOverlay : Color.clear
        }
    }

    private var borderColor: Color {
        NLColor.borderStrong
    }
}

#Preview("Primary buttons") {
    VStack(spacing: NLSpacing.sm) {
        PrimaryButton(title: "Checar agora", action: {})
        PrimaryButton(title: "Trocar jogo", style: .secondaryOutline, action: {})
        PrimaryButton(title: "Apagar histórico", style: .filledCritical, action: {})
        PrimaryButton(title: "Medindo…", isLoading: true, action: {})
    }
    .padding()
    .background(NLColor.backgroundBase)
    .preferredColorScheme(.dark)
}
