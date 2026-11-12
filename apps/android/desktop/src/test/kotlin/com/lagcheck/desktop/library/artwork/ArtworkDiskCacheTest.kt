package com.lagcheck.desktop.library.artwork

import java.nio.file.Files
import java.nio.file.attribute.FileTime
import kotlin.test.*

class ArtworkDiskCacheTest {
    @Test
    fun guardaERecuperaPorJogoETipo() = withTempDir { dir ->
        val c = ArtworkDiskCache(dir.resolve("c"))
        assertNull(c.get("steam_1", ArtworkType.COVER))
        val p = c.put("steam_1", ArtworkType.COVER, jpegBytes())
        assertEquals(p, c.get("steam_1", ArtworkType.COVER))
        assertNull(c.get("steam_1", ArtworkType.HERO))
        assertNull(c.get("steam_2", ArtworkType.COVER))
    }

    @Test
    fun idComSimbolosViraNomeDeArquivoSeguro() = withTempDir { dir ->
        val c = ArtworkDiskCache(dir)
        val p = c.put("xbox_Pub.Game_8wekyb3d8bbwe/../x", ArtworkType.COVER, jpegBytes())
        assertEquals(dir, p.parent)
        assertTrue(Files.isRegularFile(p))
    }

    @Test
    fun falhaNaoEncontradaDuraDiasEPassageiraDuraMinutos() = withTempDir { dir ->
        var now = 1_000_000L
        val c = ArtworkDiskCache(dir, clock = { now }, notFoundTtlMs = 7 * 86_400_000L, failureTtlMs = 15 * 60_000L)
        c.markMiss("a", ArtworkType.COVER, permanent = true)
        c.markMiss("b", ArtworkType.COVER, permanent = false)
        assertTrue(c.isMissActive("a", ArtworkType.COVER))
        assertTrue(c.isMissActive("b", ArtworkType.COVER))
        now += 16 * 60_000L
        assertTrue(c.isMissActive("a", ArtworkType.COVER))
        assertFalse(c.isMissActive("b", ArtworkType.COVER))
        now += 7 * 86_400_000L
        assertFalse(c.isMissActive("a", ArtworkType.COVER))
    }

    @Test
    fun baixarComSucessoLimpaOLembreteDeFalha() = withTempDir { dir ->
        val c = ArtworkDiskCache(dir)
        c.markMiss("a", ArtworkType.COVER, permanent = true)
        c.put("a", ArtworkType.COVER, jpegBytes())
        assertFalse(c.isMissActive("a", ArtworkType.COVER))
    }

    @Test
    fun respeitaOTetoRemovendoOMenosUsado() = withTempDir { dir ->
        var now = 1_000L
        val c = ArtworkDiskCache(dir, maxBytes = 1_000, clock = { now })
        c.put("old", ArtworkType.COVER, jpegBytes(396)) // 400 bytes
        now += 10; c.put("mid", ArtworkType.COVER, jpegBytes(396))
        now += 10
        assertNotNull(c.get("old", ArtworkType.COVER)) // "old" é usado de novo e passa a ser o mais recente
        now += 10; c.put("new", ArtworkType.COVER, jpegBytes(396)) // 1200 > 1000: sai o menos usado ("mid")
        assertNull(c.get("mid", ArtworkType.COVER))
        assertNotNull(c.get("old", ArtworkType.COVER))
        assertNotNull(c.get("new", ArtworkType.COVER))
        assertTrue(c.totalImageBytes() <= 1_000)
    }

    @Test
    fun imagemMaiorQueOTetoNaoApagaASiMesma() = withTempDir { dir ->
        val c = ArtworkDiskCache(dir, maxBytes = 100)
        val p = c.put("big", ArtworkType.HERO, jpegBytes(500))
        assertTrue(Files.isRegularFile(p))
    }

    @Test
    fun clearApagaImagensELembretesSoDaqueleJogo() = withTempDir { dir ->
        val c = ArtworkDiskCache(dir)
        c.put("a", ArtworkType.COVER, jpegBytes()); c.put("a", ArtworkType.HERO, jpegBytes())
        c.markMiss("a", ArtworkType.ICON, permanent = true)
        c.put("b", ArtworkType.COVER, jpegBytes())
        c.clear("a")
        assertNull(c.get("a", ArtworkType.COVER)); assertNull(c.get("a", ArtworkType.HERO))
        assertFalse(c.isMissActive("a", ArtworkType.ICON))
        assertNotNull(c.get("b", ArtworkType.COVER))
    }

    @Test
    fun pastaInexistenteOuSemPermissaoNaoLancaNaLeitura() = withTempDir { dir ->
        val c = ArtworkDiskCache(dir.resolve("nunca-criada"))
        assertNull(c.get("a", ArtworkType.COVER))
        assertFalse(c.isMissActive("a", ArtworkType.COVER))
        assertEquals(0L, c.totalImageBytes())
        c.clear("a")
    }
}
