package com.lagcheck.android.ui.check

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
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
                    .height(52.dp)
                    .padding(top = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(10.dp))
                        .clickable { onCancel() }
                        .padding(horizontal = 7.dp, vertical = 6.dp)
                ) {
                    Text(
                        text = tr("Cancelar"),
                        fontSize = 14.sp,
                        color = LagCheckColors.TextMuted
                    )
                }

                Text(
                    text = "${game.name} · $platform",
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
                            .padding(horizontal = 19.dp, vertical = 12.dp)
                    ) {
                        Text(
                            text = tr("Tentar novamente"),
                            fontSize = 14.sp,
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
                    modifier = Modifier.fillMaxWidth()
                )
            }

            Spacer(modifier = Modifier.weight(1.3f))
        }

        // Sheet de Consentimento para Uso de Dados Móveis (1:1 com protótipo)
        if (showMobileDataConsent) {
            val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
            ModalBottomSheet(
                onDismissRequest = onCancel,
                sheetState = sheetState,
                containerColor = LagCheckColors.Surface,
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
                        .padding(bottom = 32.dp)
                ) {
                    Text(
                        text = tr("Usar dados móveis?"),
                        style = LagCheckTypography.SectionHeader.copy(fontSize = 24.sp),
                        color = LagCheckColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = tr("Este teste pode consumir até 10 MB."),
                        style = LagCheckTypography.BodyMedium,
                        color = LagCheckColors.TextMuted
                    )
                    Spacer(modifier = Modifier.height(20.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(48.dp)
                                .clip(RoundedCornerShape(11.dp))
                                .border(1.dp, LagCheckColors.Border, RoundedCornerShape(11.dp))
                                .clickable { onCancel() },
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = tr("Cancelar"),
                                fontSize = 15.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = LagCheckColors.TextPrimary
                            )
                        }

                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(48.dp)
                                .clip(RoundedCornerShape(11.dp))
                                .background(LagCheckColors.AccentPrimary)
                                .clickable { onConfirmMobileData() },
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = tr("Continuar"),
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }
                    }
                }
            }
        }
    }
}
