package com.lagcheck.desktop.library.artwork

import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.scanner.XboxPackageFiles
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonArray
import java.io.File
import java.nio.file.Path
import java.util.Base64

private fun normalizeTitle(title: String): String =
    title.lowercase().filter { it.isLetterOrDigit() }

/**
 * Imagens oficiais de jogos da Epic, a partir do catálogo que o próprio Epic Games Launcher guarda neste PC
 * (`Data\Catalog\catcache.bin`). O arquivo lista os endereços públicos das capas no CDN da Epic; só a imagem
 * de um jogo é pedida, e só se o download de imagens estiver ligado.
 */
class EpicCatalogSource(
    private val dataDir: () -> File? = ::defaultEpicDataDir,
) : ArtworkSource {
    private data class Entry(val id: String, val title: String, val images: Map<String, String>, val developer: String? = null, val description: String? = null, val categories: List<String> = emptyList())

    @Volatile private var cached: Pair<Long, List<Entry>>? = null

    /** Estúdio e descrição do catálogo local do launcher. A Epic não publica gêneros nem modos de jogo aí. */
    fun info(game: PcGame): com.lagcheck.desktop.library.model.GameInfo? {
        val entry = entryFor(game) ?: return null
        // O catálogo local costuma repetir o título como "descrição": isso não é descrição.
        val description = entry.description?.trim()?.takeIf { it.isNotEmpty() && normalizeTitle(it) != normalizeTitle(entry.title) }
        // Categorias do catálogo: "games" marca jogo; só software/engines/aplicativos, sem "games", marca não-jogo.
        val paths = entry.categories.map { it.lowercase() }
        val isGame = when {
            paths.any { it == "games" || it.startsWith("games/") } -> true
            paths.any { it.startsWith("software") || it.startsWith("engines") || it.startsWith("applications") || it.startsWith("addons") } -> false
            else -> null
        }
        return com.lagcheck.desktop.library.model.GameInfo(description = description, developer = entry.developer?.trim()?.takeIf { it.isNotEmpty() }, isGame = isGame)
            .takeUnless { it.isEmpty }
    }

    private fun entryFor(game: PcGame): Entry? {
        if (game.platform != GamePlatform.EPIC_GAMES) return null
        val root = dataDir() ?: return null
        val entries = loadCatalog(File(root, "Catalog/catcache.bin"))
        if (entries.isEmpty()) return null
        val appName = game.id.removePrefix("epic_")
        val itemId = catalogItemId(File(root, "Manifests"), appName)
        return entries.firstOrNull { itemId != null && it.id == itemId }
            ?: entries.firstOrNull { normalizeTitle(it.title) == normalizeTitle(game.title) }
    }

    override fun candidates(game: PcGame, type: ArtworkType): List<ArtworkCandidate> {
        val entry = entryFor(game) ?: return emptyList()

        val order = when (type) {
            ArtworkType.COVER -> listOf("DieselGameBoxTall", "OfferImageTall", "Thumbnail")
            ArtworkType.HERO -> listOf("DieselGameBox", "OfferImageWide", "DieselStoreFrontWide", "DieselGameBoxTall")
            ArtworkType.ICON -> return emptyList()
        }
        return order.mapNotNull { entry.images[it] }.map(ArtworkCandidate::Remote)
    }

    private fun catalogItemId(manifests: File, appName: String): String? = runCatching {
        manifests.listFiles { f -> f.isFile && f.name.endsWith(".item") }?.firstNotNullOfOrNull { item ->
            val text = item.readText()
            val app = Regex(""""AppName"\s*:\s*"([^"]+)"""").find(text)?.groupValues?.get(1)
            if (app == appName) Regex(""""CatalogItemId"\s*:\s*"([^"]+)"""").find(text)?.groupValues?.get(1) else null
        }
    }.getOrNull()

    private fun loadCatalog(file: File): List<Entry> {
        if (!file.isFile) return emptyList()
        val stamp = file.lastModified()
        cached?.takeIf { it.first == stamp }?.let { return it.second }
        val parsed = runCatching {
            val json = Base64.getMimeDecoder().decode(file.readBytes()).toString(Charsets.UTF_8)
            Json.parseToJsonElement(json).jsonArray.mapNotNull(::entryOf)
        }.getOrDefault(emptyList())
        cached = stamp to parsed
        return parsed
    }

    private fun entryOf(element: kotlinx.serialization.json.JsonElement): Entry? {
        val obj = element as? JsonObject ?: return null
        val id = (obj["id"] as? JsonPrimitive)?.content ?: return null
        val title = (obj["title"] as? JsonPrimitive)?.content ?: return null
        val images = mutableMapOf<String, String>()
        for (item in (obj["keyImages"] as? JsonArray).orEmpty()) {
            val image = item as? JsonObject ?: continue
            val type = (image["type"] as? JsonPrimitive)?.content ?: continue
            val url = (image["url"] as? JsonPrimitive)?.content ?: continue
            images[type] = url
        }
        val developer = (obj["developer"] as? JsonPrimitive)?.content
        val description = (obj["description"] as? JsonPrimitive)?.content
        val categories = (obj["categories"] as? JsonArray).orEmpty()
            .mapNotNull { ((it as? JsonObject)?.get("path") as? JsonPrimitive)?.content }
        return Entry(id, title, images, developer, description, categories)
    }

    companion object {
        /** CDNs de imagens da Epic. */
        val HOSTS = setOf("cdn1.epicgames.com", "cdn2.unrealengine.com", "cdn.unrealengine.com")

        fun defaultEpicDataDir(): File? {
            if (!System.getProperty("os.name").lowercase().contains("win")) return null
            val programData = System.getenv("ProgramData") ?: "C:\\ProgramData"
            return File(programData, "Epic\\EpicGamesLauncher\\Data").takeIf(File::isDirectory)
        }
    }
}

/**
 * Imagens que o pacote de um jogo do Xbox já traz no disco (`MicrosoftGame.config` → `ShellVisuals`):
 * o banner largo da tela de abertura para o destaque e o logo grande para a capa. Nada é baixado.
 */
class XboxPackageArtSource : ArtworkSource {
    override fun candidates(game: PcGame, type: ArtworkType): List<ArtworkCandidate> {
        if (game.platform != GamePlatform.XBOX) return emptyList()
        val attributes = when (type) {
            ArtworkType.COVER -> arrayOf("Square480x480Logo", "Square150x150Logo", "StoreLogo")
            ArtworkType.HERO -> arrayOf("SplashScreenImage", "Square480x480Logo")
            ArtworkType.ICON -> arrayOf("Square44x44Logo", "Square150x150Logo")
        }
        return XboxPackageFiles.visuals(game.installDirectory, *attributes).map { ArtworkCandidate.LocalFile(it.toPath() as Path) }
    }
}

/** Pôster e banner de jogos da Microsoft Store, a partir do que o catálogo da loja já respondeu na varredura. */
class StoreCatalogArtSource(private val catalog: com.lagcheck.desktop.library.scanner.StoreCatalog) : ArtworkSource {
    override fun candidates(game: PcGame, type: ArtworkType): List<ArtworkCandidate> {
        if (game.platform != GamePlatform.XBOX) return emptyList()
        val product = catalog.cached(game.id.removePrefix("xbox_")) ?: return emptyList()
        val url = when (type) {
            ArtworkType.COVER -> product.posterUrl
            ArtworkType.HERO -> product.heroUrl ?: product.posterUrl
            ArtworkType.ICON -> null
        }
        return listOfNotNull(url?.let(ArtworkCandidate::Remote))
    }
}
