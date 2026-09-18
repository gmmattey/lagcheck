import SwiftUI

/// Componente visual de linha nativa para a lista de jogos da Home (Decisão 22).
/// Exibe miniatura neutra, título, badge de categoria/plataforma e score ou skeleton.
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
                // Miniatura neutra
                GameArtwork(image: nil, sourceRecordID: nil, title: title)
                    .frame(width: 48, height: 48)
                    .accessibilityHidden(true)

                // Título e Meta
                VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                    Text(title)
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: NLSpacing.xs) {
                        Text(category)
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textSecondary)

                        Text("•")
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textTertiary)

                        Text(platform)
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textTertiary)
                    }
                }

                Spacer(minLength: NLSpacing.sm)

                // Score ou Skeleton
                scoreBadge
            }
            .padding(.vertical, NLSpacing.xs)
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
            RoundedRectangle(cornerRadius: NLRadius.controlSmall)
                .fill(NLColor.controlOverlay)
                .frame(width: 44, height: 32)
                .overlay {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: NLColor.textTertiary))
                        .scaleEffect(0.75)
                }
        case let .evaluated(score, classification):
            Text("\(score)")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(classification.color)
                .frame(minWidth: 44, minHeight: 32)
                .background(classification.subtleColor, in: RoundedRectangle(cornerRadius: NLRadius.controlSmall))
                .overlay {
                    RoundedRectangle(cornerRadius: NLRadius.controlSmall)
                        .stroke(classification.color.opacity(0.35), lineWidth: NLStroke.hairline)
                }
        case .inconclusive, .failed:
            Text("—")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(NLColor.textTertiary)
                .frame(minWidth: 44, minHeight: 32)
                .background(NLColor.controlOverlay, in: RoundedRectangle(cornerRadius: NLRadius.controlSmall))
        }
    }
}

#Preview("GameRowView States") {
    VStack(spacing: NLSpacing.sm) {
        GameRowView(
            title: "Fortnite",
            category: "Battle Royale",
            platform: "iPhone",
            scoreState: .evaluated(score: 92, classification: .excellent),
            action: {}
        )
        GameRowView(
            title: "Brawl Stars",
            category: "Tempo Real",
            platform: "iPhone",
            scoreState: .measuring,
            action: {}
        )
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
