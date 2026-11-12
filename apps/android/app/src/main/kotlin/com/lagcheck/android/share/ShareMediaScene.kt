package com.lagcheck.android.share

import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict
import java.text.NumberFormat
import java.util.Locale

/**
 * Tom do veredito nos cards e no vídeo de compartilhamento. Resultado inconclusivo não gera card nem vídeo
 * (nunca uma nota inventada). Paridade com `ShareMediaScene.swift` do iOS (Decisão 80).
 */
enum class ShareTone { READY, CAUTION, NOT_READY }

enum class ShareMetricKind { PING, JITTER, PACKET_LOSS }

data class ShareMetric(
    val kind: ShareMetricKind,
    /** Número já formatado ("18", "2,5", "0"); "—" quando não medido. */
    val value: String,
    /** "ms" ou "%"; vazio quando não há valor. */
    val unit: String,
    /** Valor para a contagem do vídeo; `null` quando não medido. */
    val number: Double?
)

/** Cena compartilhada pelos cards (1200x630 e 1080x1920) e pelo vídeo (1080x1920, 14 s). Pura: só números reais. */
data class ShareMediaScene(
    val gameName: String,
    /** Nome do drawable da arte autoral do jogo (`game_*`); vazio quando não há arte. */
    val artDrawableName: String,
    val tone: ShareTone,
    /** Veredito no idioma do app (ex.: "PRONTO PARA RANKED"). */
    val headline: String,
    val regionName: String,
    val metrics: List<ShareMetric>
) {
    companion object {
        fun from(
            gameName: String,
            artDrawableName: String,
            evaluation: GameReadinessEvaluation,
            locale: Locale = Locale.getDefault()
        ): ShareMediaScene? = from(
            gameName, artDrawableName, evaluation.verdict, evaluation.headline, evaluation.regionLabel,
            evaluation.pingMs, evaluation.jitterMs, evaluation.packetLossPercentage, locale
        )

        fun from(
            gameName: String,
            artDrawableName: String,
            verdict: GameReadinessVerdict,
            headline: String,
            regionName: String,
            pingMs: Double?,
            jitterMs: Double?,
            lossPercentage: Double?,
            locale: Locale = Locale.getDefault()
        ): ShareMediaScene? {
            val tone = when (verdict) {
                GameReadinessVerdict.READY -> ShareTone.READY
                GameReadinessVerdict.CAUTION -> ShareTone.CAUTION
                GameReadinessVerdict.NOT_READY -> ShareTone.NOT_READY
                GameReadinessVerdict.INCONCLUSIVE -> return null
            }
            if (pingMs == null || jitterMs == null) return null
            return ShareMediaScene(
                gameName = gameName,
                artDrawableName = artDrawableName,
                tone = tone,
                headline = headline,
                regionName = regionName,
                metrics = listOf(
                    metric(ShareMetricKind.PING, pingMs, 0, "ms", locale),
                    metric(ShareMetricKind.JITTER, jitterMs, 1, "ms", locale),
                    metric(ShareMetricKind.PACKET_LOSS, lossPercentage, 1, "%", locale)
                )
            )
        }

        private fun metric(kind: ShareMetricKind, value: Double?, decimals: Int, unit: String, locale: Locale): ShareMetric {
            if (value == null) return ShareMetric(kind, "—", "", null)
            return ShareMetric(kind, format(value, decimals, locale), unit, value)
        }

        /** Vírgula decimal em pt-BR/es, ponto em en; sem zeros inúteis ("0" em vez de "0,0"). */
        fun format(value: Double, decimals: Int, locale: Locale): String {
            val f = NumberFormat.getNumberInstance(locale)
            f.minimumFractionDigits = 0
            f.maximumFractionDigits = decimals
            return f.format(value)
        }
    }
}

/** Linha do tempo do vídeo (s): escolha 0–3,5, medição 3,5–9,5, resultado 9,5–14. */
object ShareVideoTimeline {
    const val WIDTH = 1080
    const val HEIGHT = 1920
    const val FPS = 30
    const val DURATION = 14.0
    const val MEASURE_START = 3.5
    const val RESULT_START = 9.5
    val frameCount: Int get() = (DURATION * FPS).toInt()
}
