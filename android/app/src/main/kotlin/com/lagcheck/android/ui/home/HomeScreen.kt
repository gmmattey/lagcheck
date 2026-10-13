package com.lagcheck.android.ui.home

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
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
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.data.CheckHistoryItem
import com.lagcheck.android.ui.components.HomeTopBar
import com.lagcheck.android.ui.components.PlatformHealthBanner
import com.lagcheck.network.health.PlatformHealth
import com.lagcheck.core.designsystem.components.PlatformGlyph
import com.lagcheck.core.designsystem.components.PrimaryButton
import com.lagcheck.core.designsystem.components.WifiIcon
import com.lagcheck.core.designsystem.components.RadioSignalPill
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.android.ui.tr

/**
 * 01 · Home (Modo Pronto).
 * Paridade 1:1 estrita com o protótipo de alta fidelidade Open Design (Screen 01 · Home).
 */
@Composable
fun HomeScreen(
    selectedGame: CatalogGame,
    platform: String,
    connectionType: String,
    radioSnapshot: RadioTelemetrySnapshot?,
    latestCheck: CheckHistoryItem?,
    onStartCheck: () -> Unit,
    onOpenGames: () -> Unit,
    onOpenHistory: () -> Unit,
    onOpenLatestResult: () -> Unit,
    onOpenNetworkCockpit: () -> Unit = {},
    /** Problema reportado na rede do console escolhido. Nulo = nada a avisar. */
    platformHealth: PlatformHealth? = null,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val wifi = radioSnapshot?.wifiDetails
    val radioLabel = when {
        wifi != null -> {
            // Banda só quando o sistema informou a frequência. Antes, 6 GHz e "desconhecida" apareciam como "5 GHz".
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
            .padding(horizontal = 24.dp)
            .verticalScroll(rememberScrollState())
    ) {
        // 1. Topline: Wordmark oficial (88px) + Ícone de Rede + Botão '…' (Ajustes)
        HomeTopBar(
            onOpenNetworkCockpit = onOpenNetworkCockpit,
            modifier = Modifier.padding(top = 8.dp)
        )

        Spacer(modifier = Modifier.height(6.dp))

        // 2. Network Row: Pílula central com ponto pulsante verde/âmbar
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center
        ) {
            RadioSignalPill(
                label = radioLabel,
                isWarning = isRadioWarning
            )
        }

        Spacer(modifier = Modifier.height(15.dp))

        // 3. Hero: Capa com fade inferior suave + Nome do Jogo (38px display) + Plataforma
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // A arte ocupa a largura da tela; o restante do conteúdo respeita as margens.
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(204.dp)
                    .layout { measurable, constraints ->
                        val bleed = 24.dp.roundToPx()
                        val expandedWidth = constraints.maxWidth + bleed * 2
                        val placeable = measurable.measure(
                            constraints.copy(
                                minWidth = expandedWidth,
                                maxWidth = expandedWidth
                            )
                        )
                        layout(constraints.maxWidth, placeable.height) {
                            placeable.place(-bleed, 0)
                        }
                    }
                    .background(LagCheckColors.Surface)
            ) {
                com.lagcheck.android.ui.components.RemoteGameArtwork(selectedGame, Modifier.fillMaxSize())

                // Gradiente escuro para mesclar perfeitamente no fundo #0B0D10
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.verticalGradient(
                                0.0f to Color.Transparent,
                                0.48f to Color.Transparent,
                                0.78f to LagCheckColors.Background.copy(alpha = 0.52f),
                                1.0f to LagCheckColors.Background
                            )
                        )
                )
            }

            Spacer(modifier = Modifier.height(19.dp))

            // Nome do jogo em display grande (38px, -0.06em letter-spacing)
            Text(
                text = selectedGame.name,
                style = LagCheckTypography.HomeGameTitle,
                color = LagCheckColors.TextPrimary,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )

            Spacer(modifier = Modifier.height(9.dp))

            // Plataforma e conexão em glifos: "[celular] [Wi-Fi]" (Decisão 80)
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                PlatformGlyph(platform = "Mobile", size = 18.dp) // o aparelho que mede é sempre o celular (Decisão 80)
                if (connectionType.contains("Wi-Fi", ignoreCase = true)) {
                    WifiIcon(size = 18.dp, color = LagCheckColors.TextMuted)
                } else if (connectionType.isNotBlank() && connectionType != "—") {
                    Text(
                        text = connectionType,
                        style = LagCheckTypography.Subtext.copy(fontSize = 14.sp),
                        color = LagCheckColors.TextMuted
                    )
                }
            }
        }

        if (platformHealth != null) {
            Spacer(modifier = Modifier.height(16.dp))
            PlatformHealthBanner(platformHealth)
        }

        Spacer(modifier = Modifier.height(28.dp))

        // 4. CTA Primário: "Checar agora" (62dp, Roxo Gamer #7C3AED, raio 17dp)
        PrimaryButton(
            text = tr("Checar agora"),
            onClick = onStartCheck,
            height = 62.dp
        )

        // 5. Linha de Último Resultado (ex: "● Pronto para Ranked · 8 min atrás")
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
            GameReadinessVerdict.CAUTION, GameReadinessVerdict.NOT_READY -> LagCheckColors.CoralWarning
            else -> LagCheckColors.TextMuted
        }

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 13.dp)
                .clickable { onOpenLatestResult() }
                .padding(vertical = 8.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = lastCheckText,
                style = LagCheckTypography.MonoData,
                color = lastColor
            )
        }

        Spacer(modifier = Modifier.height(27.dp))

        // 6. Atalhos Secundários: "Trocar jogo ›" e "Histórico ›"
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Trocar jogo ›
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .clickable { onOpenGames() }
                    .padding(horizontal = 14.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = tr("Trocar jogo"),
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = LagCheckColors.TextMuted
                )
                Text(
                    text = " ›",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = LagCheckColors.TextPrimary
                )
            }

            Spacer(modifier = Modifier.padding(horizontal = 14.dp))

            // Histórico ›
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .clickable { onOpenHistory() }
                    .padding(horizontal = 14.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = tr("Histórico"),
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = LagCheckColors.TextMuted
                )
                Text(
                    text = " ›",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = LagCheckColors.TextPrimary
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))
    }
}
