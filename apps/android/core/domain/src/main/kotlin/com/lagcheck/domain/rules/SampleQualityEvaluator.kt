package com.lagcheck.domain.rules

import com.lagcheck.domain.model.InconclusiveReason
import com.lagcheck.domain.model.ProbeOutcome
import com.lagcheck.domain.model.ProbeSample

data class SampleQualityAssessment(
    val shouldAbort: Boolean,
    val abortReason: InconclusiveReason?,
    val consecutiveTimeouts: Int,
    val earlyLossPercentage: Double,
    val ruleVersion: String = SampleQualityEvaluator.RULE_VERSION
)

/**
 * Watchdog determinístico (sample-quality-v1). Evita fazer o jogador esperar 15 s por uma conexão morta.
 */
object SampleQualityEvaluator {
    const val RULE_VERSION = "sample-quality-v1"

    fun assess(samples: List<ProbeSample>): SampleQualityAssessment {
        if (samples.isEmpty()) return SampleQualityAssessment(false, null, 0, 0.0)
        val sorted = samples.sortedBy { it.sequence }

        var trailing = 0
        for (sample in sorted.asReversed()) {
            if (sample.outcome == ProbeOutcome.TIMEOUT ||
                sample.outcome == ProbeOutcome.TRANSPORT_ERROR ||
                sample.outcome == ProbeOutcome.INVALID_RESPONSE
            ) trailing += 1 else break
        }
        val nonReceived = sorted.count { it.outcome != ProbeOutcome.RECEIVED }
        val loss = nonReceived.toDouble() / sorted.size * 100.0

        val abort = (sorted.size <= 6 && trailing >= 4) ||
            (sorted.size in 6..10 && loss >= 70.0) ||
            trailing >= 6
        return SampleQualityAssessment(
            shouldAbort = abort,
            abortReason = if (abort) InconclusiveReason.POOR_SAMPLE_QUALITY else null,
            consecutiveTimeouts = trailing,
            earlyLossPercentage = loss
        )
    }
}
