package com.lagcheck.domain.presentation

import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict
import java.util.Locale

/**
 * Conteúdo do relatório de rota (PDF). Só o que a medição observou: campo sem leitura sai como "—", nunca como valor
 * padrão. O renderizador (Android) só desenha esta estrutura; a regra do que entra mora aqui, testável na JVM.
 */
data class RouteReportDocument(
    val title: String,
    val verdictSymbol: String,
    val verdictHeadline: String,
    val verdictSubtitle: String,
    val summary: List<Pair<String, String>>,
    val telemetryTitle: String,
    val telemetry: List<Pair<String, String>>,
    val findingsTitle: String,
    val findings: List<Pair<String, String?>>,
    val actionsTitle: String,
    val actions: List<Pair<String, String>>,
    val weighedTitle: String,
    val weighed: String,
    val generatedAt: String,
    val footer: String
)

object RouteReport {
    private const val DASH = "—"

    fun build(
        evaluation: GameReadinessEvaluation,
        gameName: String,
        generatedAt: String,
        language: ReadinessLanguage = ReadinessLanguage.PT_BR
    ): RouteReportDocument {
        fun tr(pt: String) = UiStrings.translate(pt, language)
        fun ms(v: Double?) = v?.let { String.format(Locale.ROOT, "%.0f ms", it) } ?: DASH
        fun pct(v: Double?) = v?.let { String.format(Locale.ROOT, "%.1f%%", it) } ?: DASH

        val symbol = when (evaluation.verdict) {
            GameReadinessVerdict.READY -> "●"
            GameReadinessVerdict.CAUTION, GameReadinessVerdict.NOT_READY -> "▲"
            GameReadinessVerdict.INCONCLUSIVE -> "—"
        }
        val summary = buildList {
            add(tr("Jogo") to gameName)
            add(tr("Plataforma") to evaluation.platform)
            add(tr("Conexão") to evaluation.connectionType)
            if (evaluation.regionLabel.isNotBlank()) add(tr("Região") to evaluation.regionLabel)
        }
        return RouteReportDocument(
            title = "LAGCHECK · ${tr("RELATÓRIO DE ROTA")}",
            verdictSymbol = symbol,
            verdictHeadline = evaluation.headline,
            verdictSubtitle = evaluation.subtitle,
            summary = summary,
            telemetryTitle = tr("TELEMETRIA"),
            telemetry = listOf(
                tr("Latência P50") to ms(evaluation.pingMs),
                tr("Oscilação (Jitter)") to ms(evaluation.jitterMs),
                tr("Perda de Pacotes") to pct(evaluation.packetLossPercentage),
                tr("Pior spike") to ms(evaluation.worstSpikeMs)
            ),
            findingsTitle = tr("O QUE ENCONTRAMOS"),
            findings = evaluation.findings.map { it.label to it.detail?.takeIf { d -> d.isNotBlank() } },
            actionsTitle = tr("O QUE FAZER"),
            actions = evaluation.recommendations.map { it.title to it.instruction },
            weighedTitle = tr("O QUE MAIS PESOU"),
            weighed = evaluation.primaryWeight,
            generatedAt = generatedAt,
            footer = tr("Estimativa da rota até a infraestrutura de referência. Não é o ping real do jogo.")
        )
    }
}
