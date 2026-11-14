package com.lagcheck.domain.rules

import com.lagcheck.domain.model.MeasurementEvaluation
import com.lagcheck.domain.model.ProbeOutcome
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.model.QualityResult

internal fun received(count: Int, rtt: Double, startingAt: Int = 0): List<ProbeSample> =
    (0 until count).map { ProbeSample(startingAt + it, rtt, ProbeOutcome.RECEIVED) }

internal fun timeouts(count: Int, startingAt: Int): List<ProbeSample> =
    (0 until count).map { ProbeSample(startingAt + it, null, ProbeOutcome.TIMEOUT) }

internal fun completed(
    samples: List<ProbeSample>,
    profile: QualityProfileId = QualityProfileId.BATTLE_ROYALE_COMPETITIVE
): QualityResult =
    (QualityEvaluator.evaluate(samples, profile) as? MeasurementEvaluation.Completed)?.result
        ?: error("Expected completed evaluation")
