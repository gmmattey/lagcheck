package com.lagcheck.android.ui.check

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.Canvas
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.core.designsystem.components.MeasurementLiveTrail
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.android.ui.CancelReason
import com.lagcheck.android.ui.headline
import com.lagcheck.android.ui.tr

/**
 * 03 · Medição ao Vivo (Trilha Viva de Medição).
 * Paridade 1:1 com o protótipo de alta fidelidade Open Design (Screen 03 · Medição ao vivo).
 * Inclui modal de consentimento de dados móveis (até 10 MB).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CheckCockpitScreen(
    game: CatalogGame,
    platform: String,
    connectionType: String,
    progressRatio: Float,
    currentPingMs: Double?,
    isPhaseRest: Boolean,
    isWiFi: Boolean,
    isCancelled: Boolean = false,
    cancelReason: CancelReason? = null,
    destinationName: String = "",
    showMobileDataConsent: Boolean = false,
    onCancel: () -> Unit,
    onRetry: () -> Unit,
    onConfirmMobileData: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 22.dp)
        ) {
            // Topo: "Cancelar" (esquerda) + Nome do Jogo (direita em mono)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(10.dp))
                        .clickable { onCancel() }
                        .defaultMinSize(minWidth = 44.dp, minHeight = 44.dp)
                        .padding(horizontal = 7.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = tr("Cancelar"),
                        fontSize = 14.sp,
                        color = LagCheckColors.TextMuted
                    )
                }

                Text(
                    text = game.name,
                    style = LagCheckTypography.MonoData,
                    color = LagCheckColors.TextMuted
                )
            }

            Spacer(modifier = Modifier.weight(1f))

            if (isCancelled) {
                // Estado de Conexão Alterada / Cancelada (checkAlert no protótipo)
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = tr(cancelReason.headline()),
                        style = LagCheckTypography.SectionHeader.copy(fontSize = 28.sp),
                        color = LagCheckColors.TextPrimary,
                        textAlign = TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = tr("O teste foi cancelado para preservar a integridade da medição."),
                        style = LagCheckTypography.BodyMedium,
                        color = LagCheckColors.TextMuted,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 30.dp)
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(13.dp))
                            .border(1.dp, LagCheckColors.Border, RoundedCornerShape(13.dp))
                            .clickable { onRetry() }
                            .height(48.dp)
                            .padding(horizontal = 19.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = tr("Tentar novamente"),
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold,
                            color = LagCheckColors.TextPrimary
                        )
                    }
                }
            } else {
                // Trilha Viva com 3 Nós e Pacotes Viajando
                MeasurementLiveTrail(
                    destinationName = destinationName.ifEmpty { "…" },
                    currentRTT = currentPingMs,
                    progress = progressRatio,
                    isPhaseRest = isPhaseRest,
                    gameName = game.name,
                    isWiFi = isWiFi,
                    connectionLabel = connectionType,
                    textStatusRest = tr("Medindo rota em repouso…"),
                    textStatusLoad = tr("Avaliando sob carga…"),
                    textDetailRest = tr("O check preserva uma leitura estável."),
                    textDetailLoad = tr("Simulando tráfego simultâneo para detectar oscilações."),
                    textPhaseRest = tr("Fase 1 de 2 · Repouso"),
                    textPhaseLoad = tr("Fase 2 de 2 · Carga"),
                    textNodeDevice = if (platform.equals("Mobile", ignoreCase = true) || platform.equals("iPhone", ignoreCase = true) || platform.equals("Android", ignoreCase = true)) tr("Seu Celular") else platform,
                    textNodeLocalSubtitle = tr("Rede local"),
                    textNodeServer = tr("Região Gamer"),
                    modifier = Modifier.fillMaxWidth()
                )
            }

            Spacer(modifier = Modifier.weight(1f))
        }

        // Sheet de Consentimento para Uso de Dados Móveis (1:1 com protótipo)
        if (showMobileDataConsent) {
            val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false)
            ModalBottomSheet(
                onDismissRequest = onCancel,
                sheetState = sheetState,
                containerColor = LagCheckColors.Background,
                dragHandle = {
                    Box(
                        modifier = Modifier
                            .padding(top = 10.dp, bottom = 18.dp)
                            .size(width = 35.dp, height = 4.dp)
                            .clip(RoundedCornerShape(9.dp))
                            .background(LagCheckColors.Border)
                    )
                }
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 22.dp)
                        .padding(bottom = 32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Box(
                        modifier = Modifier
                            .size(80.dp)
                            .clip(androidx.compose.foundation.shape.CircleShape)
                            .background(LagCheckColors.AccentPrimarySubtle),
                        contentAlignment = Alignment.Center
                    ) {
                        CellularAntennaIcon()
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    Text(
                        text = tr("Uso de dados móveis"),
                        style = LagCheckTypography.SectionHeader.copy(fontSize = 24.sp),
                        color = LagCheckColors.TextPrimary,
                        textAlign = TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = tr("O teste usa dados móveis para avaliar sua conexão sob carga."),
                        style = LagCheckTypography.BodyMedium,
                        color = LagCheckColors.TextMuted,
                        textAlign = TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = tr("Limite máximo de transferência: até 10 MB (cerca de 15 segundos)."),
                        style = LagCheckTypography.Subtext,
                        color = LagCheckColors.TextTertiary,
                        textAlign = TextAlign.Center
                    )

                    Spacer(modifier = Modifier.height(32.dp))

                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(48.dp)
                                .clip(RoundedCornerShape(11.dp))
                                .background(LagCheckColors.AccentPrimary)
                                .clickable { onConfirmMobileData() },
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = tr("Continuar com dados móveis"),
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }

                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(48.dp)
                                .clip(RoundedCornerShape(11.dp))
                                .clickable { onCancel() },
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = tr("Cancelar"),
                                fontSize = 15.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = LagCheckColors.TextMuted
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CellularAntennaIcon() {
    val tint = LagCheckColors.AccentPrimary
    Canvas(modifier = Modifier.size(40.dp)) {
        val unit = size.width / 40f
        val stroke = 2.5.dp.toPx()
        val center = Offset(20f * unit, 18f * unit)
        drawCircle(tint, radius = 3f * unit, center = center)
        drawLine(tint, Offset(20f * unit, 23f * unit), Offset(20f * unit, 35f * unit), stroke, cap = StrokeCap.Round)
        for (side in listOf(-1f, 1f)) {
            for ((inner, outer, bulge) in listOf(Triple(15f, 11f, 2f), Triple(10f, 6f, 5f))) {
                val path = Path().apply {
                    moveTo((20f + side * (20f - inner)) * unit, outer * unit)
                    quadraticTo((20f + side * (20f - inner + bulge)) * unit, 18f * unit, (20f + side * (20f - inner)) * unit, (36f - outer) * unit)
                }
                drawPath(path, tint, style = Stroke(width = stroke, cap = StrokeCap.Round))
            }
        }
    }
}
