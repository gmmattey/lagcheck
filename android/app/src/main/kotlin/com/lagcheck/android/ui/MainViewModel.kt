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
import com.lagcheck.android.widget.WidgetSnapshotStore
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
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.first
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
    data class ConnectionRequired(val game: CatalogGame) : Screen()
    data class RegionalSelection(
        val game: CatalogGame,
        val platform: String,
        val connectionType: String,
        val isConfirming: Boolean = true
    ) : Screen()
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
    data class HistoryDetails(
        val item: CheckHistoryItem,
        val fromHome: Boolean = false
    ) : Screen()
    data object History : Screen()
    data object Settings : Screen()
    data object NetworkCockpit : Screen()
}

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val radioTelemetryProvider = AndroidRadioTelemetryProvider(application)
    private val localDiagnostics = LocalDiagnostics()
    private val orchestrator = CheckOrchestrator(UdpProbeTransport(), HttpLoadTransport(), localDiagnostics)
    private val regionalPreReadCoordinator = com.lagcheck.session.RegionalPreReadCoordinator()
    private val routePreflight = com.lagcheck.network.preflight.SteamA2sRoutePreflight()
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
    private val _catalogPayload = MutableStateFlow<CatalogPayload?>(null)
    val games: StateFlow<List<CatalogGame>> = _catalogPayload.map { payload ->
        payload?.let(com.lagcheck.session.CatalogPresentation::games) ?: emptyList()
    }.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())
    private val historyRepository = HistoryRepository(application)
    private val preferencesRepository = PreferencesRepository(application)
    private val preMatchReminder = com.lagcheck.android.data.PreMatchReminder(application)
    private val _reminderEnabled = MutableStateFlow(preMatchReminder.enabled)
    val reminderEnabledState: StateFlow<Boolean> = _reminderEnabled.asStateFlow()
    private val _reminderPermissionDenied = MutableStateFlow(preMatchReminder.permissionDenied)
    val reminderPermissionDenied: StateFlow<Boolean> = _reminderPermissionDenied.asStateFlow()
    private var pendingReminderGameID: String? = null
    private val reviewPromptStore = com.lagcheck.android.data.PreferencesReviewPromptStore(application)
    private val reviewPromptCoordinator = com.lagcheck.session.ReviewPromptCoordinator(
        store = reviewPromptStore,
        appVersionProvider = {
            try {
                application.packageManager.getPackageInfo(application.packageName, 0).versionName ?: "1.0.0"
            } catch (_: Exception) {
                "1.0.0"
            }
        }
    )
    private val _reviewPromptTrigger = kotlinx.coroutines.channels.Channel<Unit>(kotlinx.coroutines.channels.Channel.BUFFERED)
    val reviewPromptTrigger: kotlinx.coroutines.flow.Flow<Unit> = _reviewPromptTrigger.receiveAsFlow()
    private var reviewPromptJob: Job? = null

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

    private val _declaredExternalLink = MutableStateFlow<com.lagcheck.domain.model.ExternalEquipmentLink?>(null)
    val declaredExternalLink: StateFlow<com.lagcheck.domain.model.ExternalEquipmentLink?> = _declaredExternalLink.asStateFlow()

    val historyItems: StateFlow<List<CheckHistoryItem>> = historyRepository.history

    val latestCheck: StateFlow<CheckHistoryItem?> = historyRepository.history.map {
        it.firstOrNull()
    }.stateIn(viewModelScope, SharingStarted.Eagerly, historyRepository.history.value.firstOrNull())

    val language: StateFlow<String> = preferencesRepository.language


    data class RegionCandidate(val id: String, val label: String)

    val regionCandidates: StateFlow<List<RegionCandidate>> = kotlinx.coroutines.flow.combine(
        _catalogPayload, language
    ) { payload, lang ->
        if (payload == null) return@combine emptyList()
        val langKey = lang.toAppLanguage().catalogLabelKey()
        val list = mutableListOf<RegionCandidate>()
        list.add(RegionCandidate("automatic", com.lagcheck.domain.presentation.UiStrings.translate("Automática", lang.toAppLanguage())))
        payload.regions.forEach { r ->
            list.add(RegionCandidate(r.id, r.label[langKey] ?: r.id))
        }
        list
    }.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    val manualRegionId: StateFlow<String?> = preferencesRepository.manualRegionId

    fun setManualRegionId(regionId: String?) {
        preferencesRepository.setManualRegionId(regionId)
    }

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
    private val _localReportLoading = MutableStateFlow(false)
    val localReportLoading: StateFlow<Boolean> = _localReportLoading.asStateFlow()

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
            publishCatalog(currentCatalog())
            if (runCatching { catalogRepository.refreshIfDue() }.getOrDefault(false)) {
                catalog = async { loadCatalog() }
            }
            publishCatalog(currentCatalog())
            val savedRegion = preferencesRepository.manualRegionId.value
            if (savedRegion != null && savedRegion != "automatic" &&
                _catalogPayload.value?.regions?.none { it.id == savedRegion } == true) {
                preferencesRepository.setManualRegionId(null)
            }
        }
    }

    private fun publishCatalog(payload: CatalogPayload?) {
        _catalogPayload.value = payload
        val available = payload?.let(com.lagcheck.session.CatalogPresentation::games) ?: return
        preMatchReminder.clearIfGameUnavailable(available.mapTo(mutableSetOf()) { it.id })
        _reminderEnabled.value = preMatchReminder.enabled
        pendingReminderGameID?.let { pending ->
            available.firstOrNull { it.id == pending }?.let { game ->
                pendingReminderGameID = null; chooseGame(game); navigateTo(Screen.Home)
            }
        }
        val selected = available.firstOrNull { it.id == preferencesRepository.selectedGameId.value }
            ?: available.firstOrNull() ?: return
        _selectedGame.value = selected
        // Sem escolha de dispositivo (Decisão 80): Mobile quando o jogo tem contexto Mobile, senão o primeiro.
        val routePlatform = selected.platforms.firstOrNull { it.equals("Mobile", ignoreCase = true) } ?: selected.platforms.first()
        if (_selectedPlatform.value != routePlatform) _selectedPlatform.value = routePlatform
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
        reviewPromptJob?.cancel()
        reviewPromptJob = null
        com.lagcheck.android.data.RemoteArtworkRepository.setDownloadsEnabled(
            screen is Screen.Home || screen is Screen.GameSelection || screen is Screen.History
        )
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
    fun refreshLocalReport() {
        localReportJob?.cancel()
        refreshRadioTelemetry()
        val env = environmentOf(_liveRadioTelemetry.value)
        _localReport.value = null
        _localReportLoading.value = true
        localReportJob = viewModelScope.launch(Dispatchers.IO) {
            val job = coroutineContext[Job]
            try {
                val result = runCatching { localReporter.capture(env) }
                    .getOrDefault(LocalNetworkReport(null, null, null))
                if (localReportJob === job) _localReport.value = result
            } finally {
                if (localReportJob === job) _localReportLoading.value = false
            }
        }
    }

    fun selectGame(game: CatalogGame, platform: String, connectionType: String, declaredExternalLink: com.lagcheck.domain.model.ExternalEquipmentLink? = null) {
        _selectedGame.value = game
        _selectedPlatform.value = platform
        _declaredExternalLink.value = declaredExternalLink.takeIf { PlatformLabels.toPlatform(platform) != com.lagcheck.catalog.Platform.MOBILE }
        // A conexão não é escolha da pessoa: vem do sistema (`refreshRadioTelemetry`). O parâmetro fica por compatibilidade.
        preferencesRepository.setSelectedGame(game.id)
        preferencesRepository.setSelectedPlatform(platform)
        refreshPlatformHealth()
    }

    /**
     * Escolhe o jogo atual sem perguntar dispositivo (Decisão 80): o aparelho é o celular.
     * A plataforma de rota vem do catálogo: Mobile quando existir, senão o primeiro contexto do jogo.
     */
    fun chooseGame(game: CatalogGame) {
        val platform = game.platforms.firstOrNull { it.equals("Mobile", ignoreCase = true) }
            ?: game.platforms.firstOrNull()
            ?: "Mobile"
        selectGame(game, platform, _selectedConnectionType.value, null)
    }

    fun setLanguage(lang: String) {
        preferencesRepository.setLanguage(lang)
        if (preMatchReminder.enabled) preMatchReminder.gameId?.let { preMatchReminder.schedule(it, preMatchReminder.hour, preMatchReminder.minute) }
    }

    fun reminderEnabled(): Boolean = _reminderEnabled.value
    fun reminderHour(): Int = preMatchReminder.hour
    fun reminderMinute(): Int = preMatchReminder.minute
    fun enableReminder() { preMatchReminder.markPermissionGranted(); preMatchReminder.schedule(_selectedGame.value.id); _reminderEnabled.value = true; _reminderPermissionDenied.value = false }
    fun changeReminderTime(hour: Int, minute: Int) { preMatchReminder.gameId?.let { preMatchReminder.schedule(it, hour, minute) } }
    fun disableReminder() { preMatchReminder.cancel(); _reminderEnabled.value = false }
    fun reminderPermissionDenied() { preMatchReminder.markPermissionDenied(); _reminderEnabled.value = false; _reminderPermissionDenied.value = true }
    fun refreshReminderPermission(granted: Boolean) {
        if (granted) { preMatchReminder.markPermissionGranted(); _reminderPermissionDenied.value = false }
        else if (preMatchReminder.enabled || preMatchReminder.permissionDenied) reminderPermissionDenied()
    }
    fun openReminderGame(gameId: String) {
        val game = games.value.firstOrNull { it.id == gameId }
        if (game == null) pendingReminderGameID = gameId else { chooseGame(game); navigateTo(Screen.Home) }
    }

    /** Revalida o contexto do widget contra o catálogo vigente antes de iniciar um Check. */
    fun startCheckFromWidget(gameId: String, platform: String, declaredExternalLink: String?) {
        viewModelScope.launch {
            val available = games.value.ifEmpty { games.filter { it.isNotEmpty() }.first() }
            val game = available.firstOrNull { it.id == gameId } ?: return@launch
            if (platform !in game.platforms) return@launch
            val link = declaredExternalLink?.let {
                runCatching { com.lagcheck.domain.model.ExternalEquipmentLink.valueOf(it) }.getOrNull()
            }
            startCheck(game, platform, _selectedConnectionType.value, link)
        }
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
        connectionType: String = _selectedConnectionType.value,
        declaredExternalLink: com.lagcheck.domain.model.ExternalEquipmentLink? = _declaredExternalLink.value
    ) {
        selectGame(targetGame, platform, connectionType, declaredExternalLink)
        com.lagcheck.android.data.RemoteArtworkRepository.setDownloadsEnabled(false)
        refreshRadioTelemetry()
        val radioSnapshot = _liveRadioTelemetry.value
        val observedConnection = observedConnectionLabel(radioSnapshot)

        // O aviso de dados móveis depende do que o sistema reporta, não do que foi escolhido na tela.
        val isMobile = radioSnapshot?.transportType == RadioTelemetrySnapshot.TransportType.CELLULAR

        if (radioSnapshot?.transportType != RadioTelemetrySnapshot.TransportType.WIFI && !isMobile) {
            _currentScreen.value = Screen.ConnectionRequired(targetGame)
            return
        }

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

        executeActualCheck(targetGame, platform, observedConnection, _declaredExternalLink.value, radioSnapshot)
    }

    fun confirmMobileDataAndStart() {
        hasConsentedMobileData = true
        refreshRadioTelemetry()
        val observed = _liveRadioTelemetry.value?.transportType
        if (observed != RadioTelemetrySnapshot.TransportType.WIFI && observed != RadioTelemetrySnapshot.TransportType.CELLULAR) {
            _currentScreen.value = Screen.ConnectionRequired(_selectedGame.value)
            return
        }
        executeActualCheck(_selectedGame.value, _selectedPlatform.value, _selectedConnectionType.value, _declaredExternalLink.value, _liveRadioTelemetry.value)
    }

    private fun executeActualCheck(
        targetGame: CatalogGame,
        platform: String,
        connectionType: String,
        declaredExternalLink: com.lagcheck.domain.model.ExternalEquipmentLink?,
        radioSnapshot: RadioTelemetrySnapshot?
    ) {
        measurementJob?.cancel()
        hasConsentedMobileData = false // o consentimento vale para esta sessão de medição, não para as próximas

        val isRetest = nextStartIsRetest
        nextStartIsRetest = false
        val platformEnum = PlatformLabels.toPlatform(platform)
        if (isRetest) telemetry.retestStarted(targetGame.id, platformEnum) else telemetry.checkStarted(targetGame.id, platformEnum)

        _currentScreen.value = Screen.RegionalSelection(targetGame, platform, connectionType, isConfirming = true)
        measurementJob = viewModelScope.launch {
            val payload = currentCatalog()
            if (payload == null) {
                _currentScreen.value = Screen.RegionalSelection(targetGame, platform, connectionType, isConfirming = false)
                return@launch
            }

            val regionalSnapshot = MeasurementPlanner.planRegional(payload, targetGame.id, platform)
            if (regionalSnapshot == null || regionalSnapshot.candidates.isEmpty()) {
                _currentScreen.value = Screen.RegionalSelection(targetGame, platform, connectionType, isConfirming = false)
                return@launch
            }

            _currentScreen.value = Screen.RegionalSelection(targetGame, platform, connectionType, isConfirming = true)

            val job = this.coroutineContext[Job]
            fun cancelledScreen(reason: CancelReason) {
                _currentScreen.value = Screen.Measurement(
                    game = targetGame, platform = platform, connectionType = connectionType,
                    isCancelled = true, showMobileDataConsent = false, cancelReason = reason
                )
            }

            // Troca de rede durante a medição ou pré-leitura descarta o resultado parcial.
            pathWatcher.start { viewModelScope.launch {
                if (job?.isActive == true) {
                    val wasSelectingRegion = _currentScreen.value is Screen.RegionalSelection
                    job.cancel()
                    pathWatcher.stop()
                    if (wasSelectingRegion) _currentScreen.value = Screen.Home
                    else cancelledScreen(CancelReason.NETWORK_CHANGED)
                }
            } }
            val prefRegion = preferencesRepository.manualRegionId.value
                ?.takeIf { id -> id != "automatic" && regionalSnapshot.candidates.any { it.regionId == id } }
            val decision = try {
                regionalPreReadCoordinator.select(regionalSnapshot, prefRegion)
            } catch (e: Exception) {
                if (e is kotlinx.coroutines.CancellationException) throw e
                com.lagcheck.domain.rules.RegionalSelectionDecision.Inconclusive(com.lagcheck.domain.rules.RegionalSelectionInconclusiveReason.NO_VIABLE_REGIONAL_CANDIDATE)
            }

            if (decision is com.lagcheck.domain.rules.RegionalSelectionDecision.Inconclusive) {
                pathWatcher.stop()
                _currentScreen.value = Screen.RegionalSelection(targetGame, platform, connectionType, isConfirming = false)
                return@launch
            }

            val selectedContext = (decision as com.lagcheck.domain.rules.RegionalSelectionDecision.Selected).result.selected.resolvedContext

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

            measuring(0.04f, null, true)
            val regionLabel = payload.regions.firstOrNull { it.id == selectedContext.regionId }
                ?.label?.get(readinessLanguage().catalogLabelKey()) ?: selectedContext.regionId
            destinationLabel = regionLabel

            try {
                var lastPing: Double? = null
                val result = orchestrator.run(selectedContext, environmentOf(radioSnapshot)) { p ->
                    if (p.latestPingMs != null) lastPing = p.latestPingMs
                    measuring(p.ratio, lastPing, p.phase == CheckPhase.REST)
                }

                // Conexão que caiu no meio (watchdog) é cancelamento por integridade, não veredito.
                if (result.abortReason != null) {
                    cancelledScreen(CancelReason.POOR_QUALITY)
                    return@launch
                }

                val deepCheckResult = com.lagcheck.domain.rules.DeepCheckEvaluator.evaluate(
                    restSamples = result.restSamples,
                    loadSamples = result.loadSamples,
                    profile = selectedContext.profileId
                )
                val metrics = (deepCheckResult as? com.lagcheck.domain.rules.DeepCheckEvaluation.Completed)?.result?.metrics

                val evaluation = ReadinessPresenter.present(
                    assessment = result.assessment,
                    language = readinessLanguage(),
                    platform = platform,
                    connectionType = connectionType,
                    declaredExternalLink = declaredExternalLink,
                    destinationName = "$regionLabel · rota regional de referência",
                    confidence = selectedContext.confidence,
                    latencySeries = result.latencySeries,
                    radio = radioSnapshot,
                    regionLabel = regionLabel,
                    // Onde a fase sob carga começa na série. Sem carga medida, não há trecho "sob carga" para rotular.
                    loadStartIndex = if (result.loadMeasured) result.restSamples.count { it.isValidResponse } else null,
                    metrics = metrics
                )

                // Um resultado final, inclusive inconclusivo por amostra insuficiente,
                // entra no ritual. Cancelamentos e troca de rede retornam antes daqui.
                historyRepository.recordCheck(
                    game = targetGame,
                    evaluation = evaluation,
                    profileRuleVersion = selectedContext.profileRuleVersion,
                    regionId = selectedContext.regionId,
                    observedNetwork = radioSnapshot?.transportType?.name,
                    validResponseCount = result.restSamples.count { it.isValidResponse }
                )
                // O widget só recebe um resultado conclusivo com p50 real e a arte local do catálogo Android.
                if (evaluation.verdict != GameReadinessVerdict.INCONCLUSIVE) {
                    historyRepository.history.value.firstOrNull()?.let { item ->
                        WidgetSnapshotStore(getApplication()).save(targetGame, item, regionLabel)
                    }
                } else {
                    WidgetSnapshotStore(getApplication()).clear()
                }

                // Decisão 77: Sistema Unificado de Avaliação In-App (Google Play In-App Review)
                // Disparo de delight oportuno: estritamente veredito READY, 3 checks acumulados e cancelável se sair da tela/background
                if (evaluation.verdict == GameReadinessVerdict.READY) {
                    val shouldPrompt = reviewPromptCoordinator.recordMeasurementCompleted(GameReadinessVerdict.READY)
                    if (shouldPrompt) {
                        reviewPromptJob?.cancel()
                        reviewPromptJob = viewModelScope.launch {
                            kotlinx.coroutines.delay(1500)
                            if (_currentScreen.value is Screen.Verdict) {
                                reviewPromptCoordinator.recordPromptPresented()
                                _reviewPromptTrigger.send(Unit)
                            }
                        }
                    }
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
        reviewPromptJob?.cancel()
        reviewPromptJob = null
        val screen = _currentScreen.value
        if (screen is Screen.Measurement && !screen.isCancelled && !screen.showMobileDataConsent) {
            measurementJob?.cancel()
            pathWatcher.stop()
            _currentScreen.value = screen.copy(isCancelled = true, cancelReason = CancelReason.BACKGROUND)
        } else if (screen is Screen.RegionalSelection && screen.isConfirming) {
            measurementJob?.cancel()
            pathWatcher.stop()
            _currentScreen.value = Screen.Home
        }
    }

    fun cancelCheck() {
        measurementJob?.cancel()
        pathWatcher.stop()
        _currentScreen.value = Screen.Home
    }

    fun retryCheck() {
        nextStartIsRetest = true
        startCheck(_selectedGame.value, _selectedPlatform.value, _selectedConnectionType.value, _declaredExternalLink.value)
    }

    override fun onCleared() {
        pathWatcher.stop()
        super.onCleared()
    }

    fun openLatestResult() {
        val check = latestCheck.value ?: return
        _currentScreen.value = Screen.HistoryDetails(check, fromHome = true)
    }

    fun openCheckDetails(check: CheckHistoryItem) {
        _currentScreen.value = Screen.HistoryDetails(check)
    }
}
