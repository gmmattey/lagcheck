import SwiftUI

/// Componentes visuais para descoberta de jogos. Eles não conhecem catálogo,
/// disponibilidade técnica, URL nem origem de arte.
public struct CatalogSearchField: View {
    @Binding private var query: String
    private let placeholder: LocalizedStringKey
    private let accessibilityLabel: LocalizedStringKey
    private let dismiss: (() -> Void)?
    private let focusesOnAppear: Bool
    @FocusState private var isFocused: Bool

    public init(
        query: Binding<String>,
        placeholder: LocalizedStringKey,
        accessibilityLabel: LocalizedStringKey,
        dismiss: (() -> Void)? = nil,
        focusesOnAppear: Bool = false
    ) {
        _query = query
        self.placeholder = placeholder
        self.accessibilityLabel = accessibilityLabel
        self.dismiss = dismiss
        self.focusesOnAppear = focusesOnAppear
    }

    public var body: some View {
        HStack(spacing: NLSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(NLColor.textTertiary)
                .accessibilityHidden(true)
            TextField(placeholder, text: $query)
                .font(NLTypography.body)
                .foregroundStyle(NLColor.textPrimary)
                .tint(NLColor.accentPrimary)
                .focused($isFocused)
                .accessibilityLabel(Text(accessibilityLabel))
            if let dismiss {
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(NLColor.textSecondary)
                }
                .accessibilityLabel(Text("catalog.search.close"))
            }
        }
        .padding(.horizontal, NLSpacing.md)
        .frame(minHeight: NLSizing.touchTarget)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.controlMedium))
        .overlay {
            RoundedRectangle(cornerRadius: NLRadius.controlMedium)
                .stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline)
        }
        .task {
            guard focusesOnAppear else { return }
            await Task.yield()
            isFocused = true
        }
    }
}

public struct CatalogCategoryChip: View {
    private let label: String
    private let isSelected: Bool
    private let action: () -> Void

    public init(label: String, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(NLTypography.captionStrong)
                .foregroundStyle(isSelected ? NLColor.accentPrimary : NLColor.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, NLSpacing.md)
                .frame(minHeight: NLSizing.touchTarget)
                .background(isSelected ? NLColor.accentPrimarySubtle : NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.controlSmall))
                .overlay {
                    RoundedRectangle(cornerRadius: NLRadius.controlSmall)
                        .stroke(isSelected ? NLColor.accentPrimary : NLColor.borderSubtle, lineWidth: NLStroke.hairline)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

public struct CatalogGameTile: View {
    private let title: String
    private let category: String
    private let image: Image?
    private let sourceRecordID: String?
    private let latestScore: Int?
    private let latestScoreColor: Color
    private let accessibilityLabel: String
    private let action: () -> Void

    public init(
        title: String,
        category: String,
        image: Image?,
        sourceRecordID: String?,
        latestScore: Int? = nil,
        latestScoreColor: Color = NLColor.scoreNeutral,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.category = category
        self.image = image
        self.sourceRecordID = sourceRecordID
        self.latestScore = latestScore
        self.latestScoreColor = latestScoreColor
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                ZStack(alignment: .bottomTrailing) {
                    GameArtwork(image: image, sourceRecordID: sourceRecordID, title: title)
                        .accessibilityHidden(true)

                    if let latestScore {
                        Text("\(latestScore)")
                            .font(NLTypography.captionStrong)
                            .foregroundStyle(latestScoreColor)
                            .frame(minWidth: NLSizing.iconMedium, minHeight: NLSizing.iconMedium)
                            .padding(NLSpacing.xxs)
                            .background(NLColor.backgroundBase, in: Capsule())
                            .overlay { Capsule().stroke(latestScoreColor, lineWidth: NLStroke.hairline) }
                            .padding(NLSpacing.xs)
                            .accessibilityHidden(true)
                    }
                }

                Text(title)
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(category)
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel))
    }
}

/// Atalho compacto para a descoberta. Nome e categoria são suficientes para
/// escolher um jogo; não repetimos uma ilustração genérica em cada opção.
public struct CompactCatalogGameTile: View {
    private let title: String
    private let category: String
    private let isSelected: Bool
    private let accessibilityLabel: String
    private let action: () -> Void
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(title: String, category: String, isSelected: Bool, accessibilityLabel: String, action: @escaping () -> Void) {
        self.title = title
        self.category = category
        self.isSelected = isSelected
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        VStack(spacing: NLSpacing.xs) {
            Button(action: action) {
                Text(title)
                    .font(NLTypography.footnote.weight(.semibold))
                    .foregroundStyle(NLColor.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: NLSizing.compactGameTileWidth, height: NLSizing.compactGameTileMinHeight)
                    .background(
                        isSelected ? NLColor.accentPrimarySubtle : NLColor.backgroundRaised,
                        in: RoundedRectangle(cornerRadius: NLRadius.controlMedium)
                    )
                    .shadow(
                        color: reduceTransparency ? .clear : (isSelected ? NLShadow.selectedCardColor : NLShadow.cardColor),
                        radius: reduceTransparency ? 0 : (isSelected ? NLShadow.selectedCardRadius : NLShadow.cardRadius),
                        y: reduceTransparency || isSelected ? 0 : NLShadow.cardYOffset
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(accessibilityLabel))
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            Text(category)
                .font(NLTypography.caption)
                .foregroundStyle(NLColor.textSecondary)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(width: NLSizing.compactGameTileWidth)
        }
        .frame(width: NLSizing.compactGameTileWidth, alignment: .top)
    }
}

public struct CatalogAvailabilityState: View {
    private let title: LocalizedStringKey
    private let message: LocalizedStringKey
    private let actionTitle: LocalizedStringKey?
    private let action: (() -> Void)?

    public init(
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: NLSpacing.md) {
            Image(systemName: "gamecontroller")
                .font(.system(size: NLSizing.iconMedium, weight: .medium))
                .foregroundStyle(NLColor.textTertiary)
                .accessibilityHidden(true)
            Text(title)
                .font(NLTypography.headline)
                .foregroundStyle(NLColor.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(NLTypography.body)
                .foregroundStyle(NLColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, style: .secondaryOutline, action: action)
            }
        }
        .frame(maxWidth: .infinity, minHeight: NLSizing.emptyStateMinHeight)
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay { RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline) }
        .accessibilityElement(children: .contain)
    }
}

#Preview("Catalog discovery") {
    VStack(alignment: .leading, spacing: NLSpacing.lg) {
        CatalogCategoryChip(label: "Battle Royale", isSelected: true, action: {})
        CatalogGameTile(
            title: "Fortnite",
            category: "Battle Royale",
            image: nil,
            sourceRecordID: nil,
            latestScore: 92,
            latestScoreColor: NLColor.scoreExcellent,
            accessibilityLabel: "Fortnite, Battle Royale, disponível",
            action: {}
        )
        CatalogAvailabilityState(
            title: "catalog.unavailable.title",
            message: "catalog.unavailable.message"
        )
    }
    .padding()
    .background(NLColor.backgroundBase)
    .preferredColorScheme(.dark)
}
