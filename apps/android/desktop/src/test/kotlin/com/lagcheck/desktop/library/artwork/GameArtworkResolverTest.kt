package com.lagcheck.desktop.library.artwork

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.runBlocking
import java.nio.file.Files
import java.nio.file.Path
import kotlin.test.*

class GameArtworkResolverTest {
    private val remote = FixedSource(listOf(ArtworkCandidate.Remote("https://cdn.example/a.jpg"), ArtworkCandidate.Remote("https://cdn.example/b.jpg")))

    private fun resolver(
        dir: Path, fetcher: FakeFetcher, local: List<ArtworkSource> = emptyList(), remoteSources: List<ArtworkSource> = listOf(remote),
        enabled: () -> Boolean = { true }, cache: ArtworkDiskCache = ArtworkDiskCache(dir.resolve("cache")),
    ) = GameArtworkResolver(local, remoteSources, cache, fetcher, enabled, Dispatchers.IO)

    @Test
    fun baixaGuardaEDepoisUsaOCacheSemNovoDownload() = withTempDir { dir ->
        val f = FakeFetcher({ FetchResult.Bytes(jpegBytes()) })
        val r = resolver(dir, f)
        val first = runBlocking { r.resolve(steamGame, ArtworkType.COVER) }
        assertTrue(first is ArtworkResult.Available)
        val second = runBlocking { r.resolve(steamGame, ArtworkType.COVER) }
        assertEquals(first, second)
        assertEquals(2, f.calls.size)
    }

    @Test
    fun arteLocalEntraNoCacheSemRedeQuandoNaoHaFonteRemota() = withTempDir { dir ->
        val img = dir.resolve("launcher.jpg").also { Files.write(it, jpegBytes()) }
        val f = FakeFetcher({ FetchResult.Bytes(jpegBytes()) })
        val r = resolver(dir, f, local = listOf(FixedSource(listOf(ArtworkCandidate.LocalFile(img)))), remoteSources = emptyList())
        assertTrue(runBlocking { r.resolve(steamGame, ArtworkType.COVER) } is ArtworkResult.Available)
        assertTrue(f.calls.isEmpty())
    }

    @Test
    fun maiorImagemLocalCompativelVenceAFonteQuandoHaDimensoesConfiaveis() = withTempDir { dir ->
        val small = dir.resolve("small.png").also { Files.write(it, pngBytes(1920, 620)) }
        val large = dir.resolve("large.png").also { Files.write(it, pngBytes(3840, 1240)) }
        val wrongShape = dir.resolve("poster.png").also { Files.write(it, pngBytes(3000, 4500)) }
        val source = FixedSource(listOf(ArtworkCandidate.LocalFile(small), ArtworkCandidate.LocalFile(wrongShape), ArtworkCandidate.LocalFile(large)))
        val result = runBlocking { resolver(dir, FakeFetcher(), local = listOf(source), remoteSources = emptyList()).resolve(steamGame, ArtworkType.HERO) }
        assertTrue(result is ArtworkResult.Available && Files.readAllBytes(result.path).toList() == pngBytes(3840, 1240).toList())
    }

    @Test
    fun arquivoLocalQueNaoEImagemEIgnorado() = withTempDir { dir ->
        val fake = dir.resolve("falso.jpg").also { Files.writeString(it, "<html>erro</html> ".repeat(10)) }
        val f = FakeFetcher({ FetchResult.Bytes(jpegBytes()) })
        val r = resolver(dir, f, local = listOf(FixedSource(listOf(ArtworkCandidate.LocalFile(fake), ArtworkCandidate.LocalFile(dir.resolve("naoexiste.jpg"))))))
        val res = runBlocking { r.resolve(steamGame, ArtworkType.COVER) }
        assertTrue(res is ArtworkResult.Available && res.path != fake)
        assertEquals(2, f.calls.size)
    }

    @Test
    fun segundaUrlEUsadaQuandoAPrimeiraNaoExiste() = withTempDir { dir ->
        val f = FakeFetcher({ if (it.endsWith("a.jpg")) FetchResult.NotFound else FetchResult.Bytes(jpegBytes()) })
        val res = runBlocking { resolver(dir, f).resolve(steamGame, ArtworkType.COVER) }
        assertTrue(res is ArtworkResult.Available)
        assertEquals(2, f.calls.size)
    }

    @Test
    fun maiorImagemRemotaCompativelVenceQuandoLojaNaoInformaDimensoes() = withTempDir { dir ->
        val source = FixedSource(listOf(
            ArtworkCandidate.Remote("https://cdn.example/small.png"),
            ArtworkCandidate.Remote("https://cdn.example/poster.png"),
            ArtworkCandidate.Remote("https://cdn.example/large.png"),
        ))
        val fetcher = FakeFetcher(respond = { url -> when {
            url.endsWith("small.png") -> FetchResult.Bytes(pngBytes(1920, 620))
            url.endsWith("poster.png") -> FetchResult.Bytes(pngBytes(3000, 4500))
            else -> FetchResult.Bytes(pngBytes(3840, 1240))
        } })
        val result = runBlocking { resolver(dir, fetcher, remoteSources = listOf(source)).resolve(epicGame, ArtworkType.HERO) } as ArtworkResult.Available
        assertEquals(3, fetcher.calls.size)
        assertEquals(pngBytes(3840, 1240).toList(), Files.readAllBytes(result.path).toList())
    }

    @Test
    fun imagemRemotaSemDimensoesSoEUsadaSeNenhumaCandidataMedidaForCompativel() = withTempDir { dir ->
        val source = FixedSource(listOf(
            ArtworkCandidate.Remote("https://cdn.example/unknown.jpg"),
            ArtworkCandidate.Remote("https://cdn.example/large.png"),
        ))
        val fetcher = FakeFetcher(respond = { url ->
            if (url.endsWith("unknown.jpg")) FetchResult.Bytes(jpegBytes())
            else FetchResult.Bytes(pngBytes(3840, 1240))
        })

        val result = runBlocking { resolver(dir, fetcher, remoteSources = listOf(source)).resolve(epicGame, ArtworkType.HERO) } as ArtworkResult.Available

        assertEquals(2, fetcher.calls.size)
        assertEquals(pngBytes(3840, 1240).toList(), Files.readAllBytes(result.path).toList())
    }

    @Test
    fun maiorImagemEntreCacheLocalERemotoCompativelESelecionada() = withTempDir { dir ->
        val local = dir.resolve("local.png").also { Files.write(it, pngBytes(3840, 1240)) }
        val source = FixedSource(listOf(ArtworkCandidate.Remote("https://cdn.example/remote.png")))
        val fetcher = FakeFetcher(respond = { FetchResult.Bytes(pngBytes(1920, 620)) })
        val result = runBlocking {
            resolver(dir, fetcher, local = listOf(FixedSource(listOf(ArtworkCandidate.LocalFile(local)))), remoteSources = listOf(source))
                .resolve(epicGame, ArtworkType.HERO)
        } as ArtworkResult.Available
        assertEquals(1, fetcher.calls.size)
        assertEquals(pngBytes(3840, 1240).toList(), Files.readAllBytes(result.path).toList())
    }

    @Test
    fun naoEncontradoViraFallbackELembraSemPedirDeNovo() = withTempDir { dir ->
        val f = FakeFetcher({ FetchResult.NotFound })
        val r = resolver(dir, f)
        assertEquals(ArtworkResult.Fallback, runBlocking { r.resolve(steamGame, ArtworkType.HERO) })
        assertEquals(2, f.calls.size)
        assertEquals(ArtworkResult.Fallback, runBlocking { r.resolve(steamGame, ArtworkType.HERO) })
        assertEquals(2, f.calls.size) // não tentou de novo
    }

    @Test
    fun falhaPassageiraTentaDeNovoDepoisDoPrazoCurto() = withTempDir { dir ->
        var now = 0L
        val cache = ArtworkDiskCache(dir.resolve("cache"), clock = { now }, failureTtlMs = 60_000)
        val f = FakeFetcher({ FetchResult.Failed("sem rede") })
        val r = resolver(dir, f, cache = cache)
        assertEquals(ArtworkResult.Fallback, runBlocking { r.resolve(steamGame, ArtworkType.COVER) })
        val after = f.calls.size
        runBlocking { r.resolve(steamGame, ArtworkType.COVER) }
        assertEquals(after, f.calls.size)
        now += 61_000
        f.respond = { FetchResult.Bytes(jpegBytes()) }
        assertTrue(runBlocking { r.resolve(steamGame, ArtworkType.COVER) } is ArtworkResult.Available)
    }

    @Test
    fun respostaQueNaoEImagemNaoEGravadaComoImagem() = withTempDir { dir ->
        val f = FakeFetcher({ FetchResult.Bytes("<html>login</html>".toByteArray().copyOf(100)) })
        val r = resolver(dir, f)
        assertEquals(ArtworkResult.Fallback, runBlocking { r.resolve(steamGame, ArtworkType.COVER) })
        assertEquals(0L, ArtworkDiskCache(dir.resolve("cache")).totalImageBytes())
    }

    @Test
    fun downloadDesligadoNaoUsaRedeMasUsaCacheJaBaixado() = withTempDir { dir ->
        val cache = ArtworkDiskCache(dir.resolve("cache"))
        val f = FakeFetcher({ FetchResult.Bytes(jpegBytes()) })
        var on = true
        val r = resolver(dir, f, enabled = { on }, cache = cache)
        assertTrue(runBlocking { r.resolve(steamGame, ArtworkType.COVER) } is ArtworkResult.Available)
        on = false
        assertTrue(runBlocking { r.resolve(steamGame, ArtworkType.COVER) } is ArtworkResult.Available) // já estava no disco
        assertEquals(ArtworkResult.Fallback, runBlocking { r.resolve(steamGame, ArtworkType.HERO) })
        assertEquals(2, f.calls.size)
    }

    @Test
    fun jogoSemFonteRemotaVaiDiretoParaFallbackSemLembrete() = withTempDir { dir ->
        val f = FakeFetcher()
        val r = resolver(dir, f, remoteSources = listOf(FixedSource(emptyList())))
        assertEquals(ArtworkResult.Fallback, runBlocking { r.resolve(epicGame, ArtworkType.COVER) })
        assertTrue(f.calls.isEmpty())
        assertFalse(ArtworkDiskCache(dir.resolve("cache")).isMissActive(epicGame.id, ArtworkType.COVER))
    }

    @Test
    fun pedidosSimultaneosDaMesmaImagemFazemUmSoDownload() = withTempDir { dir ->
        val f = FakeFetcher({ FetchResult.Bytes(jpegBytes()) }, delayMs = 250)
        val r = resolver(dir, f)
        val results = runBlocking { (1..8).map { async(Dispatchers.Default) { r.resolve(steamGame, ArtworkType.COVER) } }.awaitAll() }
        assertTrue(results.all { it is ArtworkResult.Available })
        assertEquals(2, f.calls.size)
    }

    @Test
    fun atualizarApagaOCacheEBuscaDeNovo() = withTempDir { dir ->
        var n = 0
        val f = FakeFetcher({ n++; FetchResult.Bytes(jpegBytes(100 + n)) })
        val r = resolver(dir, f)
        val a = runBlocking { r.resolve(steamGame, ArtworkType.COVER) } as ArtworkResult.Available
        val sizeBefore = Files.size(a.path)
        r.refresh(steamGame)
        assertNull(ArtworkDiskCache(dir.resolve("cache")).get(steamGame.id, ArtworkType.COVER)) // apagou
        val b = runBlocking { r.resolve(steamGame, ArtworkType.COVER) } as ArtworkResult.Available
        assertEquals(4, f.calls.size)
        assertNotEquals(sizeBefore, Files.size(b.path)) // baixou a versão nova
    }

    @Test
    fun heroAntigoEAtualizadoUmaVezQuandoDownloadEstaLigado() = withTempDir { dir ->
        val cacheDir = dir.resolve("cache")
        Files.createDirectories(cacheDir)
        val oldHero = cacheDir.resolve("${ArtworkDiskCache.key(steamGame.id)}.hero.img")
        Files.write(oldHero, jpegBytes(80))
        val fetcher = FakeFetcher({ FetchResult.Bytes(jpegBytes(300)) })
        val cache = ArtworkDiskCache(cacheDir)
        val resolver = resolver(dir, fetcher, cache = cache)

        val result = runBlocking { resolver.resolve(steamGame, ArtworkType.HERO) } as ArtworkResult.Available
        assertEquals(2, fetcher.calls.size)
        assertNotEquals(oldHero, result.path)
        assertTrue(Files.size(result.path) > Files.size(oldHero))
        runBlocking { resolver.resolve(steamGame, ArtworkType.HERO) }
        assertEquals(2, fetcher.calls.size)
    }

    @Test
    fun heroAntigoPermaneceQuandoUpgradeFalhaOuDownloadEstaDesligado() = withTempDir { dir ->
        val cacheDir = dir.resolve("cache")
        Files.createDirectories(cacheDir)
        val oldHero = cacheDir.resolve("${ArtworkDiskCache.key(steamGame.id)}.hero.img")
        Files.write(oldHero, jpegBytes(80))
        val fetcher = FakeFetcher({ FetchResult.NotFound })
        val cache = ArtworkDiskCache(cacheDir)
        val online = resolver(dir, fetcher, cache = cache)
        assertEquals(ArtworkResult.Available(oldHero), runBlocking { online.resolve(steamGame, ArtworkType.HERO) })
        assertEquals(2, fetcher.calls.size)

        val offline = resolver(dir, FakeFetcher(), enabled = { false }, cache = cache)
        assertEquals(ArtworkResult.Available(oldHero), runBlocking { offline.resolve(steamGame, ArtworkType.HERO) })
    }

    @Test
    fun missLegadoNaoBloqueiaUpgradeDeResolucao() = withTempDir { dir ->
        val cacheDir = dir.resolve("cache")
        Files.createDirectories(cacheDir)
        Files.write(cacheDir.resolve("${ArtworkDiskCache.key(steamGame.id)}.hero.miss"), "9999999999999".toByteArray())
        val fetcher = FakeFetcher({ FetchResult.Bytes(jpegBytes(300)) })
        val result = runBlocking { resolver(dir, fetcher, cache = ArtworkDiskCache(cacheDir)).resolve(steamGame, ArtworkType.HERO) }
        assertTrue(result is ArtworkResult.Available)
        assertEquals(2, fetcher.calls.size)
    }

    @Test
    fun excecaoInesperadaDaFonteViraFallbackENaoDerrubaNada() = withTempDir { dir ->
        val boom = object : ArtworkSource { override fun candidates(game: com.lagcheck.desktop.library.model.PcGame, type: ArtworkType): List<ArtworkCandidate> = error("boom") }
        val r = resolver(dir, FakeFetcher(), local = listOf(boom))
        assertEquals(ArtworkResult.Fallback, runBlocking { r.resolve(steamGame, ArtworkType.COVER) })
    }
}
