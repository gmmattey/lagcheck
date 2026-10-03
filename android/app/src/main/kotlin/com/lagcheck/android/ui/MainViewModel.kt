package com.lagcheck.android.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.lagcheck.android.data.CheckHistoryItem
import com.lagcheck.android.data.FileCatalogCache
import com.lagcheck.android.data.HistoryRepository
import com.lagcheck.android.data.NetworkPathWatcher
import com.lagcheck.android.data.PreferencesRepository
import com.lagcheck.android.data.PrefsInstallationIdStore
import com.lagcheck.android.data.toAppLanguage
import com.lagcheck.catalog.CatalogPayload
import com.lagcheck.catalog.RemoteCatalogRepository
import com.lagcheck.core.telemetry.radio.AndroidRadioTelemetryProvider
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.FavoriteGames
import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.OfficialGameCatalog
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.domain.presentation.ReadinessLanguage
import com.lagcheck.domain.presentation.ReadinessPresenter
import com.lagcheck.network.health.PlatformHealth
import com.lagcheck.network.health.PlatformHealthClient
import com.lagcheck.network.transport.UdpProbeTransport
import com.lagcheck.network.worker.HttpCatalogFetcher
import com.lagcheck.network.worker.HttpLoadTransport
import com.lagcheck.session.CheckEnvironment
import com.lagcheck.session.CheckOrchestrator
import com.lagcheck.session.LocalDiagnostics
import com.lagcheck.session.LocalNetworkReport
import com.lagcheck.session.LocalNetworkReporter
import com.lagcheck.session.CheckPhase
import com.lagcheck.session.MeasurementPlanner
import com.lagcheck.session.PlanResult
import com.lagcheck.session.PlatformLabels
import com.lagcheck.session.TelemetryReporter
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

/** Por que um check foi cancelado. A tela diz a verdade sobre o motivo em vez de sempre dizer "a conexão mudou". */
enum class CancelReason { NETWORK_CHANGED, BACKGROUND, POOR_QUALITY, UNAVAILABLE }

fun CancelReason?.headline(): String = when (this) {
    null, CancelReason.NETWORK_CHANGED -> "A conexão mudou."
    CancelReason.BACKGROUND -> "O teste foi interrompido."
    CancelReason.POOR_QUALITY -> "Sem resposta suficiente do servidor."
    CancelReason.UNAVAILABLE -> "Rota indisponível agora."
}

sealed class Screen {
    data object Home : Screen()
    data object GameSelection : Screen()
    data class Measurement(
        val game: CatalogGame,
        val platform: String,
        val connectionType: String,
        val progressRatio: Float = 0f,
        val currentPingMs: Double? = null,
        val isPhaseRest: Boolean = true,
        val isCancelled: Boolean = false,
        val showMobileDataConsent: Boolean = false,
        val cancelReason: CancelReason? = null,
        val destinationName: String = ""
    ) : Screen()
    data class Verdict(
        val game: CatalogGame,
        val evaluation: GameReadinessEvaluation
    ) : Screen()
    data class TechnicalDetails(
        val game: CatalogGame,
        val evaluation: GameReadinessEvaluation,
        val fromHistory: Boolean = false
    ) : Screen()
    data object History : Screen()
    data object Settings : Screen()
    data object NetworkCockpit : Screen()
}

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val radioTelemetryProvider = AndroidRadioTelemetryProvider(application)
    private val localDiagnostics = LocalDiagnostics()
    private val orchestrator = CheckOrchestrator(UdpProbeTransport(), HttpLoadTransport(), localDiagnostics)
    private val localReporter = LocalNetworkReporter(localDiagnostics)
    private val pathWatcher = NetworkPathWatcher(application)
    private val telemetry = TelemetryReporter(viewModelScope, PrefsInstallationIdStore(application))

    // Catálogo assinado: base embarcada no APK + atualização diária. Só sai daqui payload já verificado.
    private val catalogRepository = RemoteCatalogRepository(
        baseEnvelope = application.assets.open("catalog-base.json").use { it.readBytes() },
        fetcher = HttpCatalogFetcher(),
        cache = FileCatalogCache(application)
    )
    @Volatile
    private var catalog: Deferred<CatalogPayload?> = viewModelScope.async(Dispatchers.IO) { loadCatalog() }
    private val historyRepository = HistoryRepository(application)
    private val preferencesRepository = PreferencesRepository(application)

    private val _currentScreen = MutableStateFlow<Screen>(Screen.Home)
    val currentScreen: StateFlow<Screen> = _currentScreen.asStateFlow()

    private val _selectedGame = MutableStateFlow(
        OfficialGameCatalog.findById(preferencesRepository.selectedGameId.value)
    )
    val selectedGame: StateFlow<CatalogGame> = _selectedGame.asStateFlow()

    private val _selectedPlatform = MutableStateFlow(preferencesRepository.selectedPlatform.value)
    val selectedPlatform: StateFlow<String> = _selectedPlatform.asStateFlow()

    private val _selectedConnectionType = MutableStateFlow(preferencesRepository.selectedConnectionType.value)
    val selectedConnectionType: StateFlow<String> = _selectedConnectionType.asStateFlow()

    val historyItems: StateFlow<List<CheckHistoryItem>> = historyRepository.history

    val latestCheck: StateFlow<CheckHistoryItem?> = historyRepository.history.map {
        it.firstOrNull()
    }.stateIn(viewModelScope, SharingStarted.Eagerly, historyRepository.history.value.firstOrNull())

    val language: StateFlow<String> = preferencesRepository.language

    val favorites: StateFlow<FavoriteGames> = preferencesRepository.favorites
    fun toggleFavorite(gameId: String) = preferencesRepository.toggleFavorite(gameId)

    // Status público da rede do console escolhido (PSN/Xbox/Nintendo). Nulo = nada a avisar (inclui falha de leitura).
    private val platformHealthClient = PlatformHealthClient()
    private val _platformHealth = MutableStateFlow<PlatformHealth?>(null)
    val platformHealth: StateFlow<PlatformHealth?> = _platformHealth.asStateFlow()
    private var platformHealthJob: Job? = null

    private fun refreshPlatformHealth() {
        platformHealthJob?.cancel()
        val platform = PlatformLabels.toPlatform(_selectedPlatform.value)
        _platformHealth.value = null
        platformHealthJob = viewModelScope.launch(Dispatchers.IO) {
            _platformHealth.value = runCatching { platformHealthClient.check(platform) }.getOrNull()?.takeIf { it.isIssueReported }
        }
    }

    private val _liveRadioTelemetry = MutableStateFlow<RadioTelemetrySnapshot?>(null)
    val liveRadioTelemetry: StateFlow<RadioTelemetrySnapshot?> = _liveRadioTelemetry.asStateFlow()

    private val _localReport = MutableStateFlow<LocalNetworkReport?>(null)
    /** Leitura local do Cockpit (gateway, NAT, banda, voz). Nulo enquanto mede. */
    val localReport: StateFlow<LocalNetworkReport?> = _localReport.asStateFlow()

    private var localReportJob: Job? = null
    private var measurementJob: Job? = null
    private var hasConsentedMobileData: Boolean = false
    private var nextStartIsRetest: Boolean = false

    init {
        refreshRadioTelemetry()
        refreshPlatformHealth()
        telemetry.appOpen()
        // Atualização diária em segundo plano (fora da thread principal: verifica assinatura). Falha mantém o catálogo
        // que já era válido e nunca bloqueia a Home. Se chegou um catálogo novo, relê: uma base expirada não pode
        // deixar o app sem medir até reiniciar.
        viewModelScope.launch(Dispatchers.IO) {
            if (runCatching { catalogRepository.refreshIfDue() }.getOrDefault(false)) {
                catalog = async { loadCatalog() }
            }
        }
    }

    /** Catálogo vigente. Sem nenhum válido, tenta uma atualização na hora antes de desistir (nunca inventa destino). */
    private suspend fun currentCatalog(): CatalogPayload? {
        catalog.await()?.let { return it }
        val refreshed = runCatching { catalogRepository.refreshIfDue() }.getOrDefault(false)
        return if (refreshed) loadCatalog().also { catalog = viewModelScope.async { it } } else null
    }

    /** Catálogo base/cache validado, ou nulo se nenhum for válido (ex.: base expirada sem rede). Nulo = não mede. */
    private suspend fun loadCatalog(): CatalogPayload? =
        runCatching { catalogRepository.loadedCatalogForLaunch().payload }.getOrNull()

    fun navigateTo(screen: Screen) {
        _currentScreen.value = screen
        if (screen is Screen.NetworkCockpit) refreshLocalReport()
    }

    /** O que o aparelho sabe do ambiente local agora, vindo só do sistema operacional. */
    private fun environmentOf(radio: RadioTelemetrySnapshot?) = CheckEnvironment(
        isWiFi = radio?.transportType == RadioTelemetrySnapshot.TransportType.WIFI,
        gatewayAddress = radio?.gatewayAddress,
        localIp = radio?.localAddress,
        wifiRadio = radio?.wifiDetails
    )

    /** Mede gateway e NAT ao abrir o Cockpit (3 amostras no gateway, 2 consultas STUN). */
    private fun refreshLocalReport() {
        localReportJob?.cancel()
        refreshRadioTelemetry()
        val env = environmentOf(_liveRadioTelemetry.value)
        _localReport.value = null
        localReportJob = viewModelScope.launch(Dispatchers.IO) {
            _localReport.value = runCatching { localReporter.capture(env) }.getOrNull()
        }
    }

    fun selectGame(game: CatalogGame, platform: String, connectionType: String) {
        _selectedGame.value = game
        _selectedPlatform.value = platform
        // A conexão não é escolha da pessoa: vem do sistema (`refreshRadioTelemetry`). O parâmetro fica por compatibilidade.
        preferencesRepository.setSelectedGame(game.id)
        preferencesRepository.setSelectedPlatform(platform)
        refreshPlatformHealth()
    }

    fun setLanguage(lang: String) {
        preferencesRepository.setLanguage(lang)
    }

    fun clearHistory() {
        historyRepository.clearAll()
    }

    fun refreshRadioTelemetry() {
        val snapshot = radioTelemetryProvider.captureCurrentSnapshot()
        _liveRadioTelemetry.value = snapshot
        _selectedConnectionType.value = observedConnectionLabel(snapshot)
    }

    /** Conexão em uso, lida do sistema. Nunca vem de preferência da pessoa. */
    private fun observedConnectionLabel(radio: RadioTelemetrySnapshot?): String = when (radio?.transportType) {
        RadioTelemetrySnapshot.TransportType.WIFI -> "Wi-Fi"
        RadioTelemetrySnapshot.TransportType.CELLULAR -> "Dados móveis"
        RadioTelemetrySnapshot.TransportType.ETHERNET -> "Ethernet"
        else -> "—"
    }

    fun startCheck(
        targetGame: CatalogGame = _selectedGame.value,
        platform: String = _selectedPlatform.value,
        connectionType: String = _selectedConnectionType.value
    ) {
        selectGame(targetGame, platform, connectionType)
        refreshRadioTelemetry()
        val radioSnapshot = _liveRadioTelemetry.value
        val observedConnection = observedConnectionLabel(radioSnapshot)

        // O aviso de dados móveis depende do que o sistema reporta, não do que foi escolhido na tela.
        val isMobile = radioSnapshot?.transportType == RadioTelemetrySnapshot.TransportType.CELLULAR

        // Se for conexão móvel e ainda não confirmou consentimento de dados, exibe sheet
        if (isMobile && !hasConsentedMobileData) {
            _currentScreen.value = Screen.Measurement(
                game = targetGame,
                platform = platform,
                connectionType = observedConnection,
                showMobileDataConsent = true
            )
            return
        }

        executeActualCheck(targetGame, platform, observedConnection, radioSnapshot)
    }

    fun confirmMobileDataAndStart() {
        hasConsentedMobileData = true
        refreshRadioTelemetry()
        executeActualCheck(_selectedGame.value, _selectedPlatform.value, _selectedConnectionType.value, _liveRadioTelemetry.value)
    }

    private fun executeActualCheck(
        targetGame: CatalogGame,
        platform: String,
        connectionType: String,
        radioSnapshot: RadioTelemetrySnapshot?
    ) {
        measurementJob?.cancel()
        hasConsentedMobileData = false // o consentimento vale para esta sessão de medição, não para as próximas

        val isRetest = nextStartIsRetest
        nextStartIsRetest = false
        val platformEnum = PlatformLabels.toPlatform(platform)
        if (isRetest) telemetry.retestStarted(targetGame.id, platformEnum) else telemetry.checkStarted(targetGame.id, platformEnum)

        measurementJob = viewModelScope.launch {
            val job = this.coroutineContext[Job]
            var destinationLabel = ""
            fun measuring(ratio: Float, ping: Double?, rest: Boolean) {
                // Eventos tardios de um check já cancelado não podem sobrescrever a tela atual.
                if (job?.isActive == true) {
                    _currentScreen.value = Screen.Measurement(
                        game = targetGame, platform = platform, connectionType = connectionType,
                        progressRatio = ratio.coerceIn(0.04f, 1f), currentPingMs = ping, isPhaseRest = rest,
                        isCancelled = false, showMobileDataConsent = false, destinationName = destinationLabel
                    )
                }
            }
            fun cancelledScreen(reason: CancelReason) {
                _currentScreen.value = Screen.Measurement(
                    game = targetGame, platform = platform, connectionType = connectionType,
                    isCancelled = true, showMobileDataConsent = false, cancelReason = reason
                )
            }

            measuring(0.04f, null, true)

            val payload = currentCatalog()
            val plan = if (payload == null) null else MeasurementPlanner.plan(payload, targetGame.id, platform)
            if (payload == null || plan !is PlanResult.Ready) {
                // Sem catálogo válido ou sem rota ativa: não há destino confiável, então não existe nota nem fallback.
                cancelledScreen(CancelReason.UNAVAILABLE)
                return@launch
            }
            val regionLabel = payload.regions.firstOrNull { it.id == plan.context.regionId }
                ?.label?.get(readinessLanguage().catalogLabelKey()) ?: plan.context.regionId
            destinationLabel = regionLabel

            // Troca de rede durante a medição descarta o resultado parcial.
            pathWatcher.start { viewModelScope.launch { if (job?.isActive == true) { job?.cancel(); cancelledScreen(CancelReason.NETWORK_CHANGED) } } }
            try {
                var lastPing: Double? = null
                val result = orchestrator.run(plan.context, environmentOf(radioSnapshot)) { p ->
                    if (p.latestPingMs != null) lastPing = p.latestPingMs
                    measuring(p.ratio, lastPing, p.phase == CheckPhase.REST)
                }

                // Conexão que caiu no meio (watchdog) é cancelamento por integridade, não veredito.
                if (result.abortReason != null) {
                    cancelledScreen(CancelReason.POOR_QUALITY)
                    return@launch
                }

                val evaluation = ReadinessPresenter.present(
                    assessment = result.assessment,
                    language = readinessLanguage(),
                    platform = platform,
                    connectionType = connectionType,
                    destinationName = "$regionLabel · rota regional de referência",
                    confidence = plan.context.confidence,
                    latencySeries = result.latencySeries,
                    radio = radioSnapshot,
                    regionLabel = regionLabel,
                    // Onde a fase sob carga começa na série. Sem carga medida, não há trecho "sob carga" para rotular.
                    loadStartIndex = if (result.loadMeasured) result.restSamples.count { it.isValidResponse } else null
                )

                // Só resultado concluído entra no histórico (inconclusivo não vira registro, como no iOS).
                if (evaluation.verdict != GameReadinessVerdict.INCONCLUSIVE) {
                    historyRepository.recordCheck(targetGame, evaluation)
                }
                telemetry.verdictViewed(targetGame.id, platformEnum, evaluation.verdict)
                _currentScreen.value = Screen.Verdict(targetGame, evaluation)
            } finally {
                pathWatcher.stop()
            }
        }
    }

    private fun readinessLanguage(): ReadinessLanguage = language.value.toAppLanguage()

    /** Chave do idioma nos rótulos de região do catálogo (`pt-BR`, `en`, `es`). */
    private fun ReadinessLanguage.catalogLabelKey(): String = when (this) {
        ReadinessLanguage.PT_BR -> "pt-BR"
        ReadinessLanguage.EN -> "en"
        ReadinessLanguage.ES -> "es"
    }

    /** Fechar o app ou ir para segundo plano durante a medição descarta o resultado parcial. */
    fun onAppBackgrounded() {
        val screen = _currentScreen.value
        if (screen is Screen.Measurement && !screen.isCancelled && !screen.showMobileDataConsent) {
            measurementJob?.cancel()
            pathWatcher.stop()
            _currentScreen.value = screen.copy(isCancelled = true, cancelReason = CancelReason.BACKGROUND)
        }
    }

    fun cancelCheck() {
        measurementJob?.cancel()
        pathWatcher.stop()
        _currentScreen.value = Screen.Home
    }

    fun retryCheck() {
        nextStartIsRetest = true
        startCheck(_selectedGame.value, _selectedPlatform.value, _selectedConnectionType.value)
    }

    override fun onCleared() {
        pathWatcher.stop()
        super.onCleared()
    }

    fun openLatestResult() {
        val check = latestCheck.value ?: return
        val game = OfficialGameCatalog.findById(check.gameId)
        val evaluation = GameReadinessEvaluation(
            verdict = check.verdict,
            headline = ReadinessPresenter.verdictCopy(check.verdict, readinessLanguage()).first,
            subtitle = ReadinessPresenter.verdictCopy(check.verdict, readinessLanguage()).second,
            score = check.score,
            primaryWeight = check.primaryWeight,
            suitableUses = check.suitableUses,
            pingMs = check.pingMs,
            jitterMs = check.jitterMs,
            packetLossPercentage = check.packetLossPercentage,
            worstSpikeMs = check.worstSpikeMs,
            isUnderLoadAffected = false,
            findings = check.findings,
            latencySeries = check.latencySeries,
            platform = check.platform,
            connectionType = check.connectionType,
            timestamp = check.timestamp
        )
        _currentScreen.value = Screen.TechnicalDetails(game, evaluation, fromHistory = false)
    }

    fun openCheckDetails(check: CheckHistoryItem) {
        val game = OfficialGameCatalog.findById(check.gameId)
        val evaluation = GameReadinessEvaluation(
            verdict = check.verdict,
            headline = ReadinessPresenter.verdictCopy(check.verdict, readinessLanguage()).first,
            subtitle = ReadinessPresenter.verdictCopy(check.verdict, readinessLanguage()).second,
            score = check.score,
            primaryWeight = check.primaryWeight,
            suitableUses = check.suitableUses,
            pingMs = check.pingMs,
            jitterMs = check.jitterMs,
            packetLossPercentage = check.packetLossPercentage,
            worstSpikeMs = check.worstSpikeMs,
            isUnderLoadAffected = false,
            findings = check.findings,
            latencySeries = check.latencySeries,
            platform = check.platform,
            connectionType = check.connectionType,
            timestamp = check.timestamp
        )
        _currentScreen.value = Screen.TechnicalDetails(game, evaluation, fromHistory = true)
    }
}
