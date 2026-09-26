import SwiftUI

/// Tipografia oficial do LagCheck — Dark Competitive UI & Performance Benchmark NoPing (Decisões 51, 52 e 53).
/// Arquitetura tipográfica híbrida:
/// 1. Títulos, Vereditos, CTAs e Rótulos Técnicos: Display Heavy / Black, caixa-alta e tracking calibrado.
/// 2. Métricas e Valores: Monoespaçado (.monospacedDigit) para precisão instrumental.
/// 3. Explicações e Diagnóstico: SF Pro Text nativo do iOS para conforto de leitura e acessibilidade.
public enum NLTypography {
    // MARK: - Dark Competitive Typography (Decisões 51, 52 e 53 — NoPing Benchmark)

    /// Headline imersiva da Home ("PRONTO PRA JOGAR?") — Caixa-alta, peso Black, tracking compacto
    public static let competitiveHero = Font.system(size: 32, weight: .black, design: .default)

    /// Manchete massiva de veredito ("● PRONTO PARA RANKED") — Caixa-alta, peso Heavy
    public static let verdictHeadline = Font.system(size: 28, weight: .heavy, design: .default)

    /// Nome do jogo protagonista em destaque
    public static let heroGameTitle = Font.system(size: 22, weight: .heavy, design: .default)

    /// Rótulo de botão de ação primária ("FAZER CHECK", "TESTAR NOVAMENTE")
    public static let ctaButton = Font.system(size: 16, weight: .heavy, design: .default)

    /// Números de telemetria principais em destaque (.monospacedDigit)
    public static let metricsNumberLarge = Font.system(size: 32, weight: .heavy, design: .default).monospacedDigit()
    public static let metricsNumber = Font.system(size: 22, weight: .bold, design: .default).monospacedDigit()

    /// Identificador compacto de métrica em caixa-alta ("PING", "JITTER", "PERDA") — Tracking largo
    public static let metricsLabel = Font.system(size: 11, weight: .bold, design: .default)

    /// Rótulo de cabeçalho de seção ("SEUS JOGOS", "O QUE ENCONTRAMOS")
    public static let sectionHeader = Font.system(size: 13, weight: .heavy, design: .default)

    /// Linha de status do último check ("● Estável · 28 ms · hoje 18:42")
    public static let statusLine = Font.system(size: 13, weight: .medium, design: .default)

    // MARK: - Tracking Tokens (Espaçamento de Caracteres)
    public static let heroTracking: CGFloat = -0.8
    public static let verdictTracking: CGFloat = -0.5
    public static let metricsLabelTracking: CGFloat = 1.5
    public static let ctaTracking: CGFloat = 0.8
    public static let sectionTracking: CGFloat = 1.0

    // MARK: - Standard & Accessible Tokens
    public static let scoreDisplay = Font.system(size: 64, weight: .heavy, design: .default).monospacedDigit()
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
}
