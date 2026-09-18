import SwiftUI

public struct BoosterItemRow: View {
    public let iconName: String
    public let title: String
    public let detail: String
    
    public init(iconName: String, title: String, detail: String) {
        self.iconName = iconName
        self.title = title
        self.detail = detail
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: NLSpacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(NLColor.accentPrimary)
                .frame(width: 36, height: 36)
                .background(NLColor.accentPrimarySubtle, in: RoundedRectangle(cornerRadius: NLRadius.controlSmall))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                Text(title)
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)
                
                Text(detail)
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: NLRadius.card)
                .stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline)
        }
    }
}

public struct BoosterSkeletonView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: NLSpacing.sm) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: NLSpacing.sm) {
                    RoundedRectangle(cornerRadius: NLRadius.controlSmall)
                        .fill(NLColor.backgroundRaised)
                        .frame(width: 36, height: 36)
                    
                    VStack(alignment: .leading, spacing: NLSpacing.xs) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(NLColor.backgroundRaised)
                            .frame(height: 16)
                            .frame(maxWidth: .infinity)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(NLColor.backgroundRaised)
                            .frame(height: 12)
                            .frame(maxWidth: 180)
                    }
                }
                .padding(NLSpacing.cardPadding)
                .background(NLColor.backgroundRaised.opacity(0.5), in: RoundedRectangle(cornerRadius: NLRadius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: NLRadius.card)
                        .stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline)
                }
            }
        }
        .opacity(0.6)
        .accessibilityLabel(Text("booster.loading.accessibility"))
    }
}
