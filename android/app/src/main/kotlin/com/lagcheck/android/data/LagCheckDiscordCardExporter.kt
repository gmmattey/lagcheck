package com.lagcheck.android.data

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import androidx.core.content.FileProvider
import com.lagcheck.domain.model.GameReadinessVerdict
import java.io.File
import java.io.FileOutputStream
import com.lagcheck.android.ui.tr

/**
 * Gerador do Card Viral de Alta Fidelidade para Discord, WhatsApp e Redes Sociais no Android.
 * Paridade 1:1 estrita com LagCheckDiscordCardExporter.swift do iOS.
 * Gera imagem PNG em 1200x675 (16:9, padrão de preview do Discord/Twitter)
 * com estética Dark Competitive UI, tipografia pesada e números de corrida.
 */
object LagCheckDiscordCardExporter {

    fun gamerQuote(verdict: GameReadinessVerdict): String {
        return when (verdict) {
            GameReadinessVerdict.READY -> tr("“Minha rota tá lisa. Bora puxar a fila.”")
            GameReadinessVerdict.CAUTION -> tr("“Minha rota tá instável, pode ter delay nos tiros.”")
            GameReadinessVerdict.NOT_READY -> tr("“Boneco tá sendo puxado pra trás. Não dá pra jogar ranked agora.”")
            GameReadinessVerdict.INCONCLUSIVE -> tr("“Medição inconclusiva, vou testar de novo.”")
        }
    }

    fun generateDiscordShareCard(
        context: Context,
        gameName: String,
        regionName: String,
        verdict: GameReadinessVerdict,
        pingMs: Double?,
        jitterMs: Double?,
        packetLossPercentage: Double?,
        isWiFi: Boolean
    ): File? {
        val width = 1200
        val height = 675
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // 1. Fundo Dark Profundo (#0B0D10)
        val bgPaint = Paint().apply {
            color = android.graphics.Color.parseColor("#0B0D10")
            style = Paint.Style.FILL
        }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), bgPaint)

        // 2. Painel Central com borda fina 1.5px (#15181E)
        val panelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = android.graphics.Color.parseColor("#15181E")
            style = Paint.Style.FILL
        }
        val panelBorderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = android.graphics.Color.argb(30, 255, 255, 255)
            style = Paint.Style.STROKE
            strokeWidth = 1.5f
        }
        val panelRect = RectF(40f, 40f, width - 40f, height - 40f)
        canvas.drawRoundRect(panelRect, 24f, 24f, panelPaint)
        canvas.drawRoundRect(panelRect, 24f, 24f, panelBorderPaint)

        // 3. Header: Wordmark "lagcheck" + Selo Oficial
        val wordmarkPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = android.graphics.Color.WHITE
            textSize = 34f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        canvas.drawText("lagcheck", 75f, 100f, wordmarkPaint)

        val tagPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = android.graphics.Color.parseColor("#7C3AED") // Roxo Gamer
            textSize = 15f
            typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
        }
        canvas.drawText(tr("● ATESTADO OFICIAL DE ROTA"), 250f, 96f, tagPaint)

        // Subtítulo da conexão
        val connType = if (isWiFi) tr("WI-FI OBSERVADO NO DISPOSITIVO") else tr("DADOS MÓVEIS OBSERVADOS")
        val subPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = android.graphics.Color.argb(160, 255, 255, 255)
            textSize = 14f
            typeface = Typeface.create(Typeface.MONOSPACE, Typeface.NORMAL)
        }
        canvas.drawText("${gameName.uppercase()} · ${regionName.uppercase()} · $connType", 75f, 138f, subPaint)

        // Linha divisória
        val dividerPaint = Paint().apply {
            color = android.graphics.Color.argb(25, 255, 255, 255)
            strokeWidth = 1f
        }
        canvas.drawLine(75f, 168f, width - 75f, 168f, dividerPaint)

        // 4. Veredito Central Gigante
        val (verdictText, verdictColorHex) = when (verdict) {
            GameReadinessVerdict.READY -> tr("● PRONTO PARA RANKED") to "#22C55E"
            GameReadinessVerdict.CAUTION -> tr("▲ INSTÁVEL: PODE TER DELAY") to "#F59E0B"
            GameReadinessVerdict.NOT_READY -> tr("■ EVITE JOGAR RANKED AGORA") to "#FF5A36"
            GameReadinessVerdict.INCONCLUSIVE -> tr("— RESULTADO INCONCLUSIVO") to "#8A93A0"
        }

        val verdictPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = android.graphics.Color.parseColor(verdictColorHex)
            textSize = 46f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        canvas.drawText(verdictText, 75f, 235f, verdictPaint)

        // Frase do Discord (A Regra do Discord)
        val quotePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = android.graphics.Color.argb(220, 255, 255, 255)
            textSize = 22f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.ITALIC)
        }
        canvas.drawText(gamerQuote(verdict), 75f, 280f, quotePaint)

        // 5. Bloco de Telemetria com 3 Colunas
        val teleY = 330f
        val colWidth = (width - 150f) / 3f

        val pingStr = pingMs?.let { "%.0f ms".format(java.util.Locale.ROOT, it) } ?: "—"
        val jitterStr = jitterMs?.let { "%.1f ms".format(java.util.Locale.ROOT, it) } ?: "—"
        val lossStr = packetLossPercentage?.let { "%.1f%%".format(java.util.Locale.ROOT, it) } ?: "—"

        val metrics = listOf(
            Triple(tr("LATÊNCIA (PING)"), pingStr, if ((pingMs ?: 999.0) <= 40) verdictColorHex else "#FFFFFF"),
            Triple(tr("OSCILAÇÃO (JITTER)"), jitterStr, if ((jitterMs ?: 999.0) <= 4.0) verdictColorHex else "#F59E0B"),
            Triple(tr("PERDA DE PACOTES"), lossStr, if ((packetLossPercentage ?: 999.0) == 0.0) verdictColorHex else "#FF5A36")
        )

        for ((index, item) in metrics.withIndex()) {
            val colX = 75f + (index * colWidth)
            val rectCol = RectF(colX, teleY, colX + colWidth - 20f, teleY + 165f)

            // Fundo da coluna
            val colBgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = android.graphics.Color.parseColor("#0E1014")
                style = Paint.Style.FILL
            }
            val colBorderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = android.graphics.Color.argb(20, 255, 255, 255)
                style = Paint.Style.STROKE
                strokeWidth = 1f
            }
            canvas.drawRoundRect(rectCol, 16f, 16f, colBgPaint)
            canvas.drawRoundRect(rectCol, 16f, 16f, colBorderPaint)

            // Label
            val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = android.graphics.Color.argb(130, 255, 255, 255)
                textSize = 14f
                typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
            }
            canvas.drawText(item.first, colX + 20f, teleY + 40f, labelPaint)

            // Valor Grande Monoespaçado
            val valPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = android.graphics.Color.parseColor(item.third)
                textSize = 48f
                typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
            }
            canvas.drawText(item.second, colX + 20f, teleY + 105f, valPaint)

            // Sub-legenda de honestidade
            val honestyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = android.graphics.Color.argb(110, 255, 255, 255)
                textSize = 12f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
            }
            val subText = when (index) {
                0 -> tr("mediana em repouso, via UDP")
                1 -> tr("variação entre pacotes seguidos")
                else -> tr("perda no teste em repouso")
            }
            canvas.drawText(subText, colX + 20f, teleY + 138f, honestyPaint)
        }

        // Rodapé de autenticidade
        val footerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = android.graphics.Color.argb(120, 255, 255, 255)
            textSize = 13f
            typeface = Typeface.create(Typeface.MONOSPACE, Typeface.NORMAL)
        }
        canvas.drawText(tr("lagcheck.signallq.com · Medição real determinística · Sem notas inventadas"), 75f, height - 70f, footerPaint)

        // Salvar imagem no cache para compartilhamento seguro
        return try {
            val cachePath = File(context.cacheDir, "images").apply { mkdirs() }
            val file = File(cachePath, "LagCheck_${gameName.replace(" ", "_")}_${System.currentTimeMillis()}.png")
            val stream = FileOutputStream(file)
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.flush()
            stream.close()
            file
        } catch (e: Exception) {
            null
        }
    }
}
