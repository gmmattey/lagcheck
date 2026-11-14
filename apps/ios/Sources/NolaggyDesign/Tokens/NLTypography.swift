import CoreText
import SwiftUI

private final class BundleToken {}

private enum FontRegistrar {
    private static let _registered: Void = {
        let bundle = Bundle(for: BundleToken.self)
        let fontNames = [
            "barlow_regular",
            "barlow_medium",
            "barlow_semibold",
            "barlow_semicondensed_bold",
            "barlow_semicondensed_extrabold",
            "chakra_petch_semibold"
        ]
        for name in fontNames {
            if let url = bundle.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                ?? bundle.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }()

    static func ensureRegistered() {
        _ = _registered
    }
}

/// Tipografia oficial do LagCheck Design System (Decisão 125 / DESIGN.md).
/// 3 famílias oficiais:
/// 1. Display (`BarlowSemiCondensed`): títulos, vereditos e nomes de jogo em destaque.
/// 2. Corpo (`Barlow`): leitura, navegação, explicações e controles/CTAs.
/// 3. Telemetria (`ChakraPetch`): score, métricas, tempo e rótulos técnicos.
public enum NLTypography {
    private static func custom(_ name: String, size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        FontRegistrar.ensureRegistered()
        return Font.custom(name, size: size, relativeTo: textStyle)
    }

    // MARK: - Display (Barlow Semi Condensed)

    /// Headline imersiva da Home ("PRONTO PRA JOGAR?")
    public static var competitiveHero: Font {
        custom("BarlowSemiCondensed-ExtraBold", size: 32, relativeTo: .title)
    }

    /// Manchete massiva de veredito ("● PRONTO PARA RANKED")
    public static var verdictHeadline: Font {
        custom("BarlowSemiCondensed-ExtraBold", size: 28, relativeTo: .title)
    }

    /// Manchete dominante de veredito no Hero (42pt)
    public static var verdictHeroHeadline: Font {
        custom("BarlowSemiCondensed-ExtraBold", size: 42, relativeTo: .largeTitle)
    }

    /// Nome do jogo protagonista na Home (38pt)
    public static var heroHomeName: Font {
        custom("BarlowSemiCondensed-ExtraBold", size: 38, relativeTo: .largeTitle)
    }

    /// Título de telas nomeadas abaixo da barra de ações (31pt)
    public static var screenTitle: Font {
        custom("BarlowSemiCondensed-Bold", size: 31, relativeTo: .largeTitle)
    }

    /// Cópia principal de status da medição ao vivo (25pt)
    public static var statusCopy: Font {
        custom("BarlowSemiCondensed-Bold", size: 25, relativeTo: .title2)
    }

    /// Nome do jogo protagonista em destaque
    public static var heroGameTitle: Font {
        custom("BarlowSemiCondensed-ExtraBold", size: 22, relativeTo: .title2)
    }

    /// Título display de grandes telas
    public static var displayTitle: Font {
        custom("BarlowSemiCondensed-Bold", size: 34, relativeTo: .largeTitle)
    }

    /// Score numérico principal (0–100)
    public static var scoreDisplay: Font {
        custom("ChakraPetch-SemiBold", size: 64, relativeTo: .largeTitle).monospacedDigit()
    }

    /// Score numérico de alta precisão nos Detalhes Técnicos (45pt)
    public static var monospaceDetailScore: Font {
        custom("ChakraPetch-SemiBold", size: 45, relativeTo: .largeTitle).monospacedDigit()
    }

    // MARK: - Corpo e Controles (Barlow)

    /// Rótulo de botão de ação primária (CTA)
    public static var ctaButton: Font {
        custom("Barlow-SemiBold", size: 16, relativeTo: .headline)
    }

    public static var headline: Font {
        custom("BarlowSemiCondensed-Bold", size: 22, relativeTo: .headline)
    }

    public static var subheadline: Font {
        custom("Barlow-SemiBold", size: 20, relativeTo: .title3)
    }

    public static var bodyEmphasis: Font {
        custom("Barlow-SemiBold", size: 17, relativeTo: .body)
    }

    public static var body: Font {
        custom("Barlow-Regular", size: 17, relativeTo: .body)
    }

    public static var callout: Font {
        custom("Barlow-Regular", size: 16, relativeTo: .callout)
    }

    public static var subheadlineSecondary: Font {
        custom("Barlow-Regular", size: 15, relativeTo: .subheadline)
    }

    public static var footnote: Font {
        custom("Barlow-Regular", size: 13, relativeTo: .footnote)
    }

    public static var caption: Font {
        custom("Barlow-Regular", size: 12, relativeTo: .caption)
    }

    public static var captionStrong: Font {
        custom("Barlow-SemiBold", size: 12, relativeTo: .caption)
    }

    /// Rótulo de cabeçalho de seção ("SEUS JOGOS", "O QUE ENCONTRAMOS")
    public static var sectionHeader: Font {
        custom("ChakraPetch-SemiBold", size: 13, relativeTo: .caption)
    }

    // MARK: - Técnica e Telemetria (Chakra Petch)

    /// Números de telemetria principais em destaque
    public static var metricsNumberLarge: Font {
        custom("ChakraPetch-SemiBold", size: 32, relativeTo: .title).monospacedDigit()
    }

    public static var metricsNumber: Font {
        custom("ChakraPetch-SemiBold", size: 22, relativeTo: .title2).monospacedDigit()
    }

    /// Identificador compacto de métrica em caixa-alta ("PING", "JITTER", "PERDA") — Tracking positivo
    public static var metricsLabel: Font {
        custom("ChakraPetch-SemiBold", size: 11, relativeTo: .caption2)
    }

    /// Subtítulo técnico (11pt)
    public static var monospaceSubtitle: Font {
        custom("ChakraPetch-SemiBold", size: 11, relativeTo: .caption2).monospacedDigit()
    }

    /// Linha de métricas e status (11pt)
    public static var monospaceMetrics: Font {
        custom("ChakraPetch-SemiBold", size: 11, relativeTo: .caption2).monospacedDigit()
    }

    /// Rótulo de seção em caixa-alta (11pt)
    public static var captionMonoUppercase: Font {
        custom("ChakraPetch-SemiBold", size: 11, relativeTo: .caption2)
    }

    /// Linha de status do último check ou telemetria ("Wi-Fi · 18 ms")
    public static var statusLine: Font {
        custom("ChakraPetch-SemiBold", size: 12, relativeTo: .caption).monospacedDigit()
    }

    /// Rótulo de evidência técnica
    public static var technicalEvidence: Font {
        custom("ChakraPetch-SemiBold", size: 10, relativeTo: .caption2)
    }

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
    public static var contextDisclosure: Font { caption }
    public static var gameCover: Font { custom("Barlow-SemiBold", size: 12, relativeTo: .caption) }
    public static var wordmark: Font { custom("BarlowSemiCondensed-ExtraBold", size: 20, relativeTo: .title3) }
    public static var navigationIcon: Font { custom("Barlow-SemiBold", size: 16, relativeTo: .body) }
    public static let gameCoverTracking: CGFloat = 0.5
    public static let metricsTracking: CGFloat = 1.0
}
