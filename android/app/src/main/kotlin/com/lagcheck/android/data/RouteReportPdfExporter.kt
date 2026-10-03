package com.lagcheck.android.data

import android.content.Context
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import com.lagcheck.domain.presentation.RouteReportDocument
import java.io.File
import java.io.FileOutputStream

/**
 * Desenha o [RouteReportDocument] em PDF (A4) com `PdfDocument` do próprio Android: sem biblioteca, sem rede.
 * Fundo branco e texto escuro, para imprimir e ler em qualquer tela. A regra do que entra no relatório mora em
 * `RouteReport` (domínio, testada na JVM); aqui só se desenha e se pagina.
 */
object RouteReportPdfExporter {
    private const val PAGE_W = 595 // A4 a 72 dpi
    private const val PAGE_H = 842
    private const val MARGIN = 40f
    private const val CONTENT_W = PAGE_W - 2 * MARGIN
    private const val BOTTOM = PAGE_H - 56f

    private val INK = Color.parseColor("#14171C")
    private val MUTED = Color.parseColor("#5B6470")
    private val RULE = Color.parseColor("#D9DEE5")
    private val ACCENT = Color.parseColor("#7C3AED")

    private fun paint(size: Float, color: Int, bold: Boolean = false, mono: Boolean = false) = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
        textSize = size
        this.color = color
        typeface = Typeface.create(if (mono) Typeface.MONOSPACE else Typeface.SANS_SERIF, if (bold) Typeface.BOLD else Typeface.NORMAL)
    }

    /** Gera o arquivo em `cache/reports/` e devolve-o, ou nulo se a escrita falhar. */
    fun export(context: Context, document: RouteReportDocument, fileName: String): File? = runCatching {
        val dir = File(context.cacheDir, "reports").apply { mkdirs() }
        // Um relatório por vez: não acumula PDFs antigos no cache.
        dir.listFiles()?.forEach { it.delete() }
        val file = File(dir, fileName.replace(Regex("[^A-Za-z0-9._-]"), "_").ifBlank { "lagcheck-report" } + ".pdf")

        val pdf = PdfDocument()
        val pager = Pager(pdf)
        try {
            pager.draw(document)
            FileOutputStream(file).use { pdf.writeTo(it) }
        } finally {
            pager.finish()
            pdf.close()
        }
        file
    }.getOrNull()

    private class Pager(private val pdf: PdfDocument) {
        private var number = 0
        private var page: PdfDocument.Page? = null
        private var y = MARGIN

        private fun newPage() {
            finish()
            number += 1
            page = pdf.startPage(PdfDocument.PageInfo.Builder(PAGE_W, PAGE_H, number).create())
            y = MARGIN
        }

        fun finish() {
            page?.let { pdf.finishPage(it) }
            page = null
        }

        private fun ensure(height: Float) {
            if (page == null || y + height > BOTTOM) newPage()
        }

        private fun text(value: String, p: TextPaint, width: Float = CONTENT_W, x: Float = MARGIN, gap: Float = 4f) {
            val layout = StaticLayout.Builder.obtain(value, 0, value.length, p, width.toInt())
                .setAlignment(Layout.Alignment.ALIGN_NORMAL).setIncludePad(false).build()
            ensure(layout.height.toFloat())
            val canvas = page!!.canvas
            canvas.save(); canvas.translate(x, y); layout.draw(canvas); canvas.restore()
            y += layout.height + gap
        }

        private fun rule() {
            ensure(10f)
            page!!.canvas.drawLine(MARGIN, y, PAGE_W - MARGIN, y, Paint().apply { color = RULE; strokeWidth = 1f })
            y += 12f
        }

        private fun section(title: String) {
            y += 8f
            ensure(36f)
            text(title, paint(10f, MUTED, bold = true, mono = true), gap = 6f)
        }

        private fun pair(label: String, value: String) {
            val valuePaint = paint(12f, INK, bold = true, mono = true)
            val labelPaint = paint(12f, MUTED)
            val valueW = 150f
            val l = StaticLayout.Builder.obtain(label, 0, label.length, labelPaint, (CONTENT_W - valueW - 8).toInt()).setIncludePad(false).build()
            val v = StaticLayout.Builder.obtain(value, 0, value.length, valuePaint, valueW.toInt()).setAlignment(Layout.Alignment.ALIGN_OPPOSITE).setIncludePad(false).build()
            val h = maxOf(l.height, v.height).toFloat()
            ensure(h)
            val c = page!!.canvas
            c.save(); c.translate(MARGIN, y); l.draw(c); c.restore()
            c.save(); c.translate(MARGIN + CONTENT_W - valueW, y); v.draw(c); c.restore()
            y += h + 6f
        }

        fun draw(doc: RouteReportDocument) {
            newPage()
            text(doc.title, paint(10f, ACCENT, bold = true, mono = true), gap = 14f)
            text("${doc.verdictSymbol} ${doc.verdictHeadline}", paint(24f, INK, bold = true), gap = 6f)
            text(doc.verdictSubtitle, paint(13f, MUTED), gap = 12f)
            rule()
            doc.summary.forEach { (k, v) -> pair(k, v) }

            section(doc.telemetryTitle)
            doc.telemetry.forEach { (k, v) -> pair(k, v) }

            if (doc.findings.isNotEmpty()) {
                section(doc.findingsTitle)
                doc.findings.forEach { (label, detail) ->
                    text("• $label", paint(12f, INK, bold = true), gap = if (detail == null) 5f else 1f)
                    if (detail != null) text(detail, paint(11f, MUTED), x = MARGIN + 10f, width = CONTENT_W - 10f, gap = 5f)
                }
            }
            if (doc.actions.isNotEmpty()) {
                section(doc.actionsTitle)
                doc.actions.forEach { (title, instruction) ->
                    text("• $title", paint(12f, INK, bold = true), gap = 1f)
                    text(instruction, paint(11f, MUTED), x = MARGIN + 10f, width = CONTENT_W - 10f, gap = 5f)
                }
            }
            section(doc.weighedTitle)
            text(doc.weighed, paint(12f, INK), gap = 14f)

            rule()
            text(doc.footer, paint(10f, MUTED), gap = 3f)
            text(doc.generatedAt, paint(10f, MUTED, mono = true))
        }
    }
}
