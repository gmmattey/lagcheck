package com.lagcheck.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.background
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
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
    private var artworkForeground by mutableStateOf(false)

    override fun onStart() {
        super.onStart()
        artworkForeground = true
    }

    private val viewModel: MainViewModel by viewModels()

    override fun onStop() {
        artworkForeground = false
        com.lagcheck.android.data.RemoteArtworkRepository.setDownloadsEnabled(false)
        super.onStop()
        // Ir para segundo plano no meio da medição descarta o resultado parcial (ciclo de vida da sessão).
        viewModel.onAppBackgrounded()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

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

            // Back button handling nativo conforme a tela
            BackHandler(enabled = currentScreen !is Screen.Home) {
                when (val screen = currentScreen) {
                    is Screen.GameSelection, is Screen.History, is Screen.Settings, is Screen.NetworkCockpit -> {
                        viewModel.navigateTo(Screen.Home)
                    }
                    is Screen.Measurement, is Screen.RegionalSelection, is Screen.ConnectionRequired -> {
                        viewModel.cancelCheck()
                    }
                    is Screen.Verdict -> {
                        viewModel.navigateTo(Screen.Home)
                    }
                    is Screen.TechnicalDetails -> {
                        if (screen.fromHistory) {
                            viewModel.navigateTo(Screen.History)
                        } else {
                            viewModel.navigateTo(Screen.Verdict(screen.game, screen.evaluation))
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

            val isHomeOrGames = currentScreen is Screen.Home || currentScreen is Screen.GameSelection

            val artworkAllowed = artworkForeground && (currentScreen is Screen.Home || currentScreen is Screen.GameSelection || currentScreen is Screen.History)
            androidx.compose.runtime.SideEffect {
                com.lagcheck.android.data.RemoteArtworkRepository.setDownloadsEnabled(artworkAllowed)
            }
            androidx.compose.runtime.CompositionLocalProvider(
                com.lagcheck.android.ui.components.LocalArtworkDownloadsAllowed provides artworkAllowed
            ) {
            Scaffold(
                contentWindowInsets = WindowInsets(0),
                bottomBar = {
                    if (isHomeOrGames) {
                        NavigationBar(
                            containerColor = LagCheckColors.Surface.copy(alpha = 0.9f)
                        ) {
                            NavigationBarItem(
                                selected = currentScreen is Screen.Home,
                                onClick = {
                                    gamesOpenedFromHome = false
                                    viewModel.navigateTo(Screen.Home)
                                },
                                icon = { Icon(Icons.Filled.Home, contentDescription = null) },
                                label = { Text(tr("Início")) },
                                colors = NavigationBarItemDefaults.colors(
                                    selectedIconColor = LagCheckColors.AccentPrimary,
                                    selectedTextColor = LagCheckColors.AccentPrimary,
                                    unselectedIconColor = LagCheckColors.TextMuted,
                                    unselectedTextColor = LagCheckColors.TextMuted,
                                    indicatorColor = LagCheckColors.Surface
                                )
                            )
                            NavigationBarItem(
                                selected = currentScreen is Screen.GameSelection,
                                onClick = {
                                    gamesOpenedFromHome = false
                                    viewModel.navigateTo(Screen.GameSelection)
                                },
                                icon = { GamepadTabIcon(selected = currentScreen is Screen.GameSelection) },
                                label = { Text(tr("Jogos")) },
                                colors = NavigationBarItemDefaults.colors(
                                    selectedIconColor = LagCheckColors.AccentPrimary,
                                    selectedTextColor = LagCheckColors.AccentPrimary,
                                    unselectedIconColor = LagCheckColors.TextMuted,
                                    unselectedTextColor = LagCheckColors.TextMuted,
                                    indicatorColor = LagCheckColors.Surface
                                )
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
                        .safeDrawingPadding()
                ) {
                when (val screen = currentScreen) {
                    is Screen.Home -> {
                        HomeScreen(
                            selectedGame = selectedGame,
                            platform = selectedPlatform,
                            connectionType = selectedConnectionType,
                            radioSnapshot = radioSnapshot,
                            latestCheck = latestCheck,
                            platformHealth = platformHealth,
                            onStartCheck = {
                                viewModel.startCheck(selectedGame, selectedPlatform, selectedConnectionType)
                            },
                            onOpenGames = {
                                gamesOpenedFromHome = true
                                viewModel.navigateTo(Screen.GameSelection)
                            },
                            onOpenHistory = {
                                viewModel.navigateTo(Screen.History)
                            },
                            onOpenSettings = {
                                viewModel.navigateTo(Screen.Settings)
                            },
                            onOpenLatestResult = {
                                viewModel.openLatestResult()
                            },
                            onOpenNetworkCockpit = {
                                viewModel.navigateTo(Screen.NetworkCockpit)
                            }
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
                            onGameSelected = { game, platform, conn, declaredLink ->
                                viewModel.startCheck(game, platform, conn, declaredLink)
                            },
                            onStartGeneralCheck = {
                                val generalGame = OfficialGameCatalog.findById("fortnite").copy(
                                    id = "check-geral",
                                    name = "Check Geral",
                                    category = "Rota de Referência",
                                    drawableResName = ""
                                )
                                viewModel.startCheck(generalGame, "Android", "Wi-Fi")
                            }
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
                        VerdictScreen(
                            game = screen.game,
                            evaluation = screen.evaluation,
                            onRetry = {
                                viewModel.retryCheck()
                            },
                            onDetails = {
                                viewModel.navigateTo(
                                    Screen.TechnicalDetails(screen.game, screen.evaluation, fromHistory = false)
                                )
                            },
                            onClose = {
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
                                    viewModel.navigateTo(Screen.Verdict(screen.game, screen.evaluation))
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
                            }
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
