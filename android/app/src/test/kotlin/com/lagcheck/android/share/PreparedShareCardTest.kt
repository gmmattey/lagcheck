package com.lagcheck.android.share

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class PreparedShareCardTest {
    @Test
    fun cacheKeyIsStableForTheSameSnapshotAndDistinctForARetest() {
        val first = snapshot("18")
        assertThat(snapshot("18").cacheKey).isEqualTo(first.cacheKey)
        assertThat(snapshot("19").cacheKey).isNotEqualTo(first.cacheKey)
        assertThat(snapshot("18", locale = "en", identity = "1001").cacheKey).isNotEqualTo(first.cacheKey)
        assertThat(PreparedShareCard.digest(snapshot("18").cacheKey)).isEqualTo(PreparedShareCard.digest(first.cacheKey))
    }

    private fun snapshot(ping: String, locale: String = "pt-BR", identity: String = "1000") = PreparedShareCardSnapshot(
        gameName = "Valorant", artDrawableName = "game_valorant", tone = ShareTone.READY,
        headline = "PRONTO PARA RANKED", regionName = "São Paulo",
        metrics = listOf(ShareMetric(ShareMetricKind.PING, ping, "ms", ping.toDouble())), localeTag = locale, measurementIdentity = identity
    )
}
