package com.lagcheck.android.share

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ModalBottomSheet
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import com.lagcheck.android.ui.AppLocale
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf
import com.lagcheck.core.designsystem.theme.LagCheckColors
import java.io.File
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Folha "Cards e vídeo para as redes": gera, sob demanda, os cards 1200x630 e 1080x1920 e o vídeo 9:16 do
 * resultado e abre o compartilhamento nativo com o arquivo. Nada é gerado antes do toque (Decisão 80).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShareMediaSheet(scene: ShareMediaScene, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var preview by remember { mutableStateOf<android.graphics.Bitmap?>(null) }
    var working by remember { mutableStateOf<String?>(null) }
    var progress by remember { mutableFloatStateOf(0f) }
    var failed by remember { mutableStateOf(false) }
    var job by remember { mutableStateOf<Job?>(null) }

    LaunchedEffect(scene) {
        preview = withContext(Dispatchers.Default) {
            val images = ShareMediaImages.load(context, scene, AppLocale.language, withTiles = false)
            val jpg = ShareMediaRenderer.jpeg(ShareMediaRenderer.Kind.PREVIEW, scene, images)
            BitmapFactory.decodeByteArray(jpg, 0, jpg.size)
        }
    }

    fun caption() = trf("Testei minha conexão para jogar %s no Lagcheck. Teste a sua: https://lagcheck.signallq.com", scene.gameName)

    fun share(file: File, mime: String) {
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = mime
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, caption())
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        context.startActivity(Intent.createChooser(intent, tr("Compartilhar")))
    }

    fun runCard(kind: ShareMediaRenderer.Kind, name: String, id: String) {
        failed = false
        working = id
        job = scope.launch {
            try {
                val file = withContext(Dispatchers.Default) {
                    val images = ShareMediaImages.load(context, scene, AppLocale.language, withTiles = false)
                    val bytes = ShareMediaRenderer.jpeg(kind, scene, images)
                    File(context.cacheDir, "share/$name").apply { parentFile?.mkdirs(); writeBytes(bytes) }
                }
                share(file, "image/jpeg")
            } catch (e: CancellationException) {
                throw e
            } catch (e: Throwable) {
                failed = true
            } finally {
                working = null
            }
        }
    }

    fun runVideo() {
        failed = false
        working = "video"
        progress = 0f
        job = scope.launch {
            try {
                val file = withContext(Dispatchers.Default) {
                    val images = ShareMediaImages.load(context, scene, AppLocale.language, withTiles = true)
                    ShareVideoRenderer.render(context, scene, images, isCancelled = { !isActive }, onProgress = { progress = it })
                }
                share(file, "video/mp4")
            } catch (e: CancellationException) {
                throw e
            } catch (e: ShareVideoRenderer.Cancelled) {
                // cancelado pela pessoa
            } catch (e: Throwable) {
                failed = true
            } finally {
                working = null
            }
        }
    }

    ModalBottomSheet(onDismissRequest = { job?.cancel(); onDismiss() }, containerColor = LagCheckColors.Background) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp)
                .padding(bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(tr("Cards e vídeo para as redes"), fontSize = 20.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.TextPrimary)
            preview?.let {
                Image(
                    bitmap = it.asImageBitmap(),
                    contentDescription = null,
                    contentScale = ContentScale.FillWidth,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .border(1.dp, LagCheckColors.BorderHairline, RoundedCornerShape(16.dp))
                )
            }
            Text(
                tr("Gere um card ou um vídeo com o seu resultado. Só os números medidos aparecem."),
                fontSize = 13.sp,
                color = LagCheckColors.TextSecondary
            )
            ActionRow(tr("Card 1200×630 (WhatsApp, Telegram, X)"), working == "preview", working == null, primary = false) {
                runCard(ShareMediaRenderer.Kind.PREVIEW, "lagcheck-card-1200x630.jpg", "preview")
            }
            ActionRow(tr("Card 1080×1920 (Status, Stories, TikTok)"), working == "story", working == null, primary = false) {
                runCard(ShareMediaRenderer.Kind.STORY, "lagcheck-card-1080x1920.jpg", "story")
            }
            ActionRow(tr("Vídeo 9:16 para TikTok e Reels"), working == "video", working == null, primary = true) { runVideo() }
            if (working == "video") {
                LinearProgressIndicator(
                    progress = { progress },
                    modifier = Modifier
                        .fillMaxWidth()
                        .semantics { contentDescription = tr("Gerando o vídeo…") },
                    color = LagCheckColors.AccentPrimary
                )
                Text(
                    tr("Cancelar"),
                    fontSize = 13.sp,
                    color = LagCheckColors.TextSecondary,
                    modifier = Modifier
                        .heightIn48()
                        .clickable { job?.cancel() }
                )
            }
            if (failed) Text(tr("Não foi possível gerar o arquivo. Tente de novo."), fontSize = 13.sp, color = LagCheckColors.CoralWarning)
        }
    }
}

private fun Modifier.heightIn48() = this.height(48.dp)

@Composable
private fun ActionRow(title: String, busy: Boolean, enabled: Boolean, primary: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(if (primary) LagCheckColors.AccentPrimary else LagCheckColors.Surface)
            .border(1.dp, if (primary) LagCheckColors.AccentPrimary else LagCheckColors.BorderStrong, RoundedCornerShape(14.dp))
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 16.dp),
        contentAlignment = Alignment.CenterStart
    ) {
        Text(
            text = if (busy) "$title…" else title,
            fontSize = 15.sp,
            fontWeight = FontWeight.SemiBold,
            color = if (primary) androidx.compose.ui.graphics.Color.White else LagCheckColors.TextPrimary
        )
    }
}
