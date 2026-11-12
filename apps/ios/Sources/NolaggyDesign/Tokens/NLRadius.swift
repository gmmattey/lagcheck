import Foundation

/// Raios de canto oficiais do LagCheck Design System (DESIGN.md / colors_and_type.css).
/// 8 px para mídia e métricas, 13 px para campos/cartões compactos, 17 px para CTA, 26 px para bottom sheet e pill (999 px) para estado conciso.
public enum NLRadius {
    /// Mídia, capas de jogos e cartões de métrica (8px)
    public static let sm: CGFloat = 8
    /// Campos, cartões compactos e containers de evidência (13px)
    public static let md: CGFloat = 13
    /// Botões de ação primária (CTA) (17px)
    public static let lg: CGFloat = 17
    /// Bottom sheet modal e hero cards amplos (26px)
    public static let xl: CGFloat = 26
    /// Chips de telemetria ao vivo e pílulas de status conciso (999px)
    public static let pill: CGFloat = 999

    // Aliases para legado e compatibilidade
    public static let controlSmall: CGFloat = sm
    public static let controlMedium: CGFloat = md
    public static let card: CGFloat = md
    public static let cardLarge: CGFloat = xl
    public static let button: CGFloat = lg
    public static let sheet: CGFloat = xl
    public static let hero: CGFloat = xl
}
