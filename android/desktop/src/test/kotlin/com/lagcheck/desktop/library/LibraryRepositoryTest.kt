package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.launcher.GameLaunchResult
import com.lagcheck.desktop.library.model.GamePlatform
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
            val r = repo(dir, listOf(FakeScanner(listOf(TestGames.cs2, TestGames.fallGuys, TestGames.cities))))
            r.scan()
            assertEquals(TestGames.cities.id, r.selectedGame?.id) // ordem por título
            r.selectGame(r.games.first { it.id == TestGames.fallGuys.id })
            assertEquals(TestGames.fallGuys.id, r.selectedGame?.id)
        }
    }

    @Test
    fun favoritoSobreviveAReabrirOApp() {
        withDir { dir ->
            val scanners = listOf(FakeScanner(listOf(TestGames.cs2, TestGames.fallGuys)))
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
            val scanners = listOf(FakeScanner(listOf(TestGames.cs2, TestGames.fallGuys, TestGames.cities)))
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
            val r = repo(dir, listOf(FakeScanner(listOf(TestGames.cs2, TestGames.fallGuys, TestGames.cities, TestGames.apex))))
            r.scan()

            r.searchQuery = "counter"
            assertEquals(listOf(TestGames.cs2.id), r.filteredGames.map { it.id })
            r.searchQuery = ""

            r.filter = LibraryFilter.STEAM
            assertTrue(r.filteredGames.all { it.platform == GamePlatform.STEAM })
            r.filter = LibraryFilter.EPIC
            assertEquals(listOf(TestGames.fallGuys.id), r.filteredGames.map { it.id })
            r.filter = LibraryFilter.INSTALLED
            assertFalse(r.filteredGames.any { it.id == TestGames.apex.id })
            r.filter = LibraryFilter.FAVORITES
            assertTrue(r.filteredGames.isEmpty())
        }
    }
}
