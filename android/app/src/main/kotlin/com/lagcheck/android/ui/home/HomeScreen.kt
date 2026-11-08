package com.lagcheck.android.ui.home

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.R
import com.lagcheck.android.data.CheckHistoryItem
import com.lagcheck.android.ui.components.HomeTopBar
import com.lagcheck.android.ui.components.PlatformHealthBanner
import com.lagcheck.android.ui.components.RemoteGameArtwork
import com.lagcheck.android.ui.tr
import com.lagcheck.core.designsystem.components.HomeCircularPulseGaugeHero
import com.lagcheck.core.designsystem.components.RadioSignalPill
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.core.designsystem.theme.LagCheckRadius
import com.lagcheck.core.designsystem.theme.LagCheckSpacing
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.network.health.PlatformHealth

/**
 * 01 · Home Cockpit (Decisão 113).
 * Check Geral de Conexão protagonista com Gauge Circular ("TESTAR" no centro)
 * e carrossel inferior dos jogos favoritos/recentes para medição em 1 toque.
 */
@Composable
fun HomeScreen(
    selectedGame: CatalogGame,
    platform: String,
    connectionType: String,
    radioSnapshot: RadioTelemetrySnapshot?,
    latestCheck: CheckHistoryItem?,
    favoriteGames: List<CatalogGame> = emptyList(),
    onStartCheck: () -> Unit,
    onStartGameCheck: (CatalogGame) -> Unit = {},
    onOpenGames: () -> Unit,
    onOpenLatestResult: () -> Unit,
    onOpenNetworkCockpit: () -> Unit = {},
    platformHealth: PlatformHealth? = null,
    showNativeAd: Boolean = false,
    modifier: Modifier = Modifier
) {
    val nativeAd = if (showNativeAd) com.lagcheck.android.ads.rememberNativeAd(com.lagcheck.session.ads.AdPlacement.HOME) else null
    val wifi = radioSnapshot?.wifiDetails
    val radioLabel = when {
        wifi != null -> {
            val band = when (wifi.band) {
                RadioTelemetrySnapshot.WifiBand.BAND_2_4_GHZ -> "Wi-Fi 2.4 GHz"
                RadioTelemetrySnapshot.WifiBand.BAND_5_GHZ -> "Wi-Fi 5 GHz"
                RadioTelemetrySnapshot.WifiBand.BAND_6_GHZ -> "Wi-Fi 6 GHz"
                RadioTelemetrySnapshot.WifiBand.UNKNOWN -> "Wi-Fi"
            }
            val pingEst = latestCheck?.pingMs?.let { " · %.0f ms".format(java.util.Locale.ROOT, it) } ?: ""
            "$band$pingEst"
        }
        radioSnapshot?.transportType == RadioTelemetrySnapshot.TransportType.CELLULAR -> tr("Dados móveis")
        else -> tr("Rede local")
    }
    val isRadioWarning = wifi?.band == RadioTelemetrySnapshot.WifiBand.BAND_2_4_GHZ || (wifi?.isSignalCritical == true)

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
            .verticalScroll(rememberScrollState())
    ) {
        // Dobra Superior: Arte Hero de Jogos no Topo (fades para preto antes do gauge)
        Box(
            modifier = Modifier.fillMaxWidth()
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(180.dp)
            ) {
                Image(
                    painter = painterResource(id = R.drawable.hero_top_games),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.verticalGradient(
                                0.0f to LagCheckColors.Background.copy(alpha = 0.35f),
                                0.35f to LagCheckColors.Background.copy(alpha = 0.40f),
                                0.70f to LagCheckColors.Background.copy(alpha = 0.85f),
                                0.95f to LagCheckColors.Background,
                                1.0f to LagCheckColors.Background
                            )
                        )
                )
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = LagCheckSpacing.space6),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // 1. Topline: Wordmark oficial + Botão '…' (Ajustes)
                HomeTopBar(modifier = Modifier.padding(top = LagCheckSpacing.space2))

                Spacer(modifier = Modifier.height(LagCheckSpacing.space1_5))

                // 2. Pílula de rádio: toque abre Cockpit de Rede
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center
                ) {
                    Box(
                        modifier = Modifier
                            .defaultMinSize(minHeight = 44.dp)
                            .clip(RoundedCornerShape(percent = 50))
                            .clickable { onOpenNetworkCockpit() },
                        contentAlignment = Alignment.Center
                    ) {
                        RadioSignalPill(
                            label = radioLabel,
                            isWarning = isRadioWarning
                        )
                    }
                }

                Spacer(modifier = Modifier.height(LagCheckSpacing.space4_5))

                // 3. Gauge Circular de Pulso Protagonista (Decisão 113)
                Box(
                    modifier = Modifier.fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    HomeCircularPulseGaugeHero(
                        isMeasuring = false,
                        testButtonText = tr("TESTAR"),
                        measuringText = tr("MEDINDO..."),
                        onStartCheck = onStartCheck
                    )
                }

                Spacer(modifier = Modifier.height(LagCheckSpacing.space3_5))

                // 4. Linha de Último Resultado Verificado (Idêntica à tela atual do app)
                val lastCheckText = latestCheck?.let { item ->
                    val symbol = when (item.verdict) {
                        GameReadinessVerdict.READY -> "●"
                        GameReadinessVerdict.CAUTION, GameReadinessVerdict.NOT_READY -> "▲"
                        GameReadinessVerdict.INCONCLUSIVE -> "—"
                    }
                    val verdictName = when (item.verdict) {
                        GameReadinessVerdict.READY -> tr("Pronto para Ranked")
                        GameReadinessVerdict.CAUTION -> tr("Condições Instáveis")
                        GameReadinessVerdict.NOT_READY -> tr("Evitaria Ranked Agora")
                        GameReadinessVerdict.INCONCLUSIVE -> tr("Inconclusivo")
                    }
                    "$symbol $verdictName · ${item.formattedDate}"
                } ?: tr("— Nenhum check ainda")

                val lastColor = when (latestCheck?.verdict) {
                    GameReadinessVerdict.READY -> LagCheckColors.Good
                    GameReadinessVerdict.CAUTION -> LagCheckColors.SemanticCaution
                    GameReadinessVerdict.NOT_READY -> LagCheckColors.CoralWarning
                    else -> LagCheckColors.TextMuted
                }

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onOpenLatestResult() }
                        .padding(vertical = LagCheckSpacing.space2),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = lastCheckText,
                        style = LagCheckTypography.MonoData,
                        color = lastColor
                    )
                }
            }
        }

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = LagCheckSpacing.space6)
        ) {

        if (platformHealth != null) {
            Spacer(modifier = Modifier.height(LagCheckSpacing.space3_5))
            PlatformHealthBanner(platformHealth)
        }

        Spacer(modifier = Modifier.height(LagCheckSpacing.space6))

        // 5. Seção Inferior: TESTAR POR JOGO (Carrossel Horizontal de 1 Toque)
        val gamesList = favoriteGames.ifEmpty { listOf(selectedGame) }
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(LagCheckSpacing.space3)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = tr("TESTAR POR JOGO"),
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.TextSecondary,
                    letterSpacing = 1.2.sp
                )

                Row(
                    modifier = Modifier
                        .clip(RoundedCornerShape(LagCheckRadius.sm))
                        .clickable { onOpenGames() }
                        .padding(horizontal = LagCheckSpacing.space1_5, vertical = LagCheckSpacing.space1),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = tr("Ver todos"),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = LagCheckColors.AccentPrimaryLight
                    )
                    Text(
                        text = " ›",
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                        color = LagCheckColors.AccentPrimaryLight
                    )
                }
            }

            // Carrossel horizontal
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space3)
            ) {
                gamesList.forEach { game ->
                    HomeGameCard(
                        game = game,
                        onClick = { onStartGameCheck(game) }
                    )
                }
            }
        }

        if (nativeAd != null) {
            com.lagcheck.android.ads.NativeAdSlot(
                nativeAd,
                Modifier.padding(top = LagCheckSpacing.space6)
            )
        }
        Spacer(modifier = Modifier.height(LagCheckSpacing.space6))
        }
    }
}

@Composable
private fun HomeGameCard(
    game: CatalogGame,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .width(136.dp)
            .height(154.dp)
            .clip(RoundedCornerShape(LagCheckRadius.lg))
            .background(LagCheckColors.Surface)
            .clickable { onClick() }
    ) {
        RemoteGameArtwork(
            game = game,
            modifier = Modifier.fillMaxSize()
        )

        // Gradiente escuro para contraste
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        0.0f to Color.Transparent,
                        0.4f to Color.Transparent,
                        0.75f to LagCheckColors.Background.copy(alpha = 0.85f),
                        1.0f to LagCheckColors.Background
                    )
                )
        )

        // Conteúdo
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(LagCheckSpacing.space3),
            verticalArrangement = Arrangement.Bottom
        ) {
            Text(
                text = game.name,
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                color = LagCheckColors.TextPrimary,
                maxLines = 1
            )
            Spacer(modifier = Modifier.height(LagCheckSpacing.space1))
            Text(
                text = tr("1 toque ▸"),
                style = LagCheckTypography.MonoSmall,
                fontSize = 11.sp,
                color = LagCheckColors.AccentPrimaryLight
            )
        }
    }
}
