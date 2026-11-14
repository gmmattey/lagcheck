package com.lagcheck.desktop.library.artwork

import com.lagcheck.desktop.library.model.PcGame
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import java.util.concurrent.ConcurrentHashMap

/**
 * Encontra a imagem de um jogo, sem depender de interface. Ordem:
 * 1. cache do app (já baixada antes);
 * 2. cache que o próprio launcher já tem neste PC (nada é baixado);
 * 3. imagem oficial da loja, se o download estiver ligado e não houver falha recente registrada;
 * 4. sem imagem: [ArtworkResult.Fallback], e a interface mostra a miniatura neutra com o nome do jogo.
 *
 * Nunca lança por falha de rede ou de disco: o pior resultado é [ArtworkResult.Fallback].
 */
class GameArtworkResolver(
    private val localSources: List<ArtworkSource>,
    private val remoteSources: List<ArtworkSource>,
    private val cache: ArtworkDiskCache,
    private val fetcher: ArtworkFetcher,
    private val remoteEnabled: () -> Boolean = { true },
    ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
    maxParallelDownloads: Int = 3,
    private val maxLocalFileBytes: Long = 8L * 1024 * 1024,
) {
    // A busca roda num escopo próprio: se quem pediu sair da tela (cancelando), o download continua
    // e serve a quem ainda espera a mesma imagem.
    private val scope = CoroutineScope(SupervisorJob() + ioDispatcher)
    private val inFlight = ConcurrentHashMap<String, Deferred<ArtworkResult>>()
    private val downloadGate = Semaphore(maxParallelDownloads)

    suspend fun resolve(game: PcGame, type: ArtworkType): ArtworkResult {
        val key = "${ArtworkDiskCache.key(game.id)}.${type.key}"
        val job = inFlight.computeIfAbsent(key) {
            scope.async(start = CoroutineStart.LAZY) {
                try { load(game, type) } finally { inFlight.remove(key) }
            }
        }
        job.start()
        return job.await()
    }

    /** Apaga o que o app guardou deste jogo e o lembrete de falha, para a próxima busca tentar de novo. */
    fun refresh(game: PcGame) = cache.clear(game.id)

    fun close() = scope.cancel()

    private suspend fun load(game: PcGame, type: ArtworkType): ArtworkResult = try {
        loadUnsafe(game, type)
    } catch (e: kotlinx.coroutines.CancellationException) {
        throw e
    } catch (e: Exception) {
        ArtworkResult.Fallback
    }

    private suspend fun loadUnsafe(game: PcGame, type: ArtworkType): ArtworkResult {
        val compareSources = remoteEnabled()
        cache.get(game.id, type, allowLegacy = !compareSources)?.let { return ArtworkResult.Available(it) }

        val local = resolveLocal(game, type)
        if (!compareSources) return local?.let { ArtworkResult.Available(it.path) } ?: ArtworkResult.Fallback

        val remote = downloadRemote(game, type)
        return when {
            remote != null && local != null && remote.dimensions != null && local.dimensions != null ->
                if (remote.dimensions.pixels > local.dimensions.pixels) ArtworkResult.Available(cache.put(game.id, type, remote.bytes))
                else cacheLocal(game, type, local.path)
            remote != null && local == null -> ArtworkResult.Available(cache.put(game.id, type, remote.bytes))
            remote != null && local?.dimensions == null -> ArtworkResult.Available(cache.put(game.id, type, remote.bytes))
            local != null -> cacheLocal(game, type, local.path)
            else -> cache.getLegacy(game.id, type)?.let(ArtworkResult::Available) ?: ArtworkResult.Fallback
        }
    }

    private data class LocalArtwork(val path: java.nio.file.Path, val dimensions: ImageBytes.Dimensions?)
    private data class RemoteArtwork(val bytes: ByteArray, val dimensions: ImageBytes.Dimensions?)

    private fun cacheLocal(game: PcGame, type: ArtworkType, path: java.nio.file.Path): ArtworkResult = try {
        ArtworkResult.Available(cache.put(game.id, type, java.nio.file.Files.readAllBytes(path)))
    } catch (e: Exception) {
        ArtworkResult.Available(path)
    }

    private suspend fun downloadRemote(game: PcGame, type: ArtworkType): RemoteArtwork? {
        val candidates = remoteSources.flatMap { it.candidates(game, type) }
            .filterIsInstance<ArtworkCandidate.Remote>()
        if (candidates.isEmpty() || cache.isMissActive(game.id, type)) return null

        var transientFailure = false
        // Steam informa dimensões estáveis no nome do asset. Tenta o maior primeiro, sem baixar versões
        // menores só para confirmar o que a própria loja já declarou.
        for (candidate in candidates.filter { it.dimensions != null && isCompatible(it.dimensions, type) }
            .sortedByDescending { it.dimensions!!.pixels }) {
            when (val r = downloadGate.withPermit { fetcher.fetch(candidate.url) }) {
                is FetchResult.Bytes ->
                    if (ImageBytes.looksLikeImage(r.data)) {
                        return RemoteArtwork(r.data, candidate.dimensions)
                    } else transientFailure = true // resposta estranha: tenta de novo mais tarde, não grava como imagem
                is FetchResult.NotFound -> Unit
                is FetchResult.Failed -> transientFailure = true
            }
        }

        // Epic e Microsoft fornecem URLs reais no launcher/catálogo, mas não dimensões confiáveis no
        // metadado. Lê os cabeçalhos dos candidatos daquele jogo e guarda só a maior arte proporcional.
        val measured = mutableListOf<Pair<ByteArray, ImageBytes.Dimensions>>()
        var unmeasured: ByteArray? = null
        for (candidate in candidates.filter { it.dimensions == null }) {
            when (val r = downloadGate.withPermit { fetcher.fetch(candidate.url) }) {
                is FetchResult.Bytes -> if (ImageBytes.looksLikeImage(r.data)) {
                    val dimensions = ImageBytes.dimensions(r.data)
                    if (dimensions == null) unmeasured = unmeasured ?: r.data
                    else if (isCompatible(dimensions, type)) measured += r.data to dimensions
                } else transientFailure = true
                is FetchResult.NotFound -> Unit
                is FetchResult.Failed -> transientFailure = true
            }
        }
        measured.maxByOrNull { (_, dimensions) -> dimensions.pixels }?.let { (bytes, dimensions) ->
            return RemoteArtwork(bytes, dimensions)
        }
        unmeasured?.let { return RemoteArtwork(it, null) }
        cache.markMiss(game.id, type, permanent = !transientFailure)
        return null
    }

    /** Maior imagem local que respeita o formato da tela; cabeçalhos desconhecidos mantêm a ordem da fonte. */
    private fun resolveLocal(game: PcGame, type: ArtworkType): LocalArtwork? {
        val files = localSources.flatMap { source -> source.candidates(game, type) }
            .filterIsInstance<ArtworkCandidate.LocalFile>().map { it.path }
            .filter { ImageBytes.looksLikeImageFile(it, maxLocalFileBytes) }
        val measured = files.mapNotNull { file ->
            ImageBytes.dimensions(file)?.takeIf { dimensions -> isCompatible(dimensions, type) }?.let { file to it }
        }
        return measured.maxByOrNull { (_, dimensions) -> dimensions.pixels }?.let { (path, dimensions) -> LocalArtwork(path, dimensions) }
            ?: files.firstOrNull()?.let { LocalArtwork(it, null) }
    }

    private fun isCompatible(dimensions: ImageBytes.Dimensions, type: ArtworkType): Boolean = when (type) {
        ArtworkType.HERO -> dimensions.width >= dimensions.height * 3 / 2
        ArtworkType.COVER -> dimensions.height > dimensions.width && dimensions.height * 10 >= dimensions.width * 12
        ArtworkType.ICON -> true
    }
}
