package com.lagcheck.desktop.library.scanner

import java.io.File

/** Print tirado pelo próprio usuário no jogo. Caminhos absolutos e locais; a existência é verificada na leitura. */
data class GameScreenshot(
    val path: String,
    val thumbnailPath: String?,
    val createdEpochMs: Long?,
    val width: Int?,
    val height: Int?,
)

/**
 * Lê os prints que o cliente Steam grava em userdata/<conta>/760 (screenshots.vdf + remote/<appid>/screenshots).
 * Só traz capturas do usuário: material promocional do jogo vem de outra fonte e não passa por aqui.
 * Vários perfis na mesma máquina são somados; arquivo ausente, movido ou apagado é descartado.
 */
class SteamScreenshots(private val steamRoot: () -> File?) {
    private data class Cached(val stamp: List<Pair<String, Long>>, val byApp: Map<String, List<GameScreenshot>>)

    @Volatile private var cached: Cached? = null

    /** Capturas por appid, mais recentes primeiro. */
    fun forApp(appId: String): List<GameScreenshot> = index()[appId].orEmpty()

    private fun index(): Map<String, List<GameScreenshot>> {
        val root = steamRoot() ?: return emptyMap()
        val vdfs = File(root, "userdata").listFiles { f -> f.isDirectory }
            ?.map { File(it, "760/screenshots.vdf") }
            ?.filter { it.isFile }
            .orEmpty()
        val stamp = vdfs.map { it.path to it.lastModified() }
        cached?.takeIf { it.stamp == stamp }?.let { return it.byApp }

        val merged = mutableMapOf<String, MutableList<GameScreenshot>>()
        for (vdf in vdfs) {
            val remote = File(vdf.parentFile, "remote")
            for ((appId, shot) in parse(runCatching { vdf.readText() }.getOrDefault(""), remote)) {
                merged.getOrPut(appId) { mutableListOf() }.add(shot)
            }
        }
        val byApp = merged.mapValues { (_, shots) ->
            shots.distinctBy { it.path }.sortedByDescending { it.createdEpochMs ?: 0L }.take(MAX_PER_GAME)
        }
        cached = Cached(stamp, byApp)
        return byApp
    }

    internal companion object {
        const val MAX_PER_GAME = 60
        private val blockRegex = Regex(""""\d+"\s*\{([^{}]*)\}""")
        private fun field(block: String, key: String) = Regex(""""$key"\s+"([^"]*)"""").find(block)?.groupValues?.get(1)

        /** Converte o conteúdo do screenshots.vdf; só mantém entradas cujo arquivo existe em [remoteDir]. */
        internal fun parse(content: String, remoteDir: File): List<Pair<String, GameScreenshot>> =
            blockRegex.findAll(content).mapNotNull { match ->
                val block = match.groupValues[1]
                val appId = field(block, "gameid")?.takeIf { id -> id.isNotEmpty() && id.all { it.isDigit() } && id != "0" } ?: return@mapNotNull null
                val file = field(block, "filename")?.let { File(remoteDir, it.replace('\\', '/')) }?.takeIf { it.isFile } ?: return@mapNotNull null
                val thumb = field(block, "thumbnail")?.let { File(remoteDir, it.replace('\\', '/')) }?.takeIf { it.isFile }
                appId to GameScreenshot(
                    path = file.absolutePath,
                    thumbnailPath = thumb?.absolutePath,
                    createdEpochMs = field(block, "creation")?.toLongOrNull()?.takeIf { it > 0 }?.let { it * 1000 },
                    width = field(block, "width")?.toIntOrNull()?.takeIf { it > 0 },
                    height = field(block, "height")?.toIntOrNull()?.takeIf { it > 0 },
                )
            }.toList()
    }
}
