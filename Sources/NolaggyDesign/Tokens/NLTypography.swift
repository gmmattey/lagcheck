import SwiftUI

public enum NLTypography {
    public static let scoreDisplay = Font.system(size: 64, weight: .bold, design: .default)
    public static let displayTitle = Font.system(size: 34, weight: .bold)
    public static let headline = Font.system(size: 22, weight: .bold)
    public static let subheadline = Font.system(size: 20, weight: .semibold)
    public static let bodyEmphasis = Font.system(size: 17, weight: .semibold)
    public static let body = Font.body
    public static let callout = Font.callout
    public static let contextDisclosure = Font.caption
    public static let subheadlineSecondary = Font.subheadline
    public static let footnote = Font.footnote
    public static let caption = Font.caption
    public static let captionStrong = Font.system(size: 12, weight: .semibold)
    public static let gameCover = Font.system(size: 12, weight: .semibold)
    public static let wordmark = Font.system(size: 20, weight: .bold)
    public static let navigationIcon = Font.system(size: 16, weight: .semibold)
    public static let gameCoverTracking: CGFloat = 0.5
}
