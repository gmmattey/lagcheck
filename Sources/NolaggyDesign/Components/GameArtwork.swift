import SwiftUI

/// Identidade visual neutra do jogo. Nunca imita ou incorpora IP de terceiros.
public struct GameArtwork: View {
    private let image: Image?
    private let sourceRecordID: String?
    private let title: String
    private let aspectRatio: CGFloat

    public init(
        image: Image?,
        sourceRecordID: String?,
        title: String,
        aspectRatio: CGFloat = 1
    ) {
        self.image = image
        self.sourceRecordID = sourceRecordID
        self.title = title
        self.aspectRatio = aspectRatio
    }

    public var body: some View {
        Group {
            if let img = resolvedImage {
                img
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
            } else {
                fallback
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: NLRadius.card))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
    }

    private var resolvedImage: Image? {
        if let image { return image }
        let lower = title.lowercased()
        let assetName: String?
        if lower.contains("fortnite") {
            assetName = "GameFortnite"
        } else if lower.contains("wild rift") || lower.contains("league") {
            assetName = "GameWildRift"
        } else if lower.contains("call of duty") || lower.contains("cod") {
            assetName = "GameCodm"
        } else if lower.contains("roblox") {
            assetName = "GameRoblox"
        } else if lower.contains("free fire") {
            assetName = "GameFreeFire"
        } else if lower.contains("brawl stars") {
            assetName = "GameBrawlStars"
        } else if lower.contains("pubg") {
            assetName = "GamePubg"
        } else if lower.contains("minecraft") {
            assetName = "GameMinecraft"
        } else {
            assetName = nil
        }

        if let assetName, let uiImage = UIImage(named: assetName, in: Bundle.main, compatibleWith: nil) {
            return Image(uiImage: uiImage)
        }
        return nil
    }

    private var fallback: some View {
        ZStack {
            NLColor.backgroundRaised
            LinearGradient(
                colors: [NLColor.backgroundOverlay, NLColor.backgroundRaised],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: NLSpacing.xs) {
                Image(systemName: "gamecontroller")
                    .font(.system(size: NLSizing.iconMedium, weight: .medium))
                    .foregroundStyle(NLColor.textTertiary)
                    .accessibilityHidden(true)
                Text(title)
                    .font(NLTypography.gameCover)
                    .foregroundStyle(NLColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, NLSpacing.sm)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: NLRadius.card)
                .stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline)
        }
    }
}

#Preview("Artwork fallback") {
    GameArtwork(image: nil, sourceRecordID: nil, title: "Fortnite")
        .frame(width: 104)
        .padding()
        .background(NLColor.backgroundBase)
        .preferredColorScheme(.dark)
}
