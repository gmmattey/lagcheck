package com.lagcheck.domain.presentation

import com.lagcheck.domain.model.GameReadinessAssessment
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.rules.DeepCheckLoadImpact
import com.lagcheck.domain.rules.DeepCheckMetrics
import com.lagcheck.domain.rules.LoadDegradationTier
import com.lagcheck.domain.model.QualityMetrics
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertNotNull
import org.junit.Test

class ReadinessPresenterTest {

    @Test
    fun `inconclusive result does not claim a stable route`() {
        val assessment = GameReadinessAssessment.INCONCLUSIVE
        val evaluation = ReadinessPresenter.present(
            assessment = assessment,
            platform = "Android",
            connectionType = "Wi-Fi",
            destinationName = "—"
        )
        assertEquals("Amostras UDP insuficientes", evaluation.primaryWeight)
        assertEquals(GameReadinessVerdict.INCONCLUSIVE, evaluation.verdict)
    }

    @Test
    fun `present transports DeepCheckMetrics correctly with load present`() {
        val restMetrics = QualityMetrics(
            validResponseCount = 30, timeoutCount = 0, invalidResponseCount = 0,
            p50Milliseconds = 15.0, p95Milliseconds = 18.0, p99Milliseconds = 20.0,
            jitterMilliseconds = 1.0, packetLossPercentage = 0.0, spikeCount = 0,
            severeSpikeCount = 0, spikeRatePercentage = 0.0, p95ToP50Ratio = 1.2
        )
        val loadMetrics = QualityMetrics(
            validResponseCount = 30, timeoutCount = 0, invalidResponseCount = 0,
            p50Milliseconds = 25.0, p95Milliseconds = 30.0, p99Milliseconds = 35.0,
            jitterMilliseconds = 5.0, packetLossPercentage = 1.0, spikeCount = 1,
            severeSpikeCount = 0, spikeRatePercentage = 3.3, p95ToP50Ratio = 1.2
        )
        val loadImpact = DeepCheckLoadImpact(15.0, 25.0, LoadDegradationTier.LIGHT)
        val metrics = DeepCheckMetrics(restMetrics, loadMetrics, loadImpact)

        val assessment = GameReadinessAssessment(
            verdict = GameReadinessVerdict.READY,
            headlineKey = "test", subtitleKey = "test", score = 90,
            primaryCause = null, pingMs = 15.0, jitterMs = 1.0,
            packetLossPercentage = 0.0, worstSpikeMs = null,
            isUnderLoadAffected = false, findings = emptyList(), recommendations = emptyList(),
            stabilityRatio = 1.0, stabilitySummaryKey = "test"
        )

        val evaluation = ReadinessPresenter.present(
            assessment = assessment,
            platform = "PlayStation",
            connectionType = "Wi-Fi",
            destinationName = "São Paulo",
            metrics = metrics
        )

        assertNotNull(evaluation.metrics)
        assertEquals(15.0, evaluation.metrics?.rest?.p50Milliseconds)
        assertEquals(25.0, evaluation.metrics?.load?.p50Milliseconds)
    }

    @Test
    fun `present transports DeepCheckMetrics correctly with absent load`() {
        val restMetrics = QualityMetrics(
            validResponseCount = 30, timeoutCount = 0, invalidResponseCount = 0,
            p50Milliseconds = 15.0, p95Milliseconds = 18.0, p99Milliseconds = 20.0,
            jitterMilliseconds = 1.0, packetLossPercentage = 0.0, spikeCount = 0,
            severeSpikeCount = 0, spikeRatePercentage = 0.0, p95ToP50Ratio = 1.2
        )
        val metrics = DeepCheckMetrics(restMetrics, null, null)

        val assessment = GameReadinessAssessment(
            verdict = GameReadinessVerdict.READY,
            headlineKey = "test", subtitleKey = "test", score = 90,
            primaryCause = null, pingMs = 15.0, jitterMs = 1.0,
            packetLossPercentage = 0.0, worstSpikeMs = null,
            isUnderLoadAffected = false, findings = emptyList(), recommendations = emptyList(),
            stabilityRatio = 1.0, stabilitySummaryKey = "test"
        )

        val evaluation = ReadinessPresenter.present(
            assessment = assessment,
            platform = "PlayStation",
            connectionType = "Wi-Fi",
            destinationName = "São Paulo",
            metrics = metrics
        )

        assertNotNull(evaluation.metrics)
        assertEquals(15.0, evaluation.metrics?.rest?.p50Milliseconds)
        assertNull(evaluation.metrics?.load)
    }

    @Test
    fun `present transports null metrics when absent`() {
        val assessment = GameReadinessAssessment(
            verdict = GameReadinessVerdict.READY,
            headlineKey = "test", subtitleKey = "test", score = 90,
            primaryCause = null, pingMs = 15.0, jitterMs = 1.0,
            packetLossPercentage = 0.0, worstSpikeMs = null,
            isUnderLoadAffected = false, findings = emptyList(), recommendations = emptyList(),
            stabilityRatio = 1.0, stabilitySummaryKey = "test"
        )

        val evaluation = ReadinessPresenter.present(
            assessment = assessment,
            platform = "PlayStation",
            connectionType = "Wi-Fi",
            destinationName = "São Paulo",
            metrics = null
        )

        assertNull(evaluation.metrics)
    }
}
