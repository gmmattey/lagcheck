package com.lagcheck.session

import com.lagcheck.catalog.ProbeDestination
import com.lagcheck.catalog.ResolvedMeasurementContext
import com.lagcheck.domain.model.GameReadinessAssessment
import com.lagcheck.domain.model.GatewayProbeOutcome
import com.lagcheck.domain.model.NatTopologySnapshot
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.domain.model.WiFiBandDiagnosticResult
import com.lagcheck.domain.model.WiFiLocalTelemetry
import com.lagcheck.domain.rules.GameArchitectureRegistry
import com.lagcheck.domain.rules.WiFiBandEvaluator
import com.lagcheck.network.local.GatewayProber
import com.lagcheck.network.local.StunTopologyProbe
import com.lagcheck.domain.model.InconclusiveReason
import com.lagcheck.domain.model.MeasurementConfidence
import com.lagcheck.domain.model.ProbeAcceptancePolicy
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.rules.GameReadinessEvaluator
import com.lagcheck.network.transport.ProbeCollection
import com.lagcheck.network.transport.ProbePlan
import com.lagcheck.network.transport.ProbeProgress
import com.lagcheck.network.transport.UdpProbeTransport
import com.lagcheck.network.worker.HttpLoadTransport
import com.lagcheck.network.worker.LoadOutcome
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope

fun interface ProbeCollector {
    suspend fun collect(destination: ProbeDestination, plan: ProbePlan, onProgress: (ProbeProgress) -> Unit): ProbeCollection
}

fun interface LoadTransfer {
    suspend fun transfer(isWiFi: Boolean): LoadOutcome
}

fun LoadTransfer(block: suspend () -> LoadOutcome) = LoadTransfer { _ -> block() }

enum class CheckPhase { REST, LOAD }

/** O que o aparelho sabe do ambiente local antes de medir. Tudo vem do sistema operacional, nada é suposto. */
data class CheckEnvironment(
    val isWiFi: Boolean = false,
    val gatewayAddress: String? = null,
    val localIp: String? = null,
    val wifiRadio: RadioTelemetrySnapshot.WifiDetails? = null
) {
    companion object { val NONE = CheckEnvironment() }
}

/** Diagnósticos locais observáveis. Sem eles o Check roda só com a medição UDP. */
class LocalDiagnostics(
    private val gateway: GatewayProber = GatewayProber(),
    private val nat: StunTopologyProbe = StunTopologyProbe(),
    private val gatewaySamples: Int = 5,
    private val gatewayTimeoutMillis: Long = 300
) {
    suspend fun probeGateway(env: CheckEnvironment, samples: Int = gatewaySamples): WiFiLocalTelemetry =
        gateway.probe(env.gatewayAddress, env.isWiFi, samples, gatewayTimeoutMillis)

    suspend fun probeNat(env: CheckEnvironment): NatTopologySnapshot = nat.probe(env.localIp)
}

data class CheckProgress(val phase: CheckPhase, val ratio: Float, val latestPingMs: Double?)

/** Resultado de uma sessão. `assessment` é inconclusivo quando não houve resposta UDP suficiente ou a conexão caiu. */
data class CheckResult(
    val context: ResolvedMeasurementContext,
    val assessment: GameReadinessAssessment,
    val restSamples: List<ProbeSample>,
    /** Nulo quando a carga não pôde ser medida; nesse caso a sessão não é um Check Completo. */
    val loadSamples: List<ProbeSample>?,
    val abortReason: InconclusiveReason?,
    /** Primeiro salto medido (para Cockpit e voz). Nulo se não sondado. */
    val localTelemetry: WiFiLocalTelemetry? = null,
    val wifiBand: WiFiBandDiagnosticResult? = null,
    val nat: NatTopologySnapshot? = null
) {
    val loadMeasured: Boolean get() = loadSamples != null

    /** Série de latência para o gráfico: repouso e depois carga, só respostas válidas. */
    val latencySeries: List<Double>
        get() = (restSamples + (loadSamples ?: emptyList())).filter { it.isValidResponse }.mapNotNull { it.roundTripMilliseconds }
}

/**
 * Uma sessão de medição: repouso (30 probes) e depois carga (30 probes com download concorrente do Worker).
 * Mesma ordem e regras do Deep Check do iOS. Uma única sessão por vez fica a cargo de quem chama; cancelar a
 * coroutine descarta tudo (mudança de rede, background e cancelamento nunca geram resultado parcial).
 */
class CheckOrchestrator(
    private val probes: ProbeCollector,
    private val load: LoadTransfer,
    private val restPlan: ProbePlan = ProbePlan(),
    private val loadPlan: ProbePlan = ProbePlan(),
    private val local: LocalDiagnostics? = null
) {
    constructor(
        probes: ProbeCollector,
        load: suspend () -> LoadOutcome,
        restPlan: ProbePlan = ProbePlan(),
        loadPlan: ProbePlan = ProbePlan(),
        local: LocalDiagnostics? = null
    ) : this(probes, LoadTransfer { _ -> load() }, restPlan, loadPlan, local)

    constructor(transport: UdpProbeTransport, loadTransport: HttpLoadTransport, local: LocalDiagnostics? = null) : this(
        { d, p, cb -> transport.collect(d, p, cb) },
        { isWiFi -> loadTransport.transfer(isWiFi) },
        local = local
    )

    suspend fun run(
        context: ResolvedMeasurementContext,
        env: CheckEnvironment = CheckEnvironment.NONE,
        onProgress: (CheckProgress) -> Unit = {}
    ): CheckResult {
        // Primeiro salto antes do repouso, só em Wi-Fi: não disputa banda com as fases de medição.
        val gatewayTelemetry = if (env.isWiFi) local?.probeGateway(env) else null
        val wifiBand = if (env.isWiFi && (gatewayTelemetry != null || env.wifiRadio != null)) {
            WiFiBandEvaluator.evaluate(gatewayTelemetry ?: WiFiLocalTelemetry(isWiFi = true), env.wifiRadio)
        } else null

        val rest = probes.collect(context.destination, restPlan) { event -> onProgress(progress(CheckPhase.REST, event, restPlan.count)) }
        if (rest.aborted) return inconclusive(context, rest.samples, null, rest.abortReason, gatewayTelemetry, wifiBand)

        val (loadCollection, loadOutcome) = coroutineScope {
            val transfer = async { load.transfer(env.isWiFi) }
            val collected = probes.collect(context.destination, loadPlan) { event -> onProgress(progress(CheckPhase.LOAD, event, loadPlan.count)) }
            if (collected.aborted) transfer.cancel()
            collected to (if (collected.aborted) LoadOutcome.Unavailable else transfer.await())
        }
        // Conexão que morre sob carga cancela a sessão inteira, como no iOS: nada de "pronto" sobre uma rota que caiu.
        if (loadCollection.aborted) return inconclusive(context, rest.samples, loadCollection.samples, InconclusiveReason.POOR_SAMPLE_QUALITY, gatewayTelemetry, wifiBand)

        // Repouso bom não é um Check Completo. Sem bytes de carga não houve estresse para sustentar
        // qualquer conclusão de Ranked, mesmo que o contrato legado do motor ainda aceite o repouso.
        if (loadOutcome !is LoadOutcome.Completed || loadOutcome.bytesTransferred <= 0L) {
            return incompleteLoad(context, rest.samples, gatewayTelemetry, wifiBand)
        }

        if (loadCollection.samples.count { it.isValidResponse } < ProbeAcceptancePolicy.MINIMUM_VALID_RESPONSES) {
            return inconclusive(context, rest.samples, loadCollection.samples, InconclusiveReason.POOR_SAMPLE_QUALITY, gatewayTelemetry, wifiBand)
        }

        val usableLoad = loadCollection.samples

        // Arquitetura ainda contextualiza o jogo no motor. A coleta STUN disponível não prova topologia:
        // não a envia ao veredito nem oferece UPnP com base nela.
        val architecture = GameArchitectureRegistry.serverArchitecture(context.context.gameId)

        // Uma resposta DNS do gateway pode ser encaminhada; ela fica na telemetria factual e não atribui causa,
        // rebaixa o veredito ou recomenda aproximar-se do roteador.
        val assessment = GameReadinessEvaluator.evaluate(
            restSamples = rest.samples,
            loadSamples = usableLoad,
            profile = context.profileId,
            confidence = MeasurementConfidence.HIGH,
            gatewayOutcome = GatewayProbeOutcome.Unobservable,
            serverArchitecture = architecture,
            natSnapshot = null,
            wifiBand = wifiBand
        )
        return CheckResult(context, assessment, rest.samples, usableLoad, null, gatewayTelemetry, wifiBand, null)
    }

    private fun inconclusive(
        context: ResolvedMeasurementContext,
        rest: List<ProbeSample>,
        load: List<ProbeSample>?,
        reason: InconclusiveReason?,
        gateway: WiFiLocalTelemetry?,
        wifiBand: WiFiBandDiagnosticResult?
    ) = CheckResult(context, GameReadinessAssessment.INCONCLUSIVE, rest, load, reason, gateway, wifiBand, null)

    /** A carga não transferiu dados: guarda o repouso como observação, mas não produz Check Completo. */
    private fun incompleteLoad(
        context: ResolvedMeasurementContext,
        rest: List<ProbeSample>,
        gateway: WiFiLocalTelemetry?,
        wifiBand: WiFiBandDiagnosticResult?
    ) = CheckResult(context, GameReadinessAssessment.INCONCLUSIVE, rest, null, null, gateway, wifiBand, null)

    private fun progress(phase: CheckPhase, event: ProbeProgress, planned: Int): CheckProgress {
        val base = if (phase == CheckPhase.REST) 0f else 0.5f
        return when (event) {
            is ProbeProgress.Sent -> CheckProgress(phase, base + 0.5f * (event.sequence + 1) / planned, null)
            is ProbeProgress.Received -> CheckProgress(phase, base + 0.5f * (event.sample.sequence + 1) / planned, event.sample.roundTripMilliseconds)
        }
    }
}
