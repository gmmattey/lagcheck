import Foundation

/// Raios de canto oficiais do LagCheck Design System (DESIGN.md / global.css / Decisão 126).
/// 8 px para mídia e métricas, 12 px para campos/cartões e CTA, 26 px para bottom sheet e pill (999 px) para estado conciso.
public enum NLRadius {
    /// Mídia, capas de jogos e cartões de métrica (8px)
    public static let sm: CGFloat = 8
    /// Campos, cartões compactos e containers de evidência (12px)
    public static let md: CGFloat = 12
    /// Botões de ação primária (CTA) (12px)
    public static let lg: CGFloat = 12
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
