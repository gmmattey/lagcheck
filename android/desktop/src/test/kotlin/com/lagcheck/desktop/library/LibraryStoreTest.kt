package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.repository.LibraryStore
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
}
