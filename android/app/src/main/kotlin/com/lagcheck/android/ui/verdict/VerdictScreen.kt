package com.lagcheck.android.ui.verdict

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.Image
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.widthIn
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
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import com.lagcheck.android.data.LagCheckDiscordCardExporter
import com.lagcheck.android.share.ShareMediaScene
import com.lagcheck.android.share.ShareNetworkBar
import com.lagcheck.android.share.openCardChooser
import com.lagcheck.android.share.PreparedShareCard
import com.lagcheck.android.share.PreparedShareCardSnapshot
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
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

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
    showNativeAd: Boolean = false,
    savedGamerNick: String = "",
    onSaveGamerNick: (String) -> Unit = {},
    lastDuelResolution: Pair<com.lagcheck.domain.model.HostDuelPayload, com.lagcheck.domain.model.HostDuelPayload>? = null,
    onViewDuelVersus: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val nativeAd = if (showNativeAd) com.lagcheck.android.ads.rememberNativeAd(com.lagcheck.session.ads.AdPlacement.RESULT) else null
    val context = LocalContext.current
    var showNickSheet by remember { mutableStateOf(false) }
    val shareScene = remember(evaluation, game) { ShareMediaScene.from(game.name, game.drawableResName, evaluation) }
    val shareSnapshot = remember(shareScene, evaluation.timestamp, AppLocale.language) {
        shareScene?.let { PreparedShareCardSnapshot.from(it, AppLocale.language.name, evaluation.timestamp.toString()) }
    }
    var preparedLinkCard by remember(shareSnapshot) { mutableStateOf<File?>(null) }
    var sharePreparationFailed by remember(shareSnapshot) { mutableStateOf(false) }
    var sharePreparationAttempt by remember(shareSnapshot) { mutableStateOf(0) }
    var previewBitmap by remember(preparedLinkCard) { mutableStateOf<android.graphics.Bitmap?>(null) }
    val shareStateLabel = when {
        sharePreparationFailed -> when (AppLocale.language.name) { "EN" -> "Share card failed"; "ES" -> "Error al preparar la tarjeta"; else -> "Falha ao preparar o card" }
        preparedLinkCard != null -> when (AppLocale.language.name) { "EN" -> "Share card ready"; "ES" -> "Tarjeta lista para compartir"; else -> "Card pronto para compartilhar" }
        else -> when (AppLocale.language.name) { "EN" -> "Preparing share card"; "ES" -> "Preparando tarjeta"; else -> "Preparando card" }
    }
    val retryLabel = when (AppLocale.language.name) { "EN" -> "Prepare card again"; "ES" -> "Preparar tarjeta de nuevo"; else -> "Preparar card novamente" }

    // Aguarda a primeira composição do veredito e só então prepara o card de link fora da UI.
    LaunchedEffect(shareSnapshot, sharePreparationAttempt) {
        preparedLinkCard = null
        sharePreparationFailed = false
        val snapshot = shareSnapshot ?: return@LaunchedEffect
        withFrameNanos { }
        preparedLinkCard = runCatching { withContext(Dispatchers.Default) { PreparedShareCard.prepare(context, snapshot) } }
            .onFailure { sharePreparationFailed = true }.getOrNull()
    }
    LaunchedEffect(preparedLinkCard) {
        previewBitmap = preparedLinkCard?.takeIf { it.isFile }?.let { file ->
            withContext(Dispatchers.Default) { android.graphics.BitmapFactory.decodeFile(file.path) }
        }
        if (preparedLinkCard != null && previewBitmap == null) sharePreparationFailed = true
    }

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
        val shareText = "🎮 LagCheck · ${game.name}\n$quote\nhttps://lagcheck.signallq.com"

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
            https://lagcheck.signallq.com
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
        val stamp = AppLocale.dateTime(evaluation.timestamp)
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

    fun shareGeneratedDuel(nick: String) {
        onSaveGamerNick(nick)
        val payload = com.lagcheck.domain.model.HostDuelPayload(
            gameId = game.id,
            regionId = regionLabel.ifBlank { "sa-east-1" },
            p50Ms = evaluation.pingMs ?: 0.0,
            packetLossPercent = evaluation.packetLossPercentage ?: 0.0,
            jitterMs = evaluation.jitterMs ?: 0.0,
            verdict = evaluation.verdict,
            challengerNick = nick
        )
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, payload.generateDiscordShareText(game.name))
        }
        context.startActivity(Intent.createChooser(shareIntent, tr("Desafiar Duo no Lobby")))
    }

    if (showNickSheet) {
        com.lagcheck.android.ui.duel.HostDuelNickSheet(
            initialNick = savedGamerNick,
            onDismiss = { showNickSheet = false },
            onConfirm = { nick ->
                showNickSheet = false
                shareGeneratedDuel(nick)
            }
        )
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
                    .size(48.dp)
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
                text = listOf(game.name, "Mobile", regionLabel).filter { it.isNotBlank() }.joinToString(" · "),
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

        // Única prévia do JPEG já preparado: fica abaixo do veredito, antes da telemetria.
        if (shareScene != null) {
            val previewLabel = when {
                sharePreparationFailed -> "$shareStateLabel. $retryLabel"
                previewBitmap != null -> "${tr("Compartilhar resultado")}: ${evaluation.headline}, ${game.name}, $regionLabel. $shareStateLabel"
                else -> shareStateLabel
            }
            Box(
                modifier = Modifier
                    .widthIn(max = 360.dp)
                    .fillMaxWidth()
                    .align(Alignment.CenterHorizontally)
                    .aspectRatio(1200f / 630f)
                    .clip(RoundedCornerShape(8.dp))
                    .background(LagCheckColors.Surface)
                    .border(1.dp, LagCheckColors.BorderHairline, RoundedCornerShape(8.dp))
                    .semantics { contentDescription = previewLabel }
                    .then(
                        when {
                            previewBitmap != null && preparedLinkCard != null -> Modifier.clickable(
                                onClickLabel = tr("Abrir opções de compartilhamento")
                            ) { openCardChooser(context, preparedLinkCard!!, game.name) }
                            sharePreparationFailed -> Modifier.clickable(
                                onClickLabel = retryLabel
                            ) { sharePreparationAttempt += 1 }
                            else -> Modifier
                        }
                    ),
                contentAlignment = Alignment.Center
            ) {
                previewBitmap?.let {
                    Image(
                        it.asImageBitmap(),
                        contentDescription = null,
                        contentScale = androidx.compose.ui.layout.ContentScale.Fit,
                        modifier = Modifier.fillMaxSize()
                    )
                }
                if (sharePreparationFailed) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(shareStateLabel, color = LagCheckColors.TextSecondary)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(retryLabel, color = LagCheckColors.TextSecondary)
                    }
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
            // Redes logo abaixo do card: card horizontal (WhatsApp, Telegram, X, Discord) ou vídeo (TikTok, Instagram).
            ShareNetworkBar(
                scene = shareScene,
                preparedLinkCard = preparedLinkCard,
                modifier = Modifier.widthIn(max = 360.dp).align(Alignment.CenterHorizontally)
            )
            Spacer(modifier = Modifier.height(24.dp))
        }

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

        // 7. Ações Principais: "Testar novamente", "Desafiar Duo" / "Ver Duelo", "Ver detalhes"
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            PrimaryButton(
                text = tr("Testar novamente"),
                onClick = onRetry,
                height = 56.dp
            )

            if (evaluation.verdict != GameReadinessVerdict.INCONCLUSIVE) {
                if (lastDuelResolution != null && onViewDuelVersus != null) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(56.dp)
                            .clip(RoundedCornerShape(percent = 50))
                            .background(LagCheckColors.Surface)
                            .clickable { onViewDuelVersus() },
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = tr("Ver Confronto do Duelo"),
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                            color = LagCheckColors.TextPrimary
                        )
                    }
                } else {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(56.dp)
                            .clip(RoundedCornerShape(percent = 50))
                            .background(LagCheckColors.Surface)
                            .clickable { showNickSheet = true },
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "⚔️ " + tr("Desafiar Duo no Lobby"),
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                            color = LagCheckColors.TextPrimary
                        )
                    }
                }
            }

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

            // PDF fica à direita; as redes ficam sob o card.
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.End
            ) {
                // PDF: disponível só no resultado
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(androidx.compose.foundation.shape.CircleShape)
                        .background(LagCheckColors.Surface)
                        .semantics { contentDescription = tr("PDF") }
                        .clickable { exportPDF() },
                    contentAlignment = Alignment.Center
                ) {
                    PdfDocumentIcon(size = 18.dp, color = LagCheckColors.TextSecondary)
                }
            }
        }

        if (nativeAd != null) {
            com.lagcheck.android.ads.NativeAdSlot(
                nativeAd,
                Modifier.padding(top = 32.dp)
            )
        }
        Spacer(modifier = Modifier.height(32.dp))
    }
}
