package com.lagcheck.domain.rules

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.QualityProfileId
import org.junit.Test

/** Portado de DeepCheckEvaluatorTests.swift (carga v2). */
class DeepCheckEvaluatorTest {
    private val br = QualityProfileId.BATTLE_ROYALE_COMPETITIVE

    private fun deep(rest: List<com.lagcheck.domain.model.ProbeSample>, load: List<com.lagcheck.domain.model.ProbeSample>?, profile: QualityProfileId = br): DeepCheckResult =
        (DeepCheckEvaluator.evaluate(rest, load, profile) as DeepCheckEvaluation.Completed).result

    @Test fun restScoreIsPreservedAndImpactIsP50Delta() {
        val rest = received(30, 30.0)
        val r = deep(rest, received(30, 93.0))
        assertThat(r.restResult).isEqualTo(completed(rest))
        assertThat(r.restResult.finalScore).isEqualTo(100)
        assertThat(r.metrics.load?.p50Milliseconds).isEqualTo(93.0)
        val impact = r.metrics.loadImpact!!
        assertThat(impact.increaseMilliseconds).isEqualTo(63.0)
        assertThat(impact.ruleVersion).isEqualTo("deep-load-impact-v2")
        assertThat(impact.classification).isEqualTo(LoadImpactClassification.MATERIAL)
        assertThat(impact.tier).isEqualTo(LoadDegradationTier.SEVERE)
    }

    @Test fun ruleV2Vectors() {
        val br = QualityProfileId.BATTLE_ROYALE_COMPETITIVE
        fun c(p: Double, j: Double, l: Double, s: Int) = DeepCheckLoadImpactRuleV2.classify(br, p, j, l, s)
        assertThat(c(5.0, 2.0, 0.0, 0)).isEqualTo(LoadDegradationTier.NONE)
        assertThat(c(12.0, 5.0, 0.0, 0)).isEqualTo(LoadDegradationTier.LIGHT)
        assertThat(c(22.0, 6.0, 0.0, 0)).isEqualTo(LoadDegradationTier.MATERIAL)
        assertThat(c(10.0, 10.0, 0.0, 0)).isEqualTo(LoadDegradationTier.MATERIAL)
        assertThat(c(10.0, 2.0, 2.5, 0)).isEqualTo(LoadDegradationTier.MATERIAL)
        assertThat(c(45.0, 25.0, 6.0, 4)).isEqualTo(LoadDegradationTier.SEVERE)
    }

    @Test fun failedLoadKeepsRestWithoutImpact() {
        val r = deep(received(30, 30.0), null)
        assertThat(r.restResult.finalScore).isEqualTo(100)
        assertThat(r.metrics.load).isNull()
        assertThat(r.metrics.loadImpact).isNull()
    }

    @Test fun insufficientLoadResponsesDoNotExposePartialMetrics() {
        val r = deep(received(30, 30.0), received(9, 90.0) + timeouts(21, 9))
        assertThat(r.restResult.finalScore).isEqualTo(100)
        assertThat(r.metrics.load).isNull()
        assertThat(r.metrics.loadImpact).isNull()
    }

    @Test fun insufficientRestMakesEverythingInconclusive() {
        val e = DeepCheckEvaluator.evaluate(received(9, 30.0) + timeouts(21, 9), received(30, 90.0), br)
        e as DeepCheckEvaluation.Inconclusive
        assertThat(e.diagnostics.validResponseCount).isEqualTo(9)
    }

    @Test fun negativeImpactIsDescriptive() {
        val r = deep(received(30, 93.0), received(30, 30.0))
        assertThat(r.metrics.loadImpact?.increaseMilliseconds).isEqualTo(-63.0)
        assertThat(r.metrics.loadImpact?.classification).isEqualTo(LoadImpactClassification.DESCRIPTIVE)
    }

    @Test fun materialityUsesRawTwentyMsBoundary() {
        val rest = received(30, 30.0)
        val below = deep(rest, received(30, 49.999)).metrics.loadImpact!!
        val at = deep(rest, received(30, 50.0)).metrics.loadImpact!!
        assertThat(below.classification).isEqualTo(LoadImpactClassification.DESCRIPTIVE)
        assertThat(at.classification).isEqualTo(LoadImpactClassification.MATERIAL)
        assertThat(deep(rest, received(30, 49.999)).restResult).isEqualTo(deep(rest, received(30, 50.0)).restResult)
    }

    @Test fun everyProfileUsesItsOwnRestRule() {
        val rest = received(30, 70.0)
        val load = received(30, 95.0)
        for (p in QualityProfileId.entries) {
            val r = deep(rest, load, p)
            assertThat(r.restResult).isEqualTo(completed(rest, p))
            assertThat(r.metrics.loadImpact?.increaseMilliseconds).isEqualTo(25.0)
            assertThat(r.metrics.loadImpact?.classification).isEqualTo(LoadImpactClassification.MATERIAL)
        }
    }
}
