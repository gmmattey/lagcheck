import SwiftUI

public struct RegionalReferenceCandidate: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let continentKey: String?

    public init(id: String, label: String, continentKey: String? = nil) {
        self.id = id
        self.label = label
        self.continentKey = continentKey
    }
}

public struct RegionalReferenceCard: View {
    public enum Mode: Sendable { case suggested, manual }

    private let regionLabel: String
    private let mode: Mode
    private let allowsManualSelection: Bool
    private let accessibilityIdentifier: String?
    private let onChangeRegion: (() -> Void)?

    public init(
        regionLabel: String,
        mode: Mode,
        allowsManualSelection: Bool,
        accessibilityIdentifier: String? = nil,
        onChangeRegion: (() -> Void)? = nil
    ) {
        self.regionLabel = regionLabel
        self.mode = mode
        self.allowsManualSelection = allowsManualSelection
        self.accessibilityIdentifier = accessibilityIdentifier
        self.onChangeRegion = onChangeRegion
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                Label {
                    Text(titleKey)
                        .font(NLTypography.bodyEmphasis)
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(NLColor.textSecondary)
                        .accessibilityHidden(true)
                }
                .foregroundStyle(NLColor.textPrimary)

                Text(regionLabel)
                    .font(NLTypography.subheadline)
                    .foregroundStyle(NLColor.textPrimary)

                Text(messageKey)
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("regional_selection.reference_limit")
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                Text(titleKey) + Text(": ") + Text(regionLabel) + Text(". ") + Text(messageKey) + Text(". ") + Text("regional_selection.reference_limit")
            )
            .regionalAccessibilityIdentifier(accessibilityIdentifier)

            if allowsManualSelection, let onChangeRegion {
                Button(action: onChangeRegion) {
                    Text("regional_selection.change")
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textLink)
                        .frame(minHeight: NLSizing.touchTarget)
                }
                .accessibilityHint(Text("regional_selection.change.hint"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: NLRadius.card)
                .stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline)
        }
    }

    private var titleKey: LocalizedStringKey {
        mode == .suggested ? "regional_selection.suggested.title" : "regional_selection.manual.title"
    }

    private var messageKey: LocalizedStringKey {
        mode == .suggested ? "regional_selection.suggested.message" : "regional_selection.manual.message"
    }
}

private extension View {
    @ViewBuilder
    func regionalAccessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}

public struct RegionalReferencePicker: View {
    private let candidates: [RegionalReferenceCandidate]
    private let selectedID: String?
    private let onSelect: (RegionalReferenceCandidate) -> Void

    public init(
        candidates: [RegionalReferenceCandidate],
        selectedID: String?,
        onSelect: @escaping (RegionalReferenceCandidate) -> Void
    ) {
        self.candidates = candidates
        self.selectedID = selectedID
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.md) {
            Text("regional_selection.picker.scope")
                .font(NLTypography.footnote)
                .foregroundStyle(NLColor.textSecondary)

            ForEach(candidates) { candidate in
                Button { onSelect(candidate) } label: {
                    HStack(spacing: NLSpacing.sm) {
                        Image(systemName: candidate.id == selectedID ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(candidate.id == selectedID ? NLColor.accentPrimary : NLColor.textTertiary)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                            Text(candidate.label)
                                .font(NLTypography.bodyEmphasis)
                                .foregroundStyle(NLColor.textPrimary)
                            Text("regional_selection.route")
                                .font(NLTypography.footnote)
                                .foregroundStyle(NLColor.textSecondary)
                        }
                        Spacer(minLength: NLSpacing.sm)
                    }
                    .frame(maxWidth: .infinity, minHeight: NLSizing.touchTarget, alignment: .leading)
                    .padding(NLSpacing.cardPadding)
                    .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
                    .overlay {
                        RoundedRectangle(cornerRadius: NLRadius.card)
                            .stroke(candidate.id == selectedID ? NLColor.borderFocus : NLColor.borderSubtle, lineWidth: NLStroke.hairline)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(candidate.label) + Text(", ") + Text("regional_selection.route"))
                .accessibilityAddTraits(candidate.id == selectedID ? .isSelected : [])
            }
        }
    }
}

public struct RegionalReferenceConfirming: View {
    public init() {}

    public var body: some View {
        HStack(spacing: NLSpacing.sm) {
            ProgressView().tint(NLColor.accentPrimary)
                .accessibilityHidden(true)
            Text("regional_selection.confirming")
                .font(NLTypography.body)
                .foregroundStyle(NLColor.textPrimary)
        }
        .frame(maxWidth: .infinity, minHeight: NLSizing.statusMessageMinHeight, alignment: .leading)
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay { RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline) }
        .accessibilityElement(children: .combine)
    }
}
