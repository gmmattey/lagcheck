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
            if let image, hasApprovedSourceRecord {
                image
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
            } else {
                fallback
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: NLRadius.card))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
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

    private var hasApprovedSourceRecord: Bool {
        guard let sourceRecordID else { return false }
        return !sourceRecordID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview("Artwork fallback") {
    GameArtwork(image: nil, sourceRecordID: nil, title: "Fortnite")
        .frame(width: 104)
        .padding()
        .background(NLColor.backgroundBase)
        .preferredColorScheme(.dark)
}
