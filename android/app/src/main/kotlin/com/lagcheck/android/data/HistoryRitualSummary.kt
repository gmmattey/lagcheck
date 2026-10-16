package com.lagcheck.android.data

import com.lagcheck.domain.model.GameReadinessVerdict
import java.util.Calendar

/** Contrato local do ritual de Histórico. Só resume fatos equivalentes já medidos. */
data class HistoryRitualSummary(
    val windowDays: Int,
    val readyCount: Int,
    val cautionCount: Int,
    val notReadyCount: Int,
    val inconclusiveCount: Int,
    val comparableCount: Int,
    val distinctDayCount: Int
) {
    val hasEnoughEvidence: Boolean get() = comparableCount >= 3 && distinctDayCount >= 2

    companion object {
        fun forEntries(entries: List<CheckHistoryItem>, windowDays: Int, now: Long = System.currentTimeMillis()): HistoryRitualSummary? {
            val cutoff = now - windowDays * DAY_MILLIS
            val inWindow = entries.filter { it.timestamp in cutoff..now }
            val latest = inWindow.filter(::isEligible).maxByOrNull { it.timestamp } ?: return null
            val comparable = inWindow.filter { isEligible(it) && sameContext(it, latest) }
            return HistoryRitualSummary(
                windowDays = windowDays,
                readyCount = comparable.count { it.verdict == GameReadinessVerdict.READY },
                cautionCount = comparable.count { it.verdict == GameReadinessVerdict.CAUTION },
                notReadyCount = comparable.count { it.verdict == GameReadinessVerdict.NOT_READY },
                inconclusiveCount = inWindow.count { it.verdict == GameReadinessVerdict.INCONCLUSIVE && sameContext(it, latest) },
                comparableCount = comparable.size,
                distinctDayCount = comparable.map(::dayKey).toSet().size
            )
        }

        private fun isEligible(item: CheckHistoryItem): Boolean =
            item.validResponseCount?.let { it >= 10 } == true &&
                item.profileRuleVersion != null && item.regionId != null && item.observedNetwork != null &&
                item.verdict != GameReadinessVerdict.INCONCLUSIVE

        private fun sameContext(a: CheckHistoryItem, b: CheckHistoryItem): Boolean =
            a.gameId == b.gameId && a.platform == b.platform &&
                a.declaredExternalLink == b.declaredExternalLink && a.observedNetwork == b.observedNetwork &&
                a.regionId == b.regionId && a.profileRuleVersion == b.profileRuleVersion

        private fun dayKey(item: CheckHistoryItem): String = Calendar.getInstance().run {
            timeInMillis = item.timestamp
            "${get(Calendar.YEAR)}:${get(Calendar.DAY_OF_YEAR)}"
        }

        private const val DAY_MILLIS = 86_400_000L
    }
}
