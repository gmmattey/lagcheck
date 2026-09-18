import SwiftUI

/// Banner contextual do Apple Games Editorial Hub para orientação de frequência e estabilidade da rede Wi-Fi.
public struct NetworkBandAdviceBanner: View {
    public enum Style: Sendable {
        case warning
        case positive
        case neutral
    }

    private let title: LocalizedStringKey
    private let message: LocalizedStringKey
    private let badgeText: String?
    private let style: Style
    private let iconName: String
    private let actionTitle: LocalizedStringKey?
    private let onAction: (() -> Void)?

    public init(
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        badgeText: String? = nil,
        style: Style = .warning,
        iconName: String = "wifi.exclamationmark",
        actionTitle: LocalizedStringKey? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.badgeText = badgeText
        self.style = style
        self.iconName = iconName
        self.actionTitle = actionTitle
        self.onAction = onAction
    }

    public var body: some View {
        HStack(alignment: .top, spacing: NLSpacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: 36, height: 36)
                .background(accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: NLRadius.controlSmall))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                HStack(alignment: .center) {
                    Text(title)
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textPrimary)
                    Spacer()
                    if let badgeText {
                        Text(badgeText)
                            .font(NLTypography.captionStrong)
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(accentColor.opacity(0.18), in: Capsule())
                    }
                }

                Text(message)
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)

                if let actionTitle, let onAction {
                    Button(action: onAction) {
                        HStack(spacing: NLSpacing.xxs) {
                            Text(actionTitle)
                                .font(NLTypography.captionStrong)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(NLColor.coralSolar)
                        .padding(.top, NLSpacing.xxs)
                        .frame(minHeight: NLSizing.touchTarget, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("Abre a ação recomendada"))
                }
            }
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: NLRadius.card)
                .stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline)
        }
    }

    private var accentColor: Color {
        switch style {
        case .warning:
            return NLColor.scoreUnstable
        case .positive:
            return NLColor.scoreExcellent
        case .neutral:
            return NLColor.coralSolar
        }
    }
}
