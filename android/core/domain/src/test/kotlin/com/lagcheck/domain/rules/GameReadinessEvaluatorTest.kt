package com.lagcheck.domain.rules

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.NetworkFinding
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import org.junit.Test

class GameReadinessEvaluatorTest {

    @Test
    fun lessThan10ValidSamples_returnsInconclusive() {
        val samples = (1..9).map {
            ProbeSample(it, 35.0, ProbeSample.Outcome.SUCCESS)
        }

        val result = GameReadinessEvaluator.evaluate(samples)

        assertThat(result.verdict).isEqualTo(GameReadinessVerdict.INCONCLUSIVE)
        assertThat(result.pingMs).isNull()
        assertThat(result.findings).hasSize(1)
        assertThat(result.findings[0].kind).isEqualTo(NetworkFinding.Kind.INSUFFICIENT_DATA)
    }

    @Test
    fun optimalSamples_returnsReady() {
        val samples = (1..30).map {
            ProbeSample(it, 25.0 + (it % 3), ProbeSample.Outcome.SUCCESS)
        }

        val radio = RadioTelemetrySnapshot(
            transportType = RadioTelemetrySnapshot.TransportType.WIFI,
            wifiDetails = RadioTelemetrySnapshot.WifiDetails(
                frequencyMhz = 5200,
                rssiDbm = -45,
                txLinkSpeedMbps = 866,
                rxLinkSpeedMbps = 866,
                standard = "Wi-Fi 6 (ax)"
            )
        )

        val result = GameReadinessEvaluator.evaluate(samples, radioSnapshot = radio)

        assertThat(result.verdict).isEqualTo(GameReadinessVerdict.READY)
        assertThat(result.pingMs).isAtMost(30.0)
        assertThat(result.jitterMs).isAtMost(4.0)
        assertThat(result.packetLossPercentage).isEqualTo(0.0)
        assertThat(result.findings.any { it.kind == NetworkFinding.Kind.WIFI_BAND_5GHZ }).isTrue()
    }

    @Test
    fun highPacketLoss_returnsNotReady() {
        val samples = mutableListOf<ProbeSample>()
        // 20 sucessos e 10 timeouts (33.3% loss)
        for (i in 1..20) {
            samples.add(ProbeSample(i, 30.0, ProbeSample.Outcome.SUCCESS))
        }
        for (i in 21..30) {
            samples.add(ProbeSample(i, null, ProbeSample.Outcome.TIMEOUT))
        }

        val result = GameReadinessEvaluator.evaluate(samples)

        assertThat(result.verdict).isEqualTo(GameReadinessVerdict.NOT_READY)
        assertThat(result.packetLossPercentage).isGreaterThan(2.0)
        assertThat(result.findings.any { it.kind == NetworkFinding.Kind.PACKET_LOSS }).isTrue()
    }

    @Test
    fun wifi24Ghz_emitsWifi24GhzWarningFinding() {
        val samples = (1..30).map {
            ProbeSample(it, 35.0, ProbeSample.Outcome.SUCCESS)
        }

        val radio = RadioTelemetrySnapshot(
            transportType = RadioTelemetrySnapshot.TransportType.WIFI,
            wifiDetails = RadioTelemetrySnapshot.WifiDetails(
                frequencyMhz = 2437, // Canal 6, 2.4 GHz
                rssiDbm = -65,
                txLinkSpeedMbps = 72,
                rxLinkSpeedMbps = 72,
                standard = "Wi-Fi 4 (n)"
            )
        )

        val result = GameReadinessEvaluator.evaluate(samples, radioSnapshot = radio)

        assertThat(result.findings.any { it.kind == NetworkFinding.Kind.WIFI_BAND_2_4GHZ }).isTrue()
    }

    @Test
    fun outOfOrderPackets_modulatesVerdictToCaution() {
        val samples = (1..30).map {
            ProbeSample(it, 30.0, ProbeSample.Outcome.SUCCESS, isOutOfOrder = it in 5..8)
        }

        val result = GameReadinessEvaluator.evaluate(samples)

        assertThat(result.verdict).isEqualTo(GameReadinessVerdict.CAUTION)
        assertThat(result.findings.any { it.kind == NetworkFinding.Kind.OUT_OF_ORDER_PACKETS }).isTrue()
    }
}
