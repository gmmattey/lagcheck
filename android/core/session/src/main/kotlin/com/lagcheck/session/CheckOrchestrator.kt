package com.lagcheck.session

import com.lagcheck.catalog.ProbeDestination
import com.lagcheck.catalog.ResolvedMeasurementContext
import com.lagcheck.domain.model.GameReadinessAssessment
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

data class CheckProgress(val phase: CheckPhase, val ratio: Float, val latestPingMs: Double?)

/** Resultado de uma sessão. `assessment` é inconclusivo quando não houve resposta UDP suficiente ou a conexão caiu. */
data class CheckResult(
    val context: ResolvedMeasurementContext,
    val assessment: GameReadinessAssessment,
    val restSamples: List<ProbeSample>,
    /** Nulo quando a carga não pôde ser medida (HTTP indisponível); o repouso continua válido. */
    val loadSamples: List<ProbeSample>?,
    val abortReason: InconclusiveReason?
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
    private val loadPlan: ProbePlan = ProbePlan()
) {
    constructor(transport: UdpProbeTransport, loadTransport: HttpLoadTransport) : this(
        { d, p, cb -> transport.collect(d, p, cb) },
        { loadTransport.transfer() }
    )

    suspend fun run(context: ResolvedMeasurementContext, onProgress: (CheckProgress) -> Unit = {}): CheckResult {
        val rest = probes.collect(context.destination, restPlan) { event -> onProgress(progress(CheckPhase.REST, event, restPlan.count)) }
        if (rest.aborted) return inconclusive(context, rest.samples, null, rest.abortReason)

        val (loadCollection, loadOutcome) = coroutineScope {
            val transfer = async { load.transfer() }
            val collected = probes.collect(context.destination, loadPlan) { event -> onProgress(progress(CheckPhase.LOAD, event, loadPlan.count)) }
            if (collected.aborted) transfer.cancel()
            collected to (if (collected.aborted) LoadOutcome.Unavailable else transfer.await())
        }
        // Conexão que morre sob carga cancela a sessão inteira, como no iOS: nada de "pronto" sobre uma rota que caiu.
        if (loadCollection.aborted) return inconclusive(context, rest.samples, loadCollection.samples, loadCollection.abortReason)

        val usableLoad = if (loadOutcome == LoadOutcome.Unavailable) null else loadCollection.samples
        // Paridade com o iOS: o veredito usa o padrão (confiança alta). A confiança da rota (média, AWS) só aparece na UI.
        val assessment = GameReadinessEvaluator.evaluate(
            restSamples = rest.samples,
            loadSamples = usableLoad,
            profile = context.profileId,
            confidence = MeasurementConfidence.HIGH
        )
        return CheckResult(context, assessment, rest.samples, usableLoad, null)
    }

    private fun inconclusive(
        context: ResolvedMeasurementContext,
        rest: List<ProbeSample>,
        load: List<ProbeSample>?,
        reason: InconclusiveReason?
    ) = CheckResult(context, GameReadinessAssessment.INCONCLUSIVE, rest, load, reason)

    private fun progress(phase: CheckPhase, event: ProbeProgress, planned: Int): CheckProgress {
        val base = if (phase == CheckPhase.REST) 0f else 0.5f
        return when (event) {
            is ProbeProgress.Sent -> CheckProgress(phase, base + 0.5f * (event.sequence + 1) / planned, null)
            is ProbeProgress.Received -> CheckProgress(phase, base + 0.5f * (event.sample.sequence + 1) / planned, event.sample.roundTripMilliseconds)
        }
    }
}
