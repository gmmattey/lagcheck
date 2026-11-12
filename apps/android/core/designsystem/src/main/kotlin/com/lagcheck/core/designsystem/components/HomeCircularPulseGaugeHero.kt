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

/**
 * Hero da Home do LagCheck — Gauge circular esportivo com pulso e arco em Roxo Gamer (Decisões 112 e 113).
 * No centro: texto estritamente minimalista "TESTAR".
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
        targetValue = 1.35f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 2800, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "pulse_scale"
    )
    val pulseAlpha by infiniteTransition.animateFloat(
        initialValue = 0.5f,
        targetValue = 0.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 2800, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "pulse_alpha"
    )

    val spinAngle by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1400, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "spin_angle"
    )

    Box(
        modifier = modifier.size(pulseDiameter + 40.dp),
        contentAlignment = Alignment.Center
    ) {
        // Ondas concêntricas de pulso
        if (!isMeasuring) {
            Box(
                modifier = Modifier
                    .size(pulseDiameter)
                    .scale(pulseScale)
                    .clip(CircleShape)
                    .background(LagCheckColors.AccentPrimary.copy(alpha = pulseAlpha * 0.35f))
            )
        }

        // Trilho e Arco Circular
        Canvas(modifier = Modifier.size(pulseDiameter)) {
            val strokePx = 9.dp.toPx()
            // Trilho Base
            drawCircle(
                color = LagCheckColors.BorderHairline,
                radius = (size.minDimension - strokePx) / 2f,
                style = Stroke(width = strokePx)
            )

            // Arco Ativo Roxo Gamer
            val sweep = if (isMeasuring) 280f else 240f
            val start = if (isMeasuring) spinAngle else -90f
            drawArc(
                color = LagCheckColors.AccentPrimary,
                startAngle = start,
                sweepAngle = sweep,
                useCenter = false,
                style = Stroke(width = strokePx, cap = StrokeCap.Round)
            )
        }

        // Núcleo Central Dominante de Toque
        val coreSize = pulseDiameter - 44.dp
        Box(
            modifier = Modifier
                .size(coreSize)
                .clip(CircleShape)
                .background(
                    Brush.radialGradient(
                        colors = listOf(
                            LagCheckColors.AccentPrimary.copy(alpha = 0.22f),
                            LagCheckColors.Panel.copy(alpha = 0.95f)
                        )
                    )
                )
                .clickable { onStartCheck() },
            contentAlignment = Alignment.Center
        ) {
            if (isMeasuring) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(32.dp),
                        color = LagCheckColors.AccentPrimary,
                        strokeWidth = 3.dp
                    )
                    Spacer(modifier = Modifier.height(LagCheckSpacing.space1_5))
                    Text(
                        text = measuringText,
                        style = LagCheckTypography.MonoSmall,
                        fontWeight = FontWeight.Bold,
                        color = LagCheckColors.TextPrimary
                    )
                }
            } else {
                Text(
                    text = testButtonText,
                    style = LagCheckTypography.PageTitle.copy(
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Black,
                        letterSpacing = 1.5.sp
                    ),
                    color = Color.White
                )
            }
        }
    }
}
