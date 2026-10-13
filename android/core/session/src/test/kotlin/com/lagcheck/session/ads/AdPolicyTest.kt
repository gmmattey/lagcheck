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

    @Test fun `mostra na Home e no Historico com tudo liberado`() {
        assertThat(AdPolicy.shouldShowBanner(ctx(placement = AdPlacement.HOME))).isTrue()
        assertThat(AdPolicy.shouldShowBanner(ctx(placement = AdPlacement.HISTORY))).isTrue()
    }

    @Test fun `desligado no beta nunca mostra`() {
        assertThat(AdPolicy.shouldShowBanner(ctx(enabled = false))).isFalse()
    }

    @Test fun `fora de Home e Historico nunca mostra`() {
        assertThat(AdPolicy.shouldShowBanner(ctx(placement = null))).isFalse()
    }

    @Test fun `sem consentimento nao mostra`() {
        assertThat(AdPolicy.shouldShowBanner(ctx(canRequestAds = false))).isFalse()
    }

    @Test fun `durante a medicao nao mostra`() {
        assertThat(AdPolicy.shouldShowBanner(ctx(measuring = true))).isFalse()
    }
}
