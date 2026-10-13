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
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material3.Icon
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
import com.lagcheck.core.designsystem.components.VerdictIndicatorBadge
import com.lagcheck.core.designsystem.components.WhatsAppLogo
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.AppLocale
import com.lagcheck.domain.presentation.RouteReport
import com.lagcheck.android.data.RouteReportPdfExporter
import com.lagcheck.android.ui.trf

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

    val pingText = evaluation.pingMs?.let { "%.0f ms".format(java.util.Locale.ROOT, it) } ?: "— ms"
    val jitterText = evaluation.jitterMs?.let { trf("%.0f ms jitter", it) } ?: tr("— ms jitter")
    val lossText = evaluation.packetLossPercentage?.let { trf("%.1f%% perda", it) } ?: tr("— perda")
    val regionLabel = evaluation.regionLabel

    fun shareToDiscord() {
        val cardFile = LagCheckDiscordCardExporter.generateDiscordShareCard(
            context = context,
            gameName = game.name,
            regionName = regionLabel,
            verdict = evaluation.verdict,
            pingMs = evaluation.pingMs,
            jitterMs = evaluation.jitterMs,
            packetLossPercentage = evaluation.packetLossPercentage,
            isWiFi = evaluation.connectionType.contains("Wi-Fi", ignoreCase = true)
        )
        val quote = LagCheckDiscordCardExporter.gamerQuote(evaluation.verdict)
        val shareText = "🎮 LagCheck · ${game.name}\n$quote\nhttps://lagcheck.app"

        // Copiar texto para o clipboard para facilidade no Discord
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("LagCheck Discord", shareText))
        Toast.makeText(context, tr("Texto copiado para colar no Discord!"), Toast.LENGTH_SHORT).show()

        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = if (cardFile != null) "image/png" else "text/plain"
            putExtra(Intent.EXTRA_TEXT, shareText)
            if (cardFile != null) {
                val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", cardFile)
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        }
        context.startActivity(Intent.createChooser(shareIntent, tr("Compartilhar no Discord")))
    }

    fun shareToWhatsApp() {
        val cardFile = LagCheckDiscordCardExporter.generateDiscordShareCard(
            context = context,
            gameName = game.name,
            regionName = regionLabel,
            verdict = evaluation.verdict,
            pingMs = evaluation.pingMs,
            jitterMs = evaluation.jitterMs,
            packetLossPercentage = evaluation.packetLossPercentage,
            isWiFi = evaluation.connectionType.contains("Wi-Fi", ignoreCase = true)
        )
        val quote = LagCheckDiscordCardExporter.gamerQuote(evaluation.verdict)
        val whatsappText = """
            🎮 *LagCheck — ${game.name}*
            *${tr("Veredito")}:* ${evaluation.headline}
            ⏱ *Ping:* $pingText | *Jitter:* $jitterText | *${tr("Perda")}:* $lossText
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
        context.startActivity(Intent.createChooser(shareIntent, tr("Enviar via WhatsApp")))
    }

    fun exportPDF() {
        val stamp = java.text.SimpleDateFormat("dd/MM/yyyy HH:mm", java.util.Locale.ROOT).format(java.util.Date(evaluation.timestamp))
        val document = RouteReport.build(evaluation, game.name, trf("Gerado em %s", stamp), AppLocale.language)
        val fileName = "lagcheck-${game.id}-${java.text.SimpleDateFormat("yyyyMMdd-HHmm", java.util.Locale.ROOT).format(java.util.Date(evaluation.timestamp))}"
        val file = RouteReportPdfExporter.export(context, document, fileName)
        if (file == null) {
            Toast.makeText(context, tr("Não deu para gerar o relatório."), Toast.LENGTH_SHORT).show()
            return
        }
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            putExtra(Intent.EXTRA_SUBJECT, trf("Relatório LagCheck - %s", game.name))
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        context.startActivity(Intent.createChooser(shareIntent, tr("Exportar Relatório")))
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
            .padding(horizontal = 24.dp)
            .verticalScroll(rememberScrollState())
    ) {
        // 1. Top bar: Fechar e Contexto
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(64.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .clickable { onClose() },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                    contentDescription = tr("Voltar"),
                    tint = LagCheckColors.TextPrimary
                )
            }

            Text(
                text = listOf(game.name, evaluation.platform, regionLabel).filter { it.isNotBlank() }.joinToString(" · "),
                style = LagCheckTypography.MonoData,
                color = LagCheckColors.TextMuted
            )
        }

        Spacer(modifier = Modifier.height(36.dp))

        // 2. Kicker: RESULTADO DO CHECK (11px mono uppercase)
        Text(
            text = tr("RESULTADO DO CHECK"),
            style = LagCheckTypography.MonoKicker,
            color = LagCheckColors.TextMuted
        )

        Spacer(modifier = Modifier.height(18.dp))

        // 3. Veredito Manchete: indicador acima, headline 44sp black
        VerdictIndicatorBadge(
            verdict = evaluation.verdict,
            size = 18.dp
        )
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = evaluation.headline.removePrefix("● ").removePrefix("▲ ").removePrefix("— "),
            style = LagCheckTypography.VerdictHero.copy(fontSize = 44.sp, lineHeight = 46.sp),
            color = verdictColor
        )

        Spacer(modifier = Modifier.height(20.dp))

        // 4. Frase do veredito
        Text(
            text = evaluation.subtitle,
            style = LagCheckTypography.BodySemibold,
            fontSize = 17.sp,
            fontWeight = FontWeight.Medium,
            color = LagCheckColors.TextPrimary,
            lineHeight = 24.sp
        )

        Spacer(modifier = Modifier.height(20.dp))

        // 5. Métricas inline em mono: "28 ms · 2 ms jitter · 0.0% perda"
        Text(
            text = "$pingText · $jitterText · $lossText",
            style = LagCheckTypography.MonoData,
            fontSize = 12.sp,
            lineHeight = 18.sp,
            fontWeight = FontWeight.SemiBold,
            color = LagCheckColors.TextMuted
        )

        Spacer(modifier = Modifier.height(32.dp))

        // 6. Card "O que mais pesou"
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(24.dp))
                .background(LagCheckColors.Surface)
                .padding(horizontal = 20.dp, vertical = 18.dp)
        ) {
            Column {
                Text(
                    text = tr("O QUE MAIS PESOU"),
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.TextMuted
                )
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = evaluation.primaryWeight,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = LagCheckColors.TextPrimary
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // 7. Ações Principais: "Ver detalhes" antes de "Testar novamente"
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            PrimaryButton(
                text = tr("Testar novamente"),
                onClick = onRetry,
                height = 56.dp
            )

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
                    .clip(RoundedCornerShape(percent = 50))
                    .background(LagCheckColors.Surface)
                    .clickable { onDetails() },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = tr("Ver detalhes"),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = LagCheckColors.TextPrimary
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            // 8. Ações Utilitárias Compactas: Discord, WhatsApp e PDF
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Discord
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(48.dp)
                        .clip(RoundedCornerShape(percent = 50))
                        .background(LagCheckColors.Surface)
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
                        .height(48.dp)
                        .clip(RoundedCornerShape(percent = 50))
                        .background(LagCheckColors.Surface)
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
                        .height(48.dp)
                        .clip(RoundedCornerShape(percent = 50))
                        .background(LagCheckColors.Surface)
                        .clickable { exportPDF() },
                    contentAlignment = Alignment.Center
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        PdfDocumentIcon(size = 13.dp, color = LagCheckColors.TextSecondary)
                        Text(
                            text = tr("PDF"),
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = LagCheckColors.TextSecondary
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(32.dp))
    }
}
