package com.lagcheck.catalog

import com.google.common.truth.Truth.assertThat
import com.lagcheck.catalog.CatalogTestSupport.realEnvelopeBytes
import org.junit.Test

class RemoteCatalogRepositoryTest {
    @Test fun bundledCatalogValidatesWithAllGamesAndGlobalReferences() {
        val payload = RemoteCatalogVerifier.decodeBundled(realEnvelopeBytes())

        assertThat(payload.games).hasSize(54)
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

    /** Decisão 106: o catálogo acompanha o build, sem assinatura nem validade; uma data futura nunca esvazia o app. */
    @Test fun bundledCatalogHasNoSignatureOrExpiry() {
        val text = realEnvelopeBytes().toString(Charsets.UTF_8)
        assertThat(text).doesNotContain("signatureBase64")
        assertThat(text).doesNotContain("expiresAt")
        assertThat(runCatching { RemoteCatalogVerifier.decodeBundled(realEnvelopeBytes()) }.isSuccess).isTrue()
    }

    @Test fun malformedAndOversizedBundledCatalogsAreRejected() {
        assertThat(runCatching { RemoteCatalogVerifier.decodeBundled("{}".toByteArray()) }.isFailure).isTrue()
        assertThat(runCatching { RemoteCatalogVerifier.decodeBundled(ByteArray(200 * 1024)) }.isFailure).isTrue()
    }
}
