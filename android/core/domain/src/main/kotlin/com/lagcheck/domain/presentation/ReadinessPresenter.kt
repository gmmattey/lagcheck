package com.lagcheck.domain.presentation

import com.lagcheck.domain.model.GameReadinessAssessment
import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.MeasurementConfidence
import com.lagcheck.domain.model.NetworkFinding
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.domain.rules.PrimaryCause

enum class ReadinessLanguage { PT_BR, EN, ES }

/**
 * Converte a avaliação sem copy do domínio no modelo que a UI consome, localizando as chaves.
 * Telemetria de rádio entra como fato observado (banda, sinal), nunca como causa (Decisão 50).
 */
object ReadinessPresenter {

    fun present(
        assessment: GameReadinessAssessment,
        language: ReadinessLanguage = ReadinessLanguage.PT_BR,
        platform: String,
        connectionType: String,
        destinationName: String,
        confidence: MeasurementConfidence = MeasurementConfidence.HIGH,
        latencySeries: List<Double> = emptyList(),
        radio: RadioTelemetrySnapshot? = null,
        timestamp: Long = System.currentTimeMillis()
    ): GameReadinessEvaluation {
        val table = table(language)
        fun t(key: String) = table[key] ?: key

        val findings = assessment.findings.map {
            NetworkFinding(it.kind, it.severity, t(it.labelKey), it.detail)
        } + radioFindings(radio, language)

        return GameReadinessEvaluation(
            verdict = assessment.verdict,
            headline = t(assessment.headlineKey),
            subtitle = t(assessment.subtitleKey),
            score = assessment.score ?: 0,
            primaryWeight = primaryWeight(assessment, language),
            suitableUses = suitableUses(assessment.verdict, language),
            pingMs = assessment.pingMs,
            jitterMs = assessment.jitterMs,
            packetLossPercentage = assessment.packetLossPercentage,
            worstSpikeMs = assessment.worstSpikeMs,
            isUnderLoadAffected = assessment.isUnderLoadAffected,
            findings = findings,
            latencySeries = latencySeries,
            platform = platform,
            connectionType = connectionType,
            destinationName = destinationName,
            confidence = when (confidence) {
                MeasurementConfidence.HIGH -> "alta"
                MeasurementConfidence.MEDIUM -> "boa"
            },
            timestamp = timestamp,
            radioTelemetry = radio,
            recommendations = assessment.recommendations.map { RecommendationCopy.localize(it.key, language) }
        )
    }

    private fun table(language: ReadinessLanguage) = when (language) {
        ReadinessLanguage.PT_BR -> ReadinessCopyTable.pt_br
        ReadinessLanguage.EN -> ReadinessCopyTable.en
        ReadinessLanguage.ES -> ReadinessCopyTable.es
    }

    private fun primaryWeight(a: GameReadinessAssessment, lang: ReadinessLanguage): String {
        val cause = a.primaryCause
        val (pt, en, es) = when (cause) {
            PrimaryCause.PACKET_LOSS -> Triple("Perda de pacotes na rota", "Packet loss on route", "Pérdida de paquetes en la ruta")
            PrimaryCause.HIGH_LATENCY -> Triple("Latência acima do ideal", "Latency above target", "Latencia por encima del objetivo")
            PrimaryCause.SEVERE_SPIKES -> Triple("Picos de latência", "Latency spikes", "Picos de latencia")
            PrimaryCause.HIGH_JITTER -> Triple("Variação de latência (jitter)", "Latency variation (jitter)", "Variación de latencia (jitter)")
            PrimaryCause.LOAD_DEGRADATION, PrimaryCause.LOAD_INSTABILITY ->
                Triple("Degradação sob carga", "Degradation under load", "Degradación bajo carga")
            PrimaryCause.OUT_OF_ORDER -> Triple("Pacotes fora de ordem", "Out-of-order packets", "Paquetes fuera de orden")
            PrimaryCause.TAIL_LATENCY -> Triple("Latência de cauda", "Tail latency", "Latencia de cola")
            PrimaryCause.STABLE_CONNECTION, null -> Triple("Rota estável", "Stable route", "Ruta estable")
        }
        return when (lang) { ReadinessLanguage.PT_BR -> pt; ReadinessLanguage.EN -> en; ReadinessLanguage.ES -> es }
    }

    private fun suitableUses(verdict: GameReadinessVerdict, lang: ReadinessLanguage): List<String> {
        val ranked = when (lang) { ReadinessLanguage.EN -> "Ranked"; else -> "Ranked" }
        val casual = "Casual"
        val party = "Party"
        val turn = when (lang) {
            ReadinessLanguage.PT_BR -> "Jogos por turno"
            ReadinessLanguage.EN -> "Turn-based"
            ReadinessLanguage.ES -> "Juegos por turnos"
        }
        return when (verdict) {
            GameReadinessVerdict.READY -> listOf(ranked, casual, party)
            GameReadinessVerdict.CAUTION -> listOf(casual, party)
            GameReadinessVerdict.NOT_READY -> listOf(party, turn)
            GameReadinessVerdict.INCONCLUSIVE -> listOf("—")
        }
    }

    /** Fatos de enlace local observados pelo Android. Não afirmam causa do lag. */
    private fun radioFindings(radio: RadioTelemetrySnapshot?, lang: ReadinessLanguage): List<NetworkFinding> {
        val wifi = radio?.wifiDetails ?: return emptyList()
        val ghz = when (wifi.band) {
            RadioTelemetrySnapshot.WifiBand.BAND_2_4_GHZ -> "2.4 GHz"
            RadioTelemetrySnapshot.WifiBand.BAND_5_GHZ -> "5 GHz"
            RadioTelemetrySnapshot.WifiBand.BAND_6_GHZ -> "6 GHz"
            RadioTelemetrySnapshot.WifiBand.UNKNOWN -> return emptyList()
        }
        val signalLabel = when (lang) {
            ReadinessLanguage.PT_BR -> "Sinal Wi-Fi fraco (${wifi.rssiDbm} dBm)"
            ReadinessLanguage.EN -> "Weak Wi-Fi signal (${wifi.rssiDbm} dBm)"
            ReadinessLanguage.ES -> "Señal Wi-Fi débil (${wifi.rssiDbm} dBm)"
        }
        val out = mutableListOf<NetworkFinding>()
        if (wifi.band == RadioTelemetrySnapshot.WifiBand.BAND_2_4_GHZ) {
            out += NetworkFinding(
                NetworkFinding.Kind.WIFI_BAND_2_4GHZ, NetworkFinding.Severity.WARNING,
                when (lang) {
                    ReadinessLanguage.PT_BR -> "Wi-Fi 2.4 GHz"
                    ReadinessLanguage.EN -> "Wi-Fi 2.4 GHz"
                    ReadinessLanguage.ES -> "Wi-Fi 2.4 GHz"
                },
                "${wifi.frequencyMhz} MHz"
            )
        } else {
            out += NetworkFinding(
                NetworkFinding.Kind.WIFI_BAND_5GHZ, NetworkFinding.Severity.POSITIVE,
                "Wi-Fi $ghz", "${wifi.rssiDbm} dBm · ${wifi.txLinkSpeedMbps} Mbps"
            )
        }
        if (wifi.isSignalCritical) {
            out += NetworkFinding(NetworkFinding.Kind.WIFI_SIGNAL_CRITICAL, NetworkFinding.Severity.WARNING, signalLabel, "${wifi.rssiDbm} dBm")
        }
        return out
    }
}
