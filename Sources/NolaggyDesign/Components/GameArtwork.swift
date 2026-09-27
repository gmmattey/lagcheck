import SwiftUI

/// Identidade visual neutra do jogo. Nunca imita ou incorpora IP de terceiros (DESIGN.md / Decisão 18).
/// Usa raio de 8px (NLRadius.sm) e insígnia neutra em Roxo Gamer.
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
                if let image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .accessibilityHidden(true)
                } else {
                    competitiveBadge(size: proxy.size)
                }
            }
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: NLRadius.sm, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
    }

    private func competitiveBadge(size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: NLRadius.sm, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [NLColor.panel, NLColor.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 2) {
                Text(gameBadgeMonogram)
                    .font(.system(size: max(14, size.width * 0.28), weight: .black, design: .monospaced))
                    .foregroundStyle(NLColor.textPrimary)
                    .tracking(1.0)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(verbatim: "ROUTE")
                    .font(.system(size: max(7, size.width * 0.11), weight: .bold, design: .monospaced))
                    .foregroundStyle(NLColor.gamerPurple)
                    .tracking(1.2)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: NLRadius.sm, style: .continuous)
                .stroke(NLColor.borderHairline, lineWidth: 1)
        }
    }

    private var gameBadgeMonogram: String {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if clean.contains("FORTNITE") { return "FN" }
        if clean.contains("COUNTER") || clean.contains("CS") { return "CS2" }
        if clean.contains("VALORANT") { return "VAL" }
        if clean.contains("LEAGUE") || clean.contains("LOL") { return "LOL" }
        if clean.contains("WARZONE") || clean.contains("COD") { return "COD" }
        if clean.contains("ROBLOX") { return "RBX" }
        if clean.contains("FREE FIRE") { return "FF" }
        if clean.contains("ROCKET") { return "RL" }
        if clean.contains("APEX") { return "APEX" }
        if clean.contains("RAINBOW") || clean.contains("R6") { return "R6" }
        if clean.contains("DOTA") { return "DOTA" }
        if clean.contains("EA SPORTS") || clean.contains("FC") { return "EAFC" }
        let words = clean.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1))
        }
        return String(clean.prefix(3))
    }
}

#Preview("Artwork fallback") {
    GameArtwork(image: nil, sourceRecordID: nil, title: "Fortnite")
        .frame(width: 104)
        .padding()
        .background(NLColor.backgroundBase)
        .preferredColorScheme(.dark)
}
