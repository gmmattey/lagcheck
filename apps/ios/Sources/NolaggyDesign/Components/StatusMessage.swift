import SwiftUI

public struct StatusMessage: View {
    public enum Kind: Sendable { case info, warning, error, cancelled, inconclusive }

    private let kind: Kind
    private let message: LocalizedStringKey
    private let actionTitle: LocalizedStringKey?
    private let action: (() -> Void)?

    public init(kind: Kind, message: LocalizedStringKey, actionTitle: LocalizedStringKey? = nil, action: (() -> Void)? = nil) {
        self.kind = kind
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .top, spacing: NLSpacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: NLSizing.iconSmall, weight: .semibold))
                .foregroundStyle(NLColor.textSecondary)
                .frame(width: NLSizing.iconSmall, height: NLSizing.iconSmall)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                Text(message)
                    .font(NLTypography.body)
                    .foregroundStyle(NLColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let actionTitle, let action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(NLTypography.bodyEmphasis)
                            .foregroundStyle(NLColor.textPrimary)
                            .frame(minHeight: NLSizing.touchTarget)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: NLSizing.statusMessageMinHeight, alignment: .leading)
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay { RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: 1) }
    }

    private var iconName: String {
        switch kind {
        case .info: "info.circle"
        case .warning: "exclamationmark.triangle"
        case .error: "xmark.octagon"
        case .cancelled: "arrow.counterclockwise.circle"
        case .inconclusive: "questionmark.circle"
        }
    }
}

#Preview("Status messages") {
    VStack(spacing: NLSpacing.md) {
        StatusMessage(kind: .inconclusive, message: "Não conseguimos dados suficientes para avaliar sua conexão. Tente novamente em instantes.", actionTitle: "Tentar novamente", action: {})
        StatusMessage(kind: .cancelled, message: "A conexão mudou durante a medição. Descartamos a leitura parcial.", actionTitle: "Reiniciar teste", action: {})
    }
    .padding()
    .background(NLColor.backgroundBase)
    .preferredColorScheme(.dark)
}
