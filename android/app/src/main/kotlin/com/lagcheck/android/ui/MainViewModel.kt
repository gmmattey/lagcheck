package com.lagcheck.android.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.lagcheck.android.data.CheckHistoryItem
import com.lagcheck.android.data.HistoryRepository
import com.lagcheck.android.data.PreferencesRepository
import com.lagcheck.core.telemetry.radio.AndroidRadioTelemetryProvider
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.OfficialGameCatalog
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.domain.rules.GameReadinessEvaluator
import com.lagcheck.network.client.CloudflareWorkerClient
import com.lagcheck.network.engine.UdpMeasurementEngine
import kotlinx.coroutines.Job
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
    private val udpEngine = UdpMeasurementEngine()
    private val workerClient = CloudflareWorkerClient()
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
    private var loadJob: Job? = null
    private var hasConsentedMobileData: Boolean = false

    init {
        refreshRadioTelemetry()
    }

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
        loadJob?.cancel()
        loadJob = null

        measurementJob = viewModelScope.launch {
            val collectedSamples = mutableListOf<ProbeSample>()
            val loadSamples = mutableListOf<ProbeSample>()

            _currentScreen.value = Screen.Measurement(
                game = targetGame,
                platform = platform,
                connectionType = connectionType,
                progressRatio = 0.04f,
                currentPingMs = null,
                isPhaseRest = true,
                isCancelled = false,
                showMobileDataConsent = false
            )

            try {
                udpEngine.executeMeasurement().collect { sample ->
                    collectedSamples.add(sample)
                    val totalPlanned = 30f
                    val ratio = (collectedSamples.size / totalPlanned).coerceIn(0.04f, 1f)
                    val latestPing = if (sample.isValidResponse) sample.roundTripMillis else null
                    val isRest = collectedSamples.size <= 18

                    if (!isRest) {
                        loadSamples.add(sample)
                        // Dispara estresse real de download via Cloudflare Worker (/v1/load)
                        if (loadJob == null) {
                            loadJob = launch {
                                try {
                                    workerClient.downloadLoadPayload(maxBytes = 5 * 1024 * 1024)
                                } catch (_: Exception) {
                                    // Falha no download de carga não quebra as amostras UDP
                                }
                            }
                        }
                    }

                    _currentScreen.value = Screen.Measurement(
                        game = targetGame,
                        platform = platform,
                        connectionType = connectionType,
                        progressRatio = ratio,
                        currentPingMs = latestPing,
                        isPhaseRest = isRest,
                        isCancelled = false,
                        showMobileDataConsent = false
                    )
                }

                // Finaliza download de estresse concorrente
                loadJob?.cancel()

                val evaluation = GameReadinessEvaluator.evaluate(
                    samples = collectedSamples,
                    loadSamples = loadSamples,
                    radioSnapshot = radioSnapshot,
                    platform = platform,
                    connectionType = connectionType
                )

                // Salva no repositório de histórico do dispositivo
                historyRepository.recordCheck(targetGame, evaluation)

                _currentScreen.value = Screen.Verdict(targetGame, evaluation)

            } catch (e: Exception) {
                loadJob?.cancel()
                _currentScreen.value = Screen.Measurement(
                    game = targetGame,
                    platform = platform,
                    connectionType = connectionType,
                    isCancelled = true,
                    showMobileDataConsent = false
                )
            }
        }
    }

    fun cancelCheck() {
        measurementJob?.cancel()
        loadJob?.cancel()
        _currentScreen.value = Screen.Home
    }

    fun retryCheck() {
        startCheck(_selectedGame.value, _selectedPlatform.value, _selectedConnectionType.value)
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
