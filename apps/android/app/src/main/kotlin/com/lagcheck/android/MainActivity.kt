package com.lagcheck.android

import android.os.Bundle
import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.lagcheck.android.data.toAppLanguage
import com.lagcheck.android.ui.AppLocale
import com.lagcheck.android.ui.MainViewModel
import com.lagcheck.android.ui.Screen
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.check.CheckCockpitScreen
import com.lagcheck.android.ui.cockpit.NetworkCockpitScreen
import com.lagcheck.android.ui.details.TechnicalDetailsScreen
import com.lagcheck.android.ui.games.GameSelectionScreen
import com.lagcheck.android.ui.history.HistoryScreen
import com.lagcheck.android.ui.home.HomeScreen
import com.lagcheck.android.ui.settings.SettingsScreen
import com.lagcheck.android.ui.verdict.VerdictScreen
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.domain.model.OfficialGameCatalog

class MainActivity : ComponentActivity() {
    companion object {
        const val EXTRA_REMINDER_GAME_ID = "pre_match_reminder_game_id"
        const val EXTRA_WIDGET_GAME_ID = "widget_game_id"
        const val EXTRA_WIDGET_PLATFORM = "widget_platform"
        const val EXTRA_WIDGET_EXTERNAL_LINK = "widget_external_link"
    }
    private var artworkForeground by mutableStateOf(false)

    override fun onStart() {
        super.onStart()
        artworkForeground = true
    }

    override fun onResume() {
        super.onResume()
        if (android.os.Build.VERSION.SDK_INT >= 33) {
            viewModel.refreshReminderPermission(ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
        }
    }

    private val viewModel: MainViewModel by viewModels()
    private val ads by lazy { com.lagcheck.android.ads.AdsController(this) }
    private var enableReminderAfterPermission = false
    private val notificationPermission = registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted && enableReminderAfterPermission) viewModel.enableReminder()
        else if (enableReminderAfterPermission) viewModel.reminderPermissionDenied()
        enableReminderAfterPermission = false
    }

    override fun onStop() {
        artworkForeground = false
        com.lagcheck.android.data.RemoteArtworkRepository.setDownloadsEnabled(false)
        super.onStop()
        // Ir para segundo plano no meio da medição descarta o resultado parcial (ciclo de vida da sessão).
        viewModel.onAppBackgrounded()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent.getStringExtra(EXTRA_REMINDER_GAME_ID)?.let(viewModel::openReminderGame)
        consumeWidgetCheck(intent)
        consumeDeepLink(intent)

        // Idioma inicial já na primeira composição (sem piscar em PT-BR antes de trocar).
        AppLocale.language = viewModel.language.value.toAppLanguage()

        setContent {
            var gamesOpenedFromHome by rememberSaveable { mutableStateOf(false) }
            val currentScreen by viewModel.currentScreen.collectAsState()
            val selectedGame by viewModel.selectedGame.collectAsState()
            val catalogGames by viewModel.games.collectAsState()
            val selectedPlatform by viewModel.selectedPlatform.collectAsState()
            val selectedConnectionType by viewModel.selectedConnectionType.collectAsState()
            val historyItems by viewModel.historyItems.collectAsState()
            val latestCheck by viewModel.latestCheck.collectAsState()
            val language by viewModel.language.collectAsState()
            SideEffect { AppLocale.language = language.toAppLanguage() }
            val radioSnapshot by viewModel.liveRadioTelemetry.collectAsState()
            val localReport by viewModel.localReport.collectAsState()
            val localReportLoading by viewModel.localReportLoading.collectAsState()
            val platformHealth by viewModel.platformHealth.collectAsState()
            val favorites by viewModel.favorites.collectAsState()
            val reminderEnabled by viewModel.reminderEnabledState.collectAsState()
            val reminderPermissionDenied by viewModel.reminderPermissionDenied.collectAsState()
            val analyticsCollectionEnabled by viewModel.analyticsCollectionEnabled.collectAsState()
            val pendingDuel by viewModel.pendingDuelInvitation.collectAsState()
            val lastDuelResolution by viewModel.lastDuelResolution.collectAsState()
            val updateState by viewModel.updateUiState.collectAsState()

            // Decisão 77: Sistema Unificado de Avaliação In-App (Google Play In-App Review)
            androidx.compose.runtime.LaunchedEffect(Unit) {
                viewModel.reviewPromptTrigger.collect {
                    // Proteção de contexto: só dispara se a tela atual ainda for o resultado (Screen.Verdict)
                    if (viewModel.currentScreen.value is Screen.Verdict) {
                        launchPlayReviewFlow()
                    }
                }
            }

            // Back button handling nativo conforme a tela
            BackHandler(enabled = currentScreen !is Screen.Home) {
                when (val screen = currentScreen) {
                    is Screen.GameSelection, is Screen.History, is Screen.Settings, is Screen.NetworkCockpit -> {
                        viewModel.navigateTo(Screen.Home)
                    }
                    is Screen.Measurement, is Screen.RegionalSelection, is Screen.ConnectionRequired -> {
                        viewModel.cancelCheck()
                    }
                    is Screen.Verdict, is Screen.HostDuelVersus -> {
                        viewModel.navigateTo(Screen.Home)
                    }
                    is Screen.TechnicalDetails -> {
                        if (screen.fromHistory) {
                            viewModel.navigateTo(Screen.History)
                        } else {
                            viewModel.navigateTo(Screen.Verdict(screen.game, screen.evaluation, routeRegionId = screen.routeRegionId))
                        }
                    }
                    is Screen.HistoryDetails -> {
                        viewModel.navigateTo(if (screen.fromHome) Screen.Home else Screen.History)
                    }
                    is Screen.Home -> {
                        // Comportamento padrão de saída do app
                    }
                }
            }

            // Decisão 96: Native Advanced no fluxo das quatro telas, somente após UMP.
            val canRequestAds by ads.canRequestAds.collectAsState()
            val privacyOptionsRequired by ads.privacyOptionsRequired.collectAsState()
            androidx.compose.runtime.LaunchedEffect(currentScreen is Screen.Home) {
                if (currentScreen is Screen.Home) ads.start()
            }
            val adPlacement = when (currentScreen) {
                is Screen.Home -> com.lagcheck.session.ads.AdPlacement.HOME
                is Screen.History -> com.lagcheck.session.ads.AdPlacement.HISTORY
                is Screen.GameSelection -> com.lagcheck.session.ads.AdPlacement.GAMES
                is Screen.Verdict -> com.lagcheck.session.ads.AdPlacement.RESULT
                else -> null
            }
            val showNativeAd = com.lagcheck.session.ads.AdPolicy.shouldShowNative(
                com.lagcheck.session.ads.AdContext(
                    enabled = ads.enabled,
                    placement = adPlacement,
                    canRequestAds = canRequestAds,
                    measuring = currentScreen is Screen.Measurement || currentScreen is Screen.RegionalSelection ||
                        currentScreen is Screen.ConnectionRequired
                )
            )

            val isHomeOrGames = currentScreen is Screen.Home || currentScreen is Screen.GameSelection ||
                currentScreen is Screen.History || currentScreen is Screen.Settings

            val artworkAllowed = artworkForeground && (currentScreen is Screen.Home || currentScreen is Screen.GameSelection || currentScreen is Screen.History)
            androidx.compose.runtime.SideEffect {
                com.lagcheck.android.data.RemoteArtworkRepository.setDownloadsEnabled(artworkAllowed)
            }
            androidx.compose.runtime.CompositionLocalProvider(
                com.lagcheck.android.ui.components.LocalArtworkDownloadsAllowed provides artworkAllowed
            ) {
            val duelInvite = pendingDuel
            if (duelInvite != null) {
                val duelGameName = androidx.compose.runtime.remember(duelInvite) {
                    catalogGames.firstOrNull { it.id.equals(duelInvite.gameId, ignoreCase = true) }?.name
                        ?: duelInvite.gameId.replaceFirstChar { it.uppercase() }
                }
                com.lagcheck.android.ui.duel.HostDuelInvitationSheet(
                    duel = duelInvite,
                    gameName = duelGameName,
                    onAccept = { viewModel.acceptDuelInvitation(duelInvite) },
                    onDecline = { viewModel.declineDuelInvitation() }
                )
            }
            val isMeasuring = currentScreen is Screen.Measurement || currentScreen is Screen.RegionalSelection
            if (!isMeasuring) {
                com.lagcheck.android.ui.components.UpdateDialog(
                    state = updateState,
                    onStartUpdate = { viewModel.startUpdate(this@MainActivity) },
                    onInstallApk = { apkFile -> viewModel.proceedWithApkInstall(apkFile) },
                    onDismiss = { viewModel.dismissUpdatePrompt() },
                    onCancelDownload = { viewModel.cancelUpdateDownload() },
                    onOpenInBrowser = { viewModel.openUpdateInBrowser() },
                    onOpenInStore = { viewModel.openUpdateInStore() }
                )
            }
            Scaffold(
                contentWindowInsets = WindowInsets(0),
                bottomBar = {
                    if (isHomeOrGames) {
                        NavigationBar(
                            containerColor = LagCheckColors.Surface.copy(alpha = 0.9f)
                        ) {
                            val tabColors = NavigationBarItemDefaults.colors(
                                selectedIconColor = LagCheckColors.AccentPrimary,
                                selectedTextColor = LagCheckColors.AccentPrimary,
                                unselectedIconColor = LagCheckColors.TextMuted,
                                unselectedTextColor = LagCheckColors.TextMuted,
                                indicatorColor = LagCheckColors.Surface
                            )
                            NavigationBarItem(
                                selected = currentScreen is Screen.Home,
                                onClick = {
                                    gamesOpenedFromHome = false
                                    viewModel.navigateTo(Screen.Home)
                                },
                                icon = { Icon(Icons.Filled.Home, contentDescription = null) },
                                label = { Text(tr("Início")) },
                                colors = tabColors
                            )
                            NavigationBarItem(
                                selected = currentScreen is Screen.GameSelection,
                                onClick = {
                                    gamesOpenedFromHome = false
                                    viewModel.navigateTo(Screen.GameSelection)
                                },
                                icon = { GamepadTabIcon(selected = currentScreen is Screen.GameSelection) },
                                label = { Text(tr("Jogos")) },
                                colors = tabColors
                            )
                            NavigationBarItem(
                                selected = currentScreen is Screen.History,
                                onClick = { viewModel.navigateTo(Screen.History) },
                                icon = { HistoryTabIcon(selected = currentScreen is Screen.History) },
                                label = { Text(tr("Histórico")) },
                                colors = tabColors
                            )
                            NavigationBarItem(
                                selected = currentScreen is Screen.Settings,
                                onClick = { viewModel.navigateTo(Screen.Settings) },
                                icon = { Icon(Icons.Filled.Settings, contentDescription = null) },
                                label = { Text(tr("Configurações")) },
                                colors = tabColors
                            )
                        }
                    }
                }
            ) { innerPadding ->
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(LagCheckColors.Background)
                        .padding(innerPadding)
                        // Só a Home compõe a arte sob a status bar. Os demais fluxos
                        // preservam os insets de segurança existentes.
                        .then(
                            if (currentScreen is Screen.Home) Modifier else Modifier.safeDrawingPadding()
                        )
                ) {
                AnimatedContent(
                    targetState = currentScreen,
                    // Mesma classe de tela = mesmo conteúdo: o progresso da medição atualiza sem transição.
                    contentKey = { it::class },
                    transitionSpec = { oneUiScreenTransition(initialState, targetState) }
                ) { screen ->
                when (screen) {
                    is Screen.Home -> {
                        val favGames = favorites.resolve(catalogGames).ifEmpty { catalogGames.take(4) }
                        HomeScreen(
                            selectedGame = selectedGame,
                            platform = selectedPlatform,
                            connectionType = selectedConnectionType,
                            radioSnapshot = radioSnapshot,
                            latestCheck = latestCheck,
                            platformHealth = platformHealth,
                            favoriteGames = favGames,
                            onStartCheck = {
                                viewModel.startGeneralCheck()
                            },
                            onStartGameCheck = { game ->
                                viewModel.startCheck(targetGame = game)
                            },
                            onOpenGames = {
                                gamesOpenedFromHome = true
                                viewModel.navigateTo(Screen.GameSelection)
                            },
                            onOpenLatestResult = {
                                viewModel.openLatestResult()
                            },
                            onOpenNetworkCockpit = {
                                viewModel.navigateTo(Screen.NetworkCockpit)
                            },
                            showNativeAd = showNativeAd
                        )
                    }

                    is Screen.GameSelection -> {
                        GameSelectionScreen(
                            allGames = catalogGames,
                            showBackButton = gamesOpenedFromHome,
                            recentChecks = historyItems,
                            favorites = favorites,
                            onToggleFavorite = { viewModel.toggleFavorite(it.id) },
                            onBack = {
                                viewModel.navigateTo(Screen.Home)
                            },
                            onGameSelected = { game ->
                                viewModel.chooseGame(game)
                                gamesOpenedFromHome = false
                                viewModel.startCheck()
                            },
                            onStartGeneralCheck = {
                                val generalGame = OfficialGameCatalog.findById("fortnite").copy(
                                    id = "check-geral",
                                    name = "Check Geral",
                                    category = "Rota de Referência",
                                    drawableResName = ""
                                )
                                viewModel.startCheck(generalGame, "Mobile", "")
                            },
                            showNativeAd = showNativeAd
                        )
                    }

                    is Screen.RegionalSelection -> {
                        com.lagcheck.android.ui.check.RegionalSelectionScreen(
                            isConfirming = screen.isConfirming,
                            viewModel = viewModel,
                            onBack = { viewModel.cancelCheck() }
                        )
                    }

                    is Screen.ConnectionRequired -> {
                        com.lagcheck.android.ui.check.ConnectionRequiredScreen(
                            gameName = screen.game.name,
                            onBack = { viewModel.cancelCheck() }
                        )
                    }

                    is Screen.Measurement -> {
                        CheckCockpitScreen(
                            game = screen.game,
                            platform = screen.platform,
                            connectionType = screen.connectionType,
                            progressRatio = screen.progressRatio,
                            currentPingMs = screen.currentPingMs,
                            isPhaseRest = screen.isPhaseRest,
                            isWiFi = screen.connectionType.contains("Wi-Fi", ignoreCase = true),
                            isCancelled = screen.isCancelled,
                            cancelReason = screen.cancelReason,
                            destinationName = screen.destinationName,
                            routeRegionId = screen.routeRegionId,
                            routeMap = viewModel.routeMap,
                            routeRegionName = viewModel::routeRegionName,
                            showMobileDataConsent = screen.showMobileDataConsent,
                            onCancel = {
                                viewModel.cancelCheck()
                            },
                            onRetry = {
                                viewModel.retryCheck()
                            },
                            onConfirmMobileData = {
                                viewModel.confirmMobileDataAndStart()
                            }
                        )
                    }

                    is Screen.Verdict -> {
                        androidx.compose.runtime.LaunchedEffect(screen) {
                            viewModel.onResultViewed(screen.game, screen.evaluation)
                        }
                        VerdictScreen(
                            game = screen.game,
                            evaluation = screen.evaluation,
                            routeRegionId = screen.routeRegionId,
                            onRetry = {
                                viewModel.retryCheck()
                            },
                            onDetails = {
                                viewModel.navigateTo(
                                    Screen.TechnicalDetails(
                                        screen.game,
                                        screen.evaluation,
                                        fromHistory = false,
                                        routeRegionId = screen.routeRegionId
                                    )
                                )
                            },
                            onClose = {
                                viewModel.navigateTo(Screen.Home)
                            },
                            showNativeAd = showNativeAd,
                            savedGamerNick = viewModel.getSavedGamerNick(),
                            onSaveGamerNick = { viewModel.saveGamerNick(it) },
                            lastDuelResolution = lastDuelResolution,
                            onViewDuelVersus = lastDuelResolution?.let { res ->
                                {
                                    viewModel.navigateTo(Screen.HostDuelVersus(res.first, res.second, screen.game.name))
                                }
                            }
                        )
                    }

                    is Screen.HostDuelVersus -> {
                        com.lagcheck.android.ui.duel.HostDuelVersusScreen(
                            challenger = screen.challenger,
                            opponent = screen.opponent,
                            gameTitle = screen.gameTitle,
                            onDismiss = {
                                viewModel.navigateTo(Screen.Home)
                            }
                        )
                    }

                    is Screen.TechnicalDetails -> {
                        TechnicalDetailsScreen(
                            game = screen.game,
                            evaluation = screen.evaluation,
                            onClose = {
                                if (screen.fromHistory) {
                                    viewModel.navigateTo(Screen.History)
                                } else {
                                    viewModel.navigateTo(Screen.Verdict(screen.game, screen.evaluation, routeRegionId = screen.routeRegionId))
                                }
                            }
                        )
                    }

                    is Screen.HistoryDetails -> {
                        com.lagcheck.android.ui.details.CheckHistoryItemDetailsScreen(
                            item = screen.item,
                            onClose = {
                                viewModel.navigateTo(if (screen.fromHome) Screen.Home else Screen.History)
                            }
                        )
                    }

                    is Screen.History -> {
                        HistoryScreen(
                            catalogGames = catalogGames,
                            historyItems = historyItems,
                            onBack = {
                                viewModel.navigateTo(Screen.Home)
                            },
                            onSelectCheck = { item ->
                                viewModel.openCheckDetails(item)
                            },
                            onClearHistory = {
                                viewModel.clearHistory()
                            },
                            onGoToHome = {
                                viewModel.navigateTo(Screen.Home)
                            },
                            showNativeAd = showNativeAd
                        )
                    }

                    is Screen.Settings -> {
                        val regionCandidates by viewModel.regionCandidates.collectAsState()
                        val manualRegionId by viewModel.manualRegionId.collectAsState()
                        SettingsScreen(
                            currentLanguage = language,
                            onLanguageSelected = { viewModel.setLanguage(it) },
                            regionCandidates = regionCandidates,
                            manualRegionId = manualRegionId,
                            onRegionSelected = { viewModel.setManualRegionId(it) },
                            onOpenHistory = { viewModel.navigateTo(Screen.History) },
                            onClearHistory = { viewModel.clearHistory() },
                            reminderEnabled = reminderEnabled,
                            reminderHour = viewModel.reminderHour(),
                            reminderMinute = viewModel.reminderMinute(),
                            reminderGameName = selectedGame.name,
                            reminderPermissionDenied = reminderPermissionDenied,
                            analyticsCollectionAvailable = viewModel.analyticsCollectionAvailable,
                            analyticsCollectionEnabled = analyticsCollectionEnabled,
                            onAnalyticsCollectionEnabledChanged = viewModel::setAnalyticsCollectionEnabled,
                            onReminderToggle = { enabled ->
                                if (!enabled) viewModel.disableReminder()
                                else if (android.os.Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(this@MainActivity, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) viewModel.enableReminder()
                                else { enableReminderAfterPermission = true; notificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS) }
                            },
                            onReminderTimeChanged = viewModel::changeReminderTime,
                            onOpenNotificationSettings = {
                                startActivity(android.content.Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, packageName))
                            },
                            privacyOptionsRequired = privacyOptionsRequired,
                            onOpenPrivacyOptions = { ads.showPrivacyOptions() },
                            onCheckForUpdates = { viewModel.checkForUpdates(manual = true) },
                            onBack = { viewModel.navigateTo(Screen.Home) }
                        )
                    }
                    is Screen.NetworkCockpit -> {
                        NetworkCockpitScreen(
                            radioSnapshot = radioSnapshot,
                            report = localReport,
                            isProbing = localReportLoading,
                            language = language.toAppLanguage(),
                            onClose = {
                                viewModel.navigateTo(Screen.Home)
                            },
                            onRefresh = { viewModel.refreshLocalReport() }
                        )
                    }
                }
                }
            }
            }
        }
    }

    }
    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.getStringExtra(EXTRA_REMINDER_GAME_ID)?.let(viewModel::openReminderGame)
        consumeWidgetCheck(intent)
        consumeDeepLink(intent)
    }

    private fun consumeWidgetCheck(intent: android.content.Intent) {
        val gameId = intent.getStringExtra(EXTRA_WIDGET_GAME_ID) ?: return
        val platform = intent.getStringExtra(EXTRA_WIDGET_PLATFORM) ?: return
        viewModel.startCheckFromWidget(gameId, platform, intent.getStringExtra(EXTRA_WIDGET_EXTERNAL_LINK))
    }

    private fun consumeDeepLink(intent: android.content.Intent) {
        val uri = intent.data?.toString() ?: return
        when (val deepLink = com.lagcheck.domain.model.DeepLinkParser.parse(uri)) {
            is com.lagcheck.domain.model.AppDeepLink.HostDuel -> {
                viewModel.handleIncomingDuel(deepLink.payload)
            }
            else -> Unit
        }
    }
    private fun launchPlayReviewFlow() {
        try {
            val manager = com.google.android.play.core.review.ReviewManagerFactory.create(this)
            val request = manager.requestReviewFlow()
            request.addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    val reviewInfo = task.result
                    manager.launchReviewFlow(this, reviewInfo)
                }
            }
        } catch (_: Exception) {
            // Degradação silenciosa em emulador ou sem Play Services
        }
    }
}
@androidx.compose.runtime.Composable
private fun GamepadTabIcon(selected: Boolean) {
    val color = if (selected) LagCheckColors.AccentPrimary else LagCheckColors.TextMuted
    Canvas(modifier = Modifier.size(24.dp)) {
        val stroke = 2.dp.toPx()
        drawRoundRect(
            color = color,
            topLeft = Offset(size.width * 0.08f, size.height * 0.25f),
            size = Size(size.width * 0.84f, size.height * 0.55f),
            cornerRadius = CornerRadius(size.height * 0.22f),
            style = Stroke(width = stroke)
        )
        drawLine(color, Offset(size.width * 0.28f, size.height * 0.44f), Offset(size.width * 0.28f, size.height * 0.65f), stroke)
        drawLine(color, Offset(size.width * 0.18f, size.height * 0.55f), Offset(size.width * 0.38f, size.height * 0.55f), stroke)
        drawCircle(color, radius = stroke * 0.75f, center = Offset(size.width * 0.68f, size.height * 0.47f))
        drawCircle(color, radius = stroke * 0.75f, center = Offset(size.width * 0.78f, size.height * 0.60f))
    }
}

@androidx.compose.runtime.Composable
private fun HistoryTabIcon(selected: Boolean) {
    val color = if (selected) LagCheckColors.AccentPrimary else LagCheckColors.TextMuted
    Canvas(modifier = Modifier.size(24.dp)) {
        val stroke = 2.dp.toPx()
        drawCircle(color, radius = size.width * 0.4f, center = center, style = Stroke(width = stroke))
        drawLine(color, center, Offset(center.x, size.height * 0.28f), stroke, cap = androidx.compose.ui.graphics.StrokeCap.Round)
        drawLine(color, center, Offset(size.width * 0.66f, size.height * 0.58f), stroke, cap = androidx.compose.ui.graphics.StrokeCap.Round)
    }
}

// Movimento no estilo One UI: curva "sine" suave, deslocamento curto e fade; abas usam fade-through.
private val OneUiEasing = androidx.compose.animation.core.CubicBezierEasing(0.33f, 0f, 0.67f, 1f)
private const val OneUiSlideMillis = 400
private const val OneUiFadeMillis = 200

private fun screenDepth(screen: Screen): Int = when (screen) {
    is Screen.Home, is Screen.GameSelection, is Screen.History, is Screen.Settings -> 0
    is Screen.NetworkCockpit, is Screen.HistoryDetails, is Screen.RegionalSelection, is Screen.ConnectionRequired -> 1
    is Screen.Measurement -> 2
    is Screen.Verdict, is Screen.HostDuelVersus -> 3
    is Screen.TechnicalDetails -> 4
}

private fun oneUiScreenTransition(
    from: Screen,
    to: Screen
): androidx.compose.animation.ContentTransform {
    val fromDepth = screenDepth(from)
    val toDepth = screenDepth(to)
    val slide = androidx.compose.animation.core.tween<androidx.compose.ui.unit.IntOffset>(OneUiSlideMillis, easing = OneUiEasing)
    val fadeIn = androidx.compose.animation.core.tween<Float>(OneUiFadeMillis, delayMillis = 90, easing = OneUiEasing)
    val fadeOut = androidx.compose.animation.core.tween<Float>(90, easing = OneUiEasing)
    return when {
        toDepth > fromDepth ->
            (androidx.compose.animation.slideInHorizontally(slide) { it / 3 } + androidx.compose.animation.fadeIn(fadeIn))
                .togetherWith(androidx.compose.animation.slideOutHorizontally(slide) { -it / 4 } + androidx.compose.animation.fadeOut(fadeOut))
                .apply { targetContentZIndex = 1f }
        toDepth < fromDepth ->
            (androidx.compose.animation.slideInHorizontally(slide) { -it / 4 } + androidx.compose.animation.fadeIn(fadeIn))
                .togetherWith(androidx.compose.animation.slideOutHorizontally(slide) { it / 3 } + androidx.compose.animation.fadeOut(fadeOut))
                .apply { targetContentZIndex = 0f }
        else ->
            (androidx.compose.animation.fadeIn(fadeIn) + androidx.compose.animation.scaleIn(
                androidx.compose.animation.core.tween(OneUiSlideMillis, easing = OneUiEasing), initialScale = 0.94f
            )).togetherWith(androidx.compose.animation.fadeOut(fadeOut))
    }
}
