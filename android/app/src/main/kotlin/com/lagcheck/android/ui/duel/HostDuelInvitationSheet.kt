package com.lagcheck.android.ui.duel

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf
import com.lagcheck.core.designsystem.components.PrimaryButton
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.HostDuelPayload
import kotlin.math.roundToInt

/**
 * Sheet de Confirmação em 1 Toque quando o usuário abre um link de Duelo de Host (Decisão 112).
 * Dá a chance do jogador conferir o Wi-Fi antes de iniciar a medição do jogo.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HostDuelInvitationSheet(
    duel: HostDuelPayload,
    gameName: String,
    onAccept: () -> Unit,
    onDecline: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val challengerName = duel.challengerNick.ifBlank { tr("Seu Duo") }

    ModalBottomSheet(
        onDismissRequest = onDecline,
        sheetState = sheetState,
        containerColor = LagCheckColors.Background,
        dragHandle = {
            Box(
                modifier = Modifier
                    .padding(top = 10.dp, bottom = 12.dp)
                    .size(width = 36.dp, height = 4.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(LagCheckColors.Border)
            )
        }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 36.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            // Header
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = "${gameName.uppercase()} • ${tr("DUELO DE HOST")}",
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.AccentPrimaryLight,
                    letterSpacing = 1.sp
                )
                Text(
                    text = tr("Quem puxa a ranked?"),
                    style = LagCheckTypography.SectionHeader.copy(fontSize = 26.sp),
                    color = LagCheckColors.TextPrimary
                )
                Text(
                    text = trf("%s quer decidir quem cria a sala no lobby.", challengerName),
                    fontSize = 14.sp,
                    color = LagCheckColors.TextSecondary
                )
            }

            // Card do desafiante com elevação e profundidade tonal (sem linhas de bordas)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(18.dp))
                    .background(LagCheckColors.Panel)
                    .padding(18.dp)
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(26.dp)
                                    .clip(CircleShape)
                                    .background(LagCheckColors.AccentPrimary),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = challengerName.take(1).uppercase(),
                                    style = LagCheckTypography.MonoSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White
                                )
                            }
                            Text(
                                text = challengerName,
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Bold,
                                color = LagCheckColors.TextPrimary
                            )
                        }

                        val (verdictLabel, verdictColor) = when (duel.verdict) {
                            GameReadinessVerdict.READY -> "● " + tr("PRONTO") to LagCheckColors.Good
                            GameReadinessVerdict.CAUTION -> "▲ " + tr("INSTÁVEL") to LagCheckColors.SemanticCaution
                            GameReadinessVerdict.NOT_READY -> "▲ " + tr("EVITAR") to LagCheckColors.CoralWarning
                            GameReadinessVerdict.INCONCLUSIVE -> "— " + tr("INCONCLUSIVO") to LagCheckColors.TextSecondary
                        }
                        Text(
                            text = verdictLabel,
                            style = LagCheckTypography.MonoSmall,
                            fontWeight = FontWeight.Bold,
                            color = verdictColor
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Bottom
                    ) {
                        Row(verticalAlignment = Alignment.Bottom) {
                            Text(
                                text = "${duel.p50Ms.roundToInt()}",
                                style = LagCheckTypography.ScoreNumber.copy(fontSize = 36.sp),
                                color = LagCheckColors.TextPrimary
                            )
                            Text(
                                text = " ms",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = LagCheckColors.TextSecondary,
                                modifier = Modifier.padding(bottom = 6.dp)
                            )
                        }

                        Text(
                            text = String.format(java.util.Locale.US, "%.1f%% perda · %dms jitter", duel.packetLossPercent, duel.jitterMs.roundToInt()),
                            style = LagCheckTypography.MonoData,
                            fontSize = 11.sp,
                            color = LagCheckColors.TextSecondary,
                            modifier = Modifier.padding(bottom = 6.dp)
                        )
                    }
                }
            }

            // Linha de tempo restante
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 4.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                val remainingMin = duel.remainingSeconds() / 60
                Text(
                    text = trf("Válido por mais %d min", maxOf(1L, remainingMin)),
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.TextTertiary
                )
                Text(
                    text = tr("Regra de host v1"),
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.TextTertiary
                )
            }

            Spacer(modifier = Modifier.height(2.dp))

            // Ações
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                PrimaryButton(
                    text = tr("Aceitar e Medir Minha Rota"),
                    onClick = onAccept,
                    height = 54.dp
                )

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(44.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .clickable { onDecline() },
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = tr("Recusar Desafio"),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = LagCheckColors.TextSecondary
                    )
                }
            }
        }
    }
}
