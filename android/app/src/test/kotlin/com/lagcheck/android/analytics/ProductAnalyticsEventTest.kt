package com.lagcheck.android.analytics

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class ProductAnalyticsEventTest {
    @Test
    fun `maps the canonical events without network identifiers`() {
        val events = listOf(
            ProductAnalyticsEvent.GameSelected("fortnite"),
            ProductAnalyticsEvent.LagcheckStarted("fortnite", "iphone", "wifi", "sa-east-1"),
            ProductAnalyticsEvent.LagcheckCompleted("fortnite", "iphone", "wifi", "sa-east-1", "great", 12),
            ProductAnalyticsEvent.LagcheckInconclusive("fortnite", "iphone", "wifi", "sa-east-1", "insufficient_samples"),
            ProductAnalyticsEvent.LagcheckCancelled("fortnite", "iphone", "wifi", "sa-east-1", "background"),
            ProductAnalyticsEvent.ResultViewed("fortnite", "iphone", "ready"),
            ProductAnalyticsEvent.RetestStarted("fortnite", "iphone")
        ).map { it.toFirebasePayload() }

        assertThat(events.map { it.name }).containsExactly(
            "game_selected",
            "lagcheck_started",
            "lagcheck_completed",
            "lagcheck_inconclusive",
            "lagcheck_cancelled",
            "result_viewed",
            "retest_started"
        ).inOrder()
        assertThat(events.flatMap { it.parameters.keys })
            .containsNoneOf("ip", "ssid", "bssid", "mac", "server_address", "raw_samples")
        assertThat(events[2].parameters["duration_seconds"]).isEqualTo(12L)
    }

    @Test
    fun `noop tracker never forwards an event`() {
        NoopProductAnalyticsTracker.track(ProductAnalyticsEvent.GameSelected("fortnite"))
    }

    @Test
    fun `debug and owner excluded installs do not collect`() {
        assertThat(effectiveAnalyticsCollectionEnabled(buildAllowsCollection = false, ownerExcluded = false)).isFalse()
        assertThat(effectiveAnalyticsCollectionEnabled(buildAllowsCollection = true, ownerExcluded = true)).isFalse()
        assertThat(effectiveAnalyticsCollectionEnabled(buildAllowsCollection = true, ownerExcluded = false)).isTrue()
    }
}
