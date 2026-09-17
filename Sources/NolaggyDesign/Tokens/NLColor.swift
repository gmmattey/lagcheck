import SwiftUI

public enum NLColor {
    public static let backgroundBase = Color(red: 5 / 255, green: 11 / 255, blue: 24 / 255)
    public static let backgroundRaised = Color(red: 10 / 255, green: 23 / 255, blue: 48 / 255)
    public static let backgroundOverlay = Color(red: 16 / 255, green: 30 / 255, blue: 61 / 255)
    public static let controlOverlay = Color.white.opacity(0.06)
    public static let settingsSurface = backgroundRaised.opacity(0.82)

    public static let borderSubtle = Color.clear
    public static let borderStrong = Color(red: 42 / 255, green: 60 / 255, blue: 99 / 255)
    public static let borderFocus = Color(red: 79 / 255, green: 160 / 255, blue: 1)

    public static let textPrimary = Color(red: 245 / 255, green: 248 / 255, blue: 1)
    public static let textSecondary = Color(red: 170 / 255, green: 180 / 255, blue: 204 / 255)
    public static let textTertiary = Color(red: 107 / 255, green: 118 / 255, blue: 144 / 255)
    public static let textDisabled = Color(red: 74 / 255, green: 84 / 255, blue: 112 / 255)
    public static let textOnAccent = Color.white
    public static let textLink = Color(red: 127 / 255, green: 216 / 255, blue: 1)

    public static let accentPrimary = Color(red: 46 / 255, green: 124 / 255, blue: 1)
    public static let accentPrimaryStrong = Color(red: 26 / 255, green: 92 / 255, blue: 1)
    public static let accentPrimarySubtle = Color(red: 46 / 255, green: 124 / 255, blue: 1).opacity(0.16)

    public static let scoreExcellent = Color(red: 61 / 255, green: 220 / 255, blue: 151 / 255)
    public static let scoreExcellentSubtle = Color(red: 61 / 255, green: 220 / 255, blue: 151 / 255).opacity(0.16)
    public static let scoreUnstable = Color(red: 245 / 255, green: 185 / 255, blue: 66 / 255)
    public static let scoreUnstableSubtle = Color(red: 245 / 255, green: 185 / 255, blue: 66 / 255).opacity(0.16)
    public static let scoreLagRisk = Color(red: 240 / 255, green: 82 / 255, blue: 91 / 255)
    public static let scoreLagRiskSubtle = Color(red: 240 / 255, green: 82 / 255, blue: 91 / 255).opacity(0.16)
    public static let scoreNeutral = textTertiary
    public static let scoreNeutralSubtle = textTertiary.opacity(0.16)
}
