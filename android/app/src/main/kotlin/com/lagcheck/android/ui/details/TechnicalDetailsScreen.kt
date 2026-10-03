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
import androidx.compose.foundation.layout.width
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
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.NetworkFinding
import com.lagcheck.domain.model.RadioTelemetrySnapshot

/**
 * 05 · Detalhes Técnicos.
 * Paridade 1:1 estrita com a tela 05 · Detalhes técnicos do protótipo Open Design.
 */
@Composable
fun TechnicalDetailsScreen(
    game: CatalogGame,
    evaluation: GameReadinessEvaluation,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    val verdictSymbol = when (evaluation.verdict) {
        GameReadinessVerdict.READY -> "●"
        GameReadinessVerdict.CAUTION, GameReadinessVerdict.NOT_READY -> "▲"
        GameReadinessVerdict.INCONCLUSIVE -> "—"
    }

    val verdictColor = when (evaluation.verdict) {
        GameReadinessVerdict.READY -> LagCheckColors.Good
        GameReadinessVerdict.CAUTION, GameReadinessVerdict.NOT_READY -> LagCheckColors.CoralWarning
        GameReadinessVerdict.INCONCLUSIVE -> LagCheckColors.TextMuted
    }

    val verdictName = when (evaluation.verdict) {
        GameReadinessVerdict.READY -> "Pronto para Ranked"
        GameReadinessVerdict.CAUTION -> "Condições Instáveis"
        GameReadinessVerdict.NOT_READY -> "Evitaria Ranked Agora"
        GameReadinessVerdict.INCONCLUSIVE -> "Dados Insuficientes"
    }

    val dateFormatted = java.text.SimpleDateFormat("dd MMM · HH:mm", java.util.Locale.getDefault()).format(java.util.Date(evaluation.timestamp))

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
            .padding(horizontal = 22.dp)
            .verticalScroll(rememberScrollState())
    ) {
        // 1. Header: "Fechar" (esquerda) + "Detalhes" (centro/abaixo)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
                .padding(top = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .clickable { onClose() }
                    .padding(horizontal = 7.dp, vertical = 6.dp)
            ) {
                Text(
                    text = "Fechar",
                    fontSize = 14.sp,
                    color = LagCheckColors.TextMuted
                )
            }

            Text(
                text = "Detalhes",
                style = LagCheckTypography.PageTitle.copy(fontSize = 24.sp),
                color = LagCheckColors.TextPrimary
            )

            Spacer(modifier = Modifier.size(44.dp))
        }

        Spacer(modifier = Modifier.height(16.dp))

        // 2. Card Compacto de Resumo do Veredito
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(13.dp))
                .background(LagCheckColors.Surface)
                .border(1.dp, LagCheckColors.Border, RoundedCornerShape(13.dp))
                .padding(horizontal = 13.dp, vertical = 12.dp)
        ) {
            Column {
                Text(
                    text = "$verdictSymbol $verdictName",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = verdictColor
                )
                Spacer(modifier = Modifier.height(5.dp))
                Text(
                    text = "${game.name} · ${evaluation.platform} · $dateFormatted",
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.TextMuted
                )
            }
        }

        Spacer(modifier = Modifier.height(25.dp))

        // 3. Seção Score (Lagcheck Score 86) + Grid de Métricas (2x2)
        Column {
            Text(
                text = "SCORE",
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted
            )
            Spacer(modifier = Modifier.height(6.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Bottom
            ) {
                Text(
                    text = "Lagcheck Score",
                    fontSize = 13.sp,
                    color = LagCheckColors.TextMuted
                )
                Text(
                    text = "${evaluation.score}",
                    style = LagCheckTypography.ScoreNumber,
                    color = LagCheckColors.TextPrimary
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Grid 2x2: Latência P50, Jitter, Perda, Pior spike
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                MetricBox(
                    label = "Latência P50",
                    value = evaluation.pingMs?.let { "%.0f ms".format(it) } ?: "— ms",
                    modifier = Modifier.weight(1f)
                )
                MetricBox(
                    label = "Jitter",
                    value = evaluation.jitterMs?.let { "%.0f ms".format(it) } ?: "— ms",
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                MetricBox(
                    label = "Perda",
                    value = evaluation.packetLossPercentage?.let { "%.1f%%".format(it) } ?: "— %",
                    modifier = Modifier.weight(1f)
                )
                MetricBox(
                    label = "Pior spike",
                    value = evaluation.worstSpikeMs?.let { "%.0f ms".format(it) } ?: "— ms",
                    modifier = Modifier.weight(1f)
                )
            }
        }

        Spacer(modifier = Modifier.height(25.dp))

        // 4. Gráfico de Latência durante o Check (Canvas nativo com Repouso e Sob Carga)
        Column {
            Text(
                text = "LATÊNCIA DURANTE O CHECK",
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted
            )
            Spacer(modifier = Modifier.height(11.dp))

            LatencyChart(
                series = evaluation.latencySeries,
                worstSpike = evaluation.worstSpikeMs,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp)
            )

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 7.dp, bottom = 10.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(text = "Repouso", style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextMuted)
                Text(text = "Sob carga", style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextMuted)
            }
        }

        Spacer(modifier = Modifier.height(25.dp))

        // 5. Origem da Evidência (Enlace local vs Rota externa)
        Column {
            Text(
                text = "ORIGEM DA EVIDÊNCIA",
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted
            )
            Spacer(modifier = Modifier.height(11.dp))

            val wifi = evaluation.radioTelemetry?.wifiDetails
            val localStatus = if (wifi != null) {
                if (wifi.isSignalCritical) "Atenção" else "Estável"
            } else "Não observável"

            val localStatusColor = when (localStatus) {
                "Estável" -> LagCheckColors.Good
                "Atenção" -> LagCheckColors.CoralWarning
                else -> LagCheckColors.TextMuted
            }

            val localDetail = if (wifi != null) {
                val band = if (wifi.band == RadioTelemetrySnapshot.WifiBand.BAND_2_4_GHZ) "Wi-Fi 2.4 GHz" else "Wi-Fi 5 GHz"
                "Enlace local $band · ${wifi.rssiDbm} dBm · ${wifi.txLinkSpeedMbps} Mbps."
            } else {
                "Sem medida direta de Wi-Fi ou gateway nesta sessão."
            }

            EvidenceRow(
                title = "Enlace local",
                status = localStatus,
                statusColor = localStatusColor,
                detail = localDetail
            )

            Spacer(modifier = Modifier.height(8.dp))

            EvidenceRow(
                title = "Rota externa",
                status = if (evaluation.isUnderLoadAffected) "Atenção" else "Estável",
                statusColor = if (evaluation.isUnderLoadAffected) LagCheckColors.CoralWarning else LagCheckColors.Good,
                detail = "Rota regional de referência · São Paulo · sob carga."
            )
        }

        Spacer(modifier = Modifier.height(25.dp))

        // 6. O que encontramos (Checklist de Achados)
        Column {
            Text(
                text = "O QUE ENCONTRAMOS",
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted
            )
            Spacer(modifier = Modifier.height(11.dp))

            evaluation.findings.forEach { finding ->
                FindingItem(finding = finding)
            }
        }

        Spacer(modifier = Modifier.height(25.dp))

        // 7. Informações Técnicas Adicionais (Nota técnica)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(13.dp))
                .border(1.dp, LagCheckColors.Border, RoundedCornerShape(13.dp))
                .padding(13.dp)
        ) {
            Column {
                Text(
                    text = "Confiança: ${evaluation.confidence}",
                    style = LagCheckTypography.MonoData,
                    fontWeight = FontWeight.Bold,
                    color = LagCheckColors.TextPrimary
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "27 s de teste · regra de score v1",
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.TextMuted
                )
            }
        }

        Spacer(modifier = Modifier.height(36.dp))
    }
}

@Composable
private fun MetricBox(
    label: String,
    value: String,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(11.dp))
            .background(LagCheckColors.Surface)
            .border(1.dp, LagCheckColors.Border, RoundedCornerShape(11.dp))
            .padding(horizontal = 11.dp, vertical = 10.dp)
    ) {
        Column {
            Text(text = label, style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextMuted)
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = value,
                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace,
                fontWeight = FontWeight.SemiBold,
                fontSize = 13.sp,
                color = LagCheckColors.TextPrimary
            )
        }
    }
}

@Composable
private fun EvidenceRow(
    title: String,
    status: String,
    statusColor: Color,
    detail: String
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(13.dp))
            .background(LagCheckColors.Surface)
            .border(1.dp, LagCheckColors.Border, RoundedCornerShape(13.dp))
            .padding(13.dp)
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(text = title, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.TextPrimary)
                Text(text = status, style = LagCheckTypography.MonoSmall, color = statusColor)
            }
            Spacer(modifier = Modifier.height(6.dp))
            Text(text = detail, style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextMuted)
        }
    }
}

@Composable
private fun FindingItem(finding: NetworkFinding) {
    val dotColor = when (finding.severity) {
        NetworkFinding.Severity.POSITIVE -> LagCheckColors.Good
        NetworkFinding.Severity.WARNING, NetworkFinding.Severity.NEGATIVE -> LagCheckColors.CoralWarning
        NetworkFinding.Severity.NEUTRAL -> LagCheckColors.TextMuted
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .border(width = 0.5.dp, color = LagCheckColors.Border.copy(alpha = 0.5f))
            .padding(vertical = 10.dp),
        verticalAlignment = Alignment.Top
    ) {
        Box(
            modifier = Modifier
                .padding(top = 5.dp)
                .size(7.dp)
                .clip(CircleShape)
                .background(dotColor)
        )
        Spacer(modifier = Modifier.width(9.dp))
        Column {
            Text(text = finding.label, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.TextPrimary)
            finding.detail?.let {
                Spacer(modifier = Modifier.height(3.dp))
                Text(text = it, fontSize = 12.sp, color = LagCheckColors.TextMuted)
            }
        }
    }
}

@Composable
private fun LatencyChart(
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
                text = "Sem amostras suficientes para traçado da rota",
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted
            )
        } else {
            val points = series
            Canvas(modifier = Modifier.fillMaxSize()) {
            val width = size.width
            val height = size.height

            // 1. Metade direita tintada de carga
            drawRect(
                color = Color(0x331E232B),
                topLeft = Offset(width * 0.5f, 0f),
                size = Size(width * 0.5f, height)
            )

            // 2. Linhas de grade sutis
            val gridColor = Color(0xFF262D38)
            drawLine(gridColor, Offset(0f, height * 0.25f), Offset(width, height * 0.25f), strokeWidth = 1f)
            drawLine(gridColor, Offset(0f, height * 0.50f), Offset(width, height * 0.50f), strokeWidth = 1f)
            drawLine(gridColor, Offset(0f, height * 0.75f), Offset(width, height * 0.75f), strokeWidth = 1f)

            // 3. Traçado da Linha de Latência
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

            // Área sob a curva
            drawPath(
                path = fillPath,
                color = Color(0x1A34D399)
            )

            // Linha verde do traçado
            drawPath(
                path = path,
                color = Color(0xFF34D399),
                style = Stroke(width = 2.2f, cap = StrokeCap.Round, join = StrokeJoin.Round)
            )

            // Ponto de spike em Roxo Gamer
            if (spikeX > 0f) {
                drawCircle(
                    color = Color(0xFF7C3AED),
                    radius = 4.5f,
                    center = Offset(spikeX, spikeY)
                )
            }
        }
    }
}
}
