package com.lagcheck.core.designsystem.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.lagcheck.core.designsystem.theme.LagCheckColors

/**
 * Ícone autêntico do Discord (Clyde), normalizado em viewBox 24x24.
 * Paridade 1:1 com SocialBrandIcons.swift no iOS.
 */
@Composable
fun DiscordLogo(
    modifier: Modifier = Modifier,
    size: Dp = 16.dp,
    color: Color = Color(0xFF5865F2)
) {
    Canvas(modifier = modifier.size(size)) {
        val scaleX = this.size.width / 24f
        val scaleY = this.size.height / 24f

        val path = Path().apply {
            fillType = PathFillType.EvenOdd
            moveTo(19.54f * scaleX, 4.68f * scaleY)
            cubicTo(
                18.06f * scaleX, 4.0f * scaleY,
                16.48f * scaleX, 3.51f * scaleY,
                14.85f * scaleX, 3.23f * scaleY
            )
            cubicTo(
                14.64f * scaleX, 3.6f * scaleY,
                14.41f * scaleX, 4.07f * scaleY,
                14.24f * scaleX, 4.46f * scaleY
            )
            cubicTo(
                12.78f * scaleX, 4.24f * scaleY,
                11.22f * scaleX, 4.24f * scaleY,
                9.76f * scaleX, 4.46f * scaleY
            )
            cubicTo(
                8.98f * scaleX, 4.07f * scaleY,
                8.75f * scaleX, 3.6f * scaleY,
                9.15f * scaleX, 3.23f * scaleY
            )
            cubicTo(
                7.52f * scaleX, 3.51f * scaleY,
                5.94f * scaleX, 4.0f * scaleY,
                4.46f * scaleX, 4.68f * scaleY
            )
            cubicTo(
                1.41f * scaleX, 9.13f * scaleY,
                0.61f * scaleX, 13.48f * scaleY,
                1.45f * scaleX, 17.81f * scaleY
            )
            cubicTo(
                3.19f * scaleX, 19.09f * scaleY,
                5.17f * scaleX, 20.77f * scaleY,
                7.2f * scaleX, 20.77f * scaleY
            )
            cubicTo(
                7.64f * scaleX, 20.17f * scaleY,
                8.04f * scaleX, 19.51f * scaleY,
                8.38f * scaleX, 18.82f * scaleY
            )
            cubicTo(
                7.75f * scaleX, 18.58f * scaleY,
                7.15f * scaleX, 18.29f * scaleY,
                6.58f * scaleX, 17.95f * scaleY
            )
            cubicTo(
                6.7f * scaleX, 17.86f * scaleY,
                6.82f * scaleX, 17.76f * scaleY,
                6.94f * scaleX, 17.67f * scaleY
            )
            cubicTo(
                10.22f * scaleX, 19.22f * scaleY,
                13.78f * scaleX, 19.22f * scaleY,
                17.06f * scaleX, 17.67f * scaleY
            )
            cubicTo(
                17.18f * scaleX, 17.76f * scaleY,
                17.3f * scaleX, 17.86f * scaleY,
                17.42f * scaleX, 17.95f * scaleY
            )
            cubicTo(
                16.85f * scaleX, 18.29f * scaleY,
                16.25f * scaleX, 18.58f * scaleY,
                15.62f * scaleX, 18.82f * scaleY
            )
            cubicTo(
                15.96f * scaleX, 19.51f * scaleY,
                16.36f * scaleX, 20.17f * scaleY,
                16.8f * scaleX, 20.77f * scaleY
            )
            cubicTo(
                18.83f * scaleX, 20.77f * scaleY,
                20.81f * scaleX, 19.09f * scaleY,
                22.55f * scaleX, 17.81f * scaleY
            )
            cubicTo(
                23.49f * scaleX, 13.43f * scaleY,
                22.59f * scaleX, 9.13f * scaleY,
                19.54f * scaleX, 4.68f * scaleY
            )
            close()

            // Olhos vazados
            val eyeRadius = 1.6f * scaleX
            val eyeY = 12.5f * scaleY
            addOval(
                androidx.compose.ui.geometry.Rect(
                    8.5f * scaleX - eyeRadius,
                    eyeY - eyeRadius,
                    8.5f * scaleX + eyeRadius,
                    eyeY + eyeRadius
                )
            )
            addOval(
                androidx.compose.ui.geometry.Rect(
                    15.5f * scaleX - eyeRadius,
                    eyeY - eyeRadius,
                    15.5f * scaleX + eyeRadius,
                    eyeY + eyeRadius
                )
            )
        }

        drawPath(path, color)
    }
}

/**
 * Ícone autêntico do WhatsApp.
 * Paridade 1:1 com SocialBrandIcons.swift no iOS.
 */
@Composable
fun WhatsAppLogo(
    modifier: Modifier = Modifier,
    size: Dp = 16.dp,
    color: Color = Color(0xFF25D366)
) {
    Canvas(modifier = modifier.size(size)) {
        val scaleX = this.size.width / 24f
        val scaleY = this.size.height / 24f

        val path = Path().apply {
            fillType = PathFillType.EvenOdd
            moveTo(12.0f * scaleX, 2.0f * scaleY)
            cubicTo(6.5f * scaleX, 2.0f * scaleY, 2.0f * scaleX, 6.5f * scaleY, 3.5f * scaleX, 18.0f * scaleY)
            lineTo(2.0f * scaleX, 22.0f * scaleY)
            lineTo(6.3f * scaleX, 20.6f * scaleY)
            cubicTo(8.0f * scaleX, 21.5f * scaleY, 9.9f * scaleX, 22.0f * scaleY, 12.0f * scaleX, 22.0f * scaleY)
            cubicTo(17.5f * scaleX, 22.0f * scaleY, 22.0f * scaleX, 17.5f * scaleY, 22.0f * scaleX, 12.0f * scaleY)
            cubicTo(22.0f * scaleX, 6.5f * scaleY, 17.5f * scaleX, 2.0f * scaleY, 12.0f * scaleX, 2.0f * scaleY)
            close()

            // Monofone interno
            val phone = Path().apply {
                moveTo(8.5f * scaleX, 7.5f * scaleY)
                cubicTo(8.5f * scaleX, 12.5f * scaleY, 11.5f * scaleX, 15.5f * scaleY, 16.5f * scaleX, 15.5f * scaleY)
                lineTo(15.0f * scaleX, 17.0f * scaleY)
                cubicTo(10.0f * scaleX, 14.5f * scaleY, 9.5f * scaleX, 14.0f * scaleY, 7.0f * scaleX, 9.0f * scaleY)
                close()
            }
            addPath(phone)
        }

        drawPath(path, color)
    }
}

/**
 * Ícone de Documento / PDF.
 */
@Composable
fun PdfDocumentIcon(
    modifier: Modifier = Modifier,
    size: Dp = 16.dp,
    color: Color = LagCheckColors.TextPrimary
) {
    Canvas(modifier = modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height

        val stroke = 1.5.dp.toPx()
        val path = Path().apply {
            moveTo(w * 0.2f, h * 0.1f)
            lineTo(w * 0.6f, h * 0.1f)
            lineTo(w * 0.8f, h * 0.3f)
            lineTo(w * 0.8f, h * 0.9f)
            lineTo(w * 0.2f, h * 0.9f)
            close()
        }
        drawPath(path, color, style = Stroke(width = stroke, cap = StrokeCap.Round, join = StrokeJoin.Round))

        // Linhas de texto simuladas
        drawLine(color, Offset(w * 0.35f, h * 0.45f), Offset(w * 0.65f, h * 0.45f), strokeWidth = stroke)
        drawLine(color, Offset(w * 0.35f, h * 0.62f), Offset(w * 0.65f, h * 0.62f), strokeWidth = stroke)
    }
}

/**
 * Ícone de Celular / Smartphone (Nó 1 da rota).
 */
@Composable
fun SmartphoneIcon(
    modifier: Modifier = Modifier,
    size: Dp = 20.dp,
    color: Color = LagCheckColors.TextPrimary
) {
    Canvas(modifier = modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        val stroke = 1.6.dp.toPx()

        drawRoundRect(
            color = color,
            topLeft = Offset(w * 0.22f, h * 0.1f),
            size = Size(w * 0.56f, h * 0.8f),
            cornerRadius = CornerRadius(w * 0.12f, h * 0.12f),
            style = Stroke(width = stroke)
        )
        // Linha/Home indicator
        drawLine(
            color = color,
            start = Offset(w * 0.42f, h * 0.8f),
            end = Offset(w * 0.58f, h * 0.8f),
            strokeWidth = stroke,
            cap = StrokeCap.Round
        )
    }
}

/**
 * Ícone Wi-Fi (Nó 2 da rota).
 */
@Composable
fun WifiIcon(
    modifier: Modifier = Modifier,
    size: Dp = 20.dp,
    color: Color = LagCheckColors.TextPrimary
) {
    Canvas(modifier = modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        val stroke = 1.6.dp.toPx()

        // Ponto base
        drawCircle(color = color, radius = 1.5.dp.toPx(), center = Offset(w * 0.5f, h * 0.78f))

        // Arco menor
        val arc1 = Path().apply {
            moveTo(w * 0.35f, h * 0.62f)
            cubicTo(w * 0.42f, h * 0.54f, w * 0.58f, h * 0.54f, w * 0.65f, h * 0.62f)
        }
        drawPath(arc1, color, style = Stroke(width = stroke, cap = StrokeCap.Round))

        // Arco maior
        val arc2 = Path().apply {
            moveTo(w * 0.2f, h * 0.42f)
            cubicTo(w * 0.35f, h * 0.3f, w * 0.65f, h * 0.3f, w * 0.8f, h * 0.42f)
        }
        drawPath(arc2, color, style = Stroke(width = stroke, cap = StrokeCap.Round))
    }
}

/**
 * Ícone de Servidor / Server Rack (Nó 3 da rota).
 */
@Composable
fun ServerRackIcon(
    modifier: Modifier = Modifier,
    size: Dp = 20.dp,
    color: Color = LagCheckColors.TextPrimary
) {
    Canvas(modifier = modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        val stroke = 1.5.dp.toPx()

        // Gaveta 1
        drawRoundRect(
            color = color,
            topLeft = Offset(w * 0.15f, h * 0.15f),
            size = Size(w * 0.7f, h * 0.3f),
            cornerRadius = CornerRadius(w * 0.06f, h * 0.06f),
            style = Stroke(width = stroke)
        )
        drawCircle(color = color, radius = 1.5.dp.toPx(), center = Offset(w * 0.73f, h * 0.3f))

        // Gaveta 2
        drawRoundRect(
            color = color,
            topLeft = Offset(w * 0.15f, h * 0.55f),
            size = Size(w * 0.7f, h * 0.3f),
            cornerRadius = CornerRadius(w * 0.06f, h * 0.06f),
            style = Stroke(width = stroke)
        )
        drawCircle(color = color, radius = 1.5.dp.toPx(), center = Offset(w * 0.73f, h * 0.7f))
    }
}

/**
 * Ícone Network Cockpit (topo da Home).
 */
@Composable
fun NetworkCockpitIcon(
    modifier: Modifier = Modifier,
    size: Dp = 20.dp,
    color: Color = LagCheckColors.TextPrimary
) {
    Canvas(modifier = modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        val stroke = 1.5.dp.toPx()

        // 3 pontos de nós em rede
        drawCircle(color = color, radius = 2.5.dp.toPx(), center = Offset(w * 0.5f, h * 0.25f))
        drawCircle(color = color, radius = 2.5.dp.toPx(), center = Offset(w * 0.22f, h * 0.75f))
        drawCircle(color = color, radius = 2.5.dp.toPx(), center = Offset(w * 0.78f, h * 0.75f))

        // Linhas de conexão
        drawLine(color, Offset(w * 0.5f, h * 0.25f), Offset(w * 0.22f, h * 0.75f), strokeWidth = stroke)
        drawLine(color, Offset(w * 0.5f, h * 0.25f), Offset(w * 0.78f, h * 0.75f), strokeWidth = stroke)
        drawLine(color, Offset(w * 0.22f, h * 0.75f), Offset(w * 0.78f, h * 0.75f), strokeWidth = stroke)
    }
}

/**
 * Chevron Voltar '‹' de alta precisão.
 */
@Composable
fun ChevronLeftIcon(
    modifier: Modifier = Modifier,
    size: Dp = 20.dp,
    color: Color = LagCheckColors.TextPrimary
) {
    Canvas(modifier = modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        val stroke = 2.dp.toPx()

        val path = Path().apply {
            moveTo(w * 0.65f, h * 0.2f)
            lineTo(w * 0.35f, h * 0.5f)
            lineTo(w * 0.65f, h * 0.8f)
        }
        drawPath(path, color, style = Stroke(width = stroke, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

/**
 * Ícone de Busca (Lupa).
 */
@Composable
fun SearchIcon(
    modifier: Modifier = Modifier,
    size: Dp = 18.dp,
    color: Color = LagCheckColors.TextPrimary
) {
    Canvas(modifier = modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        val stroke = 1.8.dp.toPx()

        drawCircle(
            color = color,
            radius = w * 0.32f,
            center = Offset(w * 0.42f, h * 0.42f),
            style = Stroke(width = stroke)
        )
        drawLine(
            color = color,
            start = Offset(w * 0.65f, h * 0.65f),
            end = Offset(w * 0.88f, h * 0.88f),
            strokeWidth = stroke,
            cap = StrokeCap.Round
        )
    }
}

/**
 * Ícone Fechar '✕'.
 */
@Composable
fun CloseIcon(
    modifier: Modifier = Modifier,
    size: Dp = 18.dp,
    color: Color = LagCheckColors.TextPrimary
) {
    Canvas(modifier = modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        val stroke = 1.8.dp.toPx()

        drawLine(color, Offset(w * 0.25f, h * 0.25f), Offset(w * 0.75f, h * 0.75f), strokeWidth = stroke, cap = StrokeCap.Round)
        drawLine(color, Offset(w * 0.75f, h * 0.25f), Offset(w * 0.25f, h * 0.75f), strokeWidth = stroke, cap = StrokeCap.Round)
    }
}

/**
 * Estrela de favorito: contorno quando desligada, preenchida quando ligada.
 */
@Composable
fun StarIcon(
    filled: Boolean,
    modifier: Modifier = Modifier,
    size: Dp = 18.dp,
    color: Color = LagCheckColors.TextPrimary
) {
    Canvas(modifier = modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        val cx = w / 2f
        val cy = h * 0.54f
        val outer = w * 0.46f
        val inner = outer * 0.42f
        val path = Path()
        for (i in 0 until 10) {
            val r = if (i % 2 == 0) outer else inner
            val angle = Math.toRadians(-90.0 + i * 36.0)
            val x = cx + (r * Math.cos(angle)).toFloat()
            val y = cy + (r * Math.sin(angle)).toFloat()
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        path.close()
        if (filled) drawPath(path, color)
        drawPath(path, color, style = Stroke(width = 1.8.dp.toPx(), join = StrokeJoin.Round))
    }
}
