package com.lagcheck.android.ui.duel

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast
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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf
import com.lagcheck.core.designsystem.components.DiscordLogo
import com.lagcheck.core.designsystem.components.PrimaryButton
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.core.designsystem.theme.LagCheckRadius
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.HostDuelPayload
import com.lagcheck.domain.model.HostDuelResolver
import com.lagcheck.domain.model.HostDuelWinner
import kotlin.math.roundToInt

/**
 * Tela de Confronto do Duelo de Host no Android (Decisão 112).
 * Design Dark Competitive UI com profundidade tonal de camadas (sem linhas em cards).
 */
@Composable
fun HostDuelVersusScreen(
    challenger: HostDuelPayload,
    opponent: HostDuelPayload,
    gameTitle: String,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val resolution = remember(challenger, opponent) {
        HostDuelResolver.resolve(challenger, opponent)
    }

    fun copyDiscordText() {
        val winnerName = when (resolution.winner) {
            HostDuelWinner.CHALLENGER -> challenger.challengerNick.ifBlank { "Desafiante" }
            HostDuelWinner.OPPONENT -> opponent.challengerNick.ifBlank { "Você" }
            HostDuelWinner.TIE -> "Empate"
        }
        val text = """
            ⚔️ **DUELO DE HOST — $gameTitle**
            🏆 **${resolution.headline}**
            _${resolution.subheadline}_
            
            📊 **Placar da Rota:**
            • ${challenger.challengerNick.ifBlank { "Desafiante" }}: ${challenger.p50Ms.roundToInt()}ms (${challenger.packetLossPercent.roundToInt()}% perda)
            • ${opponent.challengerNick.ifBlank { "Você" }}: ${opponent.p50Ms.roundToInt()}ms (${opponent.packetLossPercent.roundToInt()}% perda)
            
            Link do confronto:
            ${challenger.toWebUrl()}
        """.trimIndent()

        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
        clipboard?.setPrimaryClip(ClipData.newPlainText("Duelo de Host", text))
        Toast.makeText(context, tr("Veredito copiado para a call do Discord!"), Toast.LENGTH_SHORT).show()
    }

    fun shareDuel() {
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, challenger.generateDiscordShareText(gameTitle))
        }
        context.startActivity(Intent.createChooser(shareIntent, tr("Compartilhar Duelo de Host")))
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
            .padding(horizontal = 24.dp)
            .verticalScroll(rememberScrollState())
    ) {
        // Top Bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(64.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(LagCheckRadius.sm))
                    .clickable { onDismiss() },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                    contentDescription = tr("Voltar"),
                    tint = LagCheckColors.TextPrimary
                )
            }

            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(6.dp)
                        .clip(CircleShape)
                        .background(LagCheckColors.AccentPrimary)
                )
                Text(
                    text = "${gameTitle.uppercase()} • ${tr("DUELO DE HOST")}",
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.TextTertiary,
                    letterSpacing = 0.8.sp
                )
            }

            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(LagCheckRadius.sm))
                    .clickable { onDismiss() },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = tr("Fechar"),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = LagCheckColors.TextSecondary
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Veredito do Lobby
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                text = tr("VEREDITO DO LOBBY"),
                style = LagCheckTypography.MonoSmall,
                fontWeight = FontWeight.Black,
                color = LagCheckColors.Good,
                letterSpacing = 1.2.sp
            )

            Text(
                text = resolution.headline,
                style = LagCheckTypography.PageTitle.copy(fontSize = 32.sp, lineHeight = 38.sp),
                fontWeight = FontWeight.Black,
                color = Color.White
            )

            Text(
                text = resolution.subheadline,
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium,
                color = LagCheckColors.TextSecondary
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Arena de Lutadores (Profundidade e Elevação, Zero Linhas de Borda)
        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
            if (resolution.winner == HostDuelWinner.OPPONENT) {
                FighterCard(
                    payload = opponent,
                    isWinner = true,
                    defaultLabel = tr("Você")
                )
                FighterCard(
                    payload = challenger,
                    isWinner = false,
                    defaultLabel = tr("Desafiante")
                )
            } else {
                FighterCard(
                    payload = challenger,
                    isWinner = resolution.winner == HostDuelWinner.CHALLENGER,
                    defaultLabel = tr("Desafiante")
                )
                FighterCard(
                    payload = opponent,
                    isWinner = false,
                    defaultLabel = tr("Você")
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Expiração e Regra
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 4.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            val remainingMin = minOf(challenger.remainingSeconds(), opponent.remainingSeconds()) / 60
            Text(
                text = trf("Expira em %d min", maxOf(1L, remainingMin)),
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextTertiary
            )
            Text(
                text = tr("Duelo 1v1 • Regra de host v1"),
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextTertiary
            )
        }

        Spacer(modifier = Modifier.height(32.dp))

        // Ações Principais
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Copiar pro Discord
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
                    .clip(RoundedCornerShape(percent = 50))
                    .background(Color(0xFF5865F2))
                    .clickable { copyDiscordText() },
                contentAlignment = Alignment.Center
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    DiscordLogo(size = 20.dp, color = Color.White)
                    Text(
                        text = tr("Copiar Veredito pro Discord"),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }

            // Compartilhar Duelo
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
                    .clip(RoundedCornerShape(percent = 50))
                    .background(LagCheckColors.Surface)
                    .clickable { shareDuel() },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = tr("Compartilhar Link do Duelo"),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = LagCheckColors.TextPrimary
                )
            }

            // Voltar
            PrimaryButton(
                text = tr("Voltar ao Início"),
                onClick = onDismiss,
                height = 56.dp,
                containerColor = LagCheckColors.Surface,
                contentColor = LagCheckColors.TextSecondary
            )
        }

        Spacer(modifier = Modifier.height(36.dp))
    }
}

@Composable
private fun FighterCard(
    payload: HostDuelPayload,
    isWinner: Boolean,
    defaultLabel: String
) {
    val name = payload.challengerNick.ifBlank { defaultLabel }
    val (verdictLabel, verdictColor) = when (payload.verdict) {
        GameReadinessVerdict.READY -> "● " + tr("PRONTO") to LagCheckColors.Good
        GameReadinessVerdict.CAUTION -> "▲ " + tr("INSTÁVEL") to LagCheckColors.SemanticCaution
        GameReadinessVerdict.NOT_READY -> "▲ " + tr("EVITAR") to LagCheckColors.CoralWarning
        GameReadinessVerdict.INCONCLUSIVE -> "— " + tr("INCONCLUSIVO") to LagCheckColors.TextSecondary
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(LagCheckRadius.lg))
            .background(if (isWinner) LagCheckColors.Panel else LagCheckColors.Surface)
            .padding(20.dp)
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(28.dp)
                            .clip(CircleShape)
                            .background(if (isWinner) LagCheckColors.AccentPrimary else LagCheckColors.Border),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = name.take(1).uppercase(),
                            style = LagCheckTypography.MonoSmall,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }

                    Text(
                        text = name,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = LagCheckColors.TextPrimary
                    )

                    if (isWinner) {
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(LagCheckRadius.sm))
                                .background(LagCheckColors.AccentPrimary.copy(alpha = 0.2f))
                                .padding(horizontal = 8.dp, vertical = 2.dp)
                        ) {
                            Text(
                                text = tr("HOST OFICIAL"),
                                style = LagCheckTypography.MonoSmall,
                                fontWeight = FontWeight.Black,
                                fontSize = 10.sp,
                                color = LagCheckColors.AccentPrimaryLight
                            )
                        }
                    }
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
                        text = "${payload.p50Ms.roundToInt()}",
                        style = LagCheckTypography.ScoreNumber.copy(fontSize = 38.sp),
                        color = if (isWinner) Color.White else LagCheckColors.TextPrimary
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
                    text = String.format(java.util.Locale.US, "%.1f%% perda · %dms jitter", payload.packetLossPercent, payload.jitterMs.roundToInt()),
                    style = LagCheckTypography.MonoData,
                    fontSize = 12.sp,
                    color = LagCheckColors.TextSecondary,
                    modifier = Modifier.padding(bottom = 6.dp)
                )
            }
        }
    }
}
