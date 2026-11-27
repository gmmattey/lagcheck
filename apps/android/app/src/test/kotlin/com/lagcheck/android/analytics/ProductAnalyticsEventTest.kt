package com.lagcheck.android.analytics

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class ProductAnalyticsEventTest {
    @Test
    fun `maps the canonical events without network identifiers`() {
        val events = listOf(
            ProductAnalyticsEvent.GameSelected("fortnite"),
            ProductAnalyticsEvent.LagcheckStarted("fortnite", "mobile", "wifi", "sa-east-1"),
            ProductAnalyticsEvent.LagcheckCompleted("fortnite", "mobile", "wifi", "sa-east-1", "great", 12),
            ProductAnalyticsEvent.LagcheckInconclusive("fortnite", "mobile", "wifi", "sa-east-1", "insufficient_samples"),
            ProductAnalyticsEvent.LagcheckCancelled("fortnite", "mobile", "wifi", "sa-east-1", "background", "rest"),
            ProductAnalyticsEvent.ResultViewed("fortnite", "mobile", "ready"),
            ProductAnalyticsEvent.DetailsViewed("fortnite", "mobile", "ready"),
            ProductAnalyticsEvent.RecommendationsViewed("fortnite", "mobile", 2),
            ProductAnalyticsEvent.ResultShared("fortnite", "mobile", "discord"),
            ProductAnalyticsEvent.RetestStarted("fortnite", "mobile")
        ).map { it.toFirebasePayload() }

        assertThat(events.map { it.name }).containsExactly(
            "game_selected",
            "lagcheck_started",
            "lagcheck_completed",
            "lagcheck_inconclusive",
            "lagcheck_cancelled",
            "result_viewed",
            "details_viewed",
            "recommendations_viewed",
            "result_shared",
            "retest_started"
        ).inOrder()
        assertThat(events.flatMap { it.parameters.keys })
            .containsNoneOf("ip", "ssid", "bssid", "mac", "server_address", "raw_samples")
        assertThat(events[2].parameters["duration_seconds"]).isEqualTo(12L)
        assertThat(events[4].parameters["cancellation_stage"]).isEqualTo("rest")
        assertThat(events[7].parameters["recommendation_count"]).isEqualTo(2L)
        assertThat(events[8].parameters["share_channel"]).isEqualTo("discord")
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

    @Test
    fun `maps mobile platform to mobile and never leaks iphone`() {
        assertThat(analyticsGamePlatform("Mobile")).isEqualTo("mobile")
        assertThat(analyticsGamePlatform("android")).isEqualTo("mobile")
        assertThat(analyticsGamePlatform("PlayStation")).isEqualTo("playstation")
        assertThat(analyticsGamePlatform("Xbox")).isEqualTo("xbox")
        assertThat(analyticsGamePlatform("PC")).isEqualTo("pc")
        assertThat(analyticsGamePlatform("Switch")).isEqualTo("nintendo")
    }
}
