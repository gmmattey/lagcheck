package com.lagcheck.engine

import com.lagcheck.domain.rules.StabilitySummaryEvaluator
import com.lagcheck.domain.rules.StabilitySummaryEvaluator.EntryInput
import com.lagcheck.domain.rules.StabilitySummaryEvaluator.MetricTone
import com.lagcheck.domain.rules.StabilitySummaryEvaluator.Request
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.double
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class StabilitySummaryEvaluatorTest {
    private val dayMs = 86_400_000L
    private val now = 1_760_000_000_000L

    private fun entry(
        daysAgo: Int,
        pingMs: Double? = 20.0,
        jitterMs: Double? = 3.0,
        lossPct: Double? = 0.0,
        loadDeltaMs: Double? = 6.0,
        verdict: String = "READY",
        validResponseCount: Int? = 60,
        gameId: String? = "fortnite",
        gameTitle: String? = "Fortnite",
        platform: String? = "MOBILE",
        externalLink: String? = null,
        network: String? = "WIFI",
        region: String? = "sa-east-1",
        ruleVersion: String? = "readiness-v3.0"
    ) = EntryInput(
        capturedAtEpochMs = now - daysAgo * dayMs,
        pingMs = pingMs,
        jitterMs = jitterMs,
        packetLossPercentage = lossPct,
        loadDeltaMs = loadDeltaMs,
        verdict = verdict,
        validResponseCount = validResponseCount,
        gameId = gameId,
        gameTitle = gameTitle,
        platform = platform,
        declaredExternalLink = externalLink,
        networkType = network,
        regionId = region,
        ruleVersion = ruleVersion
    )

    @Test
    fun zeroOneAndTwoChecksNeverDrawCurveOrComputeRings() {
        val empty = StabilitySummaryEvaluator.evaluate(Request(entries = emptyList(), nowEpochMs = now))
        assertFalse(empty.canDrawCurve)
        assertFalse(empty.hasSummary)
        assertNull(empty.rings)
        assertNull(empty.latest)
        assertEquals("stability.headline.empty", empty.headlineKey)

        val one = StabilitySummaryEvaluator.evaluate(Request(entries = listOf(entry(daysAgo = 1)), nowEpochMs = now))
        assertFalse(one.canDrawCurve)
        assertFalse(one.hasSummary)
        assertNull(one.rings)
        assertEquals(1, one.points.size)
        assertFalse(one.points[0].connectToPrevious)
        assertNotNull(one.latest)
        assertEquals("stability.headline.insufficient", one.headlineKey)

        val two = StabilitySummaryEvaluator.evaluate(
            Request(entries = listOf(entry(daysAgo = 2, pingMs = 18.0), entry(daysAgo = 1, pingMs = 22.0)), nowEpochMs = now)
        )
        assertFalse(two.canDrawCurve)
        assertFalse(two.hasSummary)
        assertNull(two.rings)
        assertEquals(2, two.points.size)
        assertTrue(two.points.none { it.connectToPrevious })
    }

    @Test
    fun threeOrMoreComparableChecksEnableCurveAndFourRings() {
        val res = StabilitySummaryEvaluator.evaluate(
            Request(
                entries = listOf(
                    entry(daysAgo = 5, pingMs = 20.0, jitterMs = 2.0, lossPct = 0.0, loadDeltaMs = 5.0, verdict = "READY"),
                    entry(daysAgo = 3, pingMs = 25.0, jitterMs = 4.0, lossPct = 0.0, loadDeltaMs = 10.0, verdict = "READY"),
                    entry(daysAgo = 1, pingMs = 45.0, jitterMs = 6.0, lossPct = 1.0, loadDeltaMs = 15.0, verdict = "CAUTION")
                ),
                windowDays = 14,
                nowEpochMs = now,
                gameIdFilter = "fortnite"
            )
        )
        assertTrue(res.canDrawCurve)
        assertTrue(res.hasSummary)
        assertEquals(3, res.totalComparableCount)
        assertEquals(2, res.readyCount)
        assertEquals(1, res.cautionCount)
        assertEquals(0, res.badCount)
        assertEquals(67, res.stabilityPercentage)
        assertEquals(MetricTone.WARN, res.stabilityTone)
        assertEquals("stability.headline.moderate", res.headlineKey)
        assertEquals(20.0, res.minPingMs)
        assertEquals(30.0, res.avgPingMs)
        assertEquals(45.0, res.maxPingMs)

        assertFalse(res.points[0].connectToPrevious)
        assertTrue(res.points[1].connectToPrevious)
        assertTrue(res.points[2].connectToPrevious)

        val rings = assertNotNull(res.rings)
        assertEquals(30.0, rings.ping.value)
        assertEquals(MetricTone.OK, rings.ping.tone)
        assertEquals(4.0, rings.jitter.value)
        assertEquals(MetricTone.OK, rings.jitter.tone)
        assertEquals(1.0 / 3.0, rings.loss.value!!, 0.001)
        assertEquals(MetricTone.OK, rings.loss.tone)
        assertEquals(10.0, rings.load.value)
        assertEquals(MetricTone.OK, rings.load.tone)
    }

    @Test
    fun windowCutoffFiltersOutOlderEntries() {
        val res = StabilitySummaryEvaluator.evaluate(
            Request(
                entries = listOf(
                    entry(daysAgo = 20, pingMs = 15.0),
                    entry(daysAgo = 10, pingMs = 20.0),
                    entry(daysAgo = 5, pingMs = 22.0),
                    entry(daysAgo = 1, pingMs = 24.0)
                ),
                windowDays = 7,
                nowEpochMs = now,
                gameIdFilter = "fortnite"
            )
        )
        assertEquals(2, res.totalComparableCount)
        assertFalse(res.canDrawCurve)
        assertFalse(res.hasSummary)
    }

    @Test
    fun overviewNeverConnectsPointsAcrossDifferentNetworksOrRegions() {
        val entries = listOf(
            entry(daysAgo = 6, pingMs = 14.0, network = "WIFI", region = "sa-east-1", gameId = "fortnite"),
            entry(daysAgo = 5, pingMs = 15.0, network = "WIFI", region = "sa-east-1", gameId = "valorant"),
            entry(daysAgo = 4, pingMs = 16.0, network = "WIFI", region = "sa-east-1", gameId = null),
            entry(daysAgo = 3, pingMs = 48.0, network = "CELLULAR", region = "sa-east-1", gameId = "fortnite"),
            entry(daysAgo = 2, pingMs = 52.0, network = "CELLULAR", region = "sa-east-1", gameId = "fortnite"),
            entry(daysAgo = 1, pingMs = 95.0, network = "CELLULAR", region = "us-east-1", gameId = "fortnite")
        )
        val overview = StabilitySummaryEvaluator.evaluate(
            Request(entries = entries, windowDays = 14, nowEpochMs = now, gameIdFilter = null)
        )
        assertTrue(overview.hasMixedContexts)
        assertEquals(listOf("WIFI", "CELLULAR"), overview.availableNetworks)
        assertEquals(6, overview.points.size)
        // Segmento 0 (3x WIFI sa-east-1): 1 e 2 conectam ao anterior.
        assertFalse(overview.points[0].connectToPrevious)
        assertTrue(overview.points[1].connectToPrevious)
        assertTrue(overview.points[2].connectToPrevious)
        // Mudança para CELLULAR sa-east-1 (2 pontos < 3): não conecta e não forma curva.
        assertFalse(overview.points[3].connectToPrevious)
        assertFalse(overview.points[4].connectToPrevious)
        // Mudança de região para us-east-1 (1 ponto): não conecta.
        assertFalse(overview.points[5].connectToPrevious)
        assertTrue(overview.canDrawCurve)
        // Anéis ancorados no contexto mais recente (CELLULAR us-east-1 só tem 1 check -> não inventa média).
        assertFalse(overview.hasSummary)
        assertNull(overview.rings)

        // Filtrando explicitamente para WIFI, retorna apenas os 3 de WIFI com resumo completo.
        val wifiOnly = StabilitySummaryEvaluator.evaluate(
            Request(entries = entries, windowDays = 14, nowEpochMs = now, gameIdFilter = null, networkFilter = "WIFI")
        )
        assertFalse(wifiOnly.hasMixedContexts)
        assertTrue(wifiOnly.hasSummary)
        assertEquals(3, wifiOnly.totalComparableCount)
        assertEquals(15.0, wifiOnly.avgPingMs)
    }

    @Test
    fun perGameExcludesOtherNetworksAndIsolatesInconclusives() {
        val res = StabilitySummaryEvaluator.evaluate(
            Request(
                entries = listOf(
                    entry(daysAgo = 5, pingMs = 45.0, network = "CELLULAR"),
                    entry(daysAgo = 4, pingMs = 15.0, network = "WIFI", verdict = "READY"),
                    entry(daysAgo = 3, pingMs = 16.0, network = "WIFI", verdict = "READY"),
                    entry(daysAgo = 2, pingMs = 999.0, network = "WIFI", verdict = "INCONCLUSIVE", validResponseCount = 5),
                    entry(daysAgo = 1, pingMs = 17.0, network = "WIFI", verdict = "READY"),
                    entry(daysAgo = 0, pingMs = 18.0, network = "WIFI", verdict = "READY", validResponseCount = 6) // < 10 -> inconclusivo
                ),
                windowDays = 14,
                nowEpochMs = now,
                gameIdFilter = "fortnite"
            )
        )
        assertEquals(3, res.totalComparableCount)
        assertEquals(2, res.inconclusiveCount)
        assertEquals(16.0, res.avgPingMs)
        assertEquals(17.0, res.maxPingMs)
        assertEquals(100, res.stabilityPercentage)
        assertEquals(MetricTone.OK, res.stabilityTone)
    }

    @Test
    fun missingLoadDeltaYieldsUnknownLoadRingInsteadOfZero() {
        val res = StabilitySummaryEvaluator.evaluate(
            Request(
                entries = listOf(
                    entry(daysAgo = 3, pingMs = 20.0, loadDeltaMs = null),
                    entry(daysAgo = 2, pingMs = 22.0, loadDeltaMs = null),
                    entry(daysAgo = 1, pingMs = 24.0, loadDeltaMs = null)
                ),
                windowDays = 14,
                nowEpochMs = now,
                gameIdFilter = "fortnite"
            )
        )
        val rings = assertNotNull(res.rings)
        assertNull(rings.load.value)
        assertEquals(MetricTone.UNKNOWN, rings.load.tone)
        assertEquals(0.0, rings.load.fillRatio)
    }

    @Test
    fun jsonFacadeSerializesStabilitySummaryAndHandlesInvalidInput() {
        val jsonReq = """
            {
              "windowDays": 14,
              "nowEpochMs": $now,
              "gameIdFilter": "valorant",
              "entries": [
                {"capturedAtEpochMs": ${now - 3 * dayMs}, "pingMs": 12.0, "jitterMs": 1.5, "packetLossPercentage": 0.0, "loadDeltaMs": 4.0, "verdict": "READY", "validResponseCount": 60, "gameId": "valorant", "networkType": "WIFI", "regionId": "sa-east-1"},
                {"capturedAtEpochMs": ${now - 2 * dayMs}, "pingMs": 14.0, "jitterMs": 2.0, "packetLossPercentage": 0.0, "loadDeltaMs": 5.0, "verdict": "READY", "validResponseCount": 60, "gameId": "valorant", "networkType": "WIFI", "regionId": "sa-east-1"},
                {"capturedAtEpochMs": ${now - 1 * dayMs}, "pingMs": 16.0, "jitterMs": 2.5, "packetLossPercentage": 0.0, "loadDeltaMs": 6.0, "verdict": "READY", "validResponseCount": 60, "gameId": "valorant", "networkType": "WIFI", "regionId": "sa-east-1"}
              ]
            }
        """.trimIndent()
        val parsed = Json.parseToJsonElement(LagCheckEngine.stabilitySummary(jsonReq)).jsonObject
        assertEquals(StabilitySummaryEvaluator.VERSION, parsed["ruleVersion"]!!.jsonPrimitive.content)
        assertTrue(parsed["canDrawCurve"]!!.jsonPrimitive.boolean)
        assertTrue(parsed["hasSummary"]!!.jsonPrimitive.boolean)
        assertEquals(3, parsed["points"]!!.jsonArray.size)
        assertEquals(14.0, parsed["rings"]!!.jsonObject["ping"]!!.jsonObject["value"]!!.jsonPrimitive.double)
        assertEquals(100, parsed["stabilityPercentage"]!!.jsonPrimitive.int)

        val err = LagCheckEngine.stabilitySummary("{bad-json")
        assertTrue(err.contains("\"error\""), err)
    }

    @Test
    fun ringTonesAlignWithCompetitiveReadinessThresholds() {
        val entries = listOf(
            entry(daysAgo = 4, pingMs = 20.0, jitterMs = 8.0, lossPct = 0.0, loadDeltaMs = -1.0, verdict = "READY"),
            entry(daysAgo = 3, pingMs = 20.0, jitterMs = 9.5, lossPct = 0.0, loadDeltaMs = -1.0, verdict = "READY"),
            entry(daysAgo = 2, pingMs = 26.0, jitterMs = 7.0, lossPct = 1.7, loadDeltaMs = -1.0, verdict = "READY"),
            entry(daysAgo = 1, pingMs = 24.0, jitterMs = 9.1, lossPct = 0.0, loadDeltaMs = -1.4, verdict = "READY")
        )
        val res = StabilitySummaryEvaluator.evaluate(Request(entries = entries, windowDays = 14, nowEpochMs = now))
        val rings = assertNotNull(res.rings)
        assertEquals(MetricTone.OK, res.stabilityTone)
        assertEquals(MetricTone.OK, rings.jitter.tone)
        assertEquals(8.4, rings.jitter.value!!, 0.01)
        assertEquals(MetricTone.OK, rings.loss.tone)
        assertEquals(0.425, rings.loss.value!!, 0.001)

        val moderate = StabilitySummaryEvaluator.evaluate(
            Request(
                entries = listOf(
                    entry(daysAgo = 3, pingMs = 25.0, jitterMs = 15.0, lossPct = 1.5, verdict = "CAUTION"),
                    entry(daysAgo = 2, pingMs = 26.0, jitterMs = 15.0, lossPct = 1.5, verdict = "CAUTION"),
                    entry(daysAgo = 1, pingMs = 27.0, jitterMs = 15.0, lossPct = 1.5, verdict = "CAUTION")
                ),
                windowDays = 14,
                nowEpochMs = now
            )
        ).rings!!
        assertEquals(MetricTone.WARN, moderate.jitter.tone)
        assertEquals(MetricTone.WARN, moderate.loss.tone)
    }

    @Test
    fun allCautionChecksUseNeverReadyHeadlineInWarnToneWithoutBlamingJitter() {
        val entries = listOf(
            entry(daysAgo = 4, pingMs = 23.0, jitterMs = 8.9, lossPct = 0.0, loadDeltaMs = 0.0, verdict = "CAUTION"),
            entry(daysAgo = 3, pingMs = 22.0, jitterMs = 8.9, lossPct = 0.0, loadDeltaMs = 0.0, verdict = "CAUTION"),
            entry(daysAgo = 2, pingMs = 20.0, jitterMs = 8.9, lossPct = 0.0, loadDeltaMs = 0.0, verdict = "CAUTION"),
            entry(daysAgo = 1, pingMs = 23.0, jitterMs = 8.9, lossPct = 0.0, loadDeltaMs = 0.0, verdict = "CAUTION")
        )
        val res = StabilitySummaryEvaluator.evaluate(Request(entries = entries, windowDays = 14, nowEpochMs = now))

        assertEquals("stability-summary-v2", res.ruleVersion)
        assertEquals(4, res.totalComparableCount)
        assertEquals(0, res.readyCount)
        assertEquals(4, res.cautionCount)
        assertEquals(0, res.badCount)
        assertEquals(0, res.stabilityPercentage)
        assertEquals(MetricTone.WARN, res.stabilityTone)
        assertEquals("stability.headline.never_ready", res.headlineKey)

        val rings = assertNotNull(res.rings)
        assertEquals(MetricTone.OK, rings.ping.tone)
        assertEquals(MetricTone.OK, rings.jitter.tone)
        assertEquals(MetricTone.OK, rings.loss.tone)
        assertEquals(MetricTone.OK, rings.load.tone)
    }
}
