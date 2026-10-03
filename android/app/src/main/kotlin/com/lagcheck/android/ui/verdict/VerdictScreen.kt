package com.lagcheck.android.ui.verdict

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import com.lagcheck.android.data.LagCheckDiscordCardExporter
import com.lagcheck.core.designsystem.components.DiscordLogo
import com.lagcheck.core.designsystem.components.PdfDocumentIcon
import com.lagcheck.core.designsystem.components.PrimaryButton
import com.lagcheck.core.designsystem.components.WhatsAppLogo
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict

/**
 * 04 · Veredito.
 * Paridade 1:1 estrita com CheckCompletoResultView.swift do iOS.
 * Inclui:
 * - Manchete de veredito protagonista
 * - Telemetria compacta inline
 * - Barra de estabilidade contínua da rota
 * - Card "O que mais pesou"
 * - Ações primárias ("Testar novamente", "Ver detalhes")
 * - Ações utilitárias compactas (Discord, WhatsApp e PDF)
 */
@Composable
fun VerdictScreen(
    game: CatalogGame,
    evaluation: GameReadinessEvaluation,
    onRetry: () -> Unit,
    onDetails: () -> Unit,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current

    val verdictColor = when (evaluation.verdict) {
        GameReadinessVerdict.READY -> LagCheckColors.Good
        GameReadinessVerdict.CAUTION -> LagCheckColors.SemanticCaution
        GameReadinessVerdict.NOT_READY -> LagCheckColors.CoralWarning
        GameReadinessVerdict.INCONCLUSIVE -> LagCheckColors.Inconclusive
    }

    val verdictSymbol = when (evaluation.verdict) {
        GameReadinessVerdict.READY -> "●"
        GameReadinessVerdict.CAUTION, GameReadinessVerdict.NOT_READY -> "▲"
        GameReadinessVerdict.INCONCLUSIVE -> "—"
    }

    val pingText = evaluation.pingMs?.let { "%.0f ms".format(it) } ?: "— ms"
    val jitterText = evaluation.jitterMs?.let { "%.0f ms jitter".format(it) } ?: "— ms jitter"
    val lossText = evaluation.packetLossPercentage?.let { "%.1f%% perda".format(it) } ?: "— perda"

    // Razão de estabilidade para a barra contínua (0.0 a 1.0)
    val stabilityRatio = when (evaluation.verdict) {
        GameReadinessVerdict.READY -> 0.95f
        GameReadinessVerdict.CAUTION -> 0.65f
        GameReadinessVerdict.NOT_READY -> 0.25f
        GameReadinessVerdict.INCONCLUSIVE -> 0.10f
    }

    val stabilitySummary = when (evaluation.verdict) {
        GameReadinessVerdict.READY -> "Excelente sob carga"
        GameReadinessVerdict.CAUTION -> "Oscilações detectadas"
        GameReadinessVerdict.NOT_READY -> "Gargalo severo sob carga"
        GameReadinessVerdict.INCONCLUSIVE -> "Amostras insuficientes"
    }

    fun shareToDiscord() {
        val cardFile = LagCheckDiscordCardExporter.generateDiscordShareCard(
            context = context,
            gameName = game.name,
            regionName = "São Paulo",
            verdict = evaluation.verdict,
            pingMs = evaluation.pingMs,
            jitterMs = evaluation.jitterMs,
            packetLossPercentage = evaluation.packetLossPercentage,
            isWiFi = true
        )
        val quote = LagCheckDiscordCardExporter.gamerQuote(evaluation.verdict)
        val shareText = "🎮 LagCheck · ${game.name}\n$quote\nhttps://lagcheck.app"

        // Copiar texto para o clipboard para facilidade no Discord
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("LagCheck Discord", shareText))
        Toast.makeText(context, "Texto copiado para colar no Discord!", Toast.LENGTH_SHORT).show()

        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = if (cardFile != null) "image/png" else "text/plain"
            putExtra(Intent.EXTRA_TEXT, shareText)
            if (cardFile != null) {
                val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", cardFile)
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        }
        context.startActivity(Intent.createChooser(shareIntent, "Compartilhar no Discord"))
    }

    fun shareToWhatsApp() {
        val cardFile = LagCheckDiscordCardExporter.generateDiscordShareCard(
            context = context,
            gameName = game.name,
            regionName = "São Paulo",
            verdict = evaluation.verdict,
            pingMs = evaluation.pingMs,
            jitterMs = evaluation.jitterMs,
            packetLossPercentage = evaluation.packetLossPercentage,
            isWiFi = true
        )
        val quote = LagCheckDiscordCardExporter.gamerQuote(evaluation.verdict)
        val whatsappText = """
            🎮 *LagCheck — ${game.name}*
            *Veredito:* ${evaluation.headline}
            ⏱ *Ping:* $pingText | *Jitter:* $jitterText | *Perda:* $lossText
            $quote
            https://lagcheck.app
        """.trimIndent()

        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = if (cardFile != null) "image/png" else "text/plain"
            putExtra(Intent.EXTRA_TEXT, whatsappText)
            if (cardFile != null) {
                val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", cardFile)
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        }
        context.startActivity(Intent.createChooser(shareIntent, "Enviar via WhatsApp"))
    }

    fun exportPDF() {
        val report = """
            ====================================
            LAGCHECK · RELATÓRIO OFICIAL DE ROTA
            ====================================
            Jogo: ${game.name}
            Plataforma: ${evaluation.platform}
            Região: São Paulo
            Veredito: ${evaluation.headline}
            Lagcheck Score: ${evaluation.score}

            TELEMETRIA:
            • Latência P50: $pingText
            • Oscilação (Jitter): $jitterText
            • Perda de Pacotes: $lossText
            • Pior Spike: ${evaluation.worstSpikeMs?.let { "%.0f ms".format(it) } ?: "—"}

            ORIGEM DA EVIDÊNCIA:
            • O que mais pesou: ${evaluation.primaryWeight}
            
            https://lagcheck.app
        """.trimIndent()

        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, "Relatório LagCheck - ${game.name}")
            putExtra(Intent.EXTRA_TEXT, report)
        }
        context.startActivity(Intent.createChooser(shareIntent, "Exportar Relatório"))
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
            .padding(horizontal = 22.dp)
            .verticalScroll(rememberScrollState())
    ) {
        // 1. Top bar: "Fechar" (esquerda) + "[Game] · [Plataforma] · São Paulo" (direita)
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
                    .clickable { onClose() }
                    .padding(horizontal = 7.dp, vertical = 6.dp)
            ) {
                Text(
                    text = "Fechar",
                    fontSize = 14.sp,
                    color = LagCheckColors.TextMuted
                )
            }

            Text(
                text = "${game.name} · ${evaluation.platform} · São Paulo",
                style = LagCheckTypography.MonoData,
                color = LagCheckColors.TextMuted
            )
        }

        Spacer(modifier = Modifier.height(36.dp))

        // 2. Kicker: RESULTADO DO CHECK (11px mono uppercase)
        Text(
            text = "RESULTADO DO CHECK",
            style = LagCheckTypography.MonoKicker,
            color = LagCheckColors.TextMuted
        )

        Spacer(modifier = Modifier.height(13.dp))

        // 3. Veredito Manchete (com símbolo ● ou ▲)
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = verdictSymbol,
                fontSize = 32.sp,
                fontWeight = FontWeight.Black,
                color = verdictColor
            )
            Text(
                text = evaluation.headline.removePrefix("● ").removePrefix("▲ ").removePrefix("— "),
                style = LagCheckTypography.VerdictHero,
                color = verdictColor
            )
        }

        Spacer(modifier = Modifier.height(19.dp))

        // 4. Result Copy ("Sua conexão está estável o suficiente para [Game] agora.")
        Text(
            text = "Sua conexão está estável o suficiente para ${game.name} agora.",
            style = LagCheckTypography.BodySemibold,
            color = LagCheckColors.TextPrimary
        )

        Spacer(modifier = Modifier.height(22.dp))

        // 5. Métricas Inline em Monoespaçado: "31 ms · 3 ms jitter · 0,4% perda"
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text(
                text = pingText,
                style = LagCheckTypography.MonoData,
                fontWeight = FontWeight.SemiBold,
                color = LagCheckColors.TextPrimary
            )
            Text(text = "·", style = LagCheckTypography.MonoData, color = LagCheckColors.TextMuted)
            Text(
                text = jitterText,
                style = LagCheckTypography.MonoData,
                fontWeight = FontWeight.SemiBold,
                color = LagCheckColors.TextPrimary
            )
            Text(text = "·", style = LagCheckTypography.MonoData, color = LagCheckColors.TextMuted)
            Text(
                text = lossText,
                style = LagCheckTypography.MonoData,
                fontWeight = FontWeight.SemiBold,
                color = LagCheckColors.TextPrimary
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // 6. Barra Contínua de Estabilidade da Rota (Paridade 1:1 com iOS)
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "ESTABILIDADE DA ROTA",
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.TextMuted
                )
                Text(
                    text = stabilitySummary,
                    fontSize = 12.sp,
                    color = LagCheckColors.TextSecondary
                )
            }

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp)
                    .clip(RoundedCornerShape(999.dp))
                    .background(LagCheckColors.Panel)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth(fraction = stabilityRatio)
                        .height(6.dp)
                        .clip(RoundedCornerShape(999.dp))
                        .background(verdictColor)
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // 7. Card "O que mais pesou"
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(15.dp))
                .background(LagCheckColors.Surface)
                .border(1.dp, LagCheckColors.BorderStrong, RoundedCornerShape(15.dp))
                .padding(15.dp)
        ) {
            Column {
                Text(
                    text = "O QUE MAIS PESOU",
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.TextMuted
                )
                Spacer(modifier = Modifier.height(5.dp))
                Text(
                    text = evaluation.primaryWeight,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = LagCheckColors.TextPrimary
                )
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        // 8. Ações Principais: "Testar novamente" (56dp) e "Ver detalhes" (54dp)
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            PrimaryButton(
                text = "Testar novamente",
                onClick = onRetry,
                height = 56.dp
            )

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp)
                    .clip(RoundedCornerShape(16.dp))
                    .border(1.dp, LagCheckColors.BorderStrong, RoundedCornerShape(16.dp))
                    .clickable { onDetails() },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Ver detalhes",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = LagCheckColors.TextPrimary
                )
            }

            Spacer(modifier = Modifier.height(4.dp))

            // 9. Ações Utilitárias Compactas: Discord, WhatsApp e PDF (Paridade 1:1 com iOS)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Discord
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(44.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(LagCheckColors.Surface)
                        .border(1.dp, LagCheckColors.Border, RoundedCornerShape(12.dp))
                        .clickable { shareToDiscord() },
                    contentAlignment = Alignment.Center
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        DiscordLogo(size = 15.dp)
                        Text(
                            text = "Discord",
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = LagCheckColors.TextPrimary
                        )
                    }
                }

                // WhatsApp
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(44.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(LagCheckColors.Surface)
                        .border(1.dp, LagCheckColors.Border, RoundedCornerShape(12.dp))
                        .clickable { shareToWhatsApp() },
                    contentAlignment = Alignment.Center
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        WhatsAppLogo(size = 15.dp)
                        Text(
                            text = "WhatsApp",
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = LagCheckColors.TextPrimary
                        )
                    }
                }

                // PDF
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(44.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(LagCheckColors.Surface)
                        .border(1.dp, LagCheckColors.Border, RoundedCornerShape(12.dp))
                        .clickable { exportPDF() },
                    contentAlignment = Alignment.Center
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        PdfDocumentIcon(size = 14.dp, color = LagCheckColors.TextSecondary)
                        Text(
                            text = "PDF",
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = LagCheckColors.TextPrimary
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(32.dp))
    }
}
