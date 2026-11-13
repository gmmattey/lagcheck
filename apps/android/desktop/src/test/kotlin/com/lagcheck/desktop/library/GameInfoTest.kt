package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.artwork.EpicCatalogSource
import com.lagcheck.desktop.library.info.GameInfoService
import com.lagcheck.desktop.library.info.InfoFetch
import com.lagcheck.desktop.library.info.InfoFetcher
import com.lagcheck.desktop.library.model.GameModes
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.scanner.StoreCatalog
import kotlinx.coroutines.runBlocking
import java.nio.file.Files
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class GameInfoTest {
    private val steamBody = """
        {"730":{"success":true,"data":{
          "short_description":"Competitivo de elite &quot;desde&quot; 2012. <b>Novo</b> capítulo.",
          "developers":["Valve"],"publishers":["Valve"],
          "release_date":{"coming_soon":false,"date":"21 ago. 2012"},
          "genres":[{"id":"1","description":"Ação"},{"id":"37","description":"Grátis para Jogar"}],
          "categories":[{"id":1,"description":"Multijogador"},{"id":36,"description":"PvP online"},{"id":2,"description":"Um jogador"},{"id":30,"description":"Workshop"}]
        }}}
    """.trimIndent()

    @Test fun `steam parse extracts description studio date genres and modes`() {
        val info = assertNotNull(GameInfoService.parseSteam(steamBody, "730"))
        assertEquals("Competitivo de elite \"desde\" 2012. Novo capítulo.", info.description)
        assertEquals("Valve", info.developer)
        assertEquals("Valve", info.publisher)
        assertEquals("21 ago. 2012", info.releaseDate)
        assertEquals(listOf("Ação", "Grátis para Jogar"), info.genres)
        assertEquals(listOf(GameModes.MULTIPLAYER, GameModes.ONLINE_MULTIPLAYER, GameModes.SINGLEPLAYER), info.modes)
        assertTrue(info.isOnline)
    }

    @Test fun `steam parse returns null when the store does not know the app or it is unreleased`() {
        assertNull(GameInfoService.parseSteam("""{"1":{"success":false}}""", "1"))
        assertNull(GameInfoService.parseSteam("not json".let { """{"2":{"success":true,"data":{"release_date":{"coming_soon":true,"date":"Em breve"}}}}""" }, "2"))
    }

    @Test fun `microsoft store parse reads description studio date categories and online modes`() {
        val body = """
            {"Products":[{"ProductType":"Game",
              "LocalizedProperties":[{"ProductTitle":"Jogo X","ShortDescription":"","DeveloperName":"Estudio","PublisherName":"Pub",
                "ProductDescription":"Primeiro paragrafo.\r\n\r\nSegundo paragrafo."}],
              "MarketProperties":[{"OriginalReleaseDate":"2012-07-28T01:27:59.0000000Z"}],
              "Properties":{"Category":"Puzzle","Categories":["Puzzle","Classicos"],
                "Attributes":[{"Name":"SinglePlayer"},{"Name":"XblOnlineCoop"},{"Name":"XblCloudSaves"}]}}]}
        """.trimIndent()
        val product = assertNotNull(StoreCatalog.parseProduct(body))
        val info = assertNotNull(product.info)
        assertEquals("Primeiro paragrafo.", info.description)
        assertEquals("Estudio", info.developer)
        assertEquals("Pub", info.publisher)
        assertEquals("2012-07-28", info.releaseDate)
        assertEquals(listOf("Puzzle", "Classicos"), info.genres)
        assertEquals(listOf(GameModes.SINGLEPLAYER, GameModes.ONLINE_COOP), info.modes)
    }

    private fun service(dir: java.io.File, enabled: Boolean, fetcher: InfoFetcher, clock: () -> Long = { 1_000L }) = GameInfoService(
        cacheDir = dir,
        enabled = { enabled },
        epic = EpicCatalogSource(dataDir = { null }),
        store = StoreCatalog(java.io.File(dir, "store.json"), enabled = { enabled }),
        fetcher = fetcher,
        now = clock,
    )

    private val steamGame = PcGame("steam_730", "Counter-Strike 2", GamePlatform.STEAM)

    @Test fun `steam info is fetched once then served from the disk cache`() = runBlocking {
        val dir = Files.createTempDirectory("info").toFile()
        var calls = 0
        val fetcher = InfoFetcher { calls++; InfoFetch.Body(steamBody) }
        val svc = service(dir, enabled = true, fetcher)
        assertEquals("Valve", svc.resolve(steamGame)?.developer)
        assertEquals("Valve", svc.resolve(steamGame)?.developer)
        assertEquals(1, calls)
    }

    @Test fun `steam info never touches the network while downloads are off`() = runBlocking {
        val dir = Files.createTempDirectory("info").toFile()
        var calls = 0
        val svc = service(dir, enabled = false, InfoFetcher { calls++; InfoFetch.Body(steamBody) })
        assertNull(svc.resolve(steamGame))
        assertEquals(0, calls)
    }

    @Test fun `transient failure is not cached and a stale entry survives it`() = runBlocking {
        val dir = Files.createTempDirectory("info").toFile()
        var time = 1_000L
        var online = true
        val fetcher = InfoFetcher { if (online) InfoFetch.Body(steamBody) else InfoFetch.Failed }
        val svc = service(dir, enabled = true, fetcher) { time }
        assertEquals("Valve", svc.resolve(steamGame)?.developer)
        time += GameInfoService.POSITIVE_TTL_MS + 1
        online = false
        assertEquals("Valve", svc.resolve(steamGame)?.developer) // vencido + sem rede: mantém o que já tinha
    }

    @Test fun `unknown steam app is remembered for a day instead of asked every time`() = runBlocking {
        val dir = Files.createTempDirectory("info").toFile()
        var calls = 0
        val svc = service(dir, enabled = true, InfoFetcher { calls++; InfoFetch.NotFound })
        assertNull(svc.resolve(steamGame))
        assertNull(svc.resolve(steamGame))
        assertEquals(1, calls)
    }

    @Test fun `manual games have no remote info`() = runBlocking {
        val dir = Files.createTempDirectory("info").toFile()
        val svc = service(dir, enabled = true, InfoFetcher { error("não deve consultar") })
        assertNull(svc.resolve(PcGame("manual_1", "Meu jogo", GamePlatform.MANUAL)))
    }

    private fun steamSoftware(type: String, genreIds: List<Int>) =
        """{"9":{"success":true,"data":{"type":"$type","short_description":"x","genres":[${genreIds.joinToString(",") { """{"id":"$it","description":"g"}""" }}]}}}"""

    @Test fun `steam classifies software by type and by software-only genres`() {
        // OBS: tipo "game" mas só gêneros de utilidade/produção de vídeo
        assertEquals(false, GameInfoService.parseSteam(steamSoftware("game", listOf(57, 59)), "9")?.isGame)
        // jogo comum, ainda que misture um gênero de software
        assertEquals(true, GameInfoService.parseSteam(steamSoftware("game", listOf(1, 57)), "9")?.isGame)
        assertEquals(true, GameInfoService.parseSteam(steamSoftware("game", emptyList()), "9")?.isGame)
        assertEquals(false, GameInfoService.parseSteam(steamSoftware("dlc", listOf(1)), "9")?.isGame)
    }

    @Test fun `classification comes from the disk cache without touching the network`() = runBlocking {
        val dir = Files.createTempDirectory("info").toFile()
        var calls = 0
        val obs = """{"1905180":{"success":true,"data":{"type":"game","genres":[{"id":"57","description":"Utilidades"}]}}}"""
        val game = PcGame("steam_1905180", "OBS Studio", GamePlatform.STEAM)
        val svc = service(dir, enabled = true, InfoFetcher { calls++; InfoFetch.Body(obs) })
        assertNull(svc.cached(game)) // ainda não sabe
        assertEquals(false, svc.classify(game)) // consulta uma vez
        assertEquals(false, svc.cached(game)) // depois responde do disco
        assertEquals(1, calls)
    }

    @Test fun `cache entry from before classification existed is refetched once`() = runBlocking {
        val dir = Files.createTempDirectory("info").toFile()
        java.io.File(dir, "steam_9.json").writeText("""{"fetchedAt":1000,"info":{"description":"antigo","genres":[],"modes":[]}}""")
        var calls = 0
        val svc = service(dir, enabled = true, InfoFetcher { calls++; InfoFetch.Body(steamSoftware("game", listOf(1))) })
        assertEquals(true, svc.classify(PcGame("steam_9", "Algo", GamePlatform.STEAM)))
        assertEquals(1, calls)
    }

    @Test fun `unclassified items stay visible`() = runBlocking {
        val dir = Files.createTempDirectory("info").toFile()
        val svc = service(dir, enabled = false, InfoFetcher { InfoFetch.Failed })
        assertNull(svc.classify(PcGame("steam_5", "Jogo", GamePlatform.STEAM)))
    }
}
