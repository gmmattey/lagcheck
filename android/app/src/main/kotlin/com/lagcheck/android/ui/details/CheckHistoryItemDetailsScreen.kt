package com.lagcheck.android.ui.details

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.core.designsystem.components.ChevronLeftIcon
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.android.data.CheckHistoryItem
import com.lagcheck.android.ui.tr

@Composable
fun CheckHistoryItemDetailsScreen(
    item: CheckHistoryItem,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    val dateFormatted = java.text.SimpleDateFormat("dd MMM · HH:mm", java.util.Locale.getDefault()).format(java.util.Date(item.timestamp))

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
            .padding(horizontal = 22.dp)
            .verticalScroll(rememberScrollState())
    ) {
        // Header de volta/título "Detalhes" com alvo 44dp
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp)
                .height(44.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .clickable { onClose() },
                contentAlignment = Alignment.CenterStart
            ) {
                ChevronLeftIcon(
                    size = 20.dp,
                    color = LagCheckColors.TextPrimary
                )
            }

            Text(
                text = tr("Detalhes"),
                style = LagCheckTypography.BodySemibold.copy(fontSize = 17.sp),
                color = LagCheckColors.TextPrimary,
                modifier = Modifier.weight(1f),
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.size(44.dp))
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Contexto disponível de modo compacto
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                text = "${item.gameName} · ${item.platform} · $dateFormatted",
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted
            )
            item.declaredExternalLink?.let { link ->
                val linkLabel = if (link == "ETHERNET") tr("Cabo") else "Wi-Fi"
                Text(
                    text = "$linkLabel (${tr("Informação declarada, nunca medida")})",
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.TextMuted.copy(alpha = 0.7f)
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Gráfico antes das métricas
        HistoryLatencyChart(
            series = item.latencySeries,
            worstSpike = item.worstSpikeMs,
            modifier = Modifier
                .fillMaxWidth()
                .height(118.dp)
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Métricas em lista de linhas em um bloco único
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(22.dp))
                .background(LagCheckColors.Surface)
        ) {
            HistoryDetailRow(
                label = if (item.idleP50 != null) tr("Ping P50 (Repouso)") else tr("Latência P50"),
                value = (item.idleP50 ?: item.pingMs)?.let { "%.0f ms".format(java.util.Locale.ROOT, it) } ?: "— ms",
                isLast = false
            )
            item.idleP95?.let {
                HistoryDetailRow(tr("Ping P95 (Repouso)"), "%.0f ms".format(java.util.Locale.ROOT, it), false)
            }
            item.idleP99?.let {
                HistoryDetailRow(tr("Ping P99 (Repouso)"), "%.0f ms".format(java.util.Locale.ROOT, it), false)
            }
            item.loadP50?.let {
                HistoryDetailRow(tr("Ping P50 (Carga)"), "%.0f ms".format(java.util.Locale.ROOT, it), false)
            }
            item.loadP95?.let {
                HistoryDetailRow(tr("Ping P95 (Carga)"), "%.0f ms".format(java.util.Locale.ROOT, it), false)
            }
            item.loadP99?.let {
                HistoryDetailRow(tr("Ping P99 (Carga)"), "%.0f ms".format(java.util.Locale.ROOT, it), false)
            }
            HistoryDetailRow(
                label = tr("Oscilação (Jitter)"),
                value = item.jitterMs?.let { "%.0f ms".format(java.util.Locale.ROOT, it) } ?: "— ms",
                isLast = false
            )
            HistoryDetailRow(
                label = tr("Perda de Pacotes"),
                value = item.packetLossPercentage?.let { "%.1f%%".format(java.util.Locale.ROOT, it) } ?: "— %",
                isLast = false
            )
            item.idleSpikeCount?.let {
                HistoryDetailRow(
                    label = tr("Spikes (Repouso)"),
                    value = "$it",
                    isLast = false
                )
            }
            val showScore = item.verdict != GameReadinessVerdict.INCONCLUSIVE
            HistoryDetailRow(
                label = tr("Pior spike"),
                value = item.worstSpikeMs?.let { "%.0f ms".format(java.util.Locale.ROOT, it) } ?: "— ms",
                isLast = !showScore
            )
            if (showScore) {
                HistoryDetailRow(
                    label = tr("SCORE"),
                    value = "${item.score}",
                    isLast = true
                )
            }
        }

        Spacer(modifier = Modifier.height(36.dp))
    }
}

@Composable
private fun HistoryDetailRow(
    label: String,
    value: String,
    isLast: Boolean
) {
    Column {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 14.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = label,
                style = LagCheckTypography.BodyMedium.copy(fontSize = 15.sp),
                color = LagCheckColors.TextSecondary
            )
            Text(
                text = value,
                fontFamily = com.lagcheck.core.designsystem.theme.LagCheckTypography.GoogleSans,
                style = androidx.compose.ui.text.TextStyle(fontFeatureSettings = "tnum"),
                fontSize = 15.sp,
                color = LagCheckColors.TextPrimary
            )
        }
        if (!isLast) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(LagCheckColors.Border)
            )
        }
    }
}

@Composable
private fun HistoryLatencyChart(
    series: List<Double>,
    worstSpike: Double?,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(8.dp))
            .border(1.dp, LagCheckColors.Border, RoundedCornerShape(8.dp)),
        contentAlignment = Alignment.Center
    ) {
        if (series.size < 2) {
            Text(
                text = tr("Gráfico indisponível no histórico"),
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted
            )
        } else {
            val points = series
            Canvas(modifier = Modifier.fillMaxSize()) {
                val width = size.width
                val height = size.height

                val gridColor = Color(0xFF262D38)
                drawLine(gridColor, Offset(0f, height * 0.25f), Offset(width, height * 0.25f), strokeWidth = 1f)
                drawLine(gridColor, Offset(0f, height * 0.50f), Offset(width, height * 0.50f), strokeWidth = 1f)
                drawLine(gridColor, Offset(0f, height * 0.75f), Offset(width, height * 0.75f), strokeWidth = 1f)

                val minVal = 15.0
                val maxVal = ((worstSpike ?: 50.0).coerceAtLeast(60.0)) * 1.15
                val range = maxVal - minVal

                val path = Path()
                val fillPath = Path()

                val stepX = width / (points.size - 1).coerceAtLeast(1)

                var spikeX = 0f
                var spikeY = 0f
                var maxP = 0.0

                points.forEachIndexed { index, value ->
                    val x = index * stepX
                    val normalizedY = 1f - ((value - minVal) / range).toFloat().coerceIn(0.05f, 0.95f)
                    val y = normalizedY * height

                    if (index == 0) {
                        path.moveTo(x, y)
                        fillPath.moveTo(x, height)
                        fillPath.lineTo(x, y)
                    } else {
                        path.lineTo(x, y)
                        fillPath.lineTo(x, y)
                    }

                    if (value >= maxP) {
                        maxP = value
                        spikeX = x
                        spikeY = y
                    }
                }

                fillPath.lineTo(width, height)
                fillPath.close()

                drawPath(
                    path = fillPath,
                    color = Color(0x1A34D399)
                )

                drawPath(
                    path = path,
                    color = Color(0xFF34D399),
                    style = Stroke(width = 2.2f, cap = StrokeCap.Round, join = StrokeJoin.Round)
                )

                if (spikeX > 0f) {
                    drawCircle(
                        color = LagCheckColors.CoralWarning,
                        radius = 4.5f,
                        center = Offset(spikeX, spikeY)
                    )
                }
            }
        }
    }
}
