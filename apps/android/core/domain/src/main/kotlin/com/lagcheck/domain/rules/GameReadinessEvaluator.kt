package com.lagcheck.domain.rules

import com.lagcheck.domain.model.GameReadinessAssessment
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.GameServerArchitecture
import com.lagcheck.domain.model.NatTopologySnapshot
import com.lagcheck.domain.model.WiFiBandDiagnosticResult
import com.lagcheck.domain.model.GatewayProbeOutcome
import com.lagcheck.domain.model.MeasurementConfidence
import com.lagcheck.domain.model.NetworkFinding
import com.lagcheck.domain.model.NetworkFinding.Kind
import com.lagcheck.domain.model.NetworkFinding.Severity as Sev
import com.lagcheck.domain.model.ProbeAcceptancePolicy
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.model.QualityResult
import com.lagcheck.domain.model.ReadinessFinding
import com.lagcheck.domain.model.ResultClass
import com.lagcheck.domain.model.SpikePattern
import java.util.Locale

/**
 * Port de `GameReadinessEvaluator` (Swift, readiness-v2.0).
 * Veredito avalia o repouso e penaliza degradação sob carga. Sem 10 respostas UDP válidas: inconclusivo.
 */
object GameReadinessEvaluator {
    const val VERSION = "readiness-v2.0"

    /** Pipeline completo: repouso + carga opcional → avaliação. */
    fun evaluate(
        restSamples: List<ProbeSample>,
        loadSamples: List<ProbeSample>?,
        profile: QualityProfileId,
        confidence: MeasurementConfidence = MeasurementConfidence.HIGH,
        gatewayOutcome: GatewayProbeOutcome = GatewayProbeOutcome.Unobservable,
        serverArchitecture: GameServerArchitecture = GameServerArchitecture.DEDICATED_SERVER,
        natSnapshot: NatTopologySnapshot? = null,
        wifiBand: WiFiBandDiagnosticResult? = null
    ): GameReadinessAssessment {
        val deep = DeepCheckEvaluator.evaluate(restSamples, loadSamples, profile)
        val result = (deep as? DeepCheckEvaluation.Completed)?.result ?: return GameReadinessAssessment.INCONCLUSIVE
        return evaluate(
            qualityResult = result.restResult,
            loadImpact = result.metrics.loadImpact,
            profile = profile,
            confidence = confidence,
            gatewayOutcome = gatewayOutcome,
            serverArchitecture = serverArchitecture,
            natSnapshot = natSnapshot,
            wifiBand = wifiBand
        )
    }

    fun evaluate(
        qualityResult: QualityResult?,
        loadImpact: DeepCheckLoadImpact?,
        profile: QualityProfileId,
        confidence: MeasurementConfidence = MeasurementConfidence.HIGH,
        spikePattern: SpikePattern? = null,
        gatewayOutcome: GatewayProbeOutcome = GatewayProbeOutcome.Unobservable,
        serverArchitecture: GameServerArchitecture = GameServerArchitecture.DEDICATED_SERVER,
        natSnapshot: NatTopologySnapshot? = null,
        wifiBand: WiFiBandDiagnosticResult? = null
    ): GameReadinessAssessment {
        if (qualityResult == null) return GameReadinessAssessment.INCONCLUSIVE
        val metrics = qualityResult.metrics

        // Regra inegociável: menos de 10 respostas UDP válidas é inconclusivo.
        if (metrics.validResponseCount < ProbeAcceptancePolicy.MINIMUM_VALID_RESPONSES) {
            return GameReadinessAssessment.INCONCLUSIVE
        }

        val interpretation = ResultInterpreter.interpret(qualityResult, profile, loadImpact?.tier, spikePattern)
        val cause = interpretation.primaryCause
        val guardrails = QualityEvaluator.causeGuardrails(profile)

        // Margem de 10% para rota genérica (confiança medium), Decisão 55.
        val margin = if (confidence == MeasurementConfidence.MEDIUM) 0.90 else 1.0
        val effectiveMaxLoss = guardrails.lossGuardrailPercentage * margin
        val effectiveMaxP50 = guardrails.latencyGuardrailMilliseconds * margin
        val effectiveCautionJitter = guardrails.jitterRiskMilliseconds * margin

        val isLoadSevere = loadImpact?.tier == LoadDegradationTier.SEVERE
        val isLoadMaterial = loadImpact?.tier == LoadDegradationTier.MATERIAL ||
            loadImpact?.classification == LoadImpactClassification.MATERIAL
        val hasPacketLoss = metrics.packetLossPercentage > effectiveMaxLoss || cause == PrimaryCause.PACKET_LOSS
        val hasHighLatency = (metrics.p50Milliseconds ?: 0.0) > effectiveMaxP50 || cause == PrimaryCause.HIGH_LATENCY

        val recurringSevereSpikes = if (spikePattern != null) {
            spikePattern.severeSpikes >= 2 && spikePattern.isRecurring
        } else {
            metrics.severeSpikeCount >= guardrails.severeSpikeGuardrailCount
        }
        val hasSevereSpikes = recurringSevereSpikes ||
            metrics.severeSpikeCount >= guardrails.severeSpikeGuardrailCount ||
            cause == PrimaryCause.SEVERE_SPIKES
        val hasHighJitter = (metrics.jitterMilliseconds ?: 0.0) >= effectiveCautionJitter || cause == PrimaryCause.HIGH_JITTER
        val hasRecurringSpikes = spikePattern?.isRecurring ?: false
        val hasOutOfOrder = metrics.outOfOrderCount >= 2 || metrics.outOfOrderRatePercentage >= 5.0

        // Cauda só é relevante com dispersão relativa E absoluta (evita falso positivo em fibra rápida).
        val p50 = metrics.p50Milliseconds ?: 0.0
        val p95 = metrics.p95Milliseconds ?: 0.0
        val isTailLatencyHigh = (metrics.p95ToP50Ratio ?: 0.0) >= 1.8 && (p95 - p50) >= 20.0 && p95 > 45.0
        val isGatewayDegraded = gatewayOutcome.isDegraded

        val (verdict, subtitleKey) = when {
            hasPacketLoss -> GameReadinessVerdict.NOT_READY to "game_readiness.verdict.not_ready.packet_loss"
            hasHighLatency -> GameReadinessVerdict.NOT_READY to "game_readiness.verdict.not_ready.high_latency"
            recurringSevereSpikes || hasSevereSpikes -> GameReadinessVerdict.NOT_READY to "game_readiness.verdict.not_ready.severe_spikes"
            isLoadSevere -> GameReadinessVerdict.NOT_READY to "game_readiness.verdict.not_ready.load"
            qualityResult.resultClass == ResultClass.LAG_RISK -> GameReadinessVerdict.NOT_READY to "game_readiness.verdict.not_ready.risk"
            hasHighJitter -> GameReadinessVerdict.CAUTION to "game_readiness.verdict.caution.jitter"
            hasOutOfOrder -> GameReadinessVerdict.CAUTION to "game_readiness.verdict.caution.out_of_order"
            isLoadMaterial -> GameReadinessVerdict.CAUTION to "game_readiness.verdict.caution.load"
            hasRecurringSpikes -> GameReadinessVerdict.CAUTION to "game_readiness.verdict.caution.spikes"
            isTailLatencyHigh -> GameReadinessVerdict.CAUTION to "game_readiness.verdict.caution.jitter"
            isGatewayDegraded -> GameReadinessVerdict.CAUTION to "game_readiness.verdict.caution.general"
            qualityResult.resultClass == ResultClass.UNSTABLE -> GameReadinessVerdict.CAUTION to "game_readiness.verdict.caution.general"
            else -> GameReadinessVerdict.READY to "game_readiness.verdict.ready.stable"
        }
        val headlineKey = when (verdict) {
            GameReadinessVerdict.NOT_READY -> "game_readiness.verdict.not_ready.headline"
            GameReadinessVerdict.CAUTION -> "game_readiness.verdict.caution.headline"
            else -> "game_readiness.verdict.ready.headline"
        }

        val findings = buildFindings(
            metrics = metrics,
            loadImpact = loadImpact,
            isGatewayDegraded = isGatewayDegraded,
            hasHighLatency = hasHighLatency,
            hasSevereSpikes = hasSevereSpikes,
            isTailLatencyHigh = isTailLatencyHigh,
            hasHighJitter = hasHighJitter,
            isLoadSevere = isLoadSevere,
            isLoadMaterial = isLoadMaterial,
            serverArchitecture = serverArchitecture,
            natSnapshot = natSnapshot
        )

        val recommendations = EvidenceRecommendationEngine.generate(
            DiagnosticEvidence(
                gatewayOutcome = gatewayOutcome,
                wifiBand = wifiBand?.diagnostic,
                wifiBandConfidence = wifiBand?.confidence,
                loadTier = loadImpact?.tier,
                packetLossPercentage = metrics.packetLossPercentage,
                spikePattern = spikePattern,
                tailRatio = metrics.p95ToP50Ratio,
                natType = natSnapshot?.natType,
                serverArchitecture = serverArchitecture,
                outOfOrderCount = metrics.outOfOrderCount
            )
        )

        val consistency = metrics.components?.consistency ?: qualityResult.finalScore.toDouble()
        var stability = (consistency / 100.0).coerceIn(0.0, 1.0)
        if (isLoadMaterial) stability = maxOf(0.2, stability * 0.8)
        stability = when (verdict) {
            GameReadinessVerdict.NOT_READY -> minOf(0.45, stability)
            GameReadinessVerdict.CAUTION -> minOf(0.75, maxOf(0.50, stability))
            else -> maxOf(0.85, stability)
        }
        val stabilitySummaryKey = when (verdict) {
            GameReadinessVerdict.READY -> "game_readiness.stability.ready_summary"
            GameReadinessVerdict.CAUTION -> "game_readiness.stability.caution_summary"
            GameReadinessVerdict.NOT_READY -> "game_readiness.stability.not_ready_summary"
            GameReadinessVerdict.INCONCLUSIVE -> "game_readiness.stability.inconclusive"
        }

        var evaluatedScore = qualityResult.finalScore
        if (isLoadSevere) {
            evaluatedScore = minOf(59, evaluatedScore)
        } else if (isLoadMaterial) {
            evaluatedScore = minOf(74, evaluatedScore)
        }

        val unifiedScore: Int? = when (verdict) {
            GameReadinessVerdict.READY -> maxOf(75, evaluatedScore)
            GameReadinessVerdict.CAUTION -> minOf(74, maxOf(60, evaluatedScore))
            GameReadinessVerdict.NOT_READY -> minOf(59, maxOf(0, evaluatedScore))
            GameReadinessVerdict.INCONCLUSIVE -> null
        }

        return GameReadinessAssessment(
            verdict = verdict,
            headlineKey = headlineKey,
            subtitleKey = subtitleKey,
            stabilityRatio = stability,
            stabilitySummaryKey = stabilitySummaryKey,
            findings = findings,
            pingMs = metrics.p50Milliseconds,
            jitterMs = metrics.jitterMilliseconds,
            packetLossPercentage = metrics.packetLossPercentage,
            isUnderLoadAffected = isLoadMaterial,
            worstSpikeMs = metrics.worstSpikeMilliseconds,
            score = unifiedScore,
            primaryCause = cause,
            recommendations = recommendations
        )
    }

    private fun buildFindings(
        metrics: com.lagcheck.domain.model.QualityMetrics,
        loadImpact: DeepCheckLoadImpact?,
        isGatewayDegraded: Boolean,
        hasHighLatency: Boolean,
        hasSevereSpikes: Boolean,
        isTailLatencyHigh: Boolean,
        hasHighJitter: Boolean,
        isLoadSevere: Boolean,
        isLoadMaterial: Boolean,
        serverArchitecture: GameServerArchitecture,
        natSnapshot: NatTopologySnapshot?
    ): List<ReadinessFinding> {
        val f = mutableListOf<ReadinessFinding>()

        if (isGatewayDegraded) {
            f += ReadinessFinding(Kind.LOCAL_GATEWAY, Sev.NEGATIVE, "game_readiness.finding.local_gateway_degraded", "Wi-Fi")
        }
        if (metrics.packetLossPercentage > 1.0) {
            f += ReadinessFinding(Kind.PACKET_LOSS, Sev.NEGATIVE, "game_readiness.finding.packet_loss_detected", fmt("%.1f%%", metrics.packetLossPercentage))
        } else {
            f += ReadinessFinding(Kind.PACKET_LOSS, Sev.POSITIVE, "game_readiness.finding.no_packet_loss", "0%")
        }
        if (hasHighLatency) {
            f += ReadinessFinding(Kind.HIGH_LATENCY, Sev.NEGATIVE, "game_readiness.finding.high_latency_detected", fmt("%.0f ms", metrics.p50Milliseconds ?: 0.0))
        }
        if (hasSevereSpikes) {
            f += ReadinessFinding(Kind.LATENCY_SPIKES, Sev.NEGATIVE, "game_readiness.finding.severe_spikes_detected", "${metrics.severeSpikeCount}")
        } else if (isTailLatencyHigh) {
            f += ReadinessFinding(Kind.LATENCY_SPIKES, Sev.WARNING, "game_readiness.finding.tail_latency_elevated", fmt("%.1fx", metrics.p95ToP50Ratio ?: 0.0))
        } else if (metrics.spikeCount > 0 || hasHighJitter) {
            f += ReadinessFinding(Kind.LATENCY_SPIKES, Sev.WARNING, "game_readiness.finding.jitter_oscillations")
        } else {
            f += ReadinessFinding(Kind.STABLE_ROUTE, Sev.POSITIVE, "game_readiness.finding.route_stable")
        }
        if (metrics.outOfOrderCount > 0) {
            f += ReadinessFinding(
                Kind.OUT_OF_ORDER_PACKETS,
                if (metrics.outOfOrderRatePercentage >= 10.0) Sev.NEGATIVE else Sev.WARNING,
                "game_readiness.finding.out_of_order_detected",
                "${metrics.outOfOrderCount}"
            )
        }
        when {
            isLoadSevere -> f += ReadinessFinding(Kind.LOAD_DEGRADATION, Sev.NEGATIVE, "game_readiness.finding.load_degradation_detected", fmt("+%.0f ms", loadImpact?.increaseMilliseconds ?: 0.0))
            isLoadMaterial -> f += ReadinessFinding(Kind.LOAD_DEGRADATION, Sev.WARNING, "game_readiness.finding.load_degradation_detected", fmt("+%.0f ms", loadImpact?.increaseMilliseconds ?: 0.0))
            loadImpact != null -> f += ReadinessFinding(Kind.LOAD_DEGRADATION, Sev.POSITIVE, "game_readiness.finding.load_stable")
        }
        // NAT só importa em jogo P2P ou híbrido (Decisão 55); em servidor dedicado o achado não aparece.
        if ((serverArchitecture == GameServerArchitecture.PEER_TO_PEER || serverArchitecture == GameServerArchitecture.HYBRID) && natSnapshot != null) {
            f += ReadinessFinding(
                Kind.NAT_TOPOLOGY,
                if (natSnapshot.natType.isMultiplayerRestricted) Sev.NEGATIVE else Sev.POSITIVE,
                natSnapshot.natType.titleKey,
                natSnapshot.natType.shortLabel
            )
        }
        f += ReadinessFinding(Kind.NORMAL_DESTINATION, Sev.POSITIVE, "game_readiness.finding.destination_response_normal")
        return f
    }

    // Locale.ROOT: ponto decimal estável, independente do idioma do aparelho (igual ao String(format:) do Swift em en_US_POSIX).
    private fun fmt(pattern: String, value: Double) = String.format(Locale.ROOT, pattern, value)
}
