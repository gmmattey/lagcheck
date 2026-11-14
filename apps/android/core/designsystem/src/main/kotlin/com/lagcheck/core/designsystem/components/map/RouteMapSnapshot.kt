package com.lagcheck.core.designsystem.components.map

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.Shader

/**
 * Renderiza o mapa mundi pontilhado oficial (`RouteMapGridData`) como Bitmap estático
 * para cards e vídeos de compartilhamento quando não houver jogo selecionado.
 */
object RouteMapSnapshot {
    fun render(width: Int = 1200, height: Int = 900): Bitmap {
        val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val w = width.toFloat()
        val h = height.toFloat()

        // Fundo base Dark Competitive UI (#0B0D10)
        c.drawColor(0xFF0B0D10.toInt())

        // Brilho sutil Roxo Gamer no centro do mapa
        val glowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                w * 0.45f,
                h * 0.48f,
                w * 0.55f,
                intArrayOf(0x287C3AED, 0x000B0D10),
                floatArrayOf(0f, 1f),
                Shader.TileMode.CLAMP
            )
        }
        c.drawRect(0f, 0f, w, h, glowPaint)

        // Grade técnica sutil
        val gridPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0x168A93A0
            strokeWidth = 1f
        }
        val stepGrid = w / 12f
        var gx = stepGrid
        while (gx < w) {
            c.drawLine(gx, 0f, gx, h, gridPaint)
            gx += stepGrid
        }
        var gy = stepGrid
        while (gy < h) {
            c.drawLine(0f, gy, w, gy, gridPaint)
            gy += stepGrid
        }

        // Pontos de terra do RouteMapGridData
        val rows = RouteMapGridData.ROWS
        if (rows.isEmpty()) return bmp
        val rowCount = rows.size
        val colCount = rows[0].length

        val padX = w * 0.04f
        val mapW = w - padX * 2f
        val cellW = mapW / colCount
        val mapH = cellW * rowCount
        val padY = (h - mapH) * 0.46f
        val dotRadius = (cellW * 0.36f).coerceAtLeast(1.4f)

        val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFF3A4454.toInt()
            style = Paint.Style.FILL
        }

        for (r in 0 until rowCount) {
            val row = rows[r]
            val cy = padY + (r + 0.5f) * cellW
            for (col in 0 until row.length) {
                if (row[col] == '1') {
                    val cx = padX + (col + 0.5f) * cellW
                    c.drawCircle(cx, cy, dotRadius, dotPaint)
                }
            }
        }

        return bmp
    }
}
