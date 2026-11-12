package com.lagcheck.desktop.library.artwork

import com.lagcheck.desktop.library.model.PcGame
import java.io.File
import java.nio.file.Files
import java.nio.file.Path

private fun steamAppId(game: PcGame): String? =
    game.id.takeIf { it.startsWith("steam_") }?.removePrefix("steam_")?.takeIf { it.isNotEmpty() && it.all(Char::isDigit) }

/** Imagens oficiais públicas da Steam para um app. Não existe equivalente previsível para a Epic. */
class SteamCdnSource : ArtworkSource {
    override fun candidates(game: PcGame, type: ArtworkType): List<ArtworkCandidate> {
        val id = steamAppId(game) ?: return emptyList()
        val file = when (type) {
            ArtworkType.COVER -> "library_600x900.jpg"
            ArtworkType.HERO -> "library_hero.jpg"
            ArtworkType.ICON -> return emptyList()
        }
        return listOf(
            "https://cdn.cloudflare.steamstatic.com/steam/apps/$id/$file",
            "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$id/$file",
        ).map(ArtworkCandidate::Remote)
    }
}

/**
 * Imagens que o próprio cliente Steam já guardou neste PC (`appcache/librarycache`). Se existirem,
 * nada precisa ser baixado. Aceita o formato antigo (arquivos soltos) e o novo (pasta por app).
 */
class SteamLibraryCacheSource(private val steamRoot: () -> File?) : ArtworkSource {
    override fun candidates(game: PcGame, type: ArtworkType): List<ArtworkCandidate> {
        val id = steamAppId(game) ?: return emptyList()
        val cacheDir = steamRoot()?.toPath()?.resolve("appcache")?.resolve("librarycache") ?: return emptyList()
        val name = when (type) {
            ArtworkType.COVER -> "library_600x900.jpg"
            ArtworkType.HERO -> "library_hero.jpg"
            ArtworkType.ICON -> null
        }
        val result = mutableListOf<Path>()
        // Formato antigo: <appid>_library_600x900.jpg, <appid>_icon.jpg
        val legacy = cacheDir.resolve(if (name != null) "${id}_$name" else "${id}_icon.jpg")
        if (Files.isRegularFile(legacy)) result.add(legacy)
        // Formato novo: <appid>/<hash opcional>/library_600x900.jpg
        val appDir = cacheDir.resolve(id)
        if (name != null && Files.isDirectory(appDir)) {
            runCatching {
                Files.walk(appDir, 2).use { s ->
                    s.filter { Files.isRegularFile(it) && it.fileName.toString() == name }.sorted().forEach(result::add)
                }
            }
        }
        return result.map(ArtworkCandidate::LocalFile)
    }
}
