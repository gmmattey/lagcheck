package com.lagcheck.domain.rules
import com.lagcheck.domain.model.ProbeOutcome
import kotlin.math.floor
import kotlin.math.ceil

data class RegionalPreReadSample(
    val outcome: ProbeOutcome,
    val roundTripMilliseconds: Double? = null
) {
    val validRoundTripMilliseconds: Double?
        get() = if (outcome == ProbeOutcome.RECEIVED && roundTripMilliseconds != null && roundTripMilliseconds >= 0.0 && !roundTripMilliseconds.isNaN() && !roundTripMilliseconds.isInfinite()) roundTripMilliseconds else null
}

interface RegionalSelectionCandidate<T> {
    val regionId: String
    val priority: Int
    val catalogVersion: String
    val context: T
}

data class RegionalSelectionSnapshot<T, C : RegionalSelectionCandidate<T>>(
    val catalogVersion: String,
    val context: T,
    val candidates: List<C>
) {
    init {
        if (catalogVersion.isEmpty() || candidates.isEmpty()) {
            throw RegionalSelectionError("invalidSnapshot")
        }
        if (candidates.map { it.regionId }.toSet().size != candidates.size) {
            throw RegionalSelectionError("duplicateCandidateRegion")
        }
        if (candidates.any { it.priority < 0 }) {
            throw RegionalSelectionError("invalidPriority")
        }
        if (!candidates.all { it.catalogVersion == catalogVersion && it.context == context }) {
            throw RegionalSelectionError("candidateOutsideSnapshot")
        }
    }
}

enum class RegionalSelectionMode { AUTOMATIC, MANUAL }
enum class RegionalSelectionInconclusiveReason { NO_VIABLE_REGIONAL_CANDIDATE }

sealed class RegionalSelectionDecision<T, C : RegionalSelectionCandidate<T>> {
    data class Selected<T, C : RegionalSelectionCandidate<T>>(val result: RegionalSelectionResult<T, C>) : RegionalSelectionDecision<T, C>()
    data class Inconclusive<T, C : RegionalSelectionCandidate<T>>(val reason: RegionalSelectionInconclusiveReason) : RegionalSelectionDecision<T, C>()
}

data class RegionalSelectionResult<T, C : RegionalSelectionCandidate<T>>(
    val ruleVersion: String,
    val catalogVersion: String,
    val mode: RegionalSelectionMode,
    val selected: C,
    val p50Milliseconds: Double,
    val validResponseCount: Int
)

class RegionalSelectionError(message: String) : Exception(message)

object RegionalSelectionRule {
    const val VERSION = "regional-selection-1"
    const val MINIMUM_VALID_RESPONSES = 2
    const val CLEAR_LEAD_MILLISECONDS = 6.0
    const val TIE_WINDOW_MILLISECONDS = 5.0

    fun <T, C : RegionalSelectionCandidate<T>> select(
        snapshot: RegionalSelectionSnapshot<T, C>,
        preReadSamples: Map<String, List<RegionalPreReadSample>>,
        manualRegionId: String? = null
    ): RegionalSelectionDecision<T, C> {
        val mode: RegionalSelectionMode
        val candidates: List<C>

        if (manualRegionId != null) {
            val candidate = snapshot.candidates.firstOrNull { it.regionId == manualRegionId }
                ?: throw RegionalSelectionError("manualCandidateNotAllowed")
            candidates = listOf(candidate)
            mode = RegionalSelectionMode.MANUAL
        } else {
            candidates = snapshot.candidates
            mode = RegionalSelectionMode.AUTOMATIC
        }

        val eligible = candidates.mapNotNull { candidate ->
            val validRTTs = (preReadSamples[candidate.regionId] ?: emptyList())
                .mapNotNull { it.validRoundTripMilliseconds }
            if (validRTTs.size < MINIMUM_VALID_RESPONSES) return@mapNotNull null
            val p50 = percentile(validRTTs, 0.5) ?: return@mapNotNull null
            EvaluatedCandidate(candidate, p50, validRTTs.size)
        }

        if (eligible.isEmpty()) {
            return RegionalSelectionDecision.Inconclusive(RegionalSelectionInconclusiveReason.NO_VIABLE_REGIONAL_CANDIDATE)
        }

        val winner = if (eligible.size == 1) {
            eligible.first()
        } else {
            val clearLeader = eligible.firstOrNull { contender ->
                eligible.all { other ->
                    other.candidate.regionId == contender.candidate.regionId ||
                    contender.p50Milliseconds + CLEAR_LEAD_MILLISECONDS <= other.p50Milliseconds
                }
            }
            if (clearLeader != null) {
                clearLeader
            } else {
                val minimumP50 = eligible.minOf { it.p50Milliseconds }
                eligible
                    .filter { it.p50Milliseconds <= minimumP50 + TIE_WINDOW_MILLISECONDS }
                    .sortedWith(
                        compareByDescending<EvaluatedCandidate<T, C>> { it.validResponseCount }
                            .thenBy { it.candidate.priority }
                            .thenBy { it.candidate.regionId }
                    )
                    .first()
            }
        }

        return RegionalSelectionDecision.Selected(
            RegionalSelectionResult(
                ruleVersion = VERSION,
                catalogVersion = snapshot.catalogVersion,
                mode = mode,
                selected = winner.candidate,
                p50Milliseconds = winner.p50Milliseconds,
                validResponseCount = winner.validResponseCount
            )
        )
    }

    private data class EvaluatedCandidate<T, C : RegionalSelectionCandidate<T>>(
        val candidate: C,
        val p50Milliseconds: Double,
        val validResponseCount: Int
    )

    private fun percentile(values: List<Double>, percentile: Double): Double? {
        if (values.isEmpty()) return null
        val sorted = values.sorted()
        val position = percentile * (sorted.size - 1)
        val lowerIndex = floor(position).toInt()
        val upperIndex = ceil(position).toInt()
        if (lowerIndex == upperIndex) return sorted[lowerIndex]
        val fraction = position - lowerIndex
        return sorted[lowerIndex] + (sorted[upperIndex] - sorted[lowerIndex]) * fraction
    }
}
