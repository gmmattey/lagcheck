package com.lagcheck.session

import com.google.common.truth.Truth.assertThat
import com.lagcheck.catalog.RemoteCatalogVerifier
import java.io.File
import java.time.Instant
import org.junit.Test

class CatalogPresentationTest {
    private val root = generateSequence(File(System.getProperty("user.dir")).absoluteFile) { it.parentFile }
        .first { File(it, "worker/catalog/catalog-v3.envelope.json").exists() }
    private val payload = RemoteCatalogVerifier.verifyAndDecode(
        File(root, "worker/catalog/catalog-v3.envelope.json").readBytes(), Instant.parse("2026-10-20T00:00:00Z")
    )

    @Test fun unknownGameAppearsWithoutALocalRegistryEntry() {
        val future = payload.games.first().copy(id = "future-game", name = "Future Game")
        val games = CatalogPresentation.games(payload.copy(games = listOf(future)))
        assertThat(games.map { it.id }).containsExactly("future-game")
        assertThat(games.single().drawableResName).isEmpty()
        assertThat(games.single().artworkUrl).startsWith("https://")
        assertThat(games.single().artworkRevision).isEqualTo(payload.catalogVersion)
        assertThat(games.single().platforms).contains("PC")
    }

    @Test fun removedGamesAreNotReintroducedByLocalMetadata() {
        assertThat(CatalogPresentation.games(payload.copy(games = emptyList()))).isEmpty()
    }

    @Test fun unavailableContextsAndUnknownPlatformsDoNotBecomeSelectable() {
        val game = payload.games.first()
        val contexts = game.contexts.map { it.copy(availableForMeasurement = false) }
        assertThat(CatalogPresentation.games(payload.copy(games = listOf(game.copy(contexts = contexts))))).isEmpty()
        val unknown = game.contexts.first().copy(platformKeys = setOf("future-console"))
        assertThat(CatalogPresentation.games(payload.copy(games = listOf(game.copy(contexts = listOf(unknown)))))).isEmpty()
    }
}
