package com.lagcheck.core.designsystem.components

import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/**
 * Linha fina só embaixo da linha da lista (0,5 dp, branco a 8%), como no protótipo.
 * Substitui `border`, que desenhava uma caixa inteira em volta de cada linha (efeito de grade).
 */
fun Modifier.rowDivider(color: Color = Color.White.copy(alpha = 0.08f)): Modifier = drawBehind {
    val y = size.height - 0.25.dp.toPx()
    drawLine(color, Offset(0f, y), Offset(size.width, y), strokeWidth = 0.5.dp.toPx())
}
