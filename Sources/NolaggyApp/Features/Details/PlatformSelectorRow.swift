import SwiftUI
import NolaggyDesign
import NolaggyDomain

/// Seletor horizontal de plataformas compatíveis com o jogo (Decisão 26).
/// Renderiza os ícones dispostos lado a lado em uma única linha horizontal.
struct PlatformSelectorRow: View {
    let supportedPlatforms: [Platform]
    @Binding var selectedPlatform: Platform

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NLSpacing.xs) {
                ForEach(supportedPlatforms, id: \.self) { platform in
                    let isSelected = (platform == selectedPlatform)
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedPlatform = platform
                        }
                    } label: {
                        HStack(spacing: NLSpacing.xxs) {
                            Image(systemName: iconName(for: platform))
                                .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                            Text(displayName(for: platform))
                                .font(NLTypography.captionStrong)
                        }
                        .foregroundStyle(isSelected ? NLColor.textPrimary : NLColor.textSecondary)
                        .frame(minWidth: 92)
                        .frame(minHeight: NLSizing.touchTarget)
                        .background(
                            isSelected ? NLColor.backgroundRaised : Color.clear,
                            in: RoundedRectangle(cornerRadius: NLRadius.controlSmall)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: NLRadius.controlSmall)
                                .stroke(
                                    isSelected ? NLColor.coralSolar.opacity(0.8) : NLColor.borderSubtle,
                                    lineWidth: isSelected ? 1.5 : NLStroke.hairline
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(displayName(for: platform))
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
        }
        .padding(4)
        .background(NLColor.backgroundRaised.opacity(0.5), in: RoundedRectangle(cornerRadius: NLRadius.card))
    }

    private func iconName(for platform: Platform) -> String {
        switch platform {
        case .iphone: return "iphone"
        case .playstation: return "playstation.logo"
        case .xbox: return "xbox.logo"
        case .pc: return "display"
        case .nintendo: return "gamecontroller.fill"
        }
    }

    private func displayName(for platform: Platform) -> String {
        switch platform {
        case .iphone: return "iPhone"
        case .playstation: return "PlayStation"
        case .xbox: return "Xbox"
        case .pc: return "PC"
        case .nintendo: return "Switch"
        }
    }
}
