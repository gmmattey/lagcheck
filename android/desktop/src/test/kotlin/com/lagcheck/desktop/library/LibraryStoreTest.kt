package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.repository.LibraryStore
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import java.nio.file.Files
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class LibraryStoreTest {
    private fun tempDir() = Files.createTempDirectory("lc_store")

    @Test
    fun salvaECarregaFavoritosEUltimoIniciado() {
        val dir = tempDir()
        try {
            val store = LibraryStore(dir.resolve("state.properties"))
            val snap = LibraryStore.Snapshot(setOf("steam_730", "epic_Sugar", "id com espaço:e=sinais"), mapOf("steam_730" to 1234L))
            assertTrue(store.save(snap))
            assertEquals(snap, LibraryStore(dir.resolve("state.properties")).load())
        } finally { dir.toFile().deleteRecursively() }
    }

    @Test
    fun arquivoInexistenteDevolveVazio() {
        val dir = tempDir()
        try {
            assertEquals(LibraryStore.Snapshot(), LibraryStore(dir.resolve("nao-existe.properties")).load())
        } finally { dir.toFile().deleteRecursively() }
    }

    @Test
    fun arquivoCorrompidoNaoDerrubaNada() {
        val dir = tempDir()
        try {
            val f = dir.resolve("state.properties")
            Files.write(f, byteArrayOf(0x5C, 0x75, 0x00, 0x7F)) // "\u" inválido
            assertEquals(LibraryStore.Snapshot(), LibraryStore(f).load())
        } finally { dir.toFile().deleteRecursively() }
    }

    @Test
    fun migraFavoritosDoFormatoAntigoSemApagarOArquivoAntigo() {
        val dir = tempDir()
        try {
            val legacy = dir.resolve("orbit_prefs.properties")
            Files.writeString(legacy, "fav:steam_730\nfav:epic_Sugar")
            val store = LibraryStore(dir.resolve("library-state.properties"), legacy)
            assertEquals(setOf("steam_730", "epic_Sugar"), store.load().favorites)
            assertTrue(Files.exists(legacy))
            // A partir daí lê o arquivo novo, não o antigo.
            assertEquals(setOf("steam_730", "epic_Sugar"), LibraryStore(dir.resolve("library-state.properties")).load().favorites)
        } finally { dir.toFile().deleteRecursively() }
    }

    @Test
    fun persisteJogosConhecidosComDadosOpcionais() {
        val dir = tempDir()
        try {
            val store = LibraryStore(dir.resolve("state.properties"))
            val games = listOf(
                PcGame("steam_730", "Counter-Strike 2", GamePlatform.STEAM, installDirectory = "C:\\Steam\\x", launchUri = "steam://rungameid/730", isInstalled = false, lastPlayedEpochMs = 5),
                PcGame("epic_a", "Jogo = com : símbolos", GamePlatform.EPIC_GAMES, executablePath = "C:\\g.exe"),
            )
            store.save(LibraryStore.Snapshot(knownGames = games))
            val back = LibraryStore(dir.resolve("state.properties")).load().knownGames
            assertEquals(games.map { it.id }, back.map { it.id })
            assertEquals(games[0], back[0])
            assertEquals("Jogo = com : símbolos", back[1].title)
            assertEquals("C:\\g.exe", back[1].executablePath)
            assertTrue(back[1].isInstalled)
        } finally { dir.toFile().deleteRecursively() }
    }

    @Test
    fun entradaDeJogoInvalidaEIgnoradaSemDerrubarAsOutras() {
        val dir = tempDir()
        try {
            val f = dir.resolve("state.properties")
            Files.writeString(f, "game.0.id=a\ngame.0.title=A\ngame.0.platform=NAO_EXISTE\ngame.1.id=b\ngame.1.title=B\ngame.1.platform=STEAM\ngame.2.id=c\n")
            assertEquals(listOf("b"), LibraryStore(f).load().knownGames.map { it.id })
        } finally { dir.toFile().deleteRecursively() }
    }
}
