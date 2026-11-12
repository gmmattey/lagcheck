package com.lagcheck.enginehost

import com.lagcheck.catalog.CatalogPayload
import com.lagcheck.catalog.GameContext
import com.lagcheck.catalog.Platform
import com.lagcheck.catalog.RemoteCatalogResolution
import com.lagcheck.catalog.RemoteCatalogResolver
import com.lagcheck.catalog.RemoteCatalogVerifier
import com.lagcheck.desktop.DesktopNetworkSupport
import com.lagcheck.desktop.DesktopArtwork
import com.lagcheck.desktop.DesktopPreferences
import com.lagcheck.desktop.Measurement
import com.lagcheck.desktop.update.UpdateCoordinator
import com.lagcheck.desktop.update.UpdateState
import com.lagcheck.desktop.analytics.Ga4Client
import com.lagcheck.desktop.analytics.ProductAnalyticsEvent
import com.lagcheck.desktop.analytics.InstallationId
import com.lagcheck.desktop.location.ApproxLocation
import com.lagcheck.desktop.location.IpLocationClient
import com.lagcheck.desktop.library.artwork.ArtworkResult
import com.lagcheck.desktop.library.artwork.ArtworkType
import com.lagcheck.desktop.library.launcher.GameLaunchResult
import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.repository.LibraryRepository
import com.lagcheck.domain.model.GameReadinessAssessment
import com.lagcheck.network.transport.UdpProbeTransport
import com.lagcheck.network.worker.HttpLoadTransport
import com.lagcheck.session.CheckOrchestrator
import com.lagcheck.session.CheckProgress
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonObjectBuilder
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.put
import java.util.concurrent.atomic.AtomicReference
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList
import java.io.BufferedReader
import java.io.BufferedWriter
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.nio.charset.StandardCharsets

/**
 * Fronteira local entre WinUI e o motor Kotlin. Não abre porta nem pipe de rede:
 * cada mensagem UTF-8 chega por stdin e cada resposta ocupa uma única linha em stdout.
 */
private const val PROTOCOL = "lagcheck-engine-v1"
internal enum class TerminalKind { COMPLETED, INCONCLUSIVE }
internal fun terminalKind(abortReason: String?): TerminalKind = if (abortReason == null) TerminalKind.COMPLETED else TerminalKind.INCONCLUSIVE

fun main() = EngineHost().run()

// Windows pode iniciar a JVM sob uma codepage legada; o contrato NDJSON é sempre UTF-8.
private val protocolInput = BufferedReader(InputStreamReader(System.`in`, StandardCharsets.UTF_8))
private val protocolOutput = BufferedWriter(OutputStreamWriter(System.out, StandardCharsets.UTF_8))
private fun readProtocolLine(): String? = protocolInput.readLine()
private fun writeProtocolLine(line: String) {
    protocolOutput.write(line)
    protocolOutput.newLine()
    protocolOutput.flush()
}

internal class EngineHost(
    private val input: () -> String? = ::readProtocolLine,
    private val output: (String) -> Unit = ::writeProtocolLine,
) {
    private val engine = DiagnosticEngine()
    private val library = LibraryBridge()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val outputLock = Any()
    private val activeSession = AtomicReference<ActiveSession?>(null)
    private val settings = SettingsBridge()
    private val history = CopyOnWriteArrayList<JsonObject>()
    private val analytics = Ga4Client()
    private val location = LocationBridge(settings)

    init {
        // Mantém a política existente: só consulta no ciclo de abertura quando a pessoa habilitou automático.
        if (settings.automaticUpdates()) scope.launch { settings.checkUpdate(force = false) }
    }

    fun run() {
        try {
            while (true) {
                val line = input() ?: break
                handle(line)
            }
        } finally {
            activeSession.getAndSet(null)?.job?.cancel()
            library.close()
            scope.cancel()
        }
    }

    private fun handle(line: String) {
        val command = try {
            HostJson.parse(line)
        } catch (_: Exception) {
            emitError(code = "INVALID_JSON", message = "Mensagem NDJSON inválida")
            return
        }
        val type = command.string("type")
        val requestId = command.string("requestId")
        when (type) {
            "hello" -> emit(HostJson.message("hello", requestId) {
                put("protocol", PROTOCOL)
                put("engine", "kotlin-jvm")
            })
            "start" -> start(command, requestId)
            "cancel" -> cancel(command, requestId)
            "library.snapshot" -> emitLibrarySnapshot(requestId)
            "library.rescan" -> libraryRescan(requestId)
            "library.favorite" -> libraryFavorite(command, requestId)
            "library.select" -> librarySelect(command, requestId)
            "library.launch" -> libraryLaunch(command, requestId)
            "library.artwork.refresh" -> libraryArtworkRefresh(command, requestId)
            "library.artwork.resolve" -> libraryArtworkResolve(command, requestId)
            "catalog.snapshot" -> emitCatalog(requestId)
            "history.snapshot" -> emitHistory(requestId)
            "settings.get" -> emitSettings(requestId)
            "settings.set" -> setSettings(command, requestId)
            "location.get" -> emitLocation(requestId, refresh = false)
            "location.refresh" -> emitLocation(requestId, refresh = true)
            "update.status" -> emitUpdate(requestId)
            "update.check" -> checkUpdate(requestId)
            "analytics.renew_id" -> renewAnalyticsId(requestId)
            else -> emitError(requestId, code = "UNKNOWN_COMMAND", message = "Comando não suportado")
        }
    }

    private fun start(command: JsonObject, requestId: String?) {
        val sessionId = command.string("sessionId")
        if (!sessionId.isValidId()) return emitError(requestId, sessionId, "INVALID_SESSION_ID", "sessionId é obrigatório")
        val validSessionId = requireNotNull(sessionId)
        if (activeSession.get() != null) return emitError(requestId, validSessionId, "SESSION_ACTIVE", "Já existe uma medição em andamento")
        val gameId = command.string("gameId")?.takeIf { it.isNotBlank() }
        val telemetry = SessionTelemetry(gameId ?: "generic-gaming", engine.regionId(gameId) ?: "unknown", System.nanoTime())
        val terminalEmitted = AtomicBoolean(false)
        val job = scope.launch(start = CoroutineStart.LAZY) {
            try {
                val result = engine.run(gameId) { emitProgress(validSessionId, it) }
                val abortReason = result.abortReason
                if (terminalKind(abortReason) == TerminalKind.INCONCLUSIVE || result.verdict == "inconclusive") {
                    trackOnce(telemetry) { ProductAnalyticsEvent.LagcheckInconclusive(telemetry.gameId, "pc", "unknown", result.regionId, abortReason ?: "verdict_inconclusive") }
                    clearActive(validSessionId)
                    terminalEmitted.set(true)
                    emitError(sessionId = validSessionId, code = "INCONCLUSIVE", message = "Medição inconclusiva")
                } else {
                    history += result.history(validSessionId, telemetry.gameId)
                    trackOnce(telemetry) { ProductAnalyticsEvent.LagcheckCompleted(telemetry.gameId, "pc", "unknown", result.regionId, result.verdict, telemetry.durationSeconds()) }
                    clearActive(validSessionId)
                    terminalEmitted.set(true)
                    emit(HostJson.message("result", sessionId = validSessionId) { result.putInto(this) })
                }
            } catch (cancelled: CancellationException) {
                trackOnce(telemetry) { ProductAnalyticsEvent.LagcheckCancelled(telemetry.gameId, "pc", "unknown", telemetry.regionId, "cancelled") }
                clearActive(validSessionId)
                terminalEmitted.set(true)
                emitError(sessionId = validSessionId, code = "CANCELLED", message = "Medição cancelada")
            } catch (error: EngineFailure) {
                clearActive(validSessionId)
                terminalEmitted.set(true)
                emitError(sessionId = validSessionId, code = error.code, message = error.message)
            } catch (_: Exception) {
                clearActive(validSessionId)
                terminalEmitted.set(true)
                emitError(sessionId = validSessionId, code = "ENGINE_FAILURE", message = "O motor não concluiu a medição")
            } finally {
                clearActive(validSessionId)
            }
        }
        val active = ActiveSession(validSessionId, job, telemetry)
        if (!activeSession.compareAndSet(null, active)) {
            job.cancel()
            emitError(requestId, validSessionId, "SESSION_ACTIVE", "Já existe uma medição em andamento")
            return
        }
        // Job lazy cancelado antes de start() não entra no catch; este callback ainda entrega o terminal obrigatório.
        job.invokeOnCompletion { cause ->
            if (cause is CancellationException && terminalEmitted.compareAndSet(false, true)) {
                clearActive(validSessionId)
                emitError(sessionId = validSessionId, code = "CANCELLED", message = "Medição cancelada")
            }
        }
        emit(HostJson.message("started", requestId, validSessionId) { put("protocol", PROTOCOL) })
        track(ProductAnalyticsEvent.LagcheckStarted(telemetry.gameId, "pc", "unknown", telemetry.regionId))
        job.start()
    }

    private fun cancel(command: JsonObject, requestId: String?) {
        val sessionId = command.string("sessionId")
        val active = activeSession.get()
        if (sessionId == null || active?.sessionId != sessionId) {
            emitError(requestId, sessionId, "SESSION_NOT_FOUND", "Nenhuma medição ativa com este sessionId")
            return
        }
        active.job.cancel()
        emit(HostJson.message("cancelled", requestId, sessionId))
    }

    private fun libraryRescan(requestId: String?) {
        val job = library.rescan()
        emitLibrarySnapshot(requestId)
        job.invokeOnCompletion { emitLibrarySnapshot(null) }
    }

    private fun libraryFavorite(command: JsonObject, requestId: String?) {
        val id = command.string("id")
        val favorite = command.boolean("favorite")
        if (id.isNullOrBlank() || favorite == null) return emitError(requestId, code = "INVALID_LIBRARY_COMMAND", message = "id e favorite são obrigatórios")
        when (library.setFavorite(id, favorite)) {
            LibraryAction.NotFound -> emitError(requestId, code = "GAME_NOT_FOUND", message = "Jogo não encontrado")
            LibraryAction.Done -> emitLibrarySnapshot(requestId)
        }
    }

    private fun librarySelect(command: JsonObject, requestId: String?) {
        val id = command.string("id") ?: return emitError(requestId, code = "INVALID_LIBRARY_COMMAND", message = "id é obrigatório")
        when (library.select(id)) {
            LibraryAction.NotFound -> emitError(requestId, code = "GAME_NOT_FOUND", message = "Jogo não encontrado")
            LibraryAction.Done -> emitLibrarySnapshot(requestId)
        }
    }

    private fun libraryLaunch(command: JsonObject, requestId: String?) {
        val id = command.string("id") ?: return emitError(requestId, code = "INVALID_LIBRARY_COMMAND", message = "id é obrigatório")
        when (val result = library.launch(id)) {
            is LaunchAction.NotFound -> emitError(requestId, code = "GAME_NOT_FOUND", message = "Jogo não encontrado")
            is LaunchAction.Done -> {
                emit(HostJson.message("library.launch", requestId) {
                    put("started", result.started)
                    put("message", result.message)
                    put("snapshot", library.snapshot())
                })
            }
        }
    }

    private fun libraryArtworkRefresh(command: JsonObject, requestId: String?) {
        val id = command.string("id") ?: return emitError(requestId, code = "INVALID_LIBRARY_COMMAND", message = "id é obrigatório")
        if (!library.hasGame(id)) return emitError(requestId, code = "GAME_NOT_FOUND", message = "Jogo não encontrado")
        emit(HostJson.message("library.artwork.refreshing", requestId) { put("id", id) })
        scope.launch {
            when (val result = library.refreshArtwork(id)) {
                ArtworkAction.NotFound -> emitError(requestId, code = "GAME_NOT_FOUND", message = "Jogo não encontrado")
                is ArtworkAction.Done -> emit(HostJson.message("library.artwork", requestId) {
                    put("id", id)
                    result.coverPath?.let { put("coverArtworkPath", it) }
                    result.heroPath?.let { put("heroArtworkPath", it) }
                })
            }
        }
    }

    /** Resolve apenas capas visíveis: nunca varre nem baixa a biblioteca inteira na abertura. */
    private fun libraryArtworkResolve(command: JsonObject, requestId: String?) {
        val ids = (command["ids"] as? JsonArray).orEmpty()
            .mapNotNull { (it as? JsonPrimitive)?.contentOrNull }
            .distinct()
        if (ids.isEmpty() || ids.size > 8) return emitError(requestId, code = "INVALID_ARTWORK_REQUEST", message = "ids deve ter entre 1 e 8 jogos visíveis")
        val known = ids.filter(library::hasGame)
        if (known.isEmpty()) return emitError(requestId, code = "GAME_NOT_FOUND", message = "Nenhum jogo solicitado foi encontrado")
        emit(HostJson.message("library.artwork.resolving", requestId) { put("count", known.size) })
        scope.launch {
            var processed = 0
            var available = 0
            try {
                known.forEach { id ->
                    val result = runCatching { library.resolveArtwork(id) }.getOrElse { ArtworkAction.NotFound }
                    processed++
                    if (result is ArtworkAction.Done) {
                        if (result.coverPath != null || result.heroPath != null) available++
                        emitArtwork(requestId, id, result)
                    }
                }
            } finally {
                // Terminal correlacionado mesmo sem arte, falha pontual ou fallback neutro.
                emit(HostJson.message("library.artwork.resolved", requestId) {
                    put("count", processed)
                    put("available", available)
                })
            }
        }
    }

    private fun emitArtwork(requestId: String?, id: String, result: ArtworkAction.Done) = emit(HostJson.message("library.artwork", requestId) {
        put("id", id)
        result.coverPath?.let { put("coverArtworkPath", it) }
        result.heroPath?.let { put("heroArtworkPath", it) }
    })

    private fun emitLibrarySnapshot(requestId: String?) = emit(HostJson.message("library.snapshot", requestId) {
        put("snapshot", library.snapshot())
    })

    private fun emitCatalog(requestId: String?) = emit(HostJson.message("catalog.snapshot", requestId) {
        put("games", buildJsonArray {
            Measurement.games.forEach { game -> add(buildJsonObject {
                put("id", game.id); put("name", game.name)
                game.artworkResource?.let { put("artworkResource", it) }
                Measurement.measuredRegion(game.id)?.let { region -> put("regionId", region.id); put("regionLabel", region.label) }
            }) }
        })
    })

    private fun emitHistory(requestId: String?) = emit(HostJson.message("history.snapshot", requestId) {
        put("entries", JsonArray(history.toList()))
    })

    private fun emitSettings(requestId: String?) = emit(HostJson.message("settings", requestId) { put("settings", settings.snapshot()) })

    private fun setSettings(command: JsonObject, requestId: String?) {
        val values = command["settings"] as? JsonObject
            ?: return emitError(requestId, code = "INVALID_SETTINGS", message = "settings é obrigatório")
        settings.apply(values)
        emitSettings(requestId)
    }

    private fun emitLocation(requestId: String?, refresh: Boolean) {
        scope.launch {
            val value = if (refresh) location.refresh() else location.cached()
            emit(HostJson.message("location", requestId) {
                put("enabled", settings.locationEnabled())
                value?.let { put("city", it.city ?: ""); put("country", it.country ?: ""); put("latitude", it.lat); put("longitude", it.lon) }
            })
        }
    }

    private fun emitUpdate(requestId: String?) = emit(HostJson.message("update.status", requestId) { put("update", settings.updateSnapshot()) })
    private fun checkUpdate(requestId: String?) {
        scope.launch { settings.checkUpdate(force = true); emitUpdate(requestId) }
    }

    private fun renewAnalyticsId(requestId: String?) {
        // Não devolve o identificador à interface nem a logs; só substitui o arquivo local já usado pelo desktop.
        InstallationId.renew()
        emit(HostJson.message("analytics.id_renewed", requestId))
    }

    private fun track(event: ProductAnalyticsEvent) { scope.launch { analytics.send(event, settings.analyticsEnabled()) } }
    private fun trackOnce(session: SessionTelemetry, event: () -> ProductAnalyticsEvent) {
        if (session.terminalSent.compareAndSet(false, true)) track(event())
    }

    private fun emitProgress(sessionId: String, progress: CheckProgress) = emit(HostJson.message("progress", sessionId = sessionId) {
        put("phase", progress.phase.name.lowercase())
        put("ratio", progress.ratio)
        progress.latestPingMs?.let { put("latestPingMs", it) }
    })

    private fun emitError(requestId: String? = null, sessionId: String? = null, code: String, message: String) = emit(
        HostJson.message("error", requestId, sessionId) {
            put("code", code)
            put("message", message)
        }
    )

    private fun emit(message: JsonObject) = synchronized(outputLock) { output(HostJson.encode(message)) }

    /** Libera antes do evento terminal, para o cliente poder iniciar outra sessão ao recebê-lo. */
    private fun clearActive(sessionId: String) {
        val active = activeSession.get()
        if (active?.sessionId == sessionId) activeSession.compareAndSet(active, null)
    }

    private data class ActiveSession(val sessionId: String, val job: Job, val telemetry: SessionTelemetry)
    private data class SessionTelemetry(val gameId: String, val regionId: String, val startedAtNanos: Long, val terminalSent: AtomicBoolean = AtomicBoolean(false)) {
        fun durationSeconds(): Long = ((System.nanoTime() - startedAtNanos) / 1_000_000_000).coerceAtLeast(0)
    }
}

/** Apenas adapta tipos estáveis do core para o contrato; score e veredito não são recalculados aqui. */
private class DiagnosticEngine {
    private val orchestrator = CheckOrchestrator(UdpProbeTransport(), HttpLoadTransport())
    private val payload: CatalogPayload by lazy {
        val bytes = checkNotNull(DiagnosticEngine::class.java.getResourceAsStream("/catalog-base.json")) {
            "Catálogo embarcado ausente"
        }.use { it.readBytes() }
        RemoteCatalogVerifier.decodeBundled(bytes)
    }

    suspend fun run(gameId: String?, onProgress: (CheckProgress) -> Unit): EngineResult {
        val context = if (gameId == null) GameContext.genericGaming(platform = Platform.PC) else GameContext(gameId, "BR", Platform.PC)
        val resolved = RemoteCatalogResolver.resolve(context, payload) as? RemoteCatalogResolution.Available
            ?: throw EngineFailure("UNSUPPORTED_GAME", "Jogo indisponível para medição")
        return EngineResult(orchestrator.run(resolved.context, onProgress = onProgress))
    }
    fun regionId(gameId: String?): String? = runCatching {
        val context = if (gameId == null) GameContext.genericGaming(platform = Platform.PC) else GameContext(gameId, "BR", Platform.PC)
        (RemoteCatalogResolver.resolve(context, payload) as? RemoteCatalogResolution.Available)?.context?.regionId
    }.getOrNull()
}

private data class EngineResult(private val check: com.lagcheck.session.CheckResult) {
    val abortReason: String? get() = check.abortReason?.name?.lowercase()
    val regionId: String get() = check.context.regionId
    val verdict: String get() = check.assessment.verdict.rawValue
    fun putInto(target: kotlinx.serialization.json.JsonObjectBuilder) {
        val assessment = check.assessment
        target.put("status", "completed")
        target.put("verdict", assessment.verdict.rawValue)
        assessment.score?.let { target.put("score", it) }
        assessment.pingMs?.let { target.put("pingMs", it) }
        assessment.jitterMs?.let { target.put("jitterMs", it) }
        assessment.packetLossPercentage?.let { target.put("packetLossPercentage", it) }
        assessment.worstSpikeMs?.let { target.put("worstSpikeMs", it) }
        target.put("loadMeasured", check.loadMeasured)
        target.put("regionId", check.context.regionId)
        target.put("profileId", check.context.profileId.rawValue)
        check.abortReason?.let { target.put("abortReason", it.name) }
        target.put("latencySeries", buildJsonArray { check.latencySeries.forEach { add(JsonPrimitive(it)) } })
    }

    fun history(sessionId: String, gameId: String? = null): JsonObject = buildJsonObject {
        put("sessionId", sessionId)
        if (!gameId.isNullOrBlank()) put("gameId", gameId)
        put("verdict", check.assessment.verdict.rawValue)
        check.assessment.score?.let { put("score", it) }
        check.assessment.pingMs?.let { put("pingMs", it) }
        check.assessment.jitterMs?.let { put("jitterMs", it) }
        check.assessment.packetLossPercentage?.let { put("packetLossPercentage", it) }
        put("regionId", check.context.regionId)
        put("profileId", check.context.profileId.rawValue)
        put("loadMeasured", check.loadMeasured)
    }
}

private class EngineFailure(val code: String, override val message: String) : RuntimeException(message)

private class LibraryBridge {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val repository = LibraryRepository(scope, networkResolver = DesktopNetworkSupport.resolver, autoScan = false)
    private val artwork = ConcurrentHashMap<String, ArtworkPaths>()

    fun rescan(): Job = repository.rescan()
    fun close() = scope.cancel()

    fun setFavorite(id: String, favorite: Boolean): LibraryAction {
        val game = find(id) ?: return LibraryAction.NotFound
        if (game.isFavorite != favorite) repository.toggleFavorite(game)
        return LibraryAction.Done
    }

    fun select(id: String): LibraryAction {
        val game = find(id) ?: return LibraryAction.NotFound
        repository.selectGame(game)
        return LibraryAction.Done
    }

    fun launch(id: String): LaunchAction {
        val game = find(id) ?: return LaunchAction.NotFound
        return when (val result = repository.launch(game)) {
            is GameLaunchResult.Success -> LaunchAction.Done(true, result.message)
            is GameLaunchResult.Failure -> LaunchAction.Done(false, result.reason)
        }
    }

    fun hasGame(id: String): Boolean = find(id) != null

    /** Respeita a preferência existente de download e devolve apenas caminhos locais do cache. */
    suspend fun refreshArtwork(id: String): ArtworkAction {
        val game = find(id) ?: return ArtworkAction.NotFound
        DesktopArtwork.resolver.refresh(game)
        return resolveArtwork(game)
    }

    /** Cache e fontes do launcher primeiro; acesso remoto só ocorre se a preferência existente autorizar. */
    suspend fun resolveArtwork(id: String): ArtworkAction {
        val game = find(id) ?: return ArtworkAction.NotFound
        return resolveArtwork(game)
    }

    private suspend fun resolveArtwork(game: PcGame): ArtworkAction {
        val cover = DesktopArtwork.resolver.resolve(game, ArtworkType.COVER).pathOrNull()
        val hero = DesktopArtwork.resolver.resolve(game, ArtworkType.HERO).pathOrNull()
        artwork[game.id] = ArtworkPaths(cover, hero)
        return ArtworkAction.Done(cover, hero)
    }

    fun snapshot(): JsonObject = buildJsonObject {
        put("isScanning", repository.isScanning)
        put("hasScanned", repository.hasScanned)
        repository.selectedGame?.id?.let { put("heroGameId", it); put("selectedGameId", it) }
        put("games", buildJsonArray { repository.games.forEach { add(it.toJson(artwork[it.id])) } })
    }

    private fun find(id: String): PcGame? = repository.games.firstOrNull { it.id == id || id in it.alsoIds }
}

/** Cada escrita preserva as demais chaves do arquivo de preferências existente. */
private class SettingsBridge {
    private val updates = UpdateCoordinator()
    private var reduceMotion = false // O Compose atual não persiste esta preferência.

    init { DesktopArtwork.downloadEnabled = DesktopPreferences.artworkDownloadEnabled() }

    fun snapshot(): JsonObject = buildJsonObject {
        put("reduceMotion", reduceMotion)
        put("artworkDownloadEnabled", DesktopPreferences.artworkDownloadEnabled())
        put("approximateLocationEnabled", DesktopPreferences.locationEnabled())
        put("analyticsEnabled", DesktopPreferences.analyticsEnabled())
        put("automaticUpdates", updates.automatic)
    }

    fun apply(values: JsonObject) {
        values.boolean("reduceMotion")?.let { reduceMotion = it }
        values.boolean("artworkDownloadEnabled")?.let {
            DesktopPreferences.setArtworkDownloadEnabled(it)
            DesktopArtwork.downloadEnabled = it
        }
        values.boolean("approximateLocationEnabled")?.let { DesktopPreferences.setLocationEnabled(it) }
        values.boolean("analyticsEnabled")?.let { DesktopPreferences.changeAnalyticsEnabled(it) }
        values.boolean("automaticUpdates")?.let { updates.changeAutomatic(it) }
    }

    fun analyticsEnabled(): Boolean = DesktopPreferences.analyticsEnabled()
    fun locationEnabled(): Boolean = DesktopPreferences.locationEnabled()
    fun checkUpdate(force: Boolean) = updates.check(force)
    fun automaticUpdates(): Boolean = updates.automatic
    fun updateSnapshot(): JsonObject = buildJsonObject {
        put("configured", com.lagcheck.desktop.update.UpdateSourceConfig.current().configured)
        updates.lastChecked?.let { put("lastCheckedEpochMs", it.toEpochMilli()) }
        when (val state = updates.state) {
            UpdateState.Nenhuma -> put("state", "none")
            UpdateState.Falha -> put("state", "failed")
            is UpdateState.Disponivel -> { put("state", "available"); put("version", state.release.version) }
            is UpdateState.Baixando -> { put("state", "downloading"); put("version", state.release.version) }
            is UpdateState.Pronta -> { put("state", "ready"); put("version", state.release.version) }
        }
    }
}

/** Localização aproximada continua opcional e só alimenta apresentação de rota, nunca score/veredito. */
private class LocationBridge(private val settings: SettingsBridge, private val client: IpLocationClient = IpLocationClient()) {
    fun cached(): ApproxLocation? = if (settings.locationEnabled()) client.cached() else null
    fun refresh(): ApproxLocation? = if (settings.locationEnabled()) client.fetch() else null
}

private sealed interface LibraryAction { data object Done : LibraryAction; data object NotFound : LibraryAction }
private sealed interface LaunchAction {
    data class Done(val started: Boolean, val message: String) : LaunchAction
    data object NotFound : LaunchAction
}
private sealed interface ArtworkAction {
    data class Done(val coverPath: String?, val heroPath: String?) : ArtworkAction
    data object NotFound : ArtworkAction
}
private data class ArtworkPaths(val cover: String?, val hero: String?)

private fun PcGame.toJson(artwork: ArtworkPaths?): JsonObject = buildJsonObject {
    put("id", id)
    put("title", title)
    put("platform", platform.name.lowercase())
    put("isInstalled", isInstalled)
    put("isFavorite", isFavorite)
    put("isLaunchable", !launchUri.isNullOrBlank() || !executablePath.isNullOrBlank())
    lastPlayedEpochMs?.let { put("lastPlayedEpochMs", it) }
    lastLaunchedEpochMs?.let { put("lastLaunchedEpochMs", it) }
    installedAtEpochMs?.let { put("installedAtEpochMs", it) }
    // A UI WinUI só recebe caminho local aprovado pelo host. URLs remotas nunca são entregues ao XAML.
    (artwork?.cover ?: localArtworkRes)?.let { put("coverArtworkPath", it) }
    (artwork?.hero ?: localArtworkRes)?.let { put("heroArtworkPath", it) }
    put("networkKind", networkSupport.kind())
    put("networkLabel", networkSupport.label())
    diagnosticGameId()?.let { put("diagnosticGameId", it) }
    put("tags", buildJsonArray { tags.forEach { add(JsonPrimitive(it)) } })
    description?.let { put("description", it) }
    put("alsoIds", buildJsonArray { alsoIds.forEach { add(JsonPrimitive(it)) } })
}

/** O identificador da loja nunca entra no motor: só o catálogo homologado pode contextualizar o Check. */
internal fun PcGame.diagnosticGameId(): String? =
    (networkSupport as? GameNetworkSupport.LagcheckSupported)?.catalogId?.takeIf { it.isNotBlank() }

private fun GameNetworkSupport.kind() = when (this) {
    is GameNetworkSupport.LagcheckSupported -> "lagcheckSupported"
    is GameNetworkSupport.GeneralConnectionOnly -> "generalConnectionOnly"
    is GameNetworkSupport.OfflineSingleplayer -> "offlineSingleplayer"
}
private fun GameNetworkSupport.label() = when (this) {
    is GameNetworkSupport.LagcheckSupported -> regionLabel ?: "Medição disponível"
    is GameNetworkSupport.GeneralConnectionOnly -> note
    is GameNetworkSupport.OfflineSingleplayer -> note
}
private fun ArtworkResult.pathOrNull(): String? = (this as? ArtworkResult.Available)?.path?.toAbsolutePath()?.toString()

private object HostJson {
    private val json = Json { explicitNulls = false }
    fun parse(line: String): JsonObject = json.parseToJsonElement(line).jsonObject
    fun encode(value: JsonObject): String = json.encodeToString(JsonObject.serializer(), value)
    fun message(type: String, requestId: String? = null, sessionId: String? = null, extra: JsonObjectBuilder.() -> Unit = {}): JsonObject =
        buildJsonObject {
            put("type", type)
            requestId?.let { put("requestId", it) }
            sessionId?.let { put("sessionId", it) }
            extra()
        }
}

private fun JsonObject.string(name: String): String? = (this[name] as? JsonPrimitive)?.contentOrNull
private fun JsonObject.boolean(name: String): Boolean? = (this[name] as? JsonPrimitive)?.booleanOrNull
private fun String?.isValidId() = !isNullOrBlank() && length <= 128 && all { it.isLetterOrDigit() || it in "-_." }
