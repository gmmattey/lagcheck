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
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf

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
        GameReadinessVerdict.READY -> tr("Pronto para Ranked")
        GameReadinessVerdict.CAUTION -> tr("Condições Instáveis")
        GameReadinessVerdict.NOT_READY -> tr("Evitaria Ranked Agora")
        GameReadinessVerdict.INCONCLUSIVE -> tr("Dados Insuficientes")
    }

    val dateFormatted = java.text.SimpleDateFormat("dd MMM · HH:mm", java.util.Locale.getDefault()).format(java.util.Date(evaluation.timestamp))

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
            .padding(horizontal = 22.dp)
            .verticalScroll(rememberScrollState())
    ) {
        // 1. Header: "Detalhes Técnicos" (esquerda) + "Fechar" (direita)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = tr("Detalhes Técnicos"),
                style = LagCheckTypography.PageTitle.copy(fontSize = 24.sp),
                color = LagCheckColors.TextPrimary
            )

            Box(
                modifier = Modifier
                    .height(44.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .clickable { onClose() }
                    .padding(horizontal = 7.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = tr("Fechar"),
                    fontSize = 14.sp,
                    color = LagCheckColors.TextMuted
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

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
                    text = "$verdictSymbol ${verdictName.uppercase()}",
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

        Spacer(modifier = Modifier.height(20.dp))

        // 3. Seção Score (Lagcheck Score 86) + Grid de Métricas (2x2)
        Column {
            Text(
                text = tr("SCORE"),
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
                    text = if (evaluation.verdict == GameReadinessVerdict.INCONCLUSIVE) "—" else "${evaluation.score}",
                    style = LagCheckTypography.ScoreNumber,
                    color = LagCheckColors.TextPrimary
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Grid 2x2: P50, Jitter, Perda e P99 quando a fase de repouso foi avaliada.
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                MetricBox(
                    label = tr("Latência P50"),
                    value = (evaluation.metrics?.rest?.p50Milliseconds ?: evaluation.pingMs)
                        ?.let { "%.0f ms".format(java.util.Locale.ROOT, it) } ?: "— ms",
                    modifier = Modifier.weight(1f)
                )
                MetricBox(
                    label = "Jitter",
                    value = evaluation.jitterMs?.let { "%.0f ms".format(java.util.Locale.ROOT, it) } ?: "— ms",
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                MetricBox(
                    label = tr("Perda"),
                    value = evaluation.packetLossPercentage?.let { "%.1f%%".format(java.util.Locale.ROOT, it) } ?: "— %",
                    modifier = Modifier.weight(1f)
                )
                val p99Rest = evaluation.metrics?.rest?.p99Milliseconds
                MetricBox(
                    label = if (p99Rest != null) "P99" else tr("Pior spike"),
                    value = (p99Rest ?: evaluation.worstSpikeMs)
                        ?.let { "%.0f ms".format(java.util.Locale.ROOT, it) } ?: "— ms",
                    modifier = Modifier.weight(1f)
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // 4. Gráfico de Latência durante o Check (Canvas nativo com Repouso e Sob Carga)
        Column {
            Text(
                text = tr("LATÊNCIA DURANTE O CHECK"),
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted
            )
            Spacer(modifier = Modifier.height(11.dp))

            val metrics = evaluation.metrics
            val p50Rest = metrics?.rest?.p50Milliseconds
            val p95Rest = metrics?.rest?.p95Milliseconds
            val p50Load = metrics?.load?.p50Milliseconds
            val p95Load = metrics?.load?.p95Milliseconds
            val p99Load = metrics?.load?.p99Milliseconds
            if (p50Rest != null && p95Rest != null && p50Load != null && p95Load != null && p99Load != null) {
                val hasSpike = metrics.rest.spikeCount > 0 || (metrics.load?.spikeCount ?: 0) > 0

                PercentileChartView(
                    p50Rest = p50Rest,
                    p95Rest = p95Rest,
                    p50Load = p50Load,
                    p95Load = p95Load,
                    p99Load = p99Load,
                    hasSpike = hasSpike,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(118.dp)
                )

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 7.dp, bottom = 10.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(text = tr("Repouso"), style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextMuted)
                    Text(text = tr("Sob carga"), style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextMuted)
                }
            } else {
                LatencyChart(
                    series = evaluation.latencySeries,
                    worstSpike = evaluation.worstSpikeMs,
                    loadStartIndex = evaluation.loadStartIndex,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(118.dp)
                )

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 7.dp, bottom = 10.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(text = tr("Repouso"), style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextMuted)
                    if (evaluation.loadStartIndex != null) {
                        Text(text = tr("Sob carga"), style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextMuted)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // 5. Origem da Evidência (Enlace local vs Rota externa)
        Column {
            Text(
                text = tr("ORIGEM DA EVIDÊNCIA"),
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted
            )
            Spacer(modifier = Modifier.height(11.dp))

            val wifi = evaluation.radioTelemetry?.wifiDetails
            // O status descreve só o que foi lido (sinal), nunca "estabilidade" do enlace: sem probe de gateway isolado
            // não se atribui a causa do lag ao Wi-Fi (Decisão 50).
            val localStatus = if (wifi != null) {
                if (wifi.isSignalCritical) "Sinal fraco" else "Sinal bom"
            } else "Não observável"

            val localStatusColor = when (localStatus) {
                "Sinal bom" -> LagCheckColors.Good
                "Sinal fraco" -> LagCheckColors.CoralWarning
                else -> LagCheckColors.TextMuted
            }

            val localDetail = if (wifi != null) {
                val band = when (wifi.band) {
                    RadioTelemetrySnapshot.WifiBand.BAND_2_4_GHZ -> "Wi-Fi 2.4 GHz"
                    RadioTelemetrySnapshot.WifiBand.BAND_5_GHZ -> "Wi-Fi 5 GHz"
                    RadioTelemetrySnapshot.WifiBand.BAND_6_GHZ -> "Wi-Fi 6 GHz"
                    RadioTelemetrySnapshot.WifiBand.UNKNOWN -> "Wi-Fi"
                }
                val rssi = wifi.rssiDbm.takeIf { it in -126..0 }?.let { " · $it dBm" } ?: ""
                val link = wifi.txLinkSpeedMbps.takeIf { it > 0 }?.let { " · $it Mbps" } ?: ""
                "$band$rssi$link"
            } else {
                tr("Sem medida direta de Wi-Fi ou gateway nesta sessão.")
            }

            EvidenceRow(
                title = tr("Enlace local"),
                status = tr(localStatus),
                statusColor = localStatusColor,
                detail = localDetail
            )

            Spacer(modifier = Modifier.height(8.dp))

            EvidenceRow(
                title = tr("Rota externa"),
                status = if (evaluation.loadStartIndex == null) tr("Carga não medida")
                    else if (evaluation.isUnderLoadAffected) tr("Atenção") else tr("Estável"),
                statusColor = if (evaluation.loadStartIndex == null) LagCheckColors.TextMuted
                    else if (evaluation.isUnderLoadAffected) LagCheckColors.CoralWarning else LagCheckColors.Good,
                detail = trf("Rota regional de referência · %s", evaluation.regionLabel.ifEmpty { "São Paulo" })
            )
        }

        Spacer(modifier = Modifier.height(20.dp))

        // 6. O que encontramos (Checklist de Achados)
        Column {
            Text(
                text = tr("O QUE ENCONTRAMOS"),
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted
            )
            Spacer(modifier = Modifier.height(11.dp))

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(13.dp))
                    .background(LagCheckColors.Surface)
                    .border(1.dp, LagCheckColors.Border, RoundedCornerShape(13.dp))
                    .padding(horizontal = 16.dp)
            ) {
                Column {
                    evaluation.findings.forEachIndexed { index, finding ->
                        FindingItem(finding = finding, isLast = index == evaluation.findings.lastIndex)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

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
                    text = trf("Confiança: %s", evaluation.confidence),
                    style = LagCheckTypography.MonoData,
                    fontWeight = FontWeight.Bold,
                    color = LagCheckColors.TextPrimary
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = trf("Regra %s", com.lagcheck.domain.rules.GameReadinessEvaluator.VERSION),
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.TextMuted
                )
            }
        }

        // Recomendações Android já vinculadas a achados medidos; não descartar conteúdo útil.
        if (evaluation.recommendations.isNotEmpty()) {
            Spacer(modifier = Modifier.height(20.dp))
            Column {
                Text(
                    text = tr("O QUE FAZER"),
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.TextMuted
                )
                Spacer(modifier = Modifier.height(11.dp))
                evaluation.recommendations.forEach { rec ->
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 10.dp)
                            .clip(RoundedCornerShape(13.dp))
                            .border(1.dp, LagCheckColors.Border, RoundedCornerShape(13.dp))
                            .padding(13.dp)
                    ) {
                        Text(text = rec.title, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.TextPrimary)
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(text = rec.instruction, fontSize = 13.sp, color = LagCheckColors.TextMuted)
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(text = rec.badge, style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextSecondary)
                    }
                }
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
private fun FindingItem(finding: NetworkFinding, isLast: Boolean) {
    val dotColor = when (finding.severity) {
        NetworkFinding.Severity.POSITIVE -> LagCheckColors.Good
        NetworkFinding.Severity.WARNING, NetworkFinding.Severity.NEGATIVE -> LagCheckColors.CoralWarning
        NetworkFinding.Severity.NEUTRAL -> LagCheckColors.TextMuted
    }

    Box(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
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

        if (!isLast) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(LagCheckColors.Border)
                    .align(Alignment.BottomCenter)
            )
        }
    }
}

@Composable
private fun LatencyChart(
    series: List<Double>,
    worstSpike: Double?,
    loadStartIndex: Int?,
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
                text = tr("Sem amostras suficientes para traçado da rota"),
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted
            )
        } else {
            val points = series
            Canvas(modifier = Modifier.fillMaxSize()) {
            val width = size.width
            val height = size.height

            // 1. Trecho sob carga tintado: começa onde a carga de fato começou (e só existe se foi medida)
            if (loadStartIndex != null && loadStartIndex in 1 until points.size) {
                val startX = width * loadStartIndex / (points.size - 1).coerceAtLeast(1)
                drawRect(
                    color = Color(0x331E232B),
                    topLeft = Offset(startX, 0f),
                    size = Size(width - startX, height)
                )
            }

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

            // Ponto de spike com cor de Warning
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

@Composable
private fun PercentileChartView(
    p50Rest: Double,
    p95Rest: Double,
    p50Load: Double,
    p95Load: Double,
    p99Load: Double,
    hasSpike: Boolean,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(8.dp))
            .border(1.dp, LagCheckColors.Border, RoundedCornerShape(8.dp)),
        contentAlignment = Alignment.Center
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val w = size.width
            val h = size.height
            val maxVal = maxOf(100.0, maxOf(p99Load, p95Rest) * 1.25)

            val yRestP50 = h * (1.0f - (p50Rest / maxVal).toFloat().coerceIn(0.05f, 1.0f))
            val yRestP95 = h * (1.0f - (p95Rest / maxVal).toFloat().coerceIn(0.05f, 1.0f))
            val yLoadP50 = h * (1.0f - (p50Load / maxVal).toFloat().coerceIn(0.05f, 1.0f))
            val yLoadP95 = h * (1.0f - (p95Load / maxVal).toFloat().coerceIn(0.05f, 1.0f))
            val yLoadP99 = h * (1.0f - (p99Load / maxVal).toFloat().coerceIn(0.05f, 1.0f))

            // Metade sob carga mais escura
            drawRect(
                color = Color(0x331E232B),
                topLeft = Offset(w * 0.5f, 0f),
                size = Size(w * 0.5f, h)
            )

            // Linhas de grade
            val gridColor = Color(0xFF262D38)
            drawLine(gridColor, Offset(0f, h * 0.25f), Offset(w, h * 0.25f), strokeWidth = 1f)
            drawLine(gridColor, Offset(0f, h * 0.50f), Offset(w, h * 0.50f), strokeWidth = 1f)
            drawLine(gridColor, Offset(0f, h * 0.75f), Offset(w, h * 0.75f), strokeWidth = 1f)

            // Curva de percentis calculada
            val path = Path()
            path.moveTo(0f, yRestP50)
            path.lineTo(w * 0.25f, yRestP50)
            path.lineTo(w * 0.45f, yRestP95)
            path.lineTo(w * 0.55f, yLoadP50)
            path.lineTo(w * 0.75f, yLoadP99)
            path.lineTo(w * 0.88f, yLoadP95)
            path.lineTo(w, yLoadP50)

            drawPath(
                path = path,
                color = Color(0xFF34D399),
                style = Stroke(width = 2.2f, cap = StrokeCap.Round, join = StrokeJoin.Round)
            )

            // Spike dot real
            if (hasSpike) {
                drawCircle(
                    color = LagCheckColors.CoralWarning,
                    radius = 4.5f,
                    center = Offset(w * 0.75f, yLoadP99)
                )
            }
        }
    }
}
