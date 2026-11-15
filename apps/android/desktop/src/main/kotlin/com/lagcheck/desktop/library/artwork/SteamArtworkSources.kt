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
        val files = when (type) {
            ArtworkType.COVER -> listOf(
                "library_600x900_2x.jpg" to ImageBytes.Dimensions(1200, 1800),
                "library_600x900.jpg" to ImageBytes.Dimensions(600, 900),
            )
            // A Steam publica o _2x em 3840x1240; o arquivo normal (1920x620) continua como fallback.
            ArtworkType.HERO -> listOf(
                "library_hero_2x.jpg" to ImageBytes.Dimensions(3840, 1240),
                "library_hero.jpg" to ImageBytes.Dimensions(1920, 620),
            )
            ArtworkType.ICON -> return emptyList()
        }
        return listOf(
            "https://cdn.cloudflare.steamstatic.com/steam/apps/$id/",
            "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$id/",
        ).flatMap { base -> files.map { (file, dimensions) -> ArtworkCandidate.Remote(base + file, dimensions) } }
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
        val names = when (type) {
            ArtworkType.COVER -> listOf("library_600x900_2x.jpg", "library_600x900.jpg")
            ArtworkType.HERO -> listOf("library_hero_2x.jpg", "library_hero.jpg")
            ArtworkType.ICON -> null
        }
        val result = mutableListOf<Path>()
        // Formato antigo: <appid>_library_600x900.jpg, <appid>_icon.jpg
        if (names != null) names.forEach { name ->
            val legacy = cacheDir.resolve("${id}_$name")
            if (Files.isRegularFile(legacy)) result.add(legacy)
        } else {
            val legacy = cacheDir.resolve("${id}_icon.jpg")
            if (Files.isRegularFile(legacy)) result.add(legacy)
        }
        // Formato novo: <appid>/<hash opcional>/library_600x900.jpg
        val appDir = cacheDir.resolve(id)
        if (names != null && Files.isDirectory(appDir)) {
            runCatching {
                Files.walk(appDir, 2).use { s ->
                    val files = s.filter(Files::isRegularFile).toList()
                    names.forEach { name -> files.filter { it.fileName.toString() == name }.sorted().forEach(result::add) }
                }
            }
        }
        return result.map(ArtworkCandidate::LocalFile)
    }
}
