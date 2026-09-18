import SwiftUI

public enum NLColor {
    public static let backgroundBase = Color.black
    public static let backgroundRaised = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    public static let backgroundOverlay = Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255)
    public static let controlOverlay = Color.white.opacity(0.08)
    public static let settingsSurface = backgroundRaised

    public static let borderSubtle = Color(white: 84 / 255).opacity(0.35)
    public static let borderStrong = Color.white.opacity(0.10)
    public static let borderFocus = Color(red: 0, green: 122 / 255, blue: 1)

    public static let textPrimary = Color.white
    public static let textSecondary = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
    public static let textTertiary = Color(red: 99 / 255, green: 99 / 255, blue: 102 / 255)
    public static let textDisabled = Color(red: 72 / 255, green: 72 / 255, blue: 74 / 255)
    public static let textOnAccent = Color.white
    public static let textLink = Color(red: 0, green: 122 / 255, blue: 1)

    public static let accentPrimary = Color(red: 0, green: 122 / 255, blue: 1)
    public static let accentPrimaryStrong = Color(red: 0, green: 113 / 255, blue: 227 / 255)
    public static let accentPrimarySubtle = Color(red: 0, green: 122 / 255, blue: 1).opacity(0.15)

    public static let scoreExcellent = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    public static let scoreExcellentSubtle = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255).opacity(0.16)
    public static let scoreUnstable = Color(red: 255 / 255, green: 214 / 255, blue: 10 / 255)
    public static let scoreUnstableSubtle = Color(red: 255 / 255, green: 214 / 255, blue: 10 / 255).opacity(0.16)
    public static let scoreLagRisk = Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255)
    public static let scoreLagRiskSubtle = Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255).opacity(0.16)
    public static let scoreNeutral = textSecondary
    public static let scoreNeutralSubtle = textSecondary.opacity(0.16)
}
