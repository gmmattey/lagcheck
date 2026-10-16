package com.lagcheck.android.data

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class PreMatchReminderContractTest {
    @Test fun `starts off and schedule replaces the single daily target`() {
        val initial = PreMatchReminderState(enabled = false, gameId = null)
        val first = initial.scheduled("fortnite", 20, 0)
        val changed = first.scheduled("fortnite", 22, 30)
        assertThat(initial.enabled).isFalse()
        assertThat(changed).isEqualTo(PreMatchReminderState(true, "fortnite", 22, 30))
    }
    @Test fun `disable and permission revocation remove the target`() {
        val active = PreMatchReminderState(true, "fortnite")
        assertThat(active.disabled()).isEqualTo(PreMatchReminderState(false, null))
        assertThat(active.permissionRevoked()).isEqualTo(PreMatchReminderState(false, null, permissionDenied = true))
    }
    @Test fun `catalog removal disables a reminder bound to an unavailable game`() {
        val active = PreMatchReminderState(true, "fortnite")
        assertThat(active.invalidated(setOf("valorant")).enabled).isFalse()
        assertThat(active.invalidated(setOf("fortnite"))).isEqualTo(active)
    }
}
