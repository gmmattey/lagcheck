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
        cache.get(game.id, type)?.let { return ArtworkResult.Available(it) }

        for (source in localSources) {
            for (candidate in source.candidates(game, type)) {
                val file = (candidate as? ArtworkCandidate.LocalFile)?.path ?: continue
                if (ImageBytes.looksLikeImageFile(file, maxLocalFileBytes)) return ArtworkResult.Available(file)
            }
        }

        if (!remoteEnabled()) return ArtworkResult.Fallback
        val urls = remoteSources.flatMap { it.candidates(game, type) }.filterIsInstance<ArtworkCandidate.Remote>().map { it.url }
        if (urls.isEmpty()) return ArtworkResult.Fallback // ex.: Epic, sem endereço público previsível
        if (cache.isMissActive(game.id, type)) return ArtworkResult.Fallback

        var transientFailure = false
        for (url in urls) {
            when (val r = downloadGate.withPermit { fetcher.fetch(url) }) {
                is FetchResult.Bytes ->
                    if (ImageBytes.looksLikeImage(r.data)) {
                        return ArtworkResult.Available(cache.put(game.id, type, r.data))
                    } else transientFailure = true // resposta estranha: tenta de novo mais tarde, não grava como imagem
                is FetchResult.NotFound -> Unit
                is FetchResult.Failed -> transientFailure = true
            }
        }
        cache.markMiss(game.id, type, permanent = !transientFailure)
        return ArtworkResult.Fallback
    }
}
