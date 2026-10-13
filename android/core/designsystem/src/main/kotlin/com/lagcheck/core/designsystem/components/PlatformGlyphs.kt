package com.lagcheck.core.designsystem.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.vector.PathParser
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.lagcheck.core.designsystem.theme.LagCheckColors

/**
 * Glifos de plataforma do protótipo Android (viewBox 24, traço 1.7).
 * Servem só para dizer onde o jogo existe; o aparelho do check é sempre o celular (Decisão 80).
 */
@Composable
fun PlatformGlyph(
    platform: String,
    modifier: Modifier = Modifier,
    size: Dp = 16.dp,
    color: Color = LagCheckColors.TextMuted
) {
    val key = platform.lowercase()
    Canvas(modifier = modifier.size(size)) {
        scale(scale = this.size.width / 24f, pivot = Offset.Zero) {
            val style = Stroke(width = 1.7f, cap = StrokeCap.Round, join = StrokeJoin.Round)
            when {
                "playstation" in key -> drawBrand(PLAYSTATION_PATH, color)
                "xbox" in key -> drawBrand(XBOX_PATH, color)
                "nintendo" in key || "switch" in key -> drawBrand(NINTENDO_SWITCH_PATH, color)
                key == "pc" || "windows" in key -> {
                    drawRoundRect(color, Offset(2.5f, 4f), Size(19f, 12f), CornerRadius(2f), style)
                    drawLine(color, Offset(8f, 20f), Offset(16f, 20f), 1.7f, StrokeCap.Round)
                    drawLine(color, Offset(12f, 16f), Offset(12f, 20f), 1.7f, StrokeCap.Round)
                }
                else -> {
                    drawRoundRect(color, Offset(7f, 2.5f), Size(10f, 19f), CornerRadius(2.5f), style)
                    drawLine(color, Offset(10.5f, 18.5f), Offset(13.5f, 18.5f), 1.7f, StrokeCap.Round)
                }
            }
        }
    }
}

/** Linha de glifos de plataforma, na ordem recebida. */
@Composable
fun PlatformGlyphRow(
    platforms: List<String>,
    modifier: Modifier = Modifier,
    size: Dp = 16.dp,
    color: Color = LagCheckColors.TextMuted
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        platforms.forEach { PlatformGlyph(it, size = size, color = color) }
    }
}

// Logos oficiais das plataformas (Simple Icons, CC0; viewBox 24). Marcas pertencem aos seus donos e
// aparecem apenas para identificar a plataforma do jogo.
private const val PLAYSTATION_PATH = "M8.984 2.596v17.547l3.915 1.261V6.688c0-.69.304-1.151.794-.991.636.18.76.814.76 1.505v5.875c2.441 1.193 4.362-.002 4.362-3.152 0-3.237-1.126-4.675-4.438-5.827-1.307-.448-3.728-1.186-5.39-1.502zm4.656 16.241l6.296-2.275c.715-.258.826-.625.246-.818-.586-.192-1.637-.139-2.357.123l-4.205 1.5V14.98l.24-.085s1.201-.42 2.913-.615c1.696-.18 3.785.03 5.437.661 1.848.601 2.04 1.472 1.576 2.072-.465.6-1.622 1.036-1.622 1.036l-8.544 3.107V18.86zM1.807 18.6c-1.9-.545-2.214-1.668-1.352-2.32.801-.586 2.16-1.052 2.16-1.052l5.615-2.013v2.313L4.205 17c-.705.271-.825.632-.239.826.586.195 1.637.15 2.343-.12L8.247 17v2.074c-.12.03-.256.044-.39.073-1.939.331-3.996.196-6.038-.479z"
private const val XBOX_PATH = "M4.102 21.033C6.211 22.881 8.977 24 12 24c3.026 0 5.789-1.119 7.902-2.967 1.877-1.912-4.316-8.709-7.902-11.417-3.582 2.708-9.779 9.505-7.898 11.417zm11.16-14.406c2.5 2.961 7.484 10.313 6.076 12.912C23.002 17.48 24 14.861 24 12.004c0-3.34-1.365-6.362-3.57-8.536 0 0-.027-.022-.082-.042-.063-.022-.152-.045-.281-.045-.592 0-1.985.434-4.805 3.246zM3.654 3.426c-.057.02-.082.041-.086.042C1.365 5.642 0 8.664 0 12.004c0 2.854.998 5.473 2.661 7.533-1.401-2.605 3.579-9.951 6.08-12.91-2.82-2.813-4.216-3.245-4.806-3.245-.131 0-.223.021-.281.046v-.002zM12 3.551S9.055 1.828 6.755 1.746c-.903-.033-1.454.295-1.521.339C7.379.646 9.659 0 11.984 0H12c2.334 0 4.605.646 6.766 2.085-.068-.046-.615-.372-1.52-.339C14.946 1.828 12 3.545 12 3.545v.006z"
private const val NINTENDO_SWITCH_PATH = "M14.176 24h3.674c3.376 0 6.15-2.774 6.15-6.15V6.15C24 2.775 21.226 0 17.85 0H14.1c-.074 0-.15.074-.15.15v23.7c-.001.076.075.15.226.15zm4.574-13.199c1.351 0 2.399 1.125 2.399 2.398 0 1.352-1.125 2.4-2.399 2.4-1.35 0-2.4-1.049-2.4-2.4-.075-1.349 1.05-2.398 2.4-2.398zM11.4 0H6.15C2.775 0 0 2.775 0 6.15v11.7C0 21.226 2.775 24 6.15 24h5.25c.074 0 .15-.074.15-.149V.15c.001-.076-.075-.15-.15-.15zM9.676 22.051H6.15c-2.326 0-4.201-1.875-4.201-4.201V6.15c0-2.326 1.875-4.201 4.201-4.201H9.6l.076 20.102zM3.75 7.199c0 1.275.975 2.25 2.25 2.25s2.25-.975 2.25-2.25c0-1.273-.975-2.25-2.25-2.25s-2.25.977-2.25 2.25z"

private fun DrawScope.drawBrand(pathData: String, color: Color) {
    drawPath(PathParser().parsePathString(pathData).toPath(), color, style = Fill)
}
