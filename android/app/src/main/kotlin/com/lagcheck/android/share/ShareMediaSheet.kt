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
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.defaultMinSize
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
import com.lagcheck.core.designsystem.components.SocialNetwork
import com.lagcheck.core.designsystem.components.SocialNetworkIcon
import com.lagcheck.core.designsystem.theme.LagCheckColors
import java.io.File
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** Formato que a pessoa escolhe antes de tocar numa rede. */
private enum class ShareFormat(val label: String, val previewKind: ShareMediaRenderer.Kind) {
    LINK("Link", ShareMediaRenderer.Kind.PREVIEW),
    STORY("Stories", ShareMediaRenderer.Kind.STORY),
    VIDEO("Vídeo", ShareMediaRenderer.Kind.STORY)
}

/**
 * Folha "Compartilhar": escolhe o formato (link 1200×630, Stories 1080×1920 ou vídeo 9:16 de 14 s) e toca no ícone
 * da rede. O arquivo é gerado só depois do toque e vai direto para o app da rede (ou para o seletor do sistema).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShareMediaSheet(scene: ShareMediaScene, highlighted: SocialNetwork? = null, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var format by remember { mutableStateOf(ShareFormat.LINK) }
    var preview by remember { mutableStateOf<android.graphics.Bitmap?>(null) }
    var working by remember { mutableStateOf<SocialNetwork?>(null) }
    var progress by remember { mutableFloatStateOf(0f) }
    var failed by remember { mutableStateOf(false) }
    var job by remember { mutableStateOf<Job?>(null) }

    LaunchedEffect(scene, format.previewKind) {
        preview = withContext(Dispatchers.Default) {
            val images = ShareMediaImages.load(context, scene, AppLocale.language, withTiles = false)
            val jpg = ShareMediaRenderer.jpeg(format.previewKind, scene, images)
            BitmapFactory.decodeByteArray(jpg, 0, jpg.size, BitmapFactory.Options().apply { inSampleSize = if (format.previewKind == ShareMediaRenderer.Kind.STORY) 2 else 1 })
        }
    }

    fun caption() = trf("Testei minha conexão para jogar %s no Lagcheck. Teste a sua: https://lagcheck.signallq.com", scene.gameName)

    fun send(file: File, mime: String, network: SocialNetwork) {
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val base = Intent(Intent.ACTION_SEND).apply {
            type = mime
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, caption())
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val pkg = network.packageName
        val installed = pkg != null && context.packageManager.getLaunchIntentForPackage(pkg) != null
        if (installed) {
            // Direto para o app da rede; se ele recusar o arquivo, cai no seletor do sistema.
            val direct = Intent(base).setPackage(pkg)
            try { context.startActivity(direct); return } catch (_: android.content.ActivityNotFoundException) {}
        }
        context.startActivity(Intent.createChooser(base, tr("Compartilhar")))
    }

    fun run(network: SocialNetwork) {
        if (working != null) return
        failed = false
        working = network
        progress = 0f
        val chosen = format
        job = scope.launch {
            try {
                val (file, mime) = withContext(Dispatchers.Default) {
                    when (chosen) {
                        ShareFormat.VIDEO -> {
                            val images = ShareMediaImages.load(context, scene, AppLocale.language, withTiles = true)
                            ShareVideoRenderer.render(context, scene, images, isCancelled = { !isActive }, onProgress = { progress = it }) to "video/mp4"
                        }
                        else -> {
                            val images = ShareMediaImages.load(context, scene, AppLocale.language, withTiles = false)
                            val name = if (chosen == ShareFormat.LINK) "lagcheck-card-1200x630.jpg" else "lagcheck-card-1080x1920.jpg"
                            val bytes = ShareMediaRenderer.jpeg(chosen.previewKind, scene, images)
                            File(context.cacheDir, "share/$name").apply { parentFile?.mkdirs(); writeBytes(bytes) } to "image/jpeg"
                        }
                    }
                }
                send(file, mime, network)
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
                .padding(horizontal = 24.dp)
                .padding(bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(tr("Compartilhar"), fontSize = 20.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.TextPrimary)
            preview?.let {
                Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                    Image(
                        bitmap = it.asImageBitmap(),
                        contentDescription = null,
                        contentScale = ContentScale.Fit,
                        modifier = Modifier
                            .heightIn(max = 300.dp)
                            .clip(RoundedCornerShape(16.dp))
                            .border(1.dp, LagCheckColors.BorderHairline, RoundedCornerShape(16.dp))
                    )
                }
            }
            // Formato: Link · Stories · Vídeo
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(percent = 50))
                    .background(LagCheckColors.Surface)
                    .padding(4.dp)
            ) {
                ShareFormat.entries.forEach { f ->
                    val selected = f == format
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .height(44.dp)
                            .clip(RoundedCornerShape(percent = 50))
                            .background(if (selected) LagCheckColors.AccentPrimary else androidx.compose.ui.graphics.Color.Transparent)
                            .clickable(enabled = working == null) { format = f },
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            tr(f.label),
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = if (selected) androidx.compose.ui.graphics.Color.White else LagCheckColors.TextSecondary
                        )
                    }
                }
            }
            // Redes: só o ícone, com o nome para o leitor de tela
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                SocialNetwork.entries.forEach { n ->
                    val desc = if (n == SocialNetwork.MORE) tr("Mais apps") else n.label
                    Box(
                        modifier = Modifier
                            .size(52.dp)
                            .then(if (n == highlighted) Modifier.border(2.dp, LagCheckColors.AccentPrimary, androidx.compose.foundation.shape.CircleShape) else Modifier)
                            .semantics { contentDescription = desc }
                            .clickable(enabled = working == null) { run(n) },
                        contentAlignment = Alignment.Center
                    ) {
                        SocialNetworkIcon(n, size = 52.dp)
                        if (working == n) {
                            androidx.compose.material3.CircularProgressIndicator(
                                modifier = Modifier.size(52.dp),
                                color = androidx.compose.ui.graphics.Color.White,
                                strokeWidth = 2.dp
                            )
                        }
                    }
                }
            }
            if (working != null && format == ShareFormat.VIDEO) {
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
                        .defaultMinSize(minHeight = 48.dp)
                        .clickable { job?.cancel() }
                )
            }
            if (failed) Text(tr("Não foi possível gerar o arquivo. Tente de novo."), fontSize = 13.sp, color = LagCheckColors.CoralWarning)
        }
    }
}
