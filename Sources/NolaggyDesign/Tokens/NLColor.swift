import SwiftUI

public enum NLColor {
    public static let backgroundBase = Color.black
    public static let backgroundRaised = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    public static let backgroundOverlay = Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255)
    public static let controlOverlay = Color.white.opacity(0.08)
    public static let settingsSurface = backgroundRaised

    public static let borderSubtle = Color(white: 84 / 255).opacity(0.35)
    public static let borderStrong = Color.white.opacity(0.10)
    public static let borderFocus = coralSolar

    public static let textPrimary = Color.white
    public static let textSecondary = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
    /// Texto auxiliar com contraste AA sobre as superfícies escuras do app.
    public static let textTertiary = Color(red: 138 / 255, green: 138 / 255, blue: 142 / 255)
    public static let textDisabled = Color(red: 72 / 255, green: 72 / 255, blue: 74 / 255)
    public static let textOnAccent = Color.white
    public static let textLink = coralSolar

    // MARK: - Coral Solar Brand Tokens (Decisão 25)
    public static let coralSolarRed = Color(red: 255 / 255, green: 56 / 255, blue: 35 / 255)       // #FF3823
    public static let coralSolar = Color(red: 255 / 255, green: 107 / 255, blue: 53 / 255)         // #FF6B35
    public static let coralSolarAmber = Color(red: 255 / 255, green: 171 / 255, blue: 46 / 255)   // #FFAB2E
    public static let coralSolarStrong = Color(red: 235 / 255, green: 77 / 255, blue: 38 / 255)   // #EB4D26

    public static let coralSolarGradient = LinearGradient(
        colors: [coralSolarRed, coralSolar, coralSolarAmber],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    public static let coralSolarHorizontalGradient = LinearGradient(
        colors: [coralSolarRed, coralSolar, coralSolarAmber],
        startPoint: .leading,
        endPoint: .trailing
    )

    public static let accentPrimary = coralSolar
    public static let accentPrimaryStrong = coralSolarStrong
    public static let accentPrimarySubtle = coralSolar.opacity(0.15)

    public static let scoreExcellent = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    public static let scoreExcellentSubtle = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255).opacity(0.16)
    public static let scoreUnstable = Color(red: 255 / 255, green: 214 / 255, blue: 10 / 255)
    public static let scoreUnstableSubtle = Color(red: 255 / 255, green: 214 / 255, blue: 10 / 255).opacity(0.16)
    public static let scoreLagRisk = Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255)
    public static let scoreLagRiskSubtle = Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255).opacity(0.16)
    public static let scoreNeutral = textSecondary
    public static let scoreNeutralSubtle = textSecondary.opacity(0.16)
}
