import SwiftUI

/// Tipografia oficial do LagCheck — Dark Competitive UI (Decisão 51).
/// Pesada, direta, com identificadores de métricas em caixa alta compacta e números monoespaçados.
public enum NLTypography {
    // MARK: - Dark Competitive Typography (Decisão 51)
    /// Headline imersiva da Home ("PRONTO PRA JOGAR?")
    public static let competitiveHero = Font.system(size: 28, weight: .black, design: .default)
    /// Manchete massiva de veredito ("● PRONTO PARA RANKED")
    public static let verdictHeadline = Font.system(size: 26, weight: .heavy, design: .default)
    /// Nome do jogo protagonista em destaque
    public static let heroGameTitle = Font.system(size: 22, weight: .bold, design: .default)
    /// Números de métricas em destaque (.monospacedDigit)
    public static let metricsNumberLarge = Font.system(size: 28, weight: .heavy, design: .default)
    public static let metricsNumber = Font.system(size: 20, weight: .bold, design: .default)
    /// Identificador compacto de métrica em caixa alta ("PING", "JITTER", "PERDA")
    public static let metricsLabel = Font.system(size: 11, weight: .bold, design: .default)
    /// Rótulo de seção ("SEUS JOGOS", "O QUE ENCONTRAMOS")
    public static let sectionHeader = Font.system(size: 12, weight: .bold, design: .default)

    // MARK: - Legacy / Standard Tokens
    public static let scoreDisplay = Font.system(size: 64, weight: .bold, design: .default)
    public static let displayTitle = Font.system(size: 34, weight: .bold)
    public static let headline = Font.system(size: 22, weight: .bold)
    public static let subheadline = Font.system(size: 20, weight: .semibold)
    public static let bodyEmphasis = Font.system(size: 17, weight: .semibold)
    public static let body = Font.body
    public static let callout = Font.callout
    public static let contextDisclosure = Font.caption
    public static let subheadlineSecondary = Font.subheadline
    public static let footnote = Font.footnote
    public static let caption = Font.caption
    public static let captionStrong = Font.system(size: 12, weight: .semibold)
    public static let gameCover = Font.system(size: 12, weight: .semibold)
    public static let wordmark = Font.system(size: 20, weight: .heavy, design: .default)
    public static let navigationIcon = Font.system(size: 16, weight: .semibold)
    public static let gameCoverTracking: CGFloat = 0.5
    public static let metricsTracking: CGFloat = 1.0
    public static let heroTracking: CGFloat = -0.5
}
