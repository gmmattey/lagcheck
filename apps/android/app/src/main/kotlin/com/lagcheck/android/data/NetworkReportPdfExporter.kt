package com.lagcheck.android.data

import android.content.Context
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import com.lagcheck.session.CockpitSection
import java.io.File
import java.io.FileOutputStream

/** PDF vetorial do mesmo retrato de dados que o Cockpit mostra na tela. */
object NetworkReportPdfExporter {
    private const val PAGE_WIDTH = 595
    private const val PAGE_HEIGHT = 842
    private const val MARGIN = 40f
    private const val CONTENT_WIDTH = PAGE_WIDTH - 2 * MARGIN
    private const val CONTENT_BOTTOM = PAGE_HEIGHT - 55f

    private val background = Color.rgb(11, 13, 16)
    private val surface = Color.rgb(21, 24, 30)
    private val border = Color.rgb(38, 45, 56)
    private val accent = Color.rgb(255, 90, 54)
    private val primary = Color.rgb(244, 245, 247)
    private val muted = Color.rgb(138, 147, 160)

    fun export(context: Context, title: String, sections: List<CockpitSection>): File? = runCatching {
        val directory = File(context.cacheDir, "network-reports").apply { mkdirs() }
        val file = File(directory, "lagcheck-network-${System.currentTimeMillis()}.pdf")
        val document = PdfDocument()
        try {
            val pager = Pager(document, title)
            sections.forEach(pager::section)
            pager.finish()
            FileOutputStream(file).use(document::writeTo)
        } finally {
            document.close()
        }
        directory.listFiles()?.filter { it != file && it.extension == "pdf" }?.forEach { it.delete() }
        file
    }.getOrNull()

    private class Pager(private val pdf: PdfDocument, private val title: String) {
        private var page: PdfDocument.Page? = null
        private var pageNumber = 0
        private var y = 0f

        private fun textPaint(size: Float, color: Int, bold: Boolean = false, mono: Boolean = false) =
            TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                textSize = size
                this.color = color
                typeface = Typeface.create(if (mono) Typeface.MONOSPACE else Typeface.SANS_SERIF, if (bold) Typeface.BOLD else Typeface.NORMAL)
            }

        private fun layout(value: String, paint: TextPaint, width: Int): StaticLayout =
            StaticLayout.Builder.obtain(value, 0, value.length, paint, width)
                .setAlignment(Layout.Alignment.ALIGN_NORMAL)
                .setIncludePad(false)
                .build()

        private fun drawText(value: String, paint: TextPaint, x: Float, top: Float, width: Int): Int {
            val textLayout = layout(value, paint, width)
            val canvas = requireNotNull(page).canvas
            canvas.save()
            canvas.translate(x, top)
            textLayout.draw(canvas)
            canvas.restore()
            return textLayout.height
        }

        private fun nextPage() {
            finish()
            pageNumber++
            page = pdf.startPage(PdfDocument.PageInfo.Builder(PAGE_WIDTH, PAGE_HEIGHT, pageNumber).create())
            val canvas = requireNotNull(page).canvas
            canvas.drawColor(background)
            drawText("lagcheck", textPaint(20f, primary, bold = true), MARGIN, 34f, CONTENT_WIDTH.toInt())
            canvas.drawRect(MARGIN, 64f, MARGIN + 34f, 67f, Paint().apply { color = accent })
            drawText(title, textPaint(12f, muted, bold = true, mono = true), MARGIN, 78f, CONTENT_WIDTH.toInt())
            y = 119f
        }

        fun section(section: CockpitSection) {
            if (page == null) nextPage()
            val labelPaint = textPaint(11f, muted)
            val valuePaint = textPaint(11f, primary, bold = true, mono = true)
            val rows = section.rows.map { row ->
                val label = layout(row.label, labelPaint, 192)
                val value = layout(row.value, valuePaint, 271)
                Triple(label, value, maxOf(24, maxOf(label.height, value.height) + 8))
            }
            val cardHeight = 43 + rows.sumOf { it.third } + 8
            if (y + cardHeight > CONTENT_BOTTOM) nextPage()
            val canvas = requireNotNull(page).canvas
            val top = y
            canvas.drawRoundRect(MARGIN, top, MARGIN + CONTENT_WIDTH, top + cardHeight, 12f, 12f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = surface })
            canvas.drawRoundRect(MARGIN, top, MARGIN + CONTENT_WIDTH, top + cardHeight, 12f, 12f, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = border
                style = Paint.Style.STROKE
                strokeWidth = 1f
            })
            drawText(section.title, textPaint(11f, accent, bold = true, mono = true), MARGIN + 16f, top + 15f, (CONTENT_WIDTH - 32).toInt())
            var rowY = top + 43f
            rows.forEach { (label, value, height) ->
                canvas.save()
                canvas.translate(MARGIN + 16f, rowY)
                label.draw(canvas)
                canvas.restore()
                canvas.save()
                canvas.translate(MARGIN + 224f, rowY)
                value.draw(canvas)
                canvas.restore()
                rowY += height
            }
            y += cardHeight + 18f
        }

        fun finish() {
            page?.let {
                drawText("lagcheck · leituras do dispositivo", textPaint(9f, muted, mono = true), MARGIN, PAGE_HEIGHT - 35f, CONTENT_WIDTH.toInt())
                pdf.finishPage(it)
            }
            page = null
        }
    }
}
