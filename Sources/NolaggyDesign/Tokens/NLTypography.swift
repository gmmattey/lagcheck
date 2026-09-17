import SwiftUI

public enum NLTypography {
    public static let scoreDisplay = oxanium(64, weight: .bold, relativeTo: .largeTitle)
    public static let displayTitle = oxanium(34, weight: .semibold, relativeTo: .largeTitle)
    public static let headline = oxanium(22, weight: .bold, relativeTo: .title2)
    public static let subheadline = oxanium(20, weight: .semibold, relativeTo: .title3)
    public static let bodyEmphasis = oxanium(17, weight: .medium, relativeTo: .headline)
    public static let body = Font.body
    public static let callout = Font.callout
    public static let contextDisclosure = Font.caption
    public static let subheadlineSecondary = Font.subheadline
    public static let footnote = Font.footnote
    public static let caption = Font.caption
    public static let captionStrong = oxanium(12, weight: .semibold, relativeTo: .caption2)
    public static let gameCover = oxanium(12, weight: .semibold, relativeTo: .caption)
    public static let wordmark = Font.title3.weight(.bold)
    public static let navigationIcon = Font.system(size: 16, weight: .semibold)
    public static let gameCoverTracking: CGFloat = 1.4

    private static func oxanium(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle) -> Font {
        .custom("OxaniumRoman-Regular", size: size, relativeTo: style).weight(weight)
    }
}
