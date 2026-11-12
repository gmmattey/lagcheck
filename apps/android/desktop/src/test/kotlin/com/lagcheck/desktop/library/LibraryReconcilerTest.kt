package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.repository.LibraryReconciler
import com.lagcheck.desktop.library.scanner.ScanResult
import kotlin.test.*

class LibraryReconcilerTest {
    private val steam = GamePlatform.STEAM
    private val epic = GamePlatform.EPIC_GAMES
    private fun steamGame(id: String, title: String, dir: String? = null) = PcGame(id, title, steam, installDirectory = dir)
    private fun found(vararg g: PcGame, unreachable: List<String> = emptyList(), unreadable: Set<String> = emptySet(), incomplete: Boolean = false) =
        ScanResult.Found(g.toList(), unreachable, unreadable, incomplete)

    @Test
    fun jogoNovoEntra() {
        val out = LibraryReconciler.reconcile(emptyList(), listOf(steam to found(steamGame("steam_1", "A"))))
        assertEquals(listOf("steam_1"), out.map { it.id })
    }

    @Test
    fun jogoQueSumiuDeVarreduraBemSucedidaViraConhecidoNaoInstalado() {
        val known = listOf(steamGame("steam_1", "A").copy(isFavorite = true), steamGame("steam_2", "B"))
        val out = LibraryReconciler.reconcile(known, listOf(steam to found(steamGame("steam_2", "B"))))
        val a = out.first { it.id == "steam_1" }
        assertFalse(a.isInstalled)
        assertTrue(a.isFavorite) // não apaga dado do usuário
        assertTrue(out.first { it.id == "steam_2" }.isInstalled)
    }

    @Test
    fun launcherIndisponivelNaoRemoveNada() {
        val known = listOf(steamGame("steam_1", "A"))
        val out = LibraryReconciler.reconcile(known, listOf(steam to ScanResult.Unavailable("Steam não encontrada")))
        assertEquals(known, out)
    }

    @Test
    fun varreduraSoAfetaAPropriaPlataforma() {
        val known = listOf(steamGame("steam_1", "A"), PcGame("epic_x", "X", epic))
        val out = LibraryReconciler.reconcile(known, listOf(steam to found()))
        assertFalse(out.first { it.id == "steam_1" }.isInstalled)
        assertTrue(out.first { it.id == "epic_x" }.isInstalled)
    }

    @Test
    fun discoDesconectadoNaoContaComoRemocao() {
        val known = listOf(steamGame("steam_1", "A", dir = "D:\\SteamLibrary\\steamapps\\common\\A"), steamGame("steam_2", "B", dir = "C:\\Steam\\steamapps\\common\\B"))
        val out = LibraryReconciler.reconcile(known, listOf(steam to found(unreachable = listOf("D:\\SteamLibrary"))))
        assertTrue(out.first { it.id == "steam_1" }.isInstalled) // disco D: fora do ar
        assertFalse(out.first { it.id == "steam_2" }.isInstalled) // disco C: lido e o jogo não está lá
    }

    @Test
    fun entradaIlegivelOuIncompletaNaoContaComoRemocao() {
        val known = listOf(steamGame("steam_1", "A"), steamGame("steam_2", "B"))
        val unreadable = LibraryReconciler.reconcile(known, listOf(steam to found(unreadable = setOf("steam_1"))))
        assertTrue(unreadable.first { it.id == "steam_1" }.isInstalled)
        assertFalse(unreadable.first { it.id == "steam_2" }.isInstalled)

        val incomplete = LibraryReconciler.reconcile(known, listOf(steam to found(incomplete = true)))
        assertTrue(incomplete.all { it.isInstalled })
    }

    @Test
    fun instalacaoAlteradaAtualizaDadosEPreservaHistorico() {
        val old = steamGame("steam_1", "A", dir = "C:\\old").copy(lastLaunchedEpochMs = 7, playTimeMinutes = 90)
        val out = LibraryReconciler.reconcile(listOf(old), listOf(steam to found(steamGame("steam_1", "A Renomeado", dir = "D:\\new"))))
        val g = out.single()
        assertEquals("A Renomeado", g.title)
        assertEquals("D:\\new", g.installDirectory)
        assertEquals(7L, g.lastLaunchedEpochMs)
        assertEquals(90L, g.playTimeMinutes)
    }

    @Test
    fun jogoReinstaladoVoltaAInstalado() {
        val gone = steamGame("steam_1", "A").copy(isInstalled = false)
        val out = LibraryReconciler.reconcile(listOf(gone), listOf(steam to found(steamGame("steam_1", "A"))))
        assertTrue(out.single().isInstalled)
    }

    @Test
    fun jogoManualNuncaEMexidoPelasVarreduras() {
        val manual = PcGame("manual_1", "Meu jogo", GamePlatform.MANUAL)
        val out = LibraryReconciler.reconcile(listOf(manual), listOf(steam to found(), epic to found()))
        assertEquals(listOf(manual), out)
    }

    @Test
    fun deduplicaPorTituloNormalizadoEntrePlataformas() {
        val games = listOf(
            PcGame("epic_x", "Fall Guys™", epic, isFavorite = true, lastLaunchedEpochMs = 50),
            steamGame("steam_9", "FALL GUYS").copy(lastLaunchedEpochMs = 10),
        )
        val view = LibraryReconciler.dedupe(games)
        assertEquals(1, view.size)
        val g = view.single()
        assertEquals("steam_9", g.id) // Steam vence a Epic
        assertEquals(listOf("epic_x"), g.alsoIds)
        assertTrue(g.isFavorite)
        assertEquals(50L, g.lastLaunchedEpochMs)
    }

    @Test
    fun deduplicaPorPastaDeInstalacaoMesmoComTitulosDiferentes() {
        val games = listOf(
            PcGame("epic_a", "Jogo X", epic, installDirectory = "D:\\Games\\X\\"),
            PcGame("xbox_a", "Jogo X: Edição Completa", GamePlatform.XBOX, installDirectory = "d:/games/x"),
        )
        assertEquals(1, LibraryReconciler.dedupe(games).size)
    }

    @Test
    fun instaladoVenceNaoInstaladoNaDeduplicacao() {
        val games = listOf(steamGame("steam_1", "A").copy(isInstalled = false), PcGame("epic_1", "A", epic))
        assertEquals("epic_1", LibraryReconciler.dedupe(games).single().id)
    }

    @Test
    fun titulosDiferentesNaoSaoMesclados() {
        val games = listOf(steamGame("steam_1", "Call of Duty"), steamGame("steam_2", "Call of Duty: Warzone"))
        assertEquals(2, LibraryReconciler.dedupe(games).size)
    }

    @Test
    fun dedupeEDeterministicoIndependenteDaOrdem() {
        val a = PcGame("epic_x", "Jogo", epic)
        val b = steamGame("steam_x", "Jogo")
        assertEquals(LibraryReconciler.dedupe(listOf(a, b)), LibraryReconciler.dedupe(listOf(b, a)))
    }
}
