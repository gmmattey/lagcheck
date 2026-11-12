import SwiftUI

/// Motion tokens oficiais do LagCheck Design System (DESIGN.md / colors_and_type.css).
/// Curva cúbica .lc-ease (0.2, 0, 0, 1), escala de pressão 0.98, sheets em 250ms e respeito a prefers-reduced-motion.
public enum NLMotion {
    /// Curva canônica do sistema: cubic-bezier(.2, 0, 0, 1)
    public static let ease = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.25)
    public static let sheetEntry = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.25)
    public static let menuToastEntry = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.18)

    public static let scoreReveal = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.45)
    public static let measurementPulse = Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
    public static let buttonPress = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.2)
    public static let gameSelectionCard = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.3)
    public static let gameSelectionCardFade = Animation.easeOut(duration: 0.15)
    public static let gameSelectionFlipDegrees: Double = 82
    public static let gameSelectionFlipPerspective: CGFloat = 0.85
}
