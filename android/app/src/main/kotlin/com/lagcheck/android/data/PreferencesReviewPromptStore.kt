package com.lagcheck.android.data

import android.content.Context
import com.lagcheck.domain.model.ReviewPromptState
import com.lagcheck.session.ReviewPromptStore

/**
 * Persistência desacoplada do estado de review via SharedPreferences (Decisão 77).
 */
class PreferencesReviewPromptStore(context: Context) : ReviewPromptStore {
    private val prefs = context.getSharedPreferences("lagcheck_review_prefs", Context.MODE_PRIVATE)

    companion object {
        private const val KEY_READY_COUNT = "review_successful_ready_count"
        private const val KEY_LAST_PROMPT_MILLIS = "review_last_prompt_millis"
        private const val KEY_LAST_PROMPT_VERSION = "review_last_prompt_version"
    }

    override fun loadState(): ReviewPromptState {
        val readyCount = prefs.getInt(KEY_READY_COUNT, 0)
        val lastMillis = if (prefs.contains(KEY_LAST_PROMPT_MILLIS)) {
            prefs.getLong(KEY_LAST_PROMPT_MILLIS, -1L).takeIf { it > 0 }
        } else null
        val lastVersion = prefs.getString(KEY_LAST_PROMPT_VERSION, null)

        return ReviewPromptState(
            successfulReadyChecksCount = readyCount,
            lastPromptedEpochMillis = lastMillis,
            lastPromptedVersion = lastVersion
        )
    }

    override fun saveState(state: ReviewPromptState) {
        val lastMillis = state.lastPromptedEpochMillis
        val lastVersion = state.lastPromptedVersion
        prefs.edit().apply {
            putInt(KEY_READY_COUNT, state.successfulReadyChecksCount)
            if (lastMillis != null) {
                putLong(KEY_LAST_PROMPT_MILLIS, lastMillis)
            } else {
                remove(KEY_LAST_PROMPT_MILLIS)
            }
            if (lastVersion != null) {
                putString(KEY_LAST_PROMPT_VERSION, lastVersion)
            } else {
                remove(KEY_LAST_PROMPT_VERSION)
            }
            apply()
        }
    }
}
