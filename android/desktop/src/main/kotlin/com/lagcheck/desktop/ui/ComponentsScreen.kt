package com.lagcheck.desktop.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.lagcheck.desktop.AppState
import com.lagcheck.desktop.ds.*
import com.lagcheck.domain.model.GameReadinessVerdict

/** Galeria viva do design system (só com `--ds`). Fonte visual de referência para o Windows. */
@Composable
fun ComponentsScreen(state: AppState) {
    var q by remember { mutableStateOf("") }
    Column(Modifier.fillMaxWidth()) {
        PageHeader("Componentes")
        Spacer(Modifier.height(LcSpace.xl))
        Block("Cores") {
            val colors = listOf("Background" to LcColor.Background, "Surface" to LcColor.Surface, "Panel" to LcColor.Panel, "Accent" to LcColor.Accent,
                "Coral" to LcColor.Coral, "Caution" to LcColor.Caution, "Good" to LcColor.Good, "Neutral" to LcColor.Inconclusive)
            colors.chunked(4).forEach { row ->
                Row(horizontalArrangement = Arrangement.spacedBy(LcSpace.sm)) {
                    row.forEach { (n, c) ->
                        Column { Box(Modifier.size(64.dp, 40.dp).background(c, RoundedCornerShape(8.dp)).border(1.dp, LcColor.BorderStrong, RoundedCornerShape(8.dp))); Text(n, style = LcType.Section, color = LcColor.TextSecondary) }
                    }
                }
                Spacer(Modifier.height(LcSpace.sm))
            }
        }
        Block("Tipografia") {
            Text("● PRONTO PARA RANKED", style = LcType.VerdictHero, color = LcColor.Good)
            Text("Título de página", style = LcType.PageTitle, color = LcColor.TextPrimary)
            Text("Corpo de leitura para frases curtas.", style = LcType.Body, color = LcColor.TextSecondary)
            Text("19 ms", style = LcType.DataHero, color = LcColor.TextPrimary)
            SectionLabel("Rótulo técnico")
        }
        Block("Botões") {
            Row(horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) {
                PrimaryButton("TESTAR AGORA", {}); SecondaryButton("VOLTAR", {}); PrimaryButton("DESABILITADO", {}, enabled = false)
            }
        }
        Block("Vereditos") {
            GameReadinessVerdict.values().forEach { v -> Text(v.style().label, style = LcType.BodyStrong, color = v.style().color) }
        }
        Block("Métricas") {
            Row(horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) { MetricTile("Ping", "19 ms", Modifier.weight(1f)); MetricTile("Jitter", "5 ms", Modifier.weight(1f)); MetricTile("Perda", null, Modifier.weight(1f)) }
        }
        Block("Campo de busca") { SearchField(q, { q = it }) }
        Block("Anel e gráfico") {
            Row(horizontalArrangement = Arrangement.spacedBy(LcSpace.xl)) {
                CircularGauge(0.6f, true, Modifier.size(140.dp)) {}
                LatencyChart(listOf(20.0, 22.0, 19.0, 85.0, 24.0, 21.0, 60.0, 30.0, 28.0, 25.0), Modifier.weight(1f).height(140.dp), 6)
            }
        }
    }
}

@Composable
private fun Block(title: String, content: @Composable ColumnScope.() -> Unit) {
    Panel(padding = LcSpace.lg) { SectionLabel(title); Spacer(Modifier.height(LcSpace.md)); content() }
    Spacer(Modifier.height(LcSpace.lg))
}
