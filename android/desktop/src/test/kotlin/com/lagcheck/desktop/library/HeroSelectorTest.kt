package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.repository.HeroSelector
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class HeroSelectorTest {
    private val a = TestGames.cs2
    private val b = TestGames.fallGuys
    private val c = TestGames.cities

    @Test
    fun semJogosNaoHaDestaque() {
        assertNull(HeroSelector.pick(emptyList()))
    }

    @Test
    fun jogoNaoInstaladoNuncaViraDestaque() {
        assertNull(HeroSelector.pick(listOf(TestGames.apex)))
        assertEquals(a.id, HeroSelector.pick(listOf(TestGames.apex, a))?.id)
    }

    @Test
    fun ultimoIniciadoPeloLagcheckTemPrioridade() {
        val games = listOf(
            a.copy(lastPlayedEpochMs = 9_000, installedAtEpochMs = 9_000),
            b.copy(lastLaunchedEpochMs = 1_000),
            c.copy(lastLaunchedEpochMs = 2_000),
        )
        assertEquals(c.id, HeroSelector.pick(games)?.id)
    }

    @Test
    fun semInicioPeloLagcheckUsaUltimoExecutado() {
        val games = listOf(a.copy(installedAtEpochMs = 9_000), b.copy(lastPlayedEpochMs = 100), c.copy(lastPlayedEpochMs = 50))
        assertEquals(b.id, HeroSelector.pick(games)?.id)
    }

    @Test
    fun semHistoricoUsaInstaladoMaisRecentemente() {
        val games = listOf(a.copy(installedAtEpochMs = 10), b.copy(installedAtEpochMs = 30), c)
        assertEquals(b.id, HeroSelector.pick(games)?.id)
    }

    @Test
    fun semNenhumDadoOrdenaPorTituloDeFormaDeterministica() {
        // "Cities..." < "Counter-Strike 2" < "Fall Guys", independente da ordem de entrada
        assertEquals(c.id, HeroSelector.pick(listOf(b, a, c))?.id)
        assertEquals(c.id, HeroSelector.pick(listOf(c, a, b))?.id)
    }
}
