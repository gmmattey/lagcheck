import SwiftUI

public enum NLMotion {
    public static let scoreReveal = Animation.easeOut(duration: 0.45)
    public static let measurementPulse = Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
    public static let buttonPress = Animation.spring(response: 0.45, dampingFraction: 0.82, blendDuration: 0)
    public static let gameSelectionCard = Animation.easeInOut(duration: 0.3)
    public static let gameSelectionCardFade = Animation.easeOut(duration: 0.15)
    public static let gameSelectionFlipDegrees: Double = 82
    public static let gameSelectionFlipPerspective: CGFloat = 0.85
}
