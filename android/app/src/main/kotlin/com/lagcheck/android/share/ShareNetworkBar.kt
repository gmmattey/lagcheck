package com.lagcheck.android.share

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.core.content.FileProvider
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf
import com.lagcheck.android.ui.AppLocale
import com.lagcheck.core.designsystem.components.SocialNetwork
import com.lagcheck.core.designsystem.components.SocialNetworkIcon
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckRadius
import java.io.File
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Legendas de divulgação (Decisão 104). O card leva só o texto; o vídeo leva também as hashtags, copiadas para a área de
 * transferência porque Instagram e TikTok ignoram o texto enviado junto com o arquivo.
 */
internal object ShareCaption {
    fun card(gameName: String): String = trf("Testei minha conexão para jogar %s no Lagcheck. Teste a sua: https://lagcheck.signallq.com", gameName)

    fun video(gameName: String): String = "${card(gameName)}\n\n${hashtags(gameName)}"

    fun hashtags(gameName: String): String {
        val game = gameName.filter { it.isLetterOrDigit() }
        val base = "#LagCheck #Gamer #Ping #Lag"
        return if (game.isEmpty()) base else "$base #$game"
    }
}

/**
 * Ícones das redes abaixo do card do resultado. O card já está pronto quando a barra habilita: o toque abre o app da rede
 * (ou o seletor do sistema) na hora. Para TikTok e Instagram o vídeo é gerado antes, com pop-up de progresso e Cancelar.
 */
@Composable
fun ShareNetworkBar(
    scene: ShareMediaScene,
    preparedLinkCard: File?,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var generating by remember { mutableStateOf(false) }
    var progress by remember { mutableFloatStateOf(0f) }
    var job by remember { mutableStateOf<Job?>(null) }
    var cachedVideo by remember(scene) { mutableStateOf<File?>(null) }
    var failed by remember { mutableStateOf(false) }
    var copied by remember { mutableStateOf(false) }

    LaunchedEffect(copied) {
        if (copied) { delay(5_000); copied = false }
    }

    fun copyCaption(text: String) {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("LagCheck", text))
        copied = true
    }

    fun send(file: File, mime: String, caption: String, network: SocialNetwork) {
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val base = Intent(Intent.ACTION_SEND).apply {
            type = mime
            putExtra(Intent.EXTRA_STREAM, uri)
            if (!network.sendsVideo) putExtra(Intent.EXTRA_TEXT, caption)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val pkg = network.packageName
        if (pkg != null && context.packageManager.getLaunchIntentForPackage(pkg) != null) {
            // Direto para o app da rede; se ele recusar o arquivo, cai no seletor do sistema.
            try { context.startActivity(Intent(base).setPackage(pkg)); return } catch (_: ActivityNotFoundException) {}
        }
        context.startActivity(Intent.createChooser(base, tr("Compartilhar")))
    }

    fun shareCard(network: SocialNetwork) {
        val card = preparedLinkCard ?: return
        send(card, "image/jpeg", ShareCaption.card(scene.gameName), network)
    }

    fun shareVideo(network: SocialNetwork) {
        val caption = ShareCaption.video(scene.gameName)
        cachedVideo?.takeIf { it.isFile }?.let {
            copyCaption(caption)
            send(it, "video/mp4", caption, network)
            return
        }
        failed = false
        progress = 0f
        generating = true
        job = scope.launch {
            try {
                val file = withContext(Dispatchers.Default) {
                    val images = ShareMediaImages.load(context, scene, AppLocale.language, withTiles = true)
                    ShareVideoRenderer.render(context, scene, images, isCancelled = { !isActive }, onProgress = { progress = it })
                }
                cachedVideo = file
                generating = false
                copyCaption(caption)
                send(file, "video/mp4", caption, network)
            } catch (e: CancellationException) {
                throw e
            } catch (e: ShareVideoRenderer.Cancelled) {
                // cancelado pela pessoa
            } catch (e: Throwable) {
                failed = true
            } finally {
                generating = false
            }
        }
    }

    Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        val ready = preparedLinkCard != null
        Row(
            modifier = Modifier.fillMaxWidth().alpha(if (ready) 1f else 0.4f),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            SocialNetwork.entries.filter { it != SocialNetwork.MORE }.forEach { n ->
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .semantics { contentDescription = n.label }
                        .clickable(enabled = ready && !generating) { if (n.sendsVideo) shareVideo(n) else shareCard(n) },
                    contentAlignment = Alignment.Center
                ) { SocialNetworkIcon(n, size = 48.dp) }
            }
        }
        if (copied) Text(tr("Legenda e hashtags copiadas. Cole no post."), fontSize = 12.sp, color = LagCheckColors.TextSecondary, textAlign = TextAlign.Center)
        if (failed) Text(tr("Não foi possível gerar o arquivo. Tente de novo."), fontSize = 12.sp, color = LagCheckColors.CoralWarning, textAlign = TextAlign.Center)
    }

    if (generating) {
        Dialog(onDismissRequest = {}, properties = DialogProperties(dismissOnBackPress = false, dismissOnClickOutside = false)) {
            Column(
                modifier = Modifier
                    .widthIn(max = 300.dp)
                    .clip(RoundedCornerShape(LagCheckRadius.xl))
                    .background(LagCheckColors.Surface)
                    .border(1.dp, LagCheckColors.BorderHairline, RoundedCornerShape(LagCheckRadius.xl))
                    .padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(tr("Gerando o vídeo…"), fontSize = 16.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.TextPrimary)
                Text("${(progress * 100).toInt()}%", fontSize = 34.sp, fontWeight = FontWeight.ExtraBold, color = LagCheckColors.TextPrimary)
                LinearProgressIndicator(progress = { progress }, modifier = Modifier.fillMaxWidth(), color = LagCheckColors.AccentPrimary)
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp)
                        .defaultMinSize(minHeight = 48.dp)
                        .clip(RoundedCornerShape(percent = 50))
                        .background(LagCheckColors.Background)
                        .clickable { job?.cancel() },
                    contentAlignment = Alignment.Center
                ) { Text(tr("Cancelar"), fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = LagCheckColors.TextPrimary) }
            }
        }
    }
}

/** Toque no próprio card: abre o seletor do sistema com o JPEG já preparado e a legenda sem hashtags. */
internal fun openCardChooser(context: Context, card: File, gameName: String) {
    val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", card)
    val send = Intent(Intent.ACTION_SEND).apply {
        type = "image/jpeg"
        putExtra(Intent.EXTRA_STREAM, uri)
        putExtra(Intent.EXTRA_TEXT, ShareCaption.card(gameName))
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
    context.startActivity(Intent.createChooser(send, tr("Compartilhar")))
}
