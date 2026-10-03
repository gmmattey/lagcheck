package com.lagcheck.session

import com.lagcheck.catalog.Platform
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.network.worker.TelemetryClient
import com.lagcheck.network.worker.TelemetryEvent
import com.lagcheck.network.worker.TelemetryPlatform
import com.lagcheck.network.worker.TelemetryVerdict
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/** UUID anônimo de instalação. Sem PII, sem identificador de hardware, sem conta. */
interface InstallationIdStore {
    fun getOrCreate(): String
}

fun interface TelemetrySender {
    suspend fun send(installationId: String, event: TelemetryEvent, gameId: String?, platform: TelemetryPlatform?, verdict: TelemetryVerdict?): Boolean
}

/**
 * Funil mínimo de produto: app_open, check_started, verdict_viewed, retest_started. Fire-and-forget: falha de
 * telemetria nunca bloqueia medição, resultado nem histórico, e nunca lança exceção para quem chama.
 */
class TelemetryReporter(
    private val scope: CoroutineScope,
    private val ids: InstallationIdStore,
    private val sender: TelemetrySender
) {
    constructor(scope: CoroutineScope, ids: InstallationIdStore, client: TelemetryClient = TelemetryClient()) :
        this(scope, ids, { id, e, g, p, v -> client.send(id, e, g, p, v) })

    fun appOpen() = dispatch(TelemetryEvent.APP_OPEN, null, null, null)

    fun checkStarted(gameId: String, platform: Platform) = dispatch(TelemetryEvent.CHECK_STARTED, gameId, platform, null)

    fun verdictViewed(gameId: String, platform: Platform, verdict: GameReadinessVerdict) =
        dispatch(TelemetryEvent.VERDICT_VIEWED, gameId, platform, verdict)

    fun retestStarted(gameId: String, platform: Platform) = dispatch(TelemetryEvent.RETEST_STARTED, gameId, platform, null)

    private fun dispatch(event: TelemetryEvent, gameId: String?, platform: Platform?, verdict: GameReadinessVerdict?) {
        scope.launch {
            runCatching {
                sender.send(ids.getOrCreate(), event, gameId?.lowercase(), platform?.let(::wire), verdict?.let(::wire))
            }
        }
    }

    private fun wire(p: Platform): TelemetryPlatform? = when (p) {
        Platform.PLAYSTATION -> TelemetryPlatform.PLAYSTATION
        Platform.XBOX -> TelemetryPlatform.XBOX
        Platform.PC -> TelemetryPlatform.PC
        Platform.MOBILE, Platform.NINTENDO -> null // o Worker não aceita esses valores; o campo é omitido
    }

    private fun wire(v: GameReadinessVerdict) = when (v) {
        GameReadinessVerdict.READY -> TelemetryVerdict.READY
        GameReadinessVerdict.CAUTION -> TelemetryVerdict.CAUTION
        GameReadinessVerdict.NOT_READY -> TelemetryVerdict.NOT_READY
        GameReadinessVerdict.INCONCLUSIVE -> TelemetryVerdict.INCONCLUSIVE
    }
}
