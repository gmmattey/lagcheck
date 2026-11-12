package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.launcher.GameLaunchResult
import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.network.CatalogGame
import com.lagcheck.desktop.library.network.NetworkSupportResolver
import com.lagcheck.desktop.library.scanner.ScanResult
import com.lagcheck.desktop.library.repository.LibraryFilter
import com.lagcheck.desktop.library.repository.LibraryRepository
import com.lagcheck.desktop.library.repository.LibraryStore
import com.lagcheck.desktop.library.scanner.LibraryScanner
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import java.nio.file.Files
import java.nio.file.Path
import kotlin.test.*

class LibraryRepositoryTest {
    private fun withDir(block: (Path) -> Unit) {
        val dir = Files.createTempDirectory("lc_repo")
        try { block(dir) } finally { dir.toFile().deleteRecursively() }
    }

    private val scope = CoroutineScope(Dispatchers.Unconfined)

    private fun LibraryRepository.scan() = runBlocking { rescan().join() }

    private fun repo(
        dir: Path,
        scanners: List<LibraryScanner>,
        launcher: (com.lagcheck.desktop.library.model.PcGame) -> GameLaunchResult = { GameLaunchResult.Success("ok") },
        clock: () -> Long = { 1_000L },
    ) = LibraryRepository(
        scope = scope, scanners = scanners, store = LibraryStore(dir.resolve("state.properties")),
        ioDispatcher = Dispatchers.Unconfined, launcher = launcher, clock = clock, autoScan = false,
    )

    @Test
    fun bibliotecaVaziaNaoTemJogoNemDestaque() {
        withDir { dir ->
            val r = repo(dir, listOf(FakeScanner(emptyList())))
            r.scan()
            assertTrue(r.games.isEmpty())
            assertNull(r.selectedGame)
            assertTrue(r.hasScanned)
            assertFalse(r.isScanning)
        }
    }

    @Test
    fun scannerComFalhaNaoDerrubaOsOutros() {
        withDir { dir ->
            val r = repo(dir, listOf(FakeScanner(emptyList(), fail = true), FakeScanner(listOf(TestGames.cs2))))
            r.scan()
            assertEquals(listOf(TestGames.cs2.id), r.games.map { it.id })
        }
    }

    @Test
    fun destaquePadraoSegueARegraEEscolhaDoUsuarioTemPrioridade() {
        withDir { dir ->
            val r = repo(dir, listOf(FakeScanner(listOf(TestGames.cs2, TestGames.cities)), FakeScanner(listOf(TestGames.fallGuys), platform = GamePlatform.EPIC_GAMES)))
            r.scan()
            assertEquals(TestGames.cities.id, r.selectedGame?.id) // ordem por título
            r.selectGame(r.games.first { it.id == TestGames.fallGuys.id })
            assertEquals(TestGames.fallGuys.id, r.selectedGame?.id)
        }
    }

    @Test
    fun favoritoSobreviveAReabrirOApp() {
        withDir { dir ->
            val scanners = listOf(FakeScanner(listOf(TestGames.cs2)), FakeScanner(listOf(TestGames.fallGuys), platform = GamePlatform.EPIC_GAMES))
            val first = repo(dir, scanners)
            first.scan()
            first.toggleFavorite(first.games.first { it.id == TestGames.cs2.id })

            val second = repo(dir, scanners)
            second.scan()
            assertTrue(second.games.first { it.id == TestGames.cs2.id }.isFavorite)
            assertFalse(second.games.first { it.id == TestGames.fallGuys.id }.isFavorite)

            second.toggleFavorite(second.games.first { it.id == TestGames.cs2.id })
            val third = repo(dir, scanners)
            third.scan()
            assertFalse(third.games.first { it.id == TestGames.cs2.id }.isFavorite)
        }
    }

    @Test
    fun jogarRegistraUltimoIniciadoEViraDestaqueNaProximaAbertura() {
        withDir { dir ->
            val scanners = listOf(FakeScanner(listOf(TestGames.cs2, TestGames.cities)), FakeScanner(listOf(TestGames.fallGuys), platform = GamePlatform.EPIC_GAMES))
            val first = repo(dir, scanners, clock = { 5_000L })
            first.scan()
            val result = first.launch(first.games.first { it.id == TestGames.fallGuys.id })
            assertTrue(result is GameLaunchResult.Success)
            assertEquals("ok", first.launchMessage)

            val second = repo(dir, scanners)
            second.scan()
            assertEquals(TestGames.fallGuys.id, second.selectedGame?.id)
            assertEquals(5_000L, second.selectedGame?.lastLaunchedEpochMs)
        }
    }

    @Test
    fun falhaAoIniciarNaoRegistraUltimoIniciado() {
        withDir { dir ->
            val r = repo(dir, listOf(FakeScanner(listOf(TestGames.cs2))), launcher = { GameLaunchResult.Failure("sem launcher") })
            r.scan()
            r.launch(r.games.first())
            assertEquals("sem launcher", r.launchMessage)
            assertNull(r.games.first().lastLaunchedEpochMs)
        }
    }

    @Test
    fun filtrosEBuscaFuncionamSobreJogosReais() {
        withDir { dir ->
            val r = repo(dir, listOf(
                FakeScanner(listOf(TestGames.cs2, TestGames.cities, TestGames.apex)),
                FakeScanner(listOf(TestGames.fallGuys), platform = GamePlatform.EPIC_GAMES),
            ))
            r.scan()

            r.searchQuery = "counter"
            assertEquals(listOf(TestGames.cs2.id), r.filteredGames.map { it.id })
            r.searchQuery = ""

            r.filter = LibraryFilter.STEAM
            assertTrue(r.filteredGames.all { it.platform == GamePlatform.STEAM })
            r.filter = LibraryFilter.EPIC
            assertEquals(listOf(TestGames.fallGuys.id), r.filteredGames.map { it.id })
            r.filter = LibraryFilter.ALL
            assertTrue(r.filteredGames.any { it.id == TestGames.apex.id }) // conhecido, não instalado
            r.filter = LibraryFilter.INSTALLED
            assertFalse(r.filteredGames.any { it.id == TestGames.apex.id })
            r.filter = LibraryFilter.FAVORITES
            assertTrue(r.filteredGames.isEmpty())
        }
    }

    @Test
    fun recentesMostraSomenteInstaladosEOrdenaPelaUltimaAtividadeConfiavel() {
        withDir { dir ->
            val cs2 = TestGames.cs2.copy(lastPlayedEpochMs = 100)
            val cities = TestGames.cities.copy(lastPlayedEpochMs = 200)
            val fallGuys = TestGames.fallGuys.copy(lastPlayedEpochMs = 300)
            val r = repo(dir, listOf(
                FakeScanner(listOf(cs2, cities)),
                FakeScanner(listOf(fallGuys), platform = GamePlatform.EPIC_GAMES),
            ), clock = { 400 })
            r.scan()
            r.launch(r.games.first { it.id == cs2.id })

            r.filter = LibraryFilter.RECENT
            assertEquals(listOf(cs2.id, fallGuys.id, cities.id), r.filteredGames.map { it.id })
        }
    }

    @Test
    fun jogoDesinstaladoContinuaConhecidoENaoAbre() {
        withDir { dir ->
            val scanner = MutableScanner(ScanResult.Found(listOf(TestGames.cs2, TestGames.cities)))
            var launched = 0
            val r = repo(dir, listOf(scanner), launcher = { launched++; GameLaunchResult.Success("ok") })
            r.scan()
            r.toggleFavorite(r.games.first { it.id == TestGames.cs2.id })

            scanner.result = ScanResult.Found(listOf(TestGames.cities)) // cs2 desinstalado
            r.scan()
            val cs2 = r.games.first { it.id == TestGames.cs2.id }
            assertFalse(cs2.isInstalled)
            assertTrue(cs2.isFavorite)
            assertEquals(1, r.installedCount)
            assertTrue(r.launch(cs2) is GameLaunchResult.Failure)
            assertEquals(0, launched)
            assertNull(r.games.first { it.id == TestGames.cs2.id }.lastLaunchedEpochMs)
        }
    }

    @Test
    fun launcherForaDoArNaoApagaABiblioteca() {
        withDir { dir ->
            val scanner = MutableScanner(ScanResult.Found(listOf(TestGames.cs2)))
            val r = repo(dir, listOf(scanner))
            r.scan()
            scanner.result = ScanResult.Unavailable("Steam não encontrada")
            r.scan()
            assertTrue(r.games.single().isInstalled)
        }
    }

    @Test
    fun conhecidosSobrevivemAReabrirMesmoComLauncherFora() {
        withDir { dir ->
            val first = repo(dir, listOf(MutableScanner(ScanResult.Found(listOf(TestGames.cs2, TestGames.cities)))))
            first.scan()

            val second = repo(dir, listOf(MutableScanner(ScanResult.Unavailable("fora"))))
            // Sem varredura bem-sucedida, a lista vem do que já era conhecido.
            assertEquals(setOf(TestGames.cs2.id, TestGames.cities.id), second.games.map { it.id }.toSet())
            assertTrue(second.games.all { it.isInstalled })
            assertNotNull(second.selectedGame)
        }
    }

    @Test
    fun duplicataEntrePlataformasApareceUmaVezEFavoritoVaiNoGrupo() {
        withDir { dir ->
            val steamCopy = TestGames.fallGuys.copy(id = "steam_77", platform = GamePlatform.STEAM)
            val r = repo(dir, listOf(
                MutableScanner(ScanResult.Found(listOf(steamCopy))),
                MutableScanner(ScanResult.Found(listOf(TestGames.fallGuys)), GamePlatform.EPIC_GAMES),
            ))
            r.scan()
            assertEquals(1, r.games.size)
            val g = r.games.single()
            assertEquals("steam_77", g.id)
            assertEquals(listOf(TestGames.fallGuys.id), g.alsoIds)

            r.toggleFavorite(g)
            assertTrue(r.games.single().isFavorite)
            r.toggleFavorite(r.games.single())
            assertFalse(r.games.single().isFavorite) // desfavoritar limpa todas as cópias
        }
    }

    @Test
    fun suporteDeRedeVemDoResolvedorECatalogoNaoDoScanner() {
        withDir { dir ->
            val resolver = NetworkSupportResolver({ listOf(CatalogGame("cs2", "Counter-Strike 2")) })
            val r = LibraryRepository(
                scope = scope, scanners = listOf(FakeScanner(listOf(TestGames.cs2, TestGames.fallGuys))),
                store = LibraryStore(dir.resolve("state.properties")), networkResolver = resolver,
                ioDispatcher = Dispatchers.Unconfined, autoScan = false,
            )
            r.scan()
            r.filter = LibraryFilter.ALL
            assertTrue(r.games.first { it.id == TestGames.cs2.id }.networkSupport is GameNetworkSupport.LagcheckSupported)
            assertTrue(r.games.first { it.id == TestGames.fallGuys.id }.networkSupport is GameNetworkSupport.GeneralConnectionOnly)
        }
    }
}
