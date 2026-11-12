package com.lagcheck.android.share

import android.content.Context
import android.graphics.Canvas
import android.graphics.RectF
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.SystemClock
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf
import java.io.File
import java.util.Locale
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.roundToInt

/**
 * Vídeo 9:16 de 14 s do resultado (MP4/H.264, MediaCodec + MediaMuxer), gerado no aparelho a partir do resultado real.
 * Cenas: escolha 0–3,5 s (grade de capas), medição 3,5–9,5 s (números chegando ao valor medido) e resultado
 * 9,5–14 s. Paridade com `ShareVideoRenderer.swift`. Renderiza no ritmo do relógio (14 s) no Surface do encoder.
 */
internal object ShareVideoRenderer {
    class Cancelled : RuntimeException("cancelado")

    fun render(context: Context, scene: ShareMediaScene, images: ShareMediaImages, isCancelled: () -> Boolean, onProgress: (Float) -> Unit): File {
        val w = ShareVideoTimeline.WIDTH
        val h = ShareVideoTimeline.HEIGHT
        val fps = ShareVideoTimeline.FPS
        val file = File(context.cacheDir, "share/lagcheck-check.mp4").apply { parentFile?.mkdirs(); delete() }
        val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, w, h).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            setInteger(MediaFormat.KEY_BIT_RATE, 8_000_000)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2)
        }
        val codec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val surface = codec.createInputSurface()
        codec.start()
        val muxer = MediaMuxer(file.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var track = -1
        var muxing = false
        val info = MediaCodec.BufferInfo()
        var basePts = -1L

        fun drain(endOfStream: Boolean) {
            while (true) {
                val idx = codec.dequeueOutputBuffer(info, if (endOfStream) 10_000 else 0)
                when {
                    idx == MediaCodec.INFO_TRY_AGAIN_LATER -> if (!endOfStream) return
                    idx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        track = muxer.addTrack(codec.outputFormat)
                        muxer.start()
                        muxing = true
                    }
                    idx >= 0 -> {
                        val buf = codec.getOutputBuffer(idx)
                        if (buf != null && info.size > 0 && muxing && info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0) {
                            // O Surface carimba o relógio do sistema; o vídeo começa em zero.
                            if (basePts < 0) basePts = info.presentationTimeUs
                            info.presentationTimeUs -= basePts
                            buf.position(info.offset)
                            buf.limit(info.offset + info.size)
                            muxer.writeSampleData(track, buf, info)
                        }
                        codec.releaseOutputBuffer(idx, false)
                        if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) return
                    }
                }
            }
        }

        try {
            val start = SystemClock.elapsedRealtime()
            val frameMs = 1000L / fps
            var next = start
            while (true) {
                if (isCancelled()) throw Cancelled()
                val t = (SystemClock.elapsedRealtime() - start) / 1000.0
                if (t >= ShareVideoTimeline.DURATION) break
                val canvas: Canvas = surface.lockCanvas(null)
                try {
                    drawFrame(canvas, t, scene, images)
                } finally {
                    surface.unlockCanvasAndPost(canvas)
                }
                drain(false)
                onProgress((t / ShareVideoTimeline.DURATION).toFloat().coerceIn(0f, 1f))
                next += frameMs
                val wait = next - SystemClock.elapsedRealtime()
                if (wait > 0) Thread.sleep(wait)
            }
            codec.signalEndOfInputStream()
            drain(true)
            onProgress(1f)
        } catch (e: Throwable) {
            file.delete()
            throw e
        } finally {
            runCatching { codec.stop() }
            codec.release()
            surface.release()
            runCatching { if (muxing) muxer.stop() }
            muxer.release()
        }
        return file
    }

    // ---- Animação (mesma curva do iOS e do protótipo) ----
    private fun clamp(v: Double, a: Double = 0.0, b: Double = 1.0) = maxOf(a, minOf(b, v))
    private fun easeOutCubic(x: Double) = 1 - (1 - x).pow(3)
    private fun easeInOut(x: Double) = -(cos(Math.PI * x) - 1) / 2
    private fun easeOutBack(x: Double): Double {
        val c1 = 1.70158
        val c3 = c1 + 1
        return 1 + c3 * (x - 1).pow(3) + c1 * (x - 1).pow(2)
    }
    private fun ramp(t: Double, a: Double, b: Double, ease: (Double) -> Double) = ease(clamp((t - a) / (b - a)))
    private fun lerp(a: Float, b: Float, k: Double) = a + (b - a) * k.toFloat()

    private const val TILE = 300f
    private const val GAP = 26f
    private const val X0 = 64f
    private const val Y0 = 440f
    private val scan = listOf(0, 1, 2, 5, 8, 7, 6, 3, 4)
    private fun tileCx(i: Int) = X0 + (i % 3) * (TILE + GAP) + TILE / 2
    private fun tileCy(i: Int) = Y0 + (i / 3) * (TILE + GAP) + TILE / 2

    private fun message(mt: Double, scene: ShareMediaScene): Pair<Double, String> {
        val all = listOf(
            0.0 to tr("Procurando o servidor mais próximo…"),
            1.0 to tr("Testando os reflexos da sua rede."),
            2.4 to trf("Cada milissegundo conta em %s.", scene.gameName),
            3.8 to tr("Enchendo a fila para ver se aguenta a pressão."),
            5.0 to tr("Quase lá. Preparando seu veredito.")
        )
        return all.lastOrNull { it.first <= mt } ?: all.first()
    }

    internal fun drawFrame(c: Canvas, t: Double, scene: ShareMediaScene, images: ShareMediaImages) {
        val tl = ShareVideoTimeline
        val w = tl.WIDTH.toFloat()
        val h = tl.HEIGHT.toFloat()
        val full = RectF(0f, 0f, w, h)
        val m = tl.MEASURE_START
        val r = tl.RESULT_START
        val end = tl.DURATION
        val fadeIn = ramp(t, 0.0, 0.5, ::easeOutCubic)
        val fadeOut = 1 - ramp(t, end - 0.5, end, ::easeOutCubic)
        val all = minOf(fadeIn, fadeOut).toFloat()
        val picked = t >= 2.5
        val toMeasure = ramp(t, m - 0.1, m + 0.8, ::easeInOut)
        val toResult = ramp(t, r - 0.1, r + 0.7, ::easeInOut)
        val others = 1 - ramp(t, m - 0.2, m + 0.4, ::easeOutCubic)

        ShareCanvas.fillRect(c, 0f, 0f, w, h, ShareCanvas.deep)

        // Cena 1: título e grade de capas
        val head = 1 - toMeasure
        if (head > 0.01) {
            val a = all * head.toFloat()
            val dy = (-toMeasure * 30).toFloat()
            ShareCanvas.draw(c, tr("Check").uppercase(Locale.getDefault()), 64f, 322f + dy, 26f, 600, ShareCanvas.accent, kern = 3f, alpha = a, mono = true)
            ShareCanvas.draw(c, if (picked) scene.gameName else tr("Escolha seu jogo."), 64f, 404f + dy, 80f, 700, ShareCanvas.text, kern = -3f, alpha = a)
        }
        val scanP = clamp((t - 1.2) / 1.2)
        val cursor = scan[minOf(scan.size - 1, (scanP * scan.size).toInt())]
        val tiles = images.tiles.toMutableList()
        for (i in 0 until 9) {
            val isSel = i == 4
            val bmp = if (isSel) images.art else if (tiles.isEmpty()) null else tiles.removeAt(0)
            val k = ramp(t, 0.2 + i * 0.08, 0.7 + i * 0.08, ::easeOutBack)
            val op = if (isSel) k else k * others * (if (picked) 0.5 else 1.0)
            if (op <= 0.01) continue
            val tw = if (isSel) lerp(TILE, w, toMeasure) else TILE
            val th = if (isSel) lerp(TILE, h, toMeasure) else TILE
            val cx = if (isSel) w / 2 else tileCx(i)
            val cy = if (isSel) lerp(tileCy(i), h / 2, toMeasure) else tileCy(i)
            val sc = if (isSel) 1f else (0.9 + 0.1 * clamp(k)).toFloat()
            val hot = ((cursor == i && t >= 1.2 && t < 2.5) || (isSel && picked)) && toMeasure < 0.05
            val radius = if (isSel) lerp(67f, 0f, toMeasure) else 67f
            val layer = c.saveLayerAlpha(0f, 0f, w, h, (all * clamp(op).toFloat() * 255).roundToInt())
            c.translate(cx, cy); c.scale(sc, sc); c.translate(-cx, -cy)
            val rect = RectF(cx - tw / 2, cy - th / 2, cx + tw / 2, cy + th / 2)
            if (hot) ShareCanvas.roundRect(c, RectF(rect).apply { inset(-7f, -7f) }, radius + 7f, ShareCanvas.purple)
            ShareCanvas.roundRect(c, rect, radius, ShareCanvas.deep)
            ShareCanvas.drawFill(c, bmp, rect, radius)
            c.restoreToCount(layer)
        }

        if (toMeasure > 0.01) {
            ShareCanvas.gradient(
                c, listOf(0f to ShareCanvas.withAlpha(ShareCanvas.deep, 0.7f), 0.22f to ShareCanvas.withAlpha(ShareCanvas.deep, 0.05f), 0.4f to ShareCanvas.withAlpha(ShareCanvas.deep, 0.15f), 0.62f to ShareCanvas.withAlpha(ShareCanvas.deep, 0.9f), 1f to ShareCanvas.withAlpha(ShareCanvas.deep, 0.97f)),
                0f, 0f, 0f, h, full, alpha = all * toMeasure.toFloat()
            )
        }
        if (toResult > 0.01) ShareCanvas.fillRect(c, 0f, 0f, w, h, ShareCanvas.withAlpha(ShareCanvas.deep, all * toResult.toFloat() * 0.4f))
        ShareCanvas.drawImage(c, images.wordmark, 60f, 64f, 200f)

        // Cena 2: medição (os números do teste chegando ao valor medido)
        val meas = 1 - ramp(t, r - 0.3, r + 0.2, ::easeOutCubic)
        if (toMeasure > 0.01 && meas > 0.01) {
            val mt = clamp(t - m, 0.0, r - m)
            val prog = clamp(mt / (r - m - 0.4))
            val a = all * (toMeasure * meas).toFloat()
            ShareCanvas.roundRect(c, RectF(64f, 1040f, 1016f, 1048f), 4f, ShareCanvas.withAlpha(0xFFFFFFFF.toInt(), 0.12f * a))
            ShareCanvas.roundRect(c, RectF(64f, 1040f, 64f + maxOf(0.0, 952 * prog).toFloat(), 1048f), 4f, ShareCanvas.withAlpha(ShareCanvas.purple, a))
            val msg = message(mt, scene)
            val msgK = ramp(t, m + msg.first, m + msg.first + 0.4, ::easeOutCubic)
            ShareCanvas.wrap(msg.second, 72f, 700, -2f, 952f).take(3).forEachIndexed { i, line ->
                ShareCanvas.draw(c, line, 64f, 1148f + i * 80f + ((1 - msgK) * 24).toFloat(), 72f, 700, ShareCanvas.text, kern = -2f, shadow = true, alpha = a * msgK.toFloat())
            }
            val windows = listOf(1.0 to 3.0, 2.0 to 3.6, 3.8 to 5.2)
            val colW = (w - 128f - 56f) / 3f
            scene.metrics.forEachIndexed { i, metric ->
                val x = 64f + i * (colW + 28f)
                val y = 1420f
                val p = clamp((mt - windows[i].first) / (windows[i].second - windows[i].first))
                val n = metric.number
                val shown = if (n != null && p > 0) {
                    if (metric.kind == ShareMetricKind.PING) (n * p).roundToInt().toString() else ShareMediaScene.format(n * p, 1, Locale.getDefault())
                } else "—"
                ShareCanvas.fillRect(c, x, y - 30f, x + 3f, y + 104f, ShareCanvas.withAlpha(0xFFFFFFFF.toInt(), 0.28f * a))
                ShareCanvas.draw(c, ShareMediaRenderer.label(metric), x + 26f, y, 26f, 600, ShareCanvas.accent, kern = 3f, alpha = a, mono = true)
                ShareCanvas.draw(c, shown, x + 26f, y + 84f, 84f, 700, if (shown == "—") ShareCanvas.muted else ShareCanvas.text, kern = -3f, alpha = a)
                if (shown != "—" && metric.unit.isNotEmpty()) {
                    val vw = ShareCanvas.width(shown, 84f, 700, -3f)
                    ShareCanvas.draw(c, metric.unit, x + 26f + vw + 6f, y + 84f, 26f, 500, ShareCanvas.muted, alpha = a)
                }
            }
        }

        // Cena 3: veredito, números medidos e chamada para o app
        val k = ramp(t, r + 0.2, r + 0.8, ::easeOutCubic)
        if (k > 0.01) {
            c.save()
            c.translate(0f, ((1 - k) * 50).toFloat())
            ShareMediaRenderer.drawVerdictBlock(c, scene, images, top = 700f, alpha = all * k.toFloat(), reveal = ramp(t, r + 0.5, r + 1.7, ::easeOutBack).toFloat(), width = w)
            c.restore()
        }
    }
}
