package com.lagcheck.android.share

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.GameReadinessVerdict
import java.util.Locale
import org.junit.Test

class ShareMediaSceneTest {
    private val pt = Locale("pt", "BR")

    private fun scene(
        verdict: GameReadinessVerdict = GameReadinessVerdict.READY,
        ping: Double? = 18.4,
        jitter: Double? = 2.46,
        loss: Double? = 0.0
    ) = ShareMediaScene.from("Valorant", "game_valorant", verdict, "PRONTO PARA RANKED", "São Paulo", ping, jitter, loss, pt)

    @Test
    fun readyBuildsSceneWithMeasuredNumbersOnly() {
        val s = scene()!!
        assertThat(s.tone).isEqualTo(ShareTone.READY)
        assertThat(s.metrics.map { it.kind }).containsExactly(ShareMetricKind.PING, ShareMetricKind.JITTER, ShareMetricKind.PACKET_LOSS).inOrder()
        assertThat(s.metrics[0].value).isEqualTo("18")
        assertThat(s.metrics[0].unit).isEqualTo("ms")
        assertThat(s.metrics[1].value).isEqualTo("2,5")
        assertThat(s.metrics[2].number).isEqualTo(0.0)
    }

    @Test
    fun verdictsMapToTones() {
        assertThat(scene(GameReadinessVerdict.CAUTION)!!.tone).isEqualTo(ShareTone.CAUTION)
        assertThat(scene(GameReadinessVerdict.NOT_READY)!!.tone).isEqualTo(ShareTone.NOT_READY)
    }

    @Test
    fun inconclusiveOrMissingNumbersProduceNoScene() {
        assertThat(scene(GameReadinessVerdict.INCONCLUSIVE)).isNull()
        assertThat(scene(ping = null)).isNull()
        assertThat(scene(jitter = null)).isNull()
    }

    @Test
    fun unmeasuredLossShowsDashInsteadOfInventingZero() {
        val loss = scene(loss = null)!!.metrics[2]
        assertThat(loss.value).isEqualTo("—")
        assertThat(loss.unit).isEmpty()
        assertThat(loss.number).isNull()
    }

    @Test
    fun decimalFormattingFollowsLocale() {
        assertThat(ShareMediaScene.format(2.46, 1, pt)).isEqualTo("2,5")
        assertThat(ShareMediaScene.format(2.46, 1, Locale.US)).isEqualTo("2.5")
        assertThat(ShareMediaScene.format(0.0, 1, pt)).isEqualTo("0")
    }

    @Test
    fun timelineCoversFourteenSeconds() {
        assertThat(ShareVideoTimeline.frameCount).isEqualTo(420)
        assertThat(ShareVideoTimeline.MEASURE_START).isLessThan(ShareVideoTimeline.RESULT_START)
        assertThat(ShareVideoTimeline.RESULT_START).isLessThan(ShareVideoTimeline.DURATION)
    }
}
