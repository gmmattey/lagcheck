package com.lagcheck.android.share

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import androidx.compose.ui.graphics.toArgb
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import com.lagcheck.core.designsystem.theme.LagCheckColors

/** Utilitários de desenho em Canvas compartilhados pelos cards e pelo vídeo (paridade com ShareCanvas.swift). */
internal object ShareCanvas {
    // Paleta da Dark Competitive UI: tokens do app, sem cores soltas (Decisão 66).
    val deep = LagCheckColors.Background.toArgb()
    val text = LagCheckColors.TextPrimary.toArgb()
    val muted = LagCheckColors.TextSecondary.toArgb()
    val accent = 0xFFA78BFA.toInt() // Roxo Gamer claro (token gamerPurpleLight do iOS)
    val purple = LagCheckColors.AccentPrimary.toArgb()
    val ready = LagCheckColors.Good.toArgb()
    val caution = LagCheckColors.SemanticCaution.toArgb()
    val notReady = LagCheckColors.CoralWarning.toArgb()

    fun toneColor(tone: ShareTone): Int = when (tone) {
        ShareTone.READY -> ready
        ShareTone.CAUTION -> caution
        ShareTone.NOT_READY -> notReady
    }

    fun withAlpha(color: Int, alpha: Float): Int {
        val a = (android.graphics.Color.alpha(color) * alpha.coerceIn(0f, 1f)).toInt()
        return (color and 0x00FFFFFF) or (a shl 24)
    }

    enum class Align { LEFT, CENTER, RIGHT }

    private var appContext: android.content.Context? = null
    private val faces = HashMap<Int, Typeface>()

    /** Precisa do contexto para ler as fontes oficiais (Barlow, Barlow Semi Condensed e Chakra Petch). */
    fun init(context: android.content.Context) {
        appContext = context.applicationContext
    }

    @Synchronized
    private fun typeface(weight: Int, mono: Boolean): Typeface {
        val key = if (mono) -1 else weight
        return faces.getOrPut(key) {
            val ctx = appContext ?: return@getOrPut Typeface.DEFAULT
            val resId = when {
                mono -> com.lagcheck.core.designsystem.R.font.chakra_petch_semibold
                weight >= 800 -> com.lagcheck.core.designsystem.R.font.barlow_semicondensed_extrabold
                weight >= 700 -> com.lagcheck.core.designsystem.R.font.barlow_semicondensed_bold
                weight >= 600 -> com.lagcheck.core.designsystem.R.font.barlow_semibold
                weight >= 500 -> com.lagcheck.core.designsystem.R.font.barlow_medium
                else -> com.lagcheck.core.designsystem.R.font.barlow_regular
            }
            runCatching {
                androidx.core.content.res.ResourcesCompat.getFont(ctx, resId)
            }.getOrNull() ?: Typeface.DEFAULT
        }
    }

    private fun paint(size: Float, weight: Int, mono: Boolean, kern: Float, color: Int) = Paint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
        textSize = size
        typeface = typeface(weight, mono)
        fontFeatureSettings = "tnum"
        letterSpacing = if (size > 0f) kern / size else 0f
        this.color = color
    }

    /** Texto com espaçamento de letras e sombra opcional; `y` é a linha de base. */
    fun draw(
        c: Canvas, s: String, x: Float, y: Float, size: Float, weight: Int, color: Int,
        kern: Float = 0f, align: Align = Align.LEFT, shadow: Boolean = false, alpha: Float = 1f, mono: Boolean = false
    ) {
        val p = paint(size, weight, mono, kern, withAlpha(color, alpha))
        if (shadow) p.setShadowLayer(12f, 0f, 2f, withAlpha(0xFF000000.toInt(), 0.55f * alpha))
        val w = p.measureText(s)
        val ox = when (align) { Align.LEFT -> x; Align.CENTER -> x - w / 2; Align.RIGHT -> x - w }
        c.drawText(s, ox, y, p)
    }

    fun width(s: String, size: Float, weight: Int, kern: Float = 0f, mono: Boolean = false): Float =
        paint(size, weight, mono, kern, 0).measureText(s)

    /** Quebra em linhas de até `maxWidth`, sem cortar palavras. */
    fun wrap(s: String, size: Float, weight: Int, kern: Float, maxWidth: Float): List<String> {
        val lines = mutableListOf<String>()
        var cur = ""
        for (word in s.split(" ").filter { it.isNotEmpty() }) {
            val trial = if (cur.isEmpty()) word else "$cur $word"
            if (cur.isNotEmpty() && width(trial, size, weight, kern) > maxWidth) {
                lines += cur
                cur = word
            } else {
                cur = trial
            }
        }
        if (cur.isNotEmpty()) lines += cur
        return lines
    }

    fun fillRect(c: Canvas, l: Float, t: Float, r: Float, b: Float, color: Int) {
        c.drawRect(l, t, r, b, Paint().apply { this.color = color; style = Paint.Style.FILL })
    }

    fun roundRect(c: Canvas, rect: RectF, radius: Float, color: Int, stroke: Boolean = false, strokeWidth: Float = 1f) {
        c.drawRoundRect(rect, radius, radius, Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            style = if (stroke) Paint.Style.STROKE else Paint.Style.FILL
            this.strokeWidth = strokeWidth
        })
    }

    fun circle(c: Canvas, cx: Float, cy: Float, r: Float, color: Int, glow: Float = 0f) {
        c.drawCircle(cx, cy, r, Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            if (glow > 0f) setShadowLayer(glow, 0f, 0f, color)
        })
    }

    /** Preenche `rect` com a imagem recortada ao centro (aspect fill); sem imagem, fundo liso. */
    fun drawFill(c: Canvas, bmp: Bitmap?, rect: RectF, radius: Float = 0f) {
        c.save()
        if (radius > 0f) c.clipPath(Path().apply { addRoundRect(rect, radius, radius, Path.Direction.CW) }) else c.clipRect(rect)
        if (bmp != null && bmp.width > 0 && bmp.height > 0) {
            val k = maxOf(rect.width() / bmp.width, rect.height() / bmp.height)
            val w = bmp.width * k
            val h = bmp.height * k
            c.drawBitmap(bmp, null, RectF(rect.centerX() - w / 2, rect.centerY() - h / 2, rect.centerX() + w / 2, rect.centerY() + h / 2), Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG))
        } else {
            c.drawRect(rect, Paint().apply { color = 0xFF1A0B2E.toInt() })
        }
        c.restore()
    }

    fun gradient(c: Canvas, stops: List<Pair<Float, Int>>, x0: Float, y0: Float, x1: Float, y1: Float, rect: RectF, alpha: Float = 1f) {
        val shader = LinearGradient(x0, y0, x1, y1, stops.map { withAlpha(it.second, alpha) }.toIntArray(), stops.map { it.first }.toFloatArray(), Shader.TileMode.CLAMP)
        c.drawRect(rect, Paint().apply { this.shader = shader })
    }

    fun drawImage(c: Canvas, bmp: Bitmap?, height: Float, x: Float, y: Float, alpha: Float = 1f) {
        if (bmp == null || bmp.height == 0) return
        val w = height * bmp.width / bmp.height
        c.drawBitmap(bmp, null, RectF(x, y, x + w, y + height), Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG).apply { this.alpha = (alpha.coerceIn(0f, 1f) * 255).toInt() })
    }

    /** QR do link da loja (ZXing); quadro branco arredondado em volta. */
    fun drawQr(c: Canvas, url: String, rect: RectF, radius: Float, padding: Float) {
        roundRect(c, rect, radius, 0xFFFFFFFF.toInt())
        val matrix = QRCodeWriter().encode(url, BarcodeFormat.QR_CODE, 0, 0, mapOf(EncodeHintType.MARGIN to 0, EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.M))
        val n = matrix.width
        val inner = rect.width() - padding * 2
        val cell = inner / n
        val p = Paint().apply { color = 0xFF17151F.toInt(); style = Paint.Style.FILL }
        for (yy in 0 until n) for (xx in 0 until n) if (matrix.get(xx, yy)) {
            val l = rect.left + padding + xx * cell
            val t = rect.top + padding + yy * cell
            c.drawRect(l, t, l + cell + 0.5f, t + cell + 0.5f, p)
        }
    }

    fun decode(context: Context, name: String): Bitmap? {
        val id = context.resources.getIdentifier(name, "drawable", context.packageName)
        if (id == 0) return null
        return BitmapFactory.decodeResource(context.resources, id, BitmapFactory.Options().apply { inScaled = false })
    }
}
