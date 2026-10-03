package com.lagcheck.session

import com.lagcheck.catalog.ProbeDestination
import com.lagcheck.catalog.ResolvedMeasurementContext
import com.lagcheck.domain.model.GameReadinessAssessment
import com.lagcheck.domain.model.GatewayProbeOutcome
import com.lagcheck.domain.model.NatTopologySnapshot
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.domain.model.WiFiBandDiagnosticResult
import com.lagcheck.domain.model.WiFiLocalTelemetry
import com.lagcheck.domain.model.GameServerArchitecture
import com.lagcheck.domain.rules.GameArchitectureRegistry
import com.lagcheck.domain.rules.WiFiBandEvaluator
import com.lagcheck.network.local.GatewayProber
import com.lagcheck.network.local.StunTopologyProbe
import com.lagcheck.domain.model.InconclusiveReason
import com.lagcheck.domain.model.MeasurementConfidence
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
    suspend fun transfer(): LoadOutcome
}

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

/** Diagnósticos locais (primeiro salto e NAT). Opcionais: sem eles o Check roda só com a medição UDP. */
class LocalDiagnostics(
    private val gateway: GatewayProber = GatewayProber(),
    private val nat: StunTopologyProbe = StunTopologyProbe(),
    /**
     * Se o primeiro salto entra no veredito e nas recomendações. **Desligado de propósito:** o RTT vem de uma consulta
     * DNS ao roteador, que pode encaminhar para fora e inflar o tempo, e isso acusaria o Wi-Fi sem evidência (Decisão 50).
     * O iOS também não usa o gateway no veredito. Ligar só depois de validar em aparelho (Breno) e com revisão do Iury.
     */
    val gatewayInfluencesVerdict: Boolean = false,
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
    /** Nulo quando a carga não pôde ser medida (HTTP indisponível); o repouso continua válido. */
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
    constructor(transport: UdpProbeTransport, loadTransport: HttpLoadTransport, local: LocalDiagnostics? = null) : this(
        { d, p, cb -> transport.collect(d, p, cb) },
        { loadTransport.transfer() },
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
            val transfer = async { load.transfer() }
            val collected = probes.collect(context.destination, loadPlan) { event -> onProgress(progress(CheckPhase.LOAD, event, loadPlan.count)) }
            if (collected.aborted) transfer.cancel()
            collected to (if (collected.aborted) LoadOutcome.Unavailable else transfer.await())
        }
        // Conexão que morre sob carga cancela a sessão inteira, como no iOS: nada de "pronto" sobre uma rota que caiu.
        if (loadCollection.aborted) return inconclusive(context, rest.samples, loadCollection.samples, loadCollection.abortReason, gatewayTelemetry, wifiBand)

        val usableLoad = if (loadOutcome == LoadOutcome.Unavailable) null else loadCollection.samples

        // NAT só importa em jogo P2P ou híbrido: nos demais não gasta ~4 s da pessoa à toa.
        val architecture = GameArchitectureRegistry.serverArchitecture(context.context.gameId)
        val needsNat = architecture != GameServerArchitecture.DEDICATED_SERVER
        val nat = if (needsNat) local?.probeNat(env) else null

        val gatewayForVerdict = if (local?.gatewayInfluencesVerdict == true) gatewayTelemetry?.gatewayOutcome else null

        // Paridade com o iOS: o veredito usa o padrão (confiança alta). A confiança da rota (média, AWS) só aparece na UI.
        val assessment = GameReadinessEvaluator.evaluate(
            restSamples = rest.samples,
            loadSamples = usableLoad,
            profile = context.profileId,
            confidence = MeasurementConfidence.HIGH,
            gatewayOutcome = gatewayForVerdict ?: GatewayProbeOutcome.Unobservable,
            serverArchitecture = architecture,
            natSnapshot = nat,
            wifiBand = wifiBand
        )
        return CheckResult(context, assessment, rest.samples, usableLoad, null, gatewayTelemetry, wifiBand, nat)
    }

    private fun inconclusive(
        context: ResolvedMeasurementContext,
        rest: List<ProbeSample>,
        load: List<ProbeSample>?,
        reason: InconclusiveReason?,
        gateway: WiFiLocalTelemetry?,
        wifiBand: WiFiBandDiagnosticResult?
    ) = CheckResult(context, GameReadinessAssessment.INCONCLUSIVE, rest, load, reason, gateway, wifiBand, null)

    private fun progress(phase: CheckPhase, event: ProbeProgress, planned: Int): CheckProgress {
        val base = if (phase == CheckPhase.REST) 0f else 0.5f
        return when (event) {
            is ProbeProgress.Sent -> CheckProgress(phase, base + 0.5f * (event.sequence + 1) / planned, null)
            is ProbeProgress.Received -> CheckProgress(phase, base + 0.5f * (event.sample.sequence + 1) / planned, event.sample.roundTripMilliseconds)
        }
    }
}
