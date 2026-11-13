package com.lagcheck.core.designsystem.components

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.core.designsystem.theme.LagCheckSpacing
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

/**
 * Hero da Home do LagCheck — Mostrador de telemetria com ticks de precisão,
 * órbita fina em Roxo Gamer e núcleo elevado com profundidade (Decisão 129).
 */
@Composable
fun HomeCircularPulseGaugeHero(
    isMeasuring: Boolean = false,
    testButtonText: String = "TESTAR",
    measuringText: String = "MEDINDO...",
    onStartCheck: () -> Unit,
    modifier: Modifier = Modifier,
    pulseDiameter: Dp = 216.dp
) {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse_transition")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1.0f,
        targetValue = 1.24f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 3000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "pulse_scale"
    )
    val pulseAlpha by infiniteTransition.animateFloat(
        initialValue = 0.28f,
        targetValue = 0.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 3000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "pulse_alpha"
    )

    val orbitAngle by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = if (isMeasuring) 1400 else 9000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "orbit_angle"
    )

    Box(
        modifier = modifier.size(pulseDiameter + 40.dp),
        contentAlignment = Alignment.Center
    ) {
        // Pulso sutil de presença
        if (!isMeasuring) {
            Box(
                modifier = Modifier
                    .size(pulseDiameter - 16.dp)
                    .scale(pulseScale)
                    .clip(CircleShape)
                    .background(LagCheckColors.AccentPrimary.copy(alpha = pulseAlpha * 0.28f))
            )
        }

        // Mostrador de telemetria: ticks radiais + trilho fino + órbita roxa com ponto
        Canvas(modifier = Modifier.size(pulseDiameter)) {
            val center = Offset(size.width / 2f, size.height / 2f)
            val outerR = (size.minDimension - 8.dp.toPx()) / 2f
            val orbitR = outerR - 10.dp.toPx()

            // 36 marcações radiais de mostrador
            for (i in 0 until 36) {
                val angleRad = (i * 10.0 - 90.0) * (PI / 180.0)
                val isCardinal = i % 9 == 0
                val tickLen = if (isCardinal) 7.dp.toPx() else 4.dp.toPx()
                val tickWidth = if (isCardinal) 1.8.dp.toPx() else 1.dp.toPx()
                val tickColor = if (isCardinal) {
                    LagCheckColors.TextSecondary.copy(alpha = 0.55f)
                } else {
                    LagCheckColors.TextTertiary.copy(alpha = 0.35f)
                }
                val startPt = Offset(
                    center.x + ((outerR - tickLen) * cos(angleRad)).toFloat(),
                    center.y + ((outerR - tickLen) * sin(angleRad)).toFloat()
                )
                val endPt = Offset(
                    center.x + (outerR * cos(angleRad)).toFloat(),
                    center.y + (outerR * sin(angleRad)).toFloat()
                )
                drawLine(color = tickColor, start = startPt, end = endPt, strokeWidth = tickWidth, cap = StrokeCap.Round)
            }

            // Trilho fino contínuo da órbita
            drawCircle(
                color = LagCheckColors.BorderHairline,
                radius = orbitR,
                style = Stroke(width = 1.2.dp.toPx())
            )

            // Arco fino da órbita + ponto guia luminoso
            val sweep = if (isMeasuring) 110f else 72f
            val startDeg = orbitAngle - 90f
            val tipDeg = startDeg + sweep
            val tipRad = tipDeg * (PI / 180.0)
            val tipOffset = Offset(
                center.x + (orbitR * cos(tipRad)).toFloat(),
                center.y + (orbitR * sin(tipRad)).toFloat()
            )

            drawArc(
                color = LagCheckColors.AccentPrimary.copy(alpha = 0.85f),
                startAngle = startDeg,
                sweepAngle = sweep,
                useCenter = false,
                topLeft = Offset(center.x - orbitR, center.y - orbitR),
                size = androidx.compose.ui.geometry.Size(orbitR * 2f, orbitR * 2f),
                style = Stroke(width = 2.5.dp.toPx(), cap = StrokeCap.Round)
            )

            // Halo + ponto orbital em AccentPrimaryLight
            drawCircle(
                color = LagCheckColors.AccentPrimary.copy(alpha = 0.35f),
                radius = 7.dp.toPx(),
                center = tipOffset
            )
            drawCircle(
                color = LagCheckColors.AccentPrimaryLight,
                radius = 3.2.dp.toPx(),
                center = tipOffset
            )
        }

        // Núcleo Central Elevado (profundidade por camada + sombra, sem linha de contorno)
        val coreSize = pulseDiameter - 48.dp
        Box(
            modifier = Modifier
                .size(coreSize)
                .shadow(elevation = 14.dp, shape = CircleShape)
                .clip(CircleShape)
                .background(
                    Brush.radialGradient(
                        colors = listOf(
                            LagCheckColors.Panel,
                            LagCheckColors.Surface
                        )
                    )
                )
                .background(
                    Brush.radialGradient(
                        colors = listOf(
                            LagCheckColors.AccentPrimary.copy(alpha = 0.16f),
                            Color.Transparent
                        )
                    )
                )
                .clickable { onStartCheck() },
            contentAlignment = Alignment.Center
        ) {
            if (isMeasuring) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(30.dp),
                        color = LagCheckColors.AccentPrimaryLight,
                        strokeWidth = 2.5.dp
                    )
                    Spacer(modifier = Modifier.height(LagCheckSpacing.space1_5))
                    Text(
                        text = measuringText,
                        style = LagCheckTypography.MonoSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = LagCheckColors.TextPrimary
                    )
                }
            } else {
                Text(
                    text = testButtonText,
                    style = LagCheckTypography.PageTitle.copy(
                        fontSize = 24.sp,
                        fontWeight = FontWeight.ExtraBold,
                        letterSpacing = 1.8.sp
                    ),
                    color = Color.White
                )
            }
        }
    }
}
