package com.lagcheck.session.ads

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class AdPolicyTest {
    private fun ctx(
        enabled: Boolean = true,
        placement: AdPlacement? = AdPlacement.HOME,
        canRequestAds: Boolean = true,
        measuring: Boolean = false
    ) = AdContext(enabled, placement, canRequestAds, measuring)

    @Test fun `mostra nas quatro superficies com tudo liberado`() {
        AdPlacement.entries.forEach { placement ->
            assertThat(AdPolicy.shouldShowNative(ctx(placement = placement))).isTrue()
        }
    }

    @Test fun `desligado nunca mostra`() {
        assertThat(AdPolicy.shouldShowNative(ctx(enabled = false))).isFalse()
    }

    @Test fun `fora das quatro superficies nunca mostra`() {
        assertThat(AdPolicy.shouldShowNative(ctx(placement = null))).isFalse()
    }

    @Test fun `sem consentimento nao mostra`() {
        assertThat(AdPolicy.shouldShowNative(ctx(canRequestAds = false))).isFalse()
    }

    @Test fun `durante a medicao nao mostra`() {
        AdPlacement.entries.forEach { placement ->
            assertThat(AdPolicy.shouldShowNative(ctx(placement = placement, measuring = true))).isFalse()
        }
    }
}
