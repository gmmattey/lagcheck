package com.lagcheck.desktop.library.artwork

import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.nio.file.attribute.FileTime

/**
 * Imagens baixadas, guardadas neste PC. Tem teto de tamanho (remove as menos usadas) e lembra
 * quando uma imagem não existe ou falhou, para não pedir de novo a cada abertura.
 */
class ArtworkDiskCache(
    private val dir: Path,
    private val maxBytes: Long = DEFAULT_MAX_BYTES,
    private val clock: () -> Long = { System.currentTimeMillis() },
    private val notFoundTtlMs: Long = 7L * 24 * 60 * 60 * 1000,
    private val failureTtlMs: Long = 15L * 60 * 1000,
) {
    /** Devolve o arquivo em cache e marca como usado agora (para a remoção por uso). */
    fun get(gameId: String, type: ArtworkType): Path? {
        val f = imageFile(gameId, type)
        if (!Files.isRegularFile(f)) return null
        runCatching { Files.setLastModifiedTime(f, FileTime.fromMillis(clock())) }
        return f
    }

    fun put(gameId: String, type: ArtworkType, bytes: ByteArray): Path {
        Files.createDirectories(dir)
        val target = imageFile(gameId, type)
        val tmp = target.resolveSibling(target.fileName.toString() + ".tmp")
        Files.write(tmp, bytes)
        Files.move(tmp, target, StandardCopyOption.REPLACE_EXISTING)
        Files.deleteIfExists(missFile(gameId, type))
        runCatching { Files.setLastModifiedTime(target, FileTime.fromMillis(clock())) }
        evict(keep = target)
        return target
    }

    /** `permanent` = o servidor disse que não existe; senão foi falha passageira, com prazo bem menor. */
    fun markMiss(gameId: String, type: ArtworkType, permanent: Boolean) {
        runCatching {
            Files.createDirectories(dir)
            val expiry = clock() + if (permanent) notFoundTtlMs else failureTtlMs
            Files.writeString(missFile(gameId, type), expiry.toString())
        }
    }

    fun isMissActive(gameId: String, type: ArtworkType): Boolean = runCatching {
        val f = missFile(gameId, type)
        if (!Files.isRegularFile(f)) return@runCatching false
        val expiry = Files.readString(f).trim().toLongOrNull() ?: return@runCatching false
        if (expiry > clock()) true else { Files.deleteIfExists(f); false }
    }.getOrDefault(false)

    /** Apaga imagens e lembretes de falha de um jogo, para a próxima abertura buscar de novo. */
    fun clear(gameId: String) {
        val prefix = key(gameId) + "."
        runCatching {
            Files.list(dir).use { s -> s.filter { it.fileName.toString().startsWith(prefix) }.toList() }
                .forEach { Files.deleteIfExists(it) }
        }
    }

    fun totalImageBytes(): Long = images().sumOf { runCatching { Files.size(it) }.getOrDefault(0L) }

    private fun evict(keep: Path) {
        val all = images().mapNotNull { p ->
            runCatching { Triple(p, Files.size(p), Files.getLastModifiedTime(p).toMillis()) }.getOrNull()
        }
        var total = all.sumOf { it.second }
        if (total <= maxBytes) return
        for ((p, size, _) in all.sortedBy { it.third }) {
            if (total <= maxBytes) break
            if (p == keep) continue
            if (runCatching { Files.deleteIfExists(p) }.getOrDefault(false)) total -= size
        }
    }

    private fun images(): List<Path> = runCatching {
        if (!Files.isDirectory(dir)) emptyList()
        else Files.list(dir).use { s -> s.filter { it.fileName.toString().endsWith(IMG) }.toList() }
    }.getOrDefault(emptyList())

    private fun imageFile(gameId: String, type: ArtworkType) = dir.resolve("${key(gameId)}.${type.key}$IMG")
    private fun missFile(gameId: String, type: ArtworkType) = dir.resolve("${key(gameId)}.${type.key}.miss")

    companion object {
        const val DEFAULT_MAX_BYTES = 200L * 1024 * 1024
        private const val IMG = ".img"

        /** Nome de arquivo seguro para qualquer id de jogo. */
        fun key(gameId: String): String = gameId.replace(Regex("[^A-Za-z0-9_-]"), "_")
    }
}
