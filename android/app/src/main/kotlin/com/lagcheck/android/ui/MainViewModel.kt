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
import com.lagcheck.catalog.CatalogPayload
import com.lagcheck.catalog.RemoteCatalogRepository
import com.lagcheck.core.telemetry.radio.AndroidRadioTelemetryProvider
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.OfficialGameCatalog
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.domain.presentation.ReadinessLanguage
import com.lagcheck.domain.presentation.ReadinessPresenter
import com.lagcheck.network.transport.UdpProbeTransport
import com.lagcheck.network.worker.HttpCatalogFetcher
import com.lagcheck.network.worker.HttpLoadTransport
import com.lagcheck.session.CheckOrchestrator
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
        val showMobileDataConsent: Boolean = false
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
    private val orchestrator = CheckOrchestrator(UdpProbeTransport(), HttpLoadTransport())
    private val pathWatcher = NetworkPathWatcher(application)
    private val telemetry = TelemetryReporter(viewModelScope, PrefsInstallationIdStore(application))

    // Catálogo assinado: base embarcada no APK + atualização diária. Só sai daqui payload já verificado.
    private val catalogRepository = RemoteCatalogRepository(
        baseEnvelope = application.assets.open("catalog-base.json").use { it.readBytes() },
        fetcher = HttpCatalogFetcher(),
        cache = FileCatalogCache(application)
    )
    private val catalog: Deferred<CatalogPayload?> = viewModelScope.async(Dispatchers.IO) { loadCatalog() }
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

    private val _liveRadioTelemetry = MutableStateFlow<RadioTelemetrySnapshot?>(null)
    val liveRadioTelemetry: StateFlow<RadioTelemetrySnapshot?> = _liveRadioTelemetry.asStateFlow()

    private var measurementJob: Job? = null
    private var hasConsentedMobileData: Boolean = false
    private var nextStartIsRetest: Boolean = false

    init {
        refreshRadioTelemetry()
        telemetry.appOpen()
        viewModelScope.launch {
            // Atualização diária em segundo plano; falha mantém o catálogo que já era válido e nunca bloqueia a Home.
            runCatching { catalogRepository.refreshIfDue() }
        }
    }

    /** Catálogo base/cache validado, ou nulo se nenhum for válido (ex.: base expirada sem rede). Nulo = não mede. */
    private suspend fun loadCatalog(): CatalogPayload? =
        runCatching { catalogRepository.loadedCatalogForLaunch().payload }.getOrNull()

    fun navigateTo(screen: Screen) {
        _currentScreen.value = screen
    }

    fun selectGame(game: CatalogGame, platform: String, connectionType: String) {
        _selectedGame.value = game
        _selectedPlatform.value = platform
        _selectedConnectionType.value = connectionType
        preferencesRepository.setSelectedGame(game.id)
        preferencesRepository.setSelectedPlatform(platform)
        preferencesRepository.setSelectedConnectionType(connectionType)
    }

    fun setLanguage(lang: String) {
        preferencesRepository.setLanguage(lang)
    }

    fun clearHistory() {
        historyRepository.clearAll()
    }

    fun refreshRadioTelemetry() {
        _liveRadioTelemetry.value = radioTelemetryProvider.captureCurrentSnapshot()
    }

    fun startCheck(
        targetGame: CatalogGame = _selectedGame.value,
        platform: String = _selectedPlatform.value,
        connectionType: String = _selectedConnectionType.value
    ) {
        selectGame(targetGame, platform, connectionType)
        refreshRadioTelemetry()
        val radioSnapshot = _liveRadioTelemetry.value

        val isMobile = connectionType.contains("4G", ignoreCase = true) ||
                connectionType.contains("5G", ignoreCase = true) ||
                radioSnapshot?.transportType == RadioTelemetrySnapshot.TransportType.CELLULAR

        // Se for conexão móvel e ainda não confirmou consentimento de dados, exibe sheet
        if (isMobile && !hasConsentedMobileData) {
            _currentScreen.value = Screen.Measurement(
                game = targetGame,
                platform = platform,
                connectionType = connectionType,
                showMobileDataConsent = true
            )
            return
        }

        executeActualCheck(targetGame, platform, connectionType, radioSnapshot)
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

        val isRetest = nextStartIsRetest
        nextStartIsRetest = false
        val platformEnum = PlatformLabels.toPlatform(platform)
        if (isRetest) telemetry.retestStarted(targetGame.id, platformEnum) else telemetry.checkStarted(targetGame.id, platformEnum)

        measurementJob = viewModelScope.launch {
            val job = this.coroutineContext[Job]
            fun measuring(ratio: Float, ping: Double?, rest: Boolean) {
                // Eventos tardios de um check já cancelado não podem sobrescrever a tela atual.
                if (job?.isActive == true) {
                    _currentScreen.value = Screen.Measurement(
                        game = targetGame, platform = platform, connectionType = connectionType,
                        progressRatio = ratio.coerceIn(0.04f, 1f), currentPingMs = ping, isPhaseRest = rest,
                        isCancelled = false, showMobileDataConsent = false
                    )
                }
            }
            fun cancelledScreen() {
                _currentScreen.value = Screen.Measurement(
                    game = targetGame, platform = platform, connectionType = connectionType,
                    isCancelled = true, showMobileDataConsent = false
                )
            }

            measuring(0.04f, null, true)

            val payload = catalog.await()
            val plan = if (payload == null) null else MeasurementPlanner.plan(payload, targetGame.id, platform)
            if (payload == null || plan !is PlanResult.Ready) {
                // Sem catálogo válido ou sem rota ativa: não há destino confiável, então não existe nota nem fallback.
                cancelledScreen()
                return@launch
            }

            // Troca de rede durante a medição descarta o resultado parcial.
            pathWatcher.start { viewModelScope.launch { if (job?.isActive == true) { job?.cancel(); cancelledScreen() } } }
            try {
                var lastPing: Double? = null
                val result = orchestrator.run(plan.context) { p ->
                    if (p.latestPingMs != null) lastPing = p.latestPingMs
                    measuring(p.ratio, lastPing, p.phase == CheckPhase.REST)
                }

                // Conexão que caiu no meio (watchdog) é cancelamento por integridade, não veredito.
                if (result.abortReason != null) {
                    cancelledScreen()
                    return@launch
                }

                val route = payload.regions.firstOrNull { it.id == plan.context.regionId }
                val regionLabel = route?.label?.get("pt-BR") ?: plan.context.regionId
                val evaluation = ReadinessPresenter.present(
                    assessment = result.assessment,
                    language = readinessLanguage(),
                    platform = platform,
                    connectionType = connectionType,
                    destinationName = "$regionLabel · rota regional de referência",
                    confidence = plan.context.confidence,
                    latencySeries = result.latencySeries,
                    radio = radioSnapshot
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

    private fun readinessLanguage(): ReadinessLanguage = when {
        language.value.contains("English", ignoreCase = true) -> ReadinessLanguage.EN
        language.value.contains("Español", ignoreCase = true) -> ReadinessLanguage.ES
        else -> ReadinessLanguage.PT_BR
    }

    /** Fechar o app ou ir para segundo plano durante a medição descarta o resultado parcial. */
    fun onAppBackgrounded() {
        val screen = _currentScreen.value
        if (screen is Screen.Measurement && !screen.isCancelled && !screen.showMobileDataConsent) {
            measurementJob?.cancel()
            pathWatcher.stop()
            _currentScreen.value = screen.copy(isCancelled = true)
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
            headline = when (check.verdict) {
                com.lagcheck.domain.model.GameReadinessVerdict.READY -> "PRONTO PARA RANKED"
                com.lagcheck.domain.model.GameReadinessVerdict.CAUTION -> "CONDIÇÕES INSTÁVEIS"
                com.lagcheck.domain.model.GameReadinessVerdict.NOT_READY -> "EU EVITARIA RANKED AGORA"
                com.lagcheck.domain.model.GameReadinessVerdict.INCONCLUSIVE -> "DADOS INSUFICIENTES"
            },
            subtitle = "Sua conexão está estável o suficiente para ${game.name} agora.",
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
            headline = when (check.verdict) {
                com.lagcheck.domain.model.GameReadinessVerdict.READY -> "PRONTO PARA RANKED"
                com.lagcheck.domain.model.GameReadinessVerdict.CAUTION -> "CONDIÇÕES INSTÁVEIS"
                com.lagcheck.domain.model.GameReadinessVerdict.NOT_READY -> "EU EVITARIA RANKED AGORA"
                com.lagcheck.domain.model.GameReadinessVerdict.INCONCLUSIVE -> "DADOS INSUFICIENTES"
            },
            subtitle = "Sua conexão está estável o suficiente para ${game.name} agora.",
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
