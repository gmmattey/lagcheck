import SwiftUI

/// Tipografia oficial do LagCheck Design System (DESIGN.md / colors_and_type.css).
/// 3 pilhas fundamentais:
/// 1. Display: ui-rounded, compacta e arredondada, para vereditos, nomes de jogo e títulos.
/// 2. Corpo: nativa Apple (-apple-system), para leitura, explicações e controles/CTAs.
/// 3. Técnica: monoespaçada (ui-monospace), para rotas, métricas, tempo e telemetria de rede.
public enum NLTypography {
    // MARK: - Display (ui-rounded, 'Arial Rounded MT Bold', system-ui, sans-serif)

    /// Headline imersiva da Home ("PRONTO PRA JOGAR?") — Arredondada, peso Heavy/Black, tracking negativo
    public static let competitiveHero = Font.system(size: 32, weight: .heavy, design: .rounded)

    /// Manchete massiva de veredito ("● PRONTO PARA RANKED") — Arredondada, peso Heavy
    public static let verdictHeadline = Font.system(size: 28, weight: .heavy, design: .rounded)

    /// Manchete dominante de veredito no Hero (42pt)
    public static let verdictHeroHeadline = Font.system(size: 42, weight: .black, design: .rounded)

    /// Nome do jogo protagonista na Home (38pt)
    public static let heroHomeName = Font.system(size: 38, weight: .heavy, design: .rounded)

    /// Título de telas nomeadas abaixo da barra de ações (31pt)
    public static let screenTitle = Font.system(size: 31, weight: .bold, design: .rounded)

    /// Cópia principal de status da medição ao vivo (25pt)
    public static let statusCopy = Font.system(size: 25, weight: .bold, design: .rounded)

    /// Nome do jogo protagonista em destaque
    public static let heroGameTitle = Font.system(size: 22, weight: .heavy, design: .rounded)

    /// Título display de grandes telas
    public static let displayTitle = Font.system(size: 34, weight: .bold, design: .rounded)

    /// Score numérico principal (0–100)
    public static let scoreDisplay = Font.system(size: 64, weight: .heavy, design: .rounded).monospacedDigit()

    /// Score numérico de alta precisão nos Detalhes Técnicos (45pt)
    public static let monospaceDetailScore = Font.system(size: 45, weight: .bold, design: .monospaced)

    // MARK: - Corpo e Controles (-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif)

    /// Rótulo de botão de ação primária (CTA) — Peso 800 (Heavy) sobre corpo nativo Apple
    public static let ctaButton = Font.system(size: 16, weight: .heavy, design: .default)

    public static let headline = Font.system(size: 22, weight: .bold, design: .rounded)
    public static let subheadline = Font.system(size: 20, weight: .semibold, design: .default)
    public static let bodyEmphasis = Font.system(size: 17, weight: .semibold, design: .default)
    public static let body = Font.body
    public static let callout = Font.callout
    public static let subheadlineSecondary = Font.subheadline
    public static let footnote = Font.footnote
    public static let caption = Font.caption
    public static let captionStrong = Font.system(size: 12, weight: .semibold, design: .default)

    /// Rótulo de cabeçalho de seção ("SEUS JOGOS", "O QUE ENCONTRAMOS")
    public static let sectionHeader = Font.system(size: 13, weight: .heavy, design: .default)

    // MARK: - Técnica e Telemetria (ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas)

    /// Números de telemetria principais em destaque (Monoespaçado)
    public static let metricsNumberLarge = Font.system(size: 32, weight: .heavy, design: .monospaced)
    public static let metricsNumber = Font.system(size: 22, weight: .bold, design: .monospaced)

    /// Identificador compacto de métrica em caixa-alta ("PING", "JITTER", "PERDA") — Tracking positivo
    public static let metricsLabel = Font.system(size: 11, weight: .bold, design: .monospaced)

    /// Subtítulo em monospace (11pt medium)
    public static let monospaceSubtitle = Font.system(size: 11, weight: .medium, design: .monospaced)

    /// Linha de métricas e status (11pt regular)
    public static let monospaceMetrics = Font.system(size: 11, weight: .regular, design: .monospaced)

    /// Rótulo de seção em caixa-alta monoespaçado (11pt regular)
    public static let captionMonoUppercase = Font.system(size: 11, weight: .regular, design: .monospaced)

    /// Linha de status do último check ou telemetria ("Wi-Fi · 18 ms")
    public static let statusLine = Font.system(size: 12, weight: .medium, design: .monospaced)

    /// Rótulo de evidência técnica
    public static let technicalEvidence = Font.system(size: 10, weight: .bold, design: .monospaced)

    // MARK: - Tracking Tokens (DESIGN.md)
    /// Títulos trabalham com tracking negativo
    public static let heroTracking: CGFloat = -0.7
    public static let verdictTracking: CGFloat = -0.75
    public static let displayTracking: CGFloat = -0.5
    public static let ctaTracking: CGFloat = 0.5
    public static let sectionTracking: CGFloat = 0.8
    /// Rótulos técnicos são pequenos, em caixa alta e com tracking positivo
    public static let metricsLabelTracking: CGFloat = 1.2
    public static let technicalEvidenceTracking: CGFloat = 1.0

    // Aliases para legado
    public static let contextDisclosure = Font.caption
    public static let gameCover = Font.system(size: 12, weight: .semibold)
    public static let wordmark = Font.system(size: 20, weight: .heavy, design: .rounded)
    public static let navigationIcon = Font.system(size: 16, weight: .semibold)
    public static let gameCoverTracking: CGFloat = 0.5
    public static let metricsTracking: CGFloat = 1.0
}
