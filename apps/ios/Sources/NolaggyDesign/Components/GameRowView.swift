import SwiftUI

/// Componente visual de linha nativa para a lista de jogos (DESIGN.md / kit-components.css).
/// Linha com min-height de 72px, miniatura neutra de 8px de raio, título display e contexto técnico em mono.
public struct GameRowView: View {
    public enum ScoreState: Equatable, Sendable {
        case measuring
        case evaluated(score: Int, classification: NLScoreClassification)
        case inconclusive
        case failed
    }

    private let title: String
    private let category: String
    private let platform: String
    private let scoreState: ScoreState
    private let action: () -> Void

    public init(
        title: String,
        category: String,
        platform: String = "iPhone",
        scoreState: ScoreState,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.category = category
        self.platform = platform
        self.scoreState = scoreState
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: NLSpacing.md) {
                // Miniatura neutra com raio de 8px
                GameArtwork(image: nil, sourceRecordID: nil, title: title, aspectRatio: 1)
                    .frame(width: 44, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: NLRadius.sm, style: .continuous))
                    .accessibilityHidden(true)

                // Título e Meta
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: NLSpacing.xs) {
                        Text(category)
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textSecondary)

                        Text("·")
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textTertiary)

                        Text(platform)
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textTertiary)
                    }
                }
                .layoutPriority(1)

                Spacer(minLength: NLSpacing.sm)

                // Score, Skeleton ou Chevron
                scoreBadge
            }
            .padding(.vertical, NLSpacing.xs)
            .frame(minHeight: 72)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("game-row-\(title.lowercased())")
    }

    @ViewBuilder
    private var scoreBadge: some View {
        switch scoreState {
        case .measuring:
            // Skeleton discreto nativo
            RoundedRectangle(cornerRadius: NLRadius.sm)
                .fill(NLColor.controlOverlay)
                .frame(width: 44, height: 32)
                .overlay {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: NLColor.accentPrimary))
                        .scaleEffect(0.75)
                }
        case let .evaluated(score, classification):
            Text("\(score)")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(classification.color)
                .frame(minWidth: 44, minHeight: 32)
                .background(classification.subtleColor, in: RoundedRectangle(cornerRadius: NLRadius.sm))
                .overlay {
                    RoundedRectangle(cornerRadius: NLRadius.sm)
                        .stroke(classification.color.opacity(0.35), lineWidth: 1)
                }
        case .inconclusive, .failed:
            Text("—")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(NLColor.textTertiary)
                .frame(minWidth: 44, minHeight: 32)
                .background(NLColor.controlOverlay, in: RoundedRectangle(cornerRadius: NLRadius.sm))
        }
    }
}

#Preview("GameRowView States") {
    VStack(spacing: 0) {
        GameRowView(
            title: "Fortnite",
            category: "Battle Royale",
            platform: "PlayStation · Wi-Fi",
            scoreState: .evaluated(score: 92, classification: .excellent),
            action: {}
        )
        Divider().overlay(NLColor.borderHairline)
        GameRowView(
            title: "Valorant",
            category: "Tático",
            platform: "PC · Ethernet",
            scoreState: .measuring,
            action: {}
        )
        Divider().overlay(NLColor.borderHairline)
        GameRowView(
            title: "Roblox",
            category: "Casual",
            platform: "iPhone",
            scoreState: .inconclusive,
            action: {}
        )
    }
    .padding()
    .background(NLColor.backgroundBase)
    .preferredColorScheme(.dark)
}
