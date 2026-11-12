package com.lagcheck.desktop.library.artwork

import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import java.nio.file.Files
import java.nio.file.Path

fun jpegBytes(size: Int = 200): ByteArray = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte(), 0xE0.toByte()) + ByteArray(size)

val steamGame = PcGame("steam_730", "Counter-Strike 2", GamePlatform.STEAM)
val epicGame = PcGame("epic_abc", "Fall Guys", GamePlatform.EPIC_GAMES)

inline fun withTempDir(block: (Path) -> Unit) {
    val dir = Files.createTempDirectory("lc_art")
    try { block(dir) } finally { dir.toFile().deleteRecursively() }
}

/** Fetcher falso: responde por URL e conta quantos pedidos recebeu. */
class FakeFetcher(var respond: (String) -> FetchResult = { FetchResult.NotFound }, private val delayMs: Long = 0) : ArtworkFetcher {
    val calls = java.util.concurrent.CopyOnWriteArrayList<String>()
    override fun fetch(url: String): FetchResult {
        calls.add(url)
        if (delayMs > 0) Thread.sleep(delayMs)
        return respond(url)
    }
}

class FixedSource(private val candidates: List<ArtworkCandidate>) : ArtworkSource {
    override fun candidates(game: PcGame, type: ArtworkType) = candidates
}
