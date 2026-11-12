import Foundation

/// Escala de espaçamento oficial do LagCheck Design System (DESIGN.md / colors_and_type.css).
/// Base de 4 px. Conteúdo de tela usa 22 px nas laterais, controles usam no mínimo 44 px e CTA principal 56–62 px.
public enum NLSpacing {
    // MARK: - Base 4px Tokens (DESIGN.md)
    public static let space1: CGFloat = 4
    public static let space2: CGFloat = 8
    public static let space3: CGFloat = 12
    public static let space4: CGFloat = 16
    public static let space5: CGFloat = 20
    public static let space6: CGFloat = 24
    public static let space7: CGFloat = 28
    public static let space8: CGFloat = 32

    // MARK: - Semantic Spacing Tokens
    /// Margem lateral padrão do conteúdo de tela (22px per DESIGN.md)
    public static let screenMarginHorizontal: CGFloat = 22
    public static let screenMarginHorizontalCompact: CGFloat = 16
    public static let cardPadding: CGFloat = 16
    public static let stackGapTight: CGFloat = 4
    public static let stackGapDefault: CGFloat = 8
    public static let resultConclusionToMetrics: CGFloat = 32
    public static let primaryButtonIconGap: CGFloat = 8

    // Aliases para legado
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 40
    public static let huge: CGFloat = 72
}
