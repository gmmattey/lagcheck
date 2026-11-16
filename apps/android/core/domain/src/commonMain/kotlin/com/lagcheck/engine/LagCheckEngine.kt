@file:OptIn(kotlin.js.ExperimentalJsExport::class)

package com.lagcheck.engine

import com.lagcheck.domain.model.GameServerArchitecture
import com.lagcheck.domain.model.GatewayProbeOutcome
import com.lagcheck.domain.model.MeasurementSource
import com.lagcheck.domain.model.NatType
import com.lagcheck.domain.model.ProbeOutcome
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.QualityMetrics
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.model.WiFiLocalTelemetry
import com.lagcheck.domain.rules.DeepCheckEvaluation
import com.lagcheck.domain.rules.DeepCheckEvaluator
import com.lagcheck.domain.rules.DeepCheckLoadImpactRuleV4
import com.lagcheck.domain.rules.EvidenceRecommendationEngine
import com.lagcheck.domain.rules.GameReadinessEvaluator
import com.lagcheck.domain.rules.ResultInterpreter
import com.lagcheck.domain.rules.SampleQualityEvaluator
import com.lagcheck.domain.rules.SpikePatternEvaluator
import com.lagcheck.domain.rules.StabilitySummaryEvaluator
import com.lagcheck.domain.rules.UseCaseEvaluator
import com.lagcheck.domain.rules.QualityEvaluator
import com.lagcheck.domain.rules.RootCauseEvaluator
import com.lagcheck.domain.rules.BufferbloatGrade
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/** API de string única para Swift, JVM host e pacote JS. Regras ficam nos avaliadores do domínio. */
@kotlin.js.JsExport
object LagCheckEngine {
    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
        explicitNulls = true
    }

    fun evaluate(requestJson: String): String = runCatching {
        val request = json.decodeFromString<EngineRequest>(requestJson)
        val source = request.source.toDomain()
        val profile = request.profile.toDomain()
        val rest = request.rest.map { it.toDomain() }
        val load = if (request.loadTransfer == LoadTransfer.MEASURED) request.load?.map { it.toDomain() } else null
        // Telemetria medida (`gateway`) ou estado já classificado pelo próprio motor (`gatewayOutcome`).
        val gateway = if (source == MeasurementSource.APP_UDP) request.gateway?.toOutcome() ?: request.gatewayOutcome?.toDomain() ?: GatewayProbeOutcome.Unobservable else GatewayProbeOutcome.Unobservable
        val nat = request.nat?.toUseCaseNat()

        json.encodeToString(when (val deep = DeepCheckEvaluator.evaluate(rest, load, profile, source)) {
            is DeepCheckEvaluation.Inconclusive -> EngineResponse.inconclusive(
                reason = deep.reason.name,
                source = source,
                profile = profile,
                rest = deep.diagnostics.toDto(),
                load = load?.let { QualityEvaluator.evaluate(it, profile, source).metricsOrNull()?.toDto() },
                useCases = UseCaseEvaluator.evaluate(UseCaseEvaluator.Input(
                    deep.diagnostics.p50Milliseconds, deep.diagnostics.jitterMilliseconds, null, request.uploadMbps, nat
                )).toDto()
            )
            is DeepCheckEvaluation.Completed -> {
                val result = deep.result
                val assessment = GameReadinessEvaluator.evaluate(
                    qualityResult = result.restResult,
                    loadImpact = result.metrics.loadImpact,
                    profile = profile,
                    gatewayOutcome = gateway,
                    spikePattern = result.restResult.metrics.spikePattern,
                    serverArchitecture = request.serverArchitecture.toDomain(),
                    source = source
                )
                val interpretation = ResultInterpreter.interpret(
                    result.restResult, profile, result.metrics.loadImpact?.tier,
                    result.restResult.metrics.spikePattern, source
                )
                EngineResponse(
                    verdict = assessment.verdict.name,
                    headlineKey = assessment.headlineKey,
                    subtitleKey = assessment.subtitleKey,
                    score = assessment.score,
                    isEstimate = source == MeasurementSource.WEB_HTTPS,
                    rest = result.metrics.rest.toDto(),
                    load = result.metrics.load?.toDto(),
                    loadImpact = result.metrics.loadImpact?.let {
                        LoadImpactDto(it.tier.name, it.increaseMilliseconds, it.deltaJitterMilliseconds, it.deltaLossPercentage, it.deltaSpikesCount, it.bufferbloatGrade.value)
                    },
                    spikePattern = result.metrics.rest.spikePattern.toName(),
                    primaryCause = interpretation.primaryCause.name,
                    secondaryCauses = interpretation.secondaryCauses.map { it.name },
                    findings = assessment.findings.map { FindingDto(it.kind.name, it.severity.name, it.labelKey, it.detail) },
                    recommendations = assessment.recommendations.map { it.key.name },
                    useCases = UseCaseEvaluator.evaluate(UseCaseEvaluator.Input(
                        result.metrics.rest.p50Milliseconds,
                        result.metrics.rest.jitterMilliseconds,
                        result.metrics.loadImpact?.increaseMilliseconds,
                        request.uploadMbps,
                        nat
                    )).toDto(),
                    ruleVersions = ruleVersions(profile)
                )
            }
        })
    }.getOrElse { error -> json.encodeToString(EngineError(error.message ?: "invalid_request")) }

    /** Classifica o roteador (primeiro salto) a partir da telemetria medida: entrada e saída em JSON. */
    fun gatewayOutcome(gatewayJson: String): String = runCatching {
        json.encodeToString(GatewayOutcomeDto.from(json.decodeFromString<Gateway>(gatewayJson).toOutcome()))
    }.getOrElse { error -> json.encodeToString(EngineError(error.message ?: "invalid_request")) }

    /** Isolamento de causa raiz (root-cause-v2): de quem é a culpa, sem acusar ninguém sem evidência (Decisão 50). */
    fun rootCause(requestJson: String): String = runCatching {
        val request = json.decodeFromString<RootCauseRequest>(requestJson)
        val report = RootCauseEvaluator.evaluate(
            gatewayOutcome = request.gateway.toDomain(),
            wanP50Milliseconds = request.wanP50Ms,
            wanJitterMilliseconds = request.wanJitterMs,
            wanPacketLossPercentage = request.wanLossPercentage,
            platformDegraded = request.platformDegraded,
            platformServiceName = request.platformServiceName,
            now = 0L
        )
        json.encodeToString(RootCauseResponse(report.primaryCulprit.rawValue, RootCauseEvaluator.VERSION))
    }.getOrElse { error -> json.encodeToString(EngineError(error.message ?: "invalid_request")) }

    /** Nota descritiva de bufferbloat (`bufferbloat-grade-v1`) para um aumento de P50 sob carga, em ms. */
    fun bufferbloatGrade(increaseMilliseconds: Double): String = BufferbloatGrade.fromIncrease(increaseMilliseconds).value

    /** Série de evolução da estabilidade e os 4 anéis de resumo (`stability-summary-v2`, Decisão 143). */
    fun stabilitySummary(requestJson: String): String = runCatching {
        val req = json.decodeFromString<StabilitySummaryRequestDto>(requestJson)
        val result = StabilitySummaryEvaluator.evaluate(
            StabilitySummaryEvaluator.Request(
                entries = req.entries.map { it.toDomain() },
                windowDays = req.windowDays,
                nowEpochMs = req.nowEpochMs,
                gameIdFilter = req.gameIdFilter,
                networkFilter = req.networkFilter,
                maxPoints = req.maxPoints
            )
        )
        json.encodeToString(result.toDto())
    }.getOrElse { error -> json.encodeToString(EngineError(error.message ?: "invalid_request")) }

    fun policy(): String = json.encodeToString(EnginePolicy(
        plannedProbeCount = com.lagcheck.domain.model.ProbeAcceptancePolicy.PLANNED_PROBE_COUNT,
        sendIntervalMillis = com.lagcheck.domain.model.ProbeAcceptancePolicy.SEND_INTERVAL_MILLIS,
        sendWindowMillis = com.lagcheck.domain.model.ProbeAcceptancePolicy.SEND_WINDOW_MILLIS,
        timeoutMillis = com.lagcheck.domain.model.ProbeAcceptancePolicy.TIMEOUT_MILLIS,
        closureMillis = com.lagcheck.domain.model.ProbeAcceptancePolicy.CLOSURE_MILLIS,
        minimumValidResponses = com.lagcheck.domain.model.ProbeAcceptancePolicy.MINIMUM_VALID_RESPONSES,
        ruleVersions = QualityProfileId.entries.associate { it.name to ruleVersions(it) },
        lossGuardrailPercentage = QualityProfileId.entries.associate { it.name to QualityEvaluator.causeGuardrails(it).lossGuardrailPercentage }
    ))

    internal fun ruleVersions(profile: QualityProfileId) = mapOf(
        "quality" to QualityEvaluator.ruleVersion(profile),
        "sampleQuality" to SampleQualityEvaluator.RULE_VERSION,
        "loadImpact" to DeepCheckLoadImpactRuleV4.VERSION,
        "recommendations" to EvidenceRecommendationEngine.VERSION,
        "rootCause" to RootCauseEvaluator.VERSION,
        "spikePattern" to SpikePatternEvaluator.VERSION,
        "readiness" to GameReadinessEvaluator.VERSION,
        "useCases" to UseCaseEvaluator.VERSION
    )
}

@Serializable
private data class EngineRequest(
    val source: Source,
    val profile: Profile,
    val rest: List<Sample>,
    val load: List<Sample>? = null,
    val loadTransfer: LoadTransfer = LoadTransfer.NOT_RUN,
    val gateway: Gateway? = null,
    val gatewayOutcome: GatewayOutcomeDto? = null,
    val wifiBand: String? = null,
    val nat: Nat? = null,
    val serverArchitecture: ServerArchitecture = ServerArchitecture.DEDICATED_SERVER,
    val gameId: String? = null,
    val uploadMbps: Double? = null
)

@Serializable private enum class Source { APP_UDP, WEB_HTTPS; fun toDomain() = MeasurementSource.valueOf(name) }
@Serializable private enum class Profile { BATTLE_ROYALE_COMPETITIVE, MOBILE_REALTIME, CASUAL_REALTIME; fun toDomain() = QualityProfileId.valueOf(name) }
@Serializable private enum class Outcome { RECEIVED, TIMEOUT, TRANSPORT_ERROR, INVALID_RESPONSE; fun toDomain() = ProbeOutcome.valueOf(name) }
@Serializable private enum class LoadTransfer { MEASURED, FAILED_NO_BYTES, NOT_RUN }
@Serializable private enum class ServerArchitecture { DEDICATED_SERVER, PEER_TO_PEER, HYBRID; fun toDomain() = GameServerArchitecture.valueOf(name) }
@Serializable private enum class NatOrigin { STUN_APP, BROWSER_ESTIMATE }

@Serializable private data class Sample(val sequence: Int, val outcome: Outcome, val rttMs: Double? = null, val arrivalIndex: Int? = null) {
    fun toDomain() = ProbeSample(sequence, rttMs, outcome.toDomain(), arrivalIndex)
}
@Serializable private data class Gateway(val rttMs: Double? = null, val jitterMs: Double? = null, val validResponses: Int = 0, val plannedResponses: Int = 0, val isWifi: Boolean = true) {
    fun toOutcome() = WiFiLocalTelemetry(rttMs, jitterMs, validSampleCount = validResponses, plannedSampleCount = plannedResponses, isWiFi = isWifi).gatewayOutcome
}
@Serializable private data class Nat(val type: NatType, val origin: NatOrigin) {
    fun toUseCaseNat() = UseCaseEvaluator.NatMeasurement(type, UseCaseEvaluator.NatSource.valueOf(origin.name))
}

@Serializable private data class MetricDto(val validResponseCount: Int, val timeoutCount: Int, val invalidResponseCount: Int, val p50Milliseconds: Double? = null, val p95Milliseconds: Double? = null, val p99Milliseconds: Double? = null, val jitterMilliseconds: Double? = null, val packetLossPercentage: Double, val spikeCount: Int, val severeSpikeCount: Int, val spikeRatePercentage: Double, val p95ToP50Ratio: Double? = null, val worstSpikeMilliseconds: Double? = null, val outOfOrderCount: Int, val outOfOrderRatePercentage: Double, val spikePattern: String)
private fun QualityMetrics.toDto() = MetricDto(validResponseCount, timeoutCount, invalidResponseCount, p50Milliseconds, p95Milliseconds, p99Milliseconds, jitterMilliseconds, packetLossPercentage, spikeCount, severeSpikeCount, spikeRatePercentage, p95ToP50Ratio, worstSpikeMilliseconds, outOfOrderCount, outOfOrderRatePercentage, spikePattern.toName())
private fun com.lagcheck.domain.model.SpikePattern.toName() = when (this) { com.lagcheck.domain.model.SpikePattern.None -> "NONE"; is com.lagcheck.domain.model.SpikePattern.Isolated -> "ISOLATED"; is com.lagcheck.domain.model.SpikePattern.Recurring -> "RECURRING" }
private fun com.lagcheck.domain.model.MeasurementEvaluation.metricsOrNull() = when (this) { is com.lagcheck.domain.model.MeasurementEvaluation.Completed -> result.metrics; is com.lagcheck.domain.model.MeasurementEvaluation.Inconclusive -> diagnostics }

@Serializable private data class LoadImpactDto(val tier: String, val deltaP50Milliseconds: Double, val deltaJitterMilliseconds: Double? = null, val deltaLossPercentage: Double? = null, val deltaSpikesCount: Int? = null, val bufferbloatGrade: String)
@Serializable private data class FindingDto(val kind: String, val severity: String, val key: String, val detail: String? = null)
@Serializable private data class UseCasesDto(val overallTone: String, val overallHeadlineKey: String, val overallSubtitleKey: String, val cases: List<UseCaseDto>)
@Serializable private data class UseCaseDto(val id: String, val status: String, val titleKey: String, val detailKey: String, val origin: String? = null)
private fun UseCaseEvaluator.Evaluation.toDto() = UseCasesDto(overallTone.name, overallHeadlineKey, overallSubtitleKey, cases.map { UseCaseDto(it.id, it.status.name, it.titleKey, it.detailKey, it.origin?.name) })

@Serializable private data class EngineResponse(val verdict: String, val headlineKey: String, val subtitleKey: String, val score: Int? = null, val isEstimate: Boolean, val rest: MetricDto, val load: MetricDto? = null, val loadImpact: LoadImpactDto? = null, val spikePattern: String, val primaryCause: String? = null, val secondaryCauses: List<String> = emptyList(), val findings: List<FindingDto> = emptyList(), val recommendations: List<String> = emptyList(), val useCases: UseCasesDto, val inconclusiveReason: String? = null, val ruleVersions: Map<String, String>) {
    companion object {
        fun inconclusive(reason: String, source: MeasurementSource, profile: QualityProfileId, rest: MetricDto, load: MetricDto?, useCases: UseCasesDto) = EngineResponse("INCONCLUSIVE", "game_readiness.verdict.inconclusive.headline", "game_readiness.verdict.inconclusive.subtitle", null, source == MeasurementSource.WEB_HTTPS, rest, load, null, rest.spikePattern, null, emptyList(), emptyList(), emptyList(), useCases, reason, LagCheckEngine.ruleVersions(profile))
    }
}
@Serializable private data class EnginePolicy(val plannedProbeCount: Int, val sendIntervalMillis: Long, val sendWindowMillis: Long, val timeoutMillis: Long, val closureMillis: Long, val minimumValidResponses: Int, val ruleVersions: Map<String, Map<String, String>>, val lossGuardrailPercentage: Map<String, Double>)
@Serializable private data class EngineError(val error: String)
@Serializable private data class GatewayOutcomeDto(val kind: String, val rttMs: Double? = null, val lossPercentage: Double? = null) {
    fun toDomain(): GatewayProbeOutcome = when (kind) {
        "STABLE" -> GatewayProbeOutcome.Stable(requireNotNull(rttMs) { "gateway_rtt_required" })
        "DEGRADED" -> GatewayProbeOutcome.Degraded(requireNotNull(rttMs) { "gateway_rtt_required" }, lossPercentage ?: 0.0)
        else -> GatewayProbeOutcome.Unobservable
    }
    companion object {
        fun from(outcome: GatewayProbeOutcome) = when (outcome) {
            is GatewayProbeOutcome.Stable -> GatewayOutcomeDto("STABLE", outcome.rttMilliseconds, 0.0)
            is GatewayProbeOutcome.Degraded -> GatewayOutcomeDto("DEGRADED", outcome.rttMilliseconds, outcome.lossPercentage)
            is GatewayProbeOutcome.Unobservable -> GatewayOutcomeDto("UNOBSERVABLE")
        }
    }
}
@Serializable private data class RootCauseRequest(val gateway: GatewayOutcomeDto, val wanP50Ms: Double? = null, val wanJitterMs: Double? = null, val wanLossPercentage: Double, val platformDegraded: Boolean = false, val platformServiceName: String? = null)
@Serializable private data class RootCauseResponse(val culprit: String, val ruleVersion: String)

@Serializable
private data class StabilityEntryDto(
    val capturedAtEpochMs: Long,
    val pingMs: Double? = null,
    val jitterMs: Double? = null,
    val packetLossPercentage: Double? = null,
    val loadDeltaMs: Double? = null,
    val verdict: String,
    val validResponseCount: Int? = null,
    val gameId: String? = null,
    val gameTitle: String? = null,
    val platform: String? = null,
    val declaredExternalLink: String? = null,
    val networkType: String? = null,
    val regionId: String? = null,
    val ruleVersion: String? = null
) {
    fun toDomain() = StabilitySummaryEvaluator.EntryInput(
        capturedAtEpochMs = capturedAtEpochMs,
        pingMs = pingMs,
        jitterMs = jitterMs,
        packetLossPercentage = packetLossPercentage,
        loadDeltaMs = loadDeltaMs,
        verdict = verdict,
        validResponseCount = validResponseCount,
        gameId = gameId,
        gameTitle = gameTitle,
        platform = platform,
        declaredExternalLink = declaredExternalLink,
        networkType = networkType,
        regionId = regionId,
        ruleVersion = ruleVersion
    )
}

@Serializable
private data class StabilitySummaryRequestDto(
    val entries: List<StabilityEntryDto>,
    val windowDays: Int = 14,
    val nowEpochMs: Long,
    val gameIdFilter: String? = null,
    val networkFilter: String? = null,
    val maxPoints: Int = 30
)

@Serializable
private data class StabilityPointDto(
    val capturedAtEpochMs: Long,
    val pingMs: Double,
    val jitterMs: Double? = null,
    val packetLossPercentage: Double? = null,
    val loadDeltaMs: Double? = null,
    val verdict: String,
    val gameId: String? = null,
    val gameTitle: String? = null,
    val networkType: String? = null,
    val regionId: String? = null,
    val segmentIndex: Int,
    val connectToPrevious: Boolean
)

@Serializable
private data class StabilityRingDto(
    val value: Double? = null,
    val tone: String,
    val fillRatio: Double
)

@Serializable
private data class StabilityRingsDto(
    val ping: StabilityRingDto,
    val jitter: StabilityRingDto,
    val loss: StabilityRingDto,
    val load: StabilityRingDto
)

@Serializable
private data class StabilitySummaryResponseDto(
    val ruleVersion: String,
    val windowDays: Int,
    val points: List<StabilityPointDto>,
    val canDrawCurve: Boolean,
    val hasSummary: Boolean,
    val hasMixedContexts: Boolean,
    val availableNetworks: List<String>,
    val summaryNetworkType: String? = null,
    val summaryRegionId: String? = null,
    val totalComparableCount: Int,
    val readyCount: Int,
    val cautionCount: Int,
    val badCount: Int,
    val inconclusiveCount: Int,
    val stabilityPercentage: Int? = null,
    val stabilityTone: String,
    val headlineKey: String,
    val minPingMs: Double? = null,
    val avgPingMs: Double? = null,
    val maxPingMs: Double? = null,
    val rings: StabilityRingsDto? = null,
    val latest: StabilityPointDto? = null
)

private fun StabilitySummaryEvaluator.Point.toDto() = StabilityPointDto(
    capturedAtEpochMs = capturedAtEpochMs,
    pingMs = pingMs,
    jitterMs = jitterMs,
    packetLossPercentage = packetLossPercentage,
    loadDeltaMs = loadDeltaMs,
    verdict = verdict.name,
    gameId = gameId,
    gameTitle = gameTitle,
    networkType = networkType,
    regionId = regionId,
    segmentIndex = segmentIndex,
    connectToPrevious = connectToPrevious
)

private fun StabilitySummaryEvaluator.RingMetric.toDto() = StabilityRingDto(
    value = value,
    tone = tone.name,
    fillRatio = fillRatio
)

private fun StabilitySummaryEvaluator.Result.toDto() = StabilitySummaryResponseDto(
    ruleVersion = ruleVersion,
    windowDays = windowDays,
    points = points.map { it.toDto() },
    canDrawCurve = canDrawCurve,
    hasSummary = hasSummary,
    hasMixedContexts = hasMixedContexts,
    availableNetworks = availableNetworks,
    summaryNetworkType = summaryNetworkType,
    summaryRegionId = summaryRegionId,
    totalComparableCount = totalComparableCount,
    readyCount = readyCount,
    cautionCount = cautionCount,
    badCount = badCount,
    inconclusiveCount = inconclusiveCount,
    stabilityPercentage = stabilityPercentage,
    stabilityTone = stabilityTone.name,
    headlineKey = headlineKey,
    minPingMs = minPingMs,
    avgPingMs = avgPingMs,
    maxPingMs = maxPingMs,
    rings = rings?.let { StabilityRingsDto(it.ping.toDto(), it.jitter.toDto(), it.loss.toDto(), it.load.toDto()) },
    latest = latest?.toDto()
)
