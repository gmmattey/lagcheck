package com.lagcheck.android.ui.check

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.ui.tr
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography

/** Estado alcançável quando a rede observada não é Wi-Fi nem celular; nenhuma coleta é iniciada. */
@Composable
fun ConnectionRequiredScreen(gameName: String, onBack: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().background(LagCheckColors.Background).padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().height(52.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier.defaultMinSize(minWidth = 48.dp, minHeight = 48.dp).clickable(onClick = onBack),
                contentAlignment = Alignment.CenterStart
            ) {
                Text(tr("Cancelar"), fontSize = 14.sp, color = LagCheckColors.TextSecondary)
            }
            Text(gameName, style = LagCheckTypography.MonoData, color = LagCheckColors.TextTertiary)
        }

        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Canvas(modifier = Modifier.size(64.dp)) {
                val u = size.width / 64f
                val color = LagCheckColors.TextSecondary
                val stroke = 3.dp.toPx()
                drawArc(color, 205f, 130f, false, Offset(4f * u, 8f * u), Size(56f * u, 56f * u), style = Stroke(stroke, cap = StrokeCap.Round))
                drawArc(color, 205f, 130f, false, Offset(16f * u, 20f * u), Size(32f * u, 32f * u), style = Stroke(stroke, cap = StrokeCap.Round))
                drawCircle(color, radius = 3f * u, center = Offset(32f * u, 47f * u))
                drawLine(color, Offset(10f * u, 8f * u), Offset(55f * u, 58f * u), stroke, cap = StrokeCap.Round)
            }
            Text(
                text = tr("Não foi possível iniciar o teste"),
                style = LagCheckTypography.SectionHeader,
                color = LagCheckColors.TextPrimary,
                textAlign = TextAlign.Center
            )
            Text(
                text = tr("Conecte-se a uma rede e tente novamente."),
                style = LagCheckTypography.BodyMedium,
                color = LagCheckColors.TextSecondary,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(8.dp))
            Box(
                modifier = Modifier.defaultMinSize(minHeight = 48.dp)
                    .border(1.dp, LagCheckColors.BorderStrong, RoundedCornerShape(13.dp))
                    .clickable(onClick = onBack).padding(horizontal = 24.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(tr("Voltar"), style = LagCheckTypography.BodySemibold, color = LagCheckColors.TextPrimary)
            }
        }

        Spacer(modifier = Modifier.height(52.dp))
    }
}
