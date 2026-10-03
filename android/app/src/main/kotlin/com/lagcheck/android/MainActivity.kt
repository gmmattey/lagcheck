package com.lagcheck.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import com.lagcheck.android.ui.MainViewModel
import com.lagcheck.android.ui.Screen
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

    private val viewModel: MainViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            val currentScreen by viewModel.currentScreen.collectAsState()
            val selectedGame by viewModel.selectedGame.collectAsState()
            val selectedPlatform by viewModel.selectedPlatform.collectAsState()
            val selectedConnectionType by viewModel.selectedConnectionType.collectAsState()
            val historyItems by viewModel.historyItems.collectAsState()
            val latestCheck by viewModel.latestCheck.collectAsState()
            val language by viewModel.language.collectAsState()
            val radioSnapshot by viewModel.liveRadioTelemetry.collectAsState()

            // Back button handling nativo conforme a tela
            BackHandler(enabled = currentScreen !is Screen.Home) {
                when (val screen = currentScreen) {
                    is Screen.GameSelection, is Screen.History, is Screen.Settings, is Screen.NetworkCockpit -> {
                        viewModel.navigateTo(Screen.Home)
                    }
                    is Screen.Measurement -> {
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
                    is Screen.Home -> {
                        // Comportamento padrão de saída do app
                    }
                }
            }

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(LagCheckColors.Background)
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
                            onStartCheck = {
                                viewModel.startCheck(selectedGame, selectedPlatform, selectedConnectionType)
                            },
                            onOpenGames = {
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
                            onBack = {
                                viewModel.navigateTo(Screen.Home)
                            },
                            onGameSelected = { game, platform, conn ->
                                viewModel.startCheck(game, platform, conn)
                            },
                            onStartGeneralCheck = {
                                val generalGame = OfficialGameCatalog.findById("fortnite").copy(
                                    id = "check-geral",
                                    name = "Check Geral",
                                    category = "Rota de Referência"
                                )
                                viewModel.startCheck(generalGame, "Android", "Wi-Fi")
                            }
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

                    is Screen.History -> {
                        HistoryScreen(
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
                        SettingsScreen(
                            currentLanguage = language,
                            onLanguageSelected = { lang ->
                                viewModel.setLanguage(lang)
                            },
                            onClearHistory = {
                                viewModel.clearHistory()
                            },
                            onBack = {
                                viewModel.navigateTo(Screen.Home)
                            }
                        )
                    }

                    is Screen.NetworkCockpit -> {
                        NetworkCockpitScreen(
                            radioSnapshot = radioSnapshot,
                            onClose = {
                                viewModel.navigateTo(Screen.Home)
                            }
                        )
                    }
                }
            }
        }
    }
}
