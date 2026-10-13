package com.lagcheck.android.share

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.RectF
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf
import java.io.ByteArrayOutputStream
import java.util.Locale

/**
 * Cards de compartilhamento: 1200x630 (link preview) e 1080x1920 (Status, Stories, TikTok).
 * Mesmo layout do protótipo "Lagcheck Cards de compartilhamento" e do iOS (`ShareMediaRenderer.swift`).
 */
internal object ShareMediaRenderer {
    enum class Kind { PREVIEW, STORY }

    const val PREVIEW_W = 1200
    const val PREVIEW_H = 630
    const val STORY_W = 1080
    const val STORY_H = 1920

    /** JPEG do card (o preview fica abaixo de ~300 KB). */
    fun jpeg(kind: Kind, scene: ShareMediaScene, images: ShareMediaImages): ByteArray {
        val w = if (kind == Kind.PREVIEW) PREVIEW_W else STORY_W
        val h = if (kind == Kind.PREVIEW) PREVIEW_H else STORY_H
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        if (kind == Kind.PREVIEW) drawPreview(c, scene, images) else drawStory(c, scene, images)
        val out = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.JPEG, if (kind == Kind.PREVIEW) 82 else 90, out)
        bmp.recycle()
        return out.toByteArray()
    }

    fun headlineSentence(scene: ShareMediaScene): String {
        val lower = scene.headline.lowercase(Locale.getDefault())
        return lower.replaceFirstChar { it.titlecase(Locale.getDefault()) }
    }

    fun label(m: ShareMetric): String = when (m.kind) {
        ShareMetricKind.PING -> tr("Resposta")
        ShareMetricKind.JITTER -> tr("Jitter")
        ShareMetricKind.PACKET_LOSS -> tr("Perda")
    }.uppercase(Locale.getDefault())

    fun eyebrow(scene: ShareMediaScene): String = trf("Check · %s", scene.gameName).uppercase(Locale.getDefault())

    class MetricStyle(val border: Float, val pad: Float, val label: Float, val value: Float, val unit: Float, val gap: Float, val height: Float)

    fun drawMetric(c: Canvas, m: ShareMetric, x: Float, y: Float, k: MetricStyle, valueOverride: String? = null, alpha: Float = 1f) {
        ShareCanvas.fillRect(c, x, y - k.label - 4, x + k.border, y - k.label - 4 + k.height, ShareCanvas.withAlpha(0xFFFFFFFF.toInt(), 0.28f * alpha))
        ShareCanvas.draw(c, label(m), x + k.pad, y, k.label, 600, ShareCanvas.accent, kern = if (k.label >= 26f) 3f else 2f, shadow = true, alpha = alpha, mono = true)
        val vy = y + k.value * 0.95f
        val kern = -k.value / 30f
        val shown = valueOverride ?: m.value
        ShareCanvas.draw(c, shown, x + k.pad, vy, k.value, 700, ShareCanvas.text, kern = kern, shadow = true, alpha = alpha)
        if (m.unit.isNotEmpty() && shown != "—") {
            val w = ShareCanvas.width(shown, k.value, 700, kern)
            ShareCanvas.draw(c, m.unit, x + k.pad + w + k.gap, vy, k.unit, 500, ShareCanvas.muted, shadow = true, alpha = alpha)
        }
    }

    // ---- 1a · Link preview 1200x630 ----
    private fun drawPreview(c: Canvas, scene: ShareMediaScene, images: ShareMediaImages) {
        val w = PREVIEW_W.toFloat()
        val h = PREVIEW_H.toFloat()
        val rect = RectF(0f, 0f, w, h)
        ShareCanvas.fillRect(c, 0f, 0f, w, h, ShareCanvas.deep)
        ShareCanvas.drawFill(c, images.art, rect)
        ShareCanvas.gradient(
            c, listOf(0f to withDeep(0.12f), 0.38f to withDeep(0.35f), 0.58f to withDeep(0.9f), 1f to withDeep(0.97f)),
            0f, 0f, w, 0f, rect
        )

        // Selo do veredito (canto inferior esquerdo)
        val tone = ShareCanvas.toneColor(scene.tone)
        val verdict = scene.headline
        val vw = ShareCanvas.width(verdict, 20f, 600, 2.5f, mono = true)
        val pill = RectF(56f, 518f, 56f + 18f + 16f + 14f + vw + 22f, 574f)
        ShareCanvas.roundRect(c, pill, 28f, withDeep(0.72f))
        ShareCanvas.roundRect(c, pill, 28f, ShareCanvas.withAlpha(0xFFFFFFFF.toInt(), 0.14f), stroke = true)
        ShareCanvas.circle(c, 56f + 18f + 8f, 546f, 8f, tone, glow = 18f)
        ShareCanvas.draw(c, verdict, 56f + 18f + 16f + 14f, 554f, 20f, 600, tone, kern = 2.5f, mono = true)

        // Coluna direita
        val left = 610f
        val right = w - 60f
        ShareCanvas.drawImage(c, images.wordmark, 44f, left, 60f)
        ShareCanvas.draw(c, "lagcheck.signallq.com", right, 88f, 20f, 500, ShareCanvas.muted, align = ShareCanvas.Align.RIGHT, shadow = true, mono = true)

        val lines = ShareCanvas.wrap(headlineSentence(scene), 60f, 700, -2f, right - left)
        val lh = 62f
        val blockH = 19f + 12f + lines.size * lh + 28f + 90f
        val top = 104f + (458f - 104f - blockH) / 2f
        ShareCanvas.draw(c, eyebrow(scene), left, top + 15f, 19f, 600, ShareCanvas.accent, kern = 3f, shadow = true, mono = true)
        lines.forEachIndexed { i, l -> ShareCanvas.draw(c, l, left, top + 31f + 60f * 0.85f + i * lh, 60f, 700, ShareCanvas.text, kern = -2f, shadow = true) }
        val my = top + 31f + lines.size * lh + 28f + 17f
        val colW = (right - left - 40f) / 3f
        val style = MetricStyle(2f, 20f, 17f, 56f, 22f, 6f, 88f)
        scene.metrics.forEachIndexed { i, m -> drawMetric(c, m, left + i * (colW + 20f), my, style) }

        // Linha inferior: QR + chamada + selo
        ShareCanvas.drawQr(c, ShareMediaImages.STORE_URL, RectF(left, 458f, left + 112f, 570f), 16f, 8f)
        ShareCanvas.draw(c, tr("Medido com pacotes UDP reais."), left + 134f, 494f, 23f, 500, ShareCanvas.muted)
        ShareCanvas.draw(c, tr("Teste a sua conexão no Lagcheck."), left + 134f, 524f, 23f, 600, ShareCanvas.text)
        ShareCanvas.drawImage(c, images.badge, 38f, left + 130f, 532f)
    }

    private fun withDeep(alpha: Float) = ShareCanvas.withAlpha(ShareCanvas.deep, alpha)

    // ---- 1b · Vertical 1080x1920 ----
    private fun drawStory(c: Canvas, scene: ShareMediaScene, images: ShareMediaImages) {
        val w = STORY_W.toFloat()
        val h = STORY_H.toFloat()
        val rect = RectF(0f, 0f, w, h)
        ShareCanvas.fillRect(c, 0f, 0f, w, h, ShareCanvas.deep)
        ShareCanvas.drawFill(c, images.art, rect)
        ShareCanvas.gradient(
            c, listOf(0f to withDeep(0.7f), 0.22f to withDeep(0.05f), 0.34f to withDeep(0.2f), 0.55f to withDeep(0.88f), 1f to withDeep(0.97f)),
            0f, 0f, 0f, h, rect
        )
        ShareCanvas.drawImage(c, images.wordmark, 60f, 64f, 240f)
        drawVerdictBlock(c, scene, images, top = 830f, alpha = 1f, reveal = 1f, width = w)
    }

    /** Bloco de veredito da vertical (selo, título, métricas, chamada, selo da loja); usado também na cena final do vídeo. */
    fun drawVerdictBlock(c: Canvas, scene: ShareMediaScene, images: ShareMediaImages, top: Float, alpha: Float, reveal: Float, width: Float, valueOverrides: List<String>? = null) {
        val side = 64f
        val tone = ShareCanvas.toneColor(scene.tone)
        ShareCanvas.circle(c, side + 13f, top + 15f, 13f, ShareCanvas.withAlpha(tone, alpha), glow = 28f)
        ShareCanvas.draw(c, "${tr("Check")} · ${scene.gameName}".uppercase(Locale.getDefault()), side + 54f, top + 26f, 30f, 600, tone, kern = 4f, shadow = true, alpha = alpha, mono = true)

        var fontSize = 112f
        var lines = ShareCanvas.wrap(headlineSentence(scene), fontSize, 700, -4f, width - side * 2)
        if (lines.size > 2) {
            fontSize = 88f
            lines = ShareCanvas.wrap(headlineSentence(scene), fontSize, 700, -3f, width - side * 2)
        }
        val firstY = top + 22f + 30f + fontSize * 0.9f
        lines.take(3).forEachIndexed { i, l ->
            ShareCanvas.draw(c, l, side, firstY + i * fontSize, fontSize, 700, ShareCanvas.text, kern = -fontSize / 28f, shadow = true, alpha = alpha)
        }
        val my = firstY + (minOf(lines.size, 3) - 1) * fontSize + 48f + 26f
        val colW = (width - side * 2 - 56f) / 3f
        val style = MetricStyle(3f, 26f, 26f, 88f, 30f, 8f, 134f)
        scene.metrics.forEachIndexed { i, m ->
            val a = alpha * (reveal * 3f - i * 0.5f).coerceIn(0f, 1f)
            drawMetric(c, m, side + i * (colW + 28f), my, style, valueOverrides?.getOrNull(i), a)
        }
        val by = my + 88f + 54f - 16f
        ShareCanvas.drawImage(c, images.badge, 104f, side - 8f, by - 4f, alpha)
        val tx = side + 104f * 2.58f + 28f
        ShareCanvas.draw(c, tr("Medido com pacotes UDP reais."), tx, by + 38f, 32f, 500, ShareCanvas.muted, alpha = alpha)
        ShareCanvas.draw(c, tr("Teste a sua conexão no Lagcheck."), tx, by + 80f, 32f, 600, ShareCanvas.text, alpha = alpha)
    }
}
