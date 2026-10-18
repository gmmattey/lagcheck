package com.lagcheck.catalog

import com.google.common.truth.Truth.assertThat
import com.lagcheck.catalog.CatalogTestSupport.realEnvelopeBytes
import org.junit.Test

class RemoteCatalogRepositoryTest {
    @Test fun bundledCatalogValidatesWithAllGamesAndGlobalReferences() {
        val payload = RemoteCatalogVerifier.verifyAndDecode(
            realEnvelopeBytes(),
            java.time.Instant.parse("2026-10-17T12:00:00Z")
        )

        assertThat(payload.games).hasSize(48)
        assertThat(payload.regions).isNotEmpty()
        payload.games.forEach { game ->
            assertThat(game.contexts).isNotEmpty()
            game.contexts.forEach { context ->
                assertThat(
                    context.routes.orEmpty().any {
                        it.kind == RouteKind.AWS_FALLBACK && it.status == RouteStatus.ACTIVE
                    }
                ).isTrue()
            }
        }
    }

    @Test fun expiredBundledCatalogFailsClosed() {
        val result = runCatching {
            RemoteCatalogVerifier.verifyAndDecode(
                realEnvelopeBytes(),
                java.time.Instant.parse("2026-12-01T00:00:00Z")
            )
        }
        assertThat(result.isFailure).isTrue()
    }
}
