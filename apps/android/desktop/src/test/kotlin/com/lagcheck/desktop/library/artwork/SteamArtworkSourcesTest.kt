package com.lagcheck.desktop.library.artwork

import java.nio.file.Files
import kotlin.test.*

class SteamArtworkSourcesTest {
    @Test
    fun cdnGeraUrlsDeCapaEBannerSoParaSteam() {
        val s = SteamCdnSource()
        val cover = s.candidates(steamGame, ArtworkType.COVER).map { (it as ArtworkCandidate.Remote).url }
        assertEquals("https://cdn.cloudflare.steamstatic.com/steam/apps/730/library_600x900.jpg", cover.first())
        assertTrue(cover.all { it.startsWith("https://") && it.endsWith("library_600x900.jpg") })
        assertTrue(s.candidates(steamGame, ArtworkType.HERO).all { (it as ArtworkCandidate.Remote).url.endsWith("library_hero.jpg") })
        assertTrue(s.candidates(steamGame, ArtworkType.ICON).isEmpty())
        assertTrue(s.candidates(epicGame, ArtworkType.COVER).isEmpty())
    }

    @Test
    fun idSteamInvalidoNaoGeraUrl() {
        val s = SteamCdnSource()
        assertTrue(s.candidates(steamGame.copy(id = "steam_../../x"), ArtworkType.COVER).isEmpty())
        assertTrue(s.candidates(steamGame.copy(id = "steam_"), ArtworkType.COVER).isEmpty())
    }

    @Test
    fun cacheDoClienteNoFormatoAntigoENovo() = withTempDir { root ->
        val lib = Files.createDirectories(root.resolve("appcache/librarycache"))
        Files.write(lib.resolve("730_library_600x900.jpg"), jpegBytes())
        val nested = Files.createDirectories(lib.resolve("440/abcdef0123"))
        Files.write(nested.resolve("library_hero.jpg"), jpegBytes())
        val s = SteamLibraryCacheSource { root.toFile() }

        val old = s.candidates(steamGame, ArtworkType.COVER).map { (it as ArtworkCandidate.LocalFile).path.fileName.toString() }
        assertEquals(listOf("730_library_600x900.jpg"), old)
        val new = s.candidates(steamGame.copy(id = "steam_440"), ArtworkType.HERO).map { (it as ArtworkCandidate.LocalFile).path.fileName.toString() }
        assertEquals(listOf("library_hero.jpg"), new)
        assertTrue(s.candidates(steamGame.copy(id = "steam_9"), ArtworkType.COVER).isEmpty())
        assertTrue(s.candidates(epicGame, ArtworkType.COVER).isEmpty())
    }

    @Test
    fun steamNaoInstaladaNaoDaCandidato() {
        assertTrue(SteamLibraryCacheSource { null }.candidates(steamGame, ArtworkType.COVER).isEmpty())
    }
}
