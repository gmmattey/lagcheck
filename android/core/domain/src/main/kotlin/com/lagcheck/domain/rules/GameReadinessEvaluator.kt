package com.lagcheck.domain.rules

import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.NetworkFinding
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Avaliador de prontidão determinístico e versionado (Decisões 50, 58 e 67).
 * Mantém paridade matemática estrita com a especificação técnica e o protótipo de alta fidelidade.
 */
object GameReadinessEvaluator {

    const val MIN_VALID_SAMPLES = 10
    const val PLANNED_PROBE_COUNT = 30

    fun evaluate(
        samples: List<ProbeSample>,
        loadSamples: List<ProbeSample> = emptyList(),
        radioSnapshot: RadioTelemetrySnapshot? = null,
        platform: String = "PlayStation",
        connectionType: String = "Wi-Fi"
    ): GameReadinessEvaluation {
        val validRTTs = samples.filter { it.isValidResponse }.mapNotNull { it.roundTripMillis }
        val timeoutCount = samples.count { it.outcome == ProbeSample.Outcome.TIMEOUT }
        val totalPlanned = if (samples.size >= PLANNED_PROBE_COUNT) samples.size else PLANNED_PROBE_COUNT
        val lossPercentage = (timeoutCount.toDouble() / totalPlanned.toDouble()) * 100.0

        // Menos de 10 amostras válidas: INCONCLUSIVE inegociável
        if (validRTTs.size < MIN_VALID_SAMPLES) {
            return GameReadinessEvaluation(
                verdict = GameReadinessVerdict.INCONCLUSIVE,
                headline = "DADOS INSUFICIENTES",
                subtitle = "Não recebemos respostas UDP suficientes para avaliar com precisão.",
                score = 0,
                primaryWeight = "Respostas insuficientes",
                suitableUses = listOf("—"),
                pingMs = null,
                jitterMs = null,
                packetLossPercentage = lossPercentage,
                worstSpikeMs = null,
                isUnderLoadAffected = false,
                findings = listOf(
                    NetworkFinding(
                        kind = NetworkFinding.Kind.INSUFFICIENT_DATA,
                        severity = NetworkFinding.Severity.NEUTRAL,
                        label = "Respostas insuficientes",
                        detail = "Recebemos apenas ${validRTTs.size} respostas válidas de $totalPlanned probes."
                    )
                ),
                latencySeries = emptyList(),
                platform = platform,
                connectionType = connectionType,
                radioTelemetry = radioSnapshot
            )
        }

        val sortedRTTs = validRTTs.sorted()
        val p50 = percentile(sortedRTTs, 0.50)
        val p95 = percentile(sortedRTTs, 0.95)
        val jitter = calculateJitter(validRTTs)
        val worstSpike = sortedRTTs.lastOrNull() ?: p50

        // RFC 4737: Verificação de reordenação de pacotes
        val outOfOrderCount = samples.count { it.isOutOfOrder }
        val outOfOrderRate = (outOfOrderCount.toDouble() / samples.size.toDouble()) * 100.0
        val isOutOfOrderHigh = outOfOrderRate > 1.0

        // Avaliação de estresse sob carga (Bufferbloat)
        val validLoadRTTs = loadSamples.filter { it.isValidResponse }.mapNotNull { it.roundTripMillis }
        val loadP50 = if (validLoadRTTs.size >= MIN_VALID_SAMPLES) percentile(validLoadRTTs.sorted(), 0.50) else null
        val isUnderLoadAffected = loadP50 != null && (loadP50 - p50) > 30.0

        // Determinação do Veredito Semântico
        val verdict = when {
            lossPercentage > 2.0 || p50 > 110.0 || jitter > 25.0 -> {
                GameReadinessVerdict.NOT_READY
            }
            lossPercentage > 0.5 || p50 > 65.0 || jitter > 10.0 || isUnderLoadAffected || isOutOfOrderHigh -> {
                GameReadinessVerdict.CAUTION
            }
            else -> {
                GameReadinessVerdict.READY
            }
        }

        val headline = when (verdict) {
            GameReadinessVerdict.READY -> "PRONTO PARA RANKED"
            GameReadinessVerdict.CAUTION -> "CONDIÇÕES INSTÁVEIS"
            GameReadinessVerdict.NOT_READY -> "EU EVITARIA RANKED AGORA"
            GameReadinessVerdict.INCONCLUSIVE -> "DADOS INSUFICIENTES"
        }

        val subtitle = when (verdict) {
            GameReadinessVerdict.READY -> "Sua conexão está estável o suficiente para ranked agora."
            GameReadinessVerdict.CAUTION -> "Oscilações observadas que podem gerar micro-travamentos."
            GameReadinessVerdict.NOT_READY -> "Perda de pacotes ou latência prejudicial detectada."
            GameReadinessVerdict.INCONCLUSIVE -> "Sem amostras suficientes para concluir."
        }

        // Cálculo determinístico do Lagcheck Score (0..100)
        var calculatedScore = 100.0
        if (p50 > 20.0) {
            calculatedScore -= (p50 - 20.0) * 0.45
        }
        calculatedScore -= (jitter * 1.5)
        calculatedScore -= (lossPercentage * 12.0)
        if (isUnderLoadAffected) {
            calculatedScore -= 12.0
        }
        if (isOutOfOrderHigh) {
            calculatedScore -= 8.0
        }
        val finalScore = calculatedScore.roundToInt().coerceIn(10, 99)

        // O que mais pesou
        val primaryWeight = when {
            lossPercentage > 1.0 -> "Perda de pacotes na rota"
            jitter > 12.0 -> "Variação de latência (jitter)"
            isUnderLoadAffected -> "Degradação sob carga de download"
            isOutOfOrderHigh -> "Pacotes fora de ordem (RFC 4737)"
            p50 > 75.0 -> "Latência média elevada"
            else -> "Rota estável sob carga"
        }

        // Casos de uso adequados
        val suitableUses = when (verdict) {
            GameReadinessVerdict.READY -> listOf("Ranked", "Casual", "Party")
            GameReadinessVerdict.CAUTION -> listOf("Casual", "Party")
            GameReadinessVerdict.NOT_READY -> listOf("Party", "Jogos por turno")
            GameReadinessVerdict.INCONCLUSIVE -> listOf("—")
        }

        // Construção dos achados objetivos ("O que encontramos")
        val findings = mutableListOf<NetworkFinding>()

        if (jitter <= 5.0) {
            findings.add(
                NetworkFinding(
                    kind = NetworkFinding.Kind.STABLE_ROUTE,
                    severity = NetworkFinding.Severity.POSITIVE,
                    label = "Estabilidade",
                    detail = "Jitter baixo durante a medição."
                )
            )
        } else {
            findings.add(
                NetworkFinding(
                    kind = NetworkFinding.Kind.HIGH_JITTER,
                    severity = NetworkFinding.Severity.WARNING,
                    label = "Jitter elevado",
                    detail = "Variação de %.1f ms entre pacotes consecutivos.".format(jitter)
                )
            )
        }

        if (!isUnderLoadAffected) {
            findings.add(
                NetworkFinding(
                    kind = NetworkFinding.Kind.STABLE_ROUTE,
                    severity = NetworkFinding.Severity.POSITIVE,
                    label = "Comportamento sob carga",
                    detail = "Sem degradação relevante na rota externa."
                )
            )
        } else {
            findings.add(
                NetworkFinding(
                    kind = NetworkFinding.Kind.LOAD_DEGRADATION,
                    severity = NetworkFinding.Severity.WARNING,
                    label = "Sensível a tráfego na rede",
                    detail = "A latência aumentou +%.0f ms durante download simultâneo.".format((loadP50 ?: 0.0) - p50)
                )
            )
        }

        findings.add(
            NetworkFinding(
                kind = NetworkFinding.Kind.STABLE_ROUTE,
                severity = NetworkFinding.Severity.POSITIVE,
                label = "Destino testado",
                detail = "São Paulo · rota regional de referência."
            )
        )

        if (lossPercentage > 0.5) {
            findings.add(
                NetworkFinding(
                    kind = NetworkFinding.Kind.PACKET_LOSS,
                    severity = if (lossPercentage > 2.0) NetworkFinding.Severity.NEGATIVE else NetworkFinding.Severity.WARNING,
                    label = "Perda de pacotes observada",
                    detail = "%.1f%% de perda até o servidor do jogo.".format(lossPercentage)
                )
            )
        }

        if (isOutOfOrderHigh) {
            findings.add(
                NetworkFinding(
                    kind = NetworkFinding.Kind.OUT_OF_ORDER_PACKETS,
                    severity = NetworkFinding.Severity.WARNING,
                    label = "Pacotes fora de ordem (RFC 4737)",
                    detail = "%.1f%% dos pacotes chegaram invertidos na rota.".format(outOfOrderRate)
                )
            )
        }

        // Modulação com telemetria física do Android
        if (radioSnapshot != null && radioSnapshot.wifiDetails != null) {
            val wifi = radioSnapshot.wifiDetails
            when (wifi.band) {
                RadioTelemetrySnapshot.WifiBand.BAND_2_4_GHZ -> {
                    findings.add(
                        NetworkFinding(
                            kind = NetworkFinding.Kind.WIFI_BAND_2_4GHZ,
                            severity = NetworkFinding.Severity.WARNING,
                            label = "Wi-Fi 2.4 GHz detectado",
                            detail = "Frequência ${wifi.frequencyMhz} MHz suscetível a interferências de canal."
                        )
                    )
                }
                RadioTelemetrySnapshot.WifiBand.BAND_5_GHZ, RadioTelemetrySnapshot.WifiBand.BAND_6_GHZ -> {
                    if (wifi.isSignalCritical) {
                        findings.add(
                            NetworkFinding(
                                kind = NetworkFinding.Kind.WIFI_SIGNAL_CRITICAL,
                                severity = NetworkFinding.Severity.WARNING,
                                label = "Sinal Wi-Fi fraco (${wifi.rssiDbm} dBm)",
                                detail = "Proximidade do roteador pode mitigar oscilações."
                            )
                        )
                    } else {
                        findings.add(
                            NetworkFinding(
                                kind = NetworkFinding.Kind.WIFI_BAND_5GHZ,
                                severity = NetworkFinding.Severity.POSITIVE,
                                label = "Wi-Fi ${if (wifi.band == RadioTelemetrySnapshot.WifiBand.BAND_6_GHZ) "6 GHz" else "5 GHz"} (${wifi.rssiDbm} dBm)",
                                detail = "Enlace local excelente a ${wifi.txLinkSpeedMbps} Mbps."
                            )
                        )
                    }
                }
                else -> Unit
            }
        }

        val allSeries = validRTTs + validLoadRTTs

        return GameReadinessEvaluation(
            verdict = verdict,
            headline = headline,
            subtitle = subtitle,
            score = finalScore,
            primaryWeight = primaryWeight,
            suitableUses = suitableUses,
            pingMs = p50,
            jitterMs = jitter,
            packetLossPercentage = lossPercentage,
            worstSpikeMs = worstSpike,
            isUnderLoadAffected = isUnderLoadAffected,
            findings = findings,
            latencySeries = allSeries,
            platform = platform,
            connectionType = connectionType,
            radioTelemetry = radioSnapshot
        )
    }

    private fun percentile(sortedList: List<Double>, p: Double): Double {
        if (sortedList.isEmpty()) return 0.0
        val index = ((sortedList.size - 1) * p).toInt()
        return sortedList[index]
    }

    private fun calculateJitter(rtts: List<Double>): Double {
        if (rtts.size < 2) return 0.0
        var diffSum = 0.0
        for (i in 0 until rtts.size - 1) {
            diffSum += abs(rtts[i + 1] - rtts[i])
        }
        return diffSum / (rtts.size - 1).toDouble()
    }
}
