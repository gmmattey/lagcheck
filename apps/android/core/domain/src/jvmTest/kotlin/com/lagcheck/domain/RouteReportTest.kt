package com.lagcheck.domain

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.LocalizedRecommendation
import com.lagcheck.domain.model.NetworkFinding
import com.lagcheck.domain.presentation.ReadinessLanguage
import com.lagcheck.domain.presentation.RouteReport
import org.junit.Test

class RouteReportTest {
    private fun eval(ping: Double? = 31.4, loss: Double? = 0.0, region: String = "São Paulo") = GameReadinessEvaluation(
        verdict = GameReadinessVerdict.READY, headline = "Pronto para Ranked", subtitle = "Rota estável",
        pingMs = ping, jitterMs = 4.2, packetLossPercentage = loss, worstSpikeMs = null, isUnderLoadAffected = false,
        findings = listOf(NetworkFinding(NetworkFinding.Kind.STABLE_ROUTE, NetworkFinding.Severity.POSITIVE, "Rota estável", "sem picos")),
        regionLabel = region,
        recommendations = listOf(LocalizedRecommendation("Cabo", "Use cabo de rede", "dica"))
    )

    @Test fun unmeasuredFieldsAreDashesNeverDefaults() {
        val r = RouteReport.build(eval(ping = null, loss = null), "Fortnite", "03/10/2026")
        val t = r.telemetry.toMap()
        assertThat(t["Latência P50"]).isEqualTo("—")
        assertThat(t["Perda de Pacotes"]).isEqualTo("—")
        assertThat(t["Pior spike"]).isEqualTo("—")
        assertThat(t["Oscilação (Jitter)"]).isEqualTo("4 ms")
    }

    @Test fun carriesOnlyWhatWasObserved() {
        val r = RouteReport.build(eval(), "Fortnite", "03/10/2026")
        assertThat(r.verdictSymbol).isEqualTo("●")
        assertThat(r.telemetry.toMap()["Latência P50"]).isEqualTo("31 ms")
        assertThat(r.findings).containsExactly("Rota estável" to "sem picos")
        assertThat(r.actions).containsExactly("Cabo" to "Use cabo de rede")
        assertThat(r.summary.toMap()["Região"]).isEqualTo("São Paulo")
    }

    @Test fun blankRegionIsOmittedAndFooterNeverPromisesGamePing() {
        val r = RouteReport.build(eval(region = ""), "Fortnite", "x")
        assertThat(r.summary.map { it.first }).doesNotContain("Região")
        assertThat(r.footer).contains("Não é o ping real do jogo")
    }

    @Test fun translatesLabels() {
        val en = RouteReport.build(eval(), "Fortnite", "x", ReadinessLanguage.EN)
        assertThat(en.title).isEqualTo("LAGCHECK · ROUTE REPORT")
        assertThat(en.telemetryTitle).isEqualTo("TELEMETRY")
        assertThat(en.footer).contains("Not the game's real ping")
        val es = RouteReport.build(eval(), "Fortnite", "x", ReadinessLanguage.ES)
        assertThat(es.actionsTitle).isEqualTo("QUÉ HACER")
        assertThat(en.findingsTitle).isEqualTo("WHAT WE FOUND")
    }
}
