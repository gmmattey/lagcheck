import Foundation

/// Dimensões semânticas oficiais do LagCheck Design System (DESIGN.md).
/// Controles usam no mínimo 44 px e CTA principal 56–62 px (58 px padrão).
public enum NLSizing {
    /// Alvo mínimo de toque (44px)
    public static let touchTarget: CGFloat = 44
    /// Altura padrão do botão primário CTA (58px, faixa 56–62px do DESIGN.md)
    public static let primaryButtonHeight: CGFloat = 58
    public static let primaryButtonMinWidth: CGFloat = 200

    public static let iconSmall: CGFloat = 20
    public static let iconMedium: CGFloat = 24
    public static let contextGameCoverHeight: CGFloat = 120
    public static let navigationControlSide: CGFloat = touchTarget
    public static let metricRowHeight: CGFloat = 56
    public static let insightBannerMinHeight: CGFloat = 64
    public static let insightBannerIconSize: CGFloat = 24
    public static let statusMessageMinHeight: CGFloat = 48
    public static let measurementPulseDiameter: CGFloat = 220
    public static let measurementPulseStrokeWidth: CGFloat = 6
    public static let detailsGraphHeight: CGFloat = 100
    public static let historyCardMinHeight: CGFloat = 96
    public static let emptyStateMinHeight: CGFloat = 180
    public static let failureStateIconSide: CGFloat = 64
    public static let compactGameArtworkSide: CGFloat = 72
    public static let compactGameTileWidth: CGFloat = 104
    public static let compactGameTileMinHeight: CGFloat = 72
    public static let gameDetailHeroHeight: CGFloat = 300

    public enum NolaggyScoreRing {
        public static let compact: CGFloat = 96
        public static let standard: CGFloat = 160
        public static let hero: CGFloat = 216
        public static let compactStroke: CGFloat = 8
        public static let standardStroke: CGFloat = 12
        public static let heroStroke: CGFloat = 14
    }
}
