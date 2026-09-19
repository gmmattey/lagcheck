import SwiftUI

/// Identidade visual neutra do jogo. Nunca imita ou incorpora IP de terceiros.
public struct GameArtwork: View {
    private let image: Image?
    private let sourceRecordID: String?
    private let title: String
    private let aspectRatio: CGFloat

    public init(
        image: Image? = nil,
        sourceRecordID: String? = nil,
        title: String,
        aspectRatio: CGFloat? = nil
    ) {
        self.image = image
        self.sourceRecordID = sourceRecordID
        self.title = title
        self.aspectRatio = aspectRatio ?? 1.0
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let img = resolvedImage {
                    img
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .accessibilityHidden(true)
                } else {
                    fallback
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: NLRadius.controlMedium))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
    }

    private var resolvedImage: Image? {
        if let image { return image }
        let lower = title.lowercased()
        let assetName: String?
        if lower.contains("fortnite") {
            assetName = "GameFortnite"
        } else if lower.contains("wild rift") {
            assetName = "GameWildRift"
        } else if lower.contains("league") || lower.contains("lol") {
            assetName = "GameLeagueOfLegends"
        } else if lower.contains("warzone") {
            assetName = "GameWarzone"
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
        } else if lower.contains("valorant") {
            assetName = "GameValorant"
        } else if lower.contains("counter-strike") || lower.contains("cs2") || lower.contains("cs:go") || lower.contains("counter strike") {
            assetName = "GameCs2"
        } else if lower.contains("ea sports") || lower.contains("fifa") || lower.contains("eafc") || lower.contains("fc 2") {
            assetName = "GameEaFc"
        } else if lower.contains("rocket league") {
            assetName = "GameRocketLeague"
        } else if lower.contains("apex") {
            assetName = "GameApexLegends"
        } else if lower.contains("rainbow six") || lower.contains("rainbow 6") || lower.contains("r6") {
            assetName = "GameRainbowSix"
        } else if lower.contains("rust") {
            assetName = "GameRust"
        } else if lower.contains("palworld") {
            assetName = "GamePalworld"
        } else if lower.contains("blood strike") || lower.contains("bloodstrike") {
            assetName = "GameBloodStrike"
        } else if lower.contains("dota") {
            assetName = "GameDota2"
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
            Image(systemName: "gamecontroller")
                .font(.system(size: NLSizing.iconMedium, weight: .medium))
                .foregroundStyle(NLColor.textTertiary)
                .accessibilityHidden(true)
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
