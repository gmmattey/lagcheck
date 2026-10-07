package com.lagcheck.domain.rules

import com.lagcheck.domain.model.CulpritEntity
import com.lagcheck.domain.model.GatewayProbeOutcome
import com.lagcheck.domain.model.QualityMetrics
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Date

class RootCauseEvaluatorTest {

    private fun sampleMetrics(
        p50: Double = 15.0,
        jitter: Double = 1.0,
        loss: Double = 0.0,
        severeSpikes: Int = 0
    ) = QualityMetrics(
        validResponseCount = 30,
        timeoutCount = 0,
        invalidResponseCount = 0,
        p50Milliseconds = p50,
        p95Milliseconds = p50 + 5.0,
        p99Milliseconds = p50 + 10.0,
        jitterMilliseconds = jitter,
        packetLossPercentage = loss,
        spikeCount = severeSpikes,
        severeSpikeCount = severeSpikes,
        spikeRatePercentage = 0.0,
        p95ToP50Ratio = 1.2
    )

    @Test
    fun testLocalWiFiCulpritWhenGatewayRTTIsElevated() {
        val report = RootCauseEvaluator.evaluate(
            gatewayOutcome = GatewayProbeOutcome.Degraded(rttMilliseconds = 25.0, lossPercentage = 0.0),
            wanMetrics = sampleMetrics(),
            platformDegraded = false
        )

        assertEquals(CulpritEntity.LOCAL_WIFI, report.primaryCulprit)
        assertTrue(report.localGatewayObservable)
        assertEquals(25.0, report.localGatewayRTTMs ?: 0.0, 0.001)
    }

    @Test
    fun testInternetProviderCulpritWhenGatewayIsCleanButWanUnstable() {
        val report = RootCauseEvaluator.evaluate(
            gatewayOutcome = GatewayProbeOutcome.Stable(rttMilliseconds = 2.0),
            wanMetrics = sampleMetrics(p50 = 35.0, jitter = 25.0),
            platformDegraded = false
        )

        assertEquals(CulpritEntity.INTERNET_PROVIDER, report.primaryCulprit)
        assertEquals(2.0, report.localGatewayRTTMs ?: 0.0, 0.001)
    }

    @Test
    fun testGamePlatformCulpritWhenPlatformDegraded() {
        val report = RootCauseEvaluator.evaluate(
            gatewayOutcome = GatewayProbeOutcome.Stable(rttMilliseconds = 2.0),
            wanMetrics = sampleMetrics(),
            platformDegraded = true,
            platformServiceName = "PlayStation Network"
        )

        assertEquals(CulpritEntity.GAME_PLATFORM, report.primaryCulprit)
        assertEquals("PlayStation Network", report.platformServiceName)
    }

    @Test
    fun testAllClearWhenEverythingOptimal() {
        val report = RootCauseEvaluator.evaluate(
            gatewayOutcome = GatewayProbeOutcome.Stable(rttMilliseconds = 1.5),
            wanMetrics = sampleMetrics(p50 = 12.0, jitter = 1.0, loss = 0.0),
            platformDegraded = false
        )

        assertEquals(CulpritEntity.ALL_CLEAR, report.primaryCulprit)
    }

    @Test
    fun testNeverBlamesWiFiWhenGatewayUnobservable() {
        val report = RootCauseEvaluator.evaluate(
            gatewayOutcome = GatewayProbeOutcome.Unobservable,
            wanMetrics = sampleMetrics(p50 = 40.0, jitter = 20.0, loss = 2.0),
            platformDegraded = false
        )

        assertEquals(CulpritEntity.INTERNET_PROVIDER, report.primaryCulprit)
        assertFalse(report.localGatewayObservable)
    }

    @Test
    fun testUnobservableWhenGatewayUnobservableAndWanIsClean() {
        val report = RootCauseEvaluator.evaluate(
            gatewayOutcome = GatewayProbeOutcome.Unobservable,
            wanMetrics = sampleMetrics(p50 = 14.0, jitter = 2.0, loss = 0.0),
            platformDegraded = false
        )

        assertEquals(CulpritEntity.UNOBSERVABLE, report.primaryCulprit)
        assertFalse(report.localGatewayObservable)
    }

    @Test
    fun testUnobservableWhenGatewayInIntermediateRangeAndWanUnstable() {
        val report = RootCauseEvaluator.evaluate(
            gatewayOutcome = GatewayProbeOutcome.Stable(rttMilliseconds = 10.0),
            wanMetrics = sampleMetrics(p50 = 40.0, jitter = 18.0, loss = 3.0),
            platformDegraded = false
        )

        assertEquals(CulpritEntity.UNOBSERVABLE, report.primaryCulprit)
        assertTrue(report.localGatewayObservable)
        assertEquals(10.0, report.localGatewayRTTMs ?: 0.0, 0.001)
    }
}

