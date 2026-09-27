import SwiftUI
import NolaggyDomain
import NolaggyDesign

/// Fileira de ícones compactos das plataformas suportadas pelo jogo.
/// Substitui concatenação textual ("iPhone · PC · PlayStation...") por telemetria visual limpa.
public struct GamePlatformIconsRow: View {
    public let platforms: [Platform]
    public var spacing: CGFloat
    public var iconSize: CGFloat
    public var foregroundColor: Color

    public init(
        platforms: [Platform],
        spacing: CGFloat = 7,
        iconSize: CGFloat = 12,
        foregroundColor: Color = NLColor.textTertiary
    ) {
        self.platforms = platforms
        self.spacing = spacing
        self.iconSize = iconSize
        self.foregroundColor = foregroundColor
    }

    public var body: some View {
        HStack(spacing: spacing) {
            ForEach(orderedPlatforms, id: \.self) { platform in
                platformIcon(platform)
            }
        }
    }

    private var orderedPlatforms: [Platform] {
        let canonicalOrder: [Platform] = [.iphone, .playstation, .xbox, .nintendo, .pc]
        return canonicalOrder.filter { platforms.contains($0) }
    }

    @ViewBuilder
    private func platformIcon(_ platform: Platform) -> some View {
        Image(systemName: iconName(for: platform))
            .font(.system(size: iconSize, weight: .semibold))
            .foregroundStyle(foregroundColor)
            .accessibilityLabel(platform.displayName)
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
}
