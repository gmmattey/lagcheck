import Foundation
import NolaggyDomain

/// Tom do veredito nos cards e no vídeo de compartilhamento.
/// Resultado inconclusivo não gera card nem vídeo (nunca uma nota inventada).
/// Paridade estrita 1:1 com ShareMediaScene.kt do Android (Decisão 81 e 103).
public enum ShareTone: String, Sendable {
    case ready
    case caution
    case notReady
}

public enum ShareMetricKind: String, Sendable {
    case ping
    case jitter
    case packetLoss
}

public struct ShareMetric: Sendable, Equatable {
    public let kind: ShareMetricKind
    /// Número já formatado ("18", "2,5", "0"); "—" quando não medido.
    public let value: String
    /// "ms" ou "%"; vazio quando não há valor.
    public let unit: String
    /// Valor numérico bruto para a contagem do vídeo; nil quando não medido.
    public let number: Double?

    public init(kind: ShareMetricKind, value: String, unit: String, number: Double?) {
        self.kind = kind
        self.value = value
        self.unit = unit
        self.number = number
    }
}

/// Cena compartilhada pelos cards (1200x630 e 1080x1920) e pelo vídeo (1080x1920, 14 s).
/// Pura: somente números e métricas observadas reais.
public struct ShareMediaScene: Sendable, Equatable {
    public let gameName: String
    /// Nome do asset da arte autoral do jogo (`Game*`); vazio quando não há arte.
    public let artAssetName: String
    public let tone: ShareTone
    /// Veredito no idioma do app (ex.: "PRONTO PARA RANKED").
    public let headline: String
    public let regionName: String
    public let metrics: [ShareMetric]

    public init(
        gameName: String,
        artAssetName: String,
        tone: ShareTone,
        headline: String,
        regionName: String,
        metrics: [ShareMetric]
    ) {
        self.gameName = gameName
        self.artAssetName = artAssetName
        self.tone = tone
        self.headline = headline
        self.regionName = regionName
        self.metrics = metrics
    }

    static func from(
        gameName: String,
        artAssetName: String,
        verdict: GameReadinessVerdict,
        headline: String,
        regionName: String,
        pingMs: Double?,
        jitterMs: Double?,
        lossPercentage: Double?,
        locale: Locale = AppLocalization.locale
    ) -> ShareMediaScene? {
        let tone: ShareTone
        switch verdict {
        case .ready:
            tone = .ready
        case .caution:
            tone = .caution
        case .notReady:
            tone = .notReady
        case .inconclusive:
            return nil
        }
        guard let pingMs, let jitterMs else { return nil }

        return ShareMediaScene(
            gameName: gameName,
            artAssetName: artAssetName,
            tone: tone,
            headline: headline,
            regionName: regionName,
            metrics: [
                metric(kind: .ping, value: pingMs, decimals: 0, unit: "ms", locale: locale),
                metric(kind: .jitter, value: jitterMs, decimals: 1, unit: "ms", locale: locale),
                metric(kind: .packetLoss, value: lossPercentage, decimals: 1, unit: "%", locale: locale)
            ]
        )
    }

    private static func metric(
        kind: ShareMetricKind,
        value: Double?,
        decimals: Int,
        unit: String,
        locale: Locale
    ) -> ShareMetric {
        guard let value else {
            return ShareMetric(kind: kind, value: "—", unit: "", number: nil)
        }
        return ShareMetric(
            kind: kind,
            value: format(value, decimals: decimals, locale: locale),
            unit: unit,
            number: value
        )
    }

    /// Vírgula decimal em pt-BR/es, ponto em en; sem zeros inúteis ("0" em vez de "0,0").
    static func format(_ value: Double, decimals: Int, locale: Locale = AppLocalization.locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }
}
