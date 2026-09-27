import SwiftUI

/// Elevação semântica oficial do LagCheck Design System (DESIGN.md / colors_and_type.css).
/// Elevação só aparece em menu, toast, CTA e sheet.
public enum NLShadow {
    /// Sombra de ação do Roxo Gamer para o botão primário (0 12px 28px oklch(.35 .11 299 / .26))
    public static let actionColor = Color(red: 124 / 255, green: 58 / 255, blue: 237 / 255).opacity(0.26)
    public static let actionRadius: CGFloat = 14
    public static let actionYOffset: CGFloat = 12

    /// Sombra flutuante para menus, toasts e bottom sheet (0 16px 34px oklch(0 0 0 / .42))
    public static let floatColor = Color.black.opacity(0.42)
    public static let floatRadius: CGFloat = 17
    public static let floatYOffset: CGFloat = 16

    // Aliases para legado
    public static let cardColor = Color.black.opacity(0.20)
    public static let cardRadius: CGFloat = 4
    public static let cardYOffset: CGFloat = 1

    public static let prominentCardColor = floatColor
    public static let prominentCardRadius: CGFloat = floatRadius
    public static let prominentCardYOffset: CGFloat = floatYOffset

    public static let selectedCardColor = actionColor
    public static let selectedCardRadius: CGFloat = 8
}
