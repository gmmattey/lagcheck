import SwiftUI

/// Uma explicação curta do achado da medição, separada de qualquer conteúdo publicitário.
public struct InsightBanner: View {
    public enum Tone: Sendable {
        case positive
        case risk
        case tip
    }

    private let tone: Tone
    private let message: LocalizedStringKey
    private let icon: Image
    private let actionTitle: LocalizedStringKey?
    private let action: (() -> Void)?

    public init(
        tone: Tone,
        message: LocalizedStringKey,
        icon: Image,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.tone = tone
        self.message = message
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .top, spacing: NLSpacing.stackGapDefault) {
            icon
                .font(.system(size: NLSizing.insightBannerIconSize, weight: .regular))
                .foregroundStyle(iconColor)
                .frame(width: NLSizing.insightBannerIconSize, height: NLSizing.insightBannerIconSize)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: NLSpacing.stackGapTight) {
                Text(message)
                    .font(NLTypography.callout)
                    .foregroundStyle(NLColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let actionTitle, let action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(NLTypography.captionStrong)
                            .foregroundStyle(NLColor.textLink)
                            .frame(minHeight: NLSizing.touchTarget, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("insight_banner.action_hint"))
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: NLSizing.insightBannerMinHeight, alignment: .leading)
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundOverlay, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: NLRadius.card)
                .stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline)
        }
    }

    private var iconColor: Color {
        switch tone {
        case .positive:
            NLColor.scoreExcellent
        case .risk:
            NLColor.scoreLagRisk
        case .tip:
            NLColor.textLink
        }
    }
}

#Preview("Insight banners") {
    VStack(spacing: NLSpacing.md) {
        InsightBanner(
            tone: .positive,
            message: "Encontramos um pico curto que não deve ser perceptível na partida.",
            icon: Image(systemName: "checkmark.circle")
        )
        InsightBanner(
            tone: .risk,
            message: "A perda de pacotes pode prejudicar sua partida.",
            icon: Image(systemName: "exclamationmark.triangle"),
            actionTitle: "Fazer Deep Check",
            action: {}
        )
        InsightBanner(
            tone: .tip,
            message: "Downloads ou streaming na rede podem causar lag.",
            icon: Image(systemName: "lightbulb")
        )
    }
    .padding()
    .background(NLColor.backgroundBase)
    .preferredColorScheme(.dark)
}
