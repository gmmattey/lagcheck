package com.lagcheck.core.designsystem.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.core.designsystem.theme.LagCheckRadius
import com.lagcheck.core.designsystem.theme.LagCheckSpacing
import com.lagcheck.domain.model.GameReadinessVerdict

/**
 * Indicador visual tático de veredito de telemetria no padrão Dark Competitive UI (Decisão 73).
 * Substitui os glifos Unicode crus (●, ▲, —) por um componente de hardware/cockpit.
 */
@Composable
fun VerdictIndicatorBadge(
    verdict: GameReadinessVerdict,
    modifier: Modifier = Modifier,
    size: Dp = 16.dp
) {
    when (verdict) {
        GameReadinessVerdict.READY -> {
            // LED de telemetria verde travado com halo concêntrico
            Box(
                contentAlignment = Alignment.Center,
                modifier = modifier.size(size + 8.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(size + 8.dp)
                        .clip(CircleShape)
                        .background(LagCheckColors.Good.copy(alpha = 0.20f))
                )
                Box(
                    modifier = Modifier
                        .size(size + 4.dp)
                        .border(1.5.dp, LagCheckColors.Good.copy(alpha = 0.55f), CircleShape)
                )
                Box(
                    modifier = Modifier
                        .size(size)
                        .clip(CircleShape)
                        .background(LagCheckColors.Good)
                )
            }
        }
        GameReadinessVerdict.CAUTION -> {
            // Micro-tag tática chanfrada / alerta em Âmbar
            Box(
                contentAlignment = Alignment.Center,
                modifier = modifier
                    .size(size + 6.dp)
                    .clip(RoundedCornerShape(LagCheckRadius.xs))
                    .background(LagCheckColors.SemanticCaution.copy(alpha = 0.18f))
                    .border(1.5.dp, LagCheckColors.SemanticCaution, RoundedCornerShape(LagCheckRadius.xs))
            ) {
                Text(
                    text = "!",
                    fontSize = (size.value * 0.75).sp,
                    fontWeight = FontWeight.Black,
                    color = LagCheckColors.SemanticCaution
                )
            }
        }
        GameReadinessVerdict.NOT_READY -> {
            // Micro-tag de corte / corte em Coral Solar
            Box(
                contentAlignment = Alignment.Center,
                modifier = modifier
                    .size(size + 6.dp)
                    .clip(RoundedCornerShape(LagCheckRadius.xs))
                    .background(LagCheckColors.CoralWarning.copy(alpha = 0.20f))
                    .border(1.5.dp, LagCheckColors.CoralWarning, RoundedCornerShape(LagCheckRadius.xs))
            ) {
                Text(
                    text = "×",
                    fontSize = (size.value * 0.85).sp,
                    fontWeight = FontWeight.Black,
                    color = LagCheckColors.CoralWarning
                )
            }
        }
        GameReadinessVerdict.INCONCLUSIVE -> {
            // Radar neutro em Slate com traço técnico
            Box(
                contentAlignment = Alignment.Center,
                modifier = modifier
                    .size(size + 4.dp)
                    .border(1.5.dp, LagCheckColors.Inconclusive, CircleShape)
            ) {
                Box(
                    modifier = Modifier
                        .size(width = size * 0.5f, height = 2.dp)
                        .background(LagCheckColors.Inconclusive)
                )
            }
        }
    }
}

@Composable
fun VerdictHeroBadge(
    headline: String,
    subtitle: String,
    verdict: GameReadinessVerdict,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(LagCheckRadius.xl))
            .background(LagCheckColors.Surface)
            .border(1.dp, LagCheckColors.Border, RoundedCornerShape(LagCheckRadius.xl))
            .padding(LagCheckSpacing.space6)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                VerdictIndicatorBadge(verdict = verdict, size = 14.dp)
                Spacer(modifier = Modifier.size(8.dp))
                Text(
                    text = headline,
                    style = LagCheckTypography.VerdictHeadline,
                    color = LagCheckColors.TextPrimary
                )
            }

            Spacer(modifier = Modifier.height(LagCheckSpacing.space2_5))

            Text(
                text = subtitle,
                style = LagCheckTypography.BodyMedium,
                color = LagCheckColors.TextSecondary
            )
        }
    }
}
