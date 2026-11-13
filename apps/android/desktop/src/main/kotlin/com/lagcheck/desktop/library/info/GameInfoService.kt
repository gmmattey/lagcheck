package com.lagcheck.desktop.library.info

import com.lagcheck.desktop.library.artwork.ArtworkDiskCache
import com.lagcheck.desktop.library.artwork.EpicCatalogSource
import com.lagcheck.desktop.library.model.GameInfo
import com.lagcheck.desktop.library.model.GameKindSource
import com.lagcheck.desktop.library.model.GameModes
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.scanner.StoreCatalog
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.io.File
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Duration

/** Download bloqueante de um texto (JSON). Os testes usam um falso. */
fun interface InfoFetcher {
    /** Corpo da resposta, `null` quando a loja não conhece o app ou houve falha. */
    fun fetch(url: String): InfoFetch
}

sealed interface InfoFetch {
    class Body(val text: String) : InfoFetch
    data object NotFound : InfoFetch
    data object Failed : InfoFetch
}

class HttpInfoFetcher(private val timeout: Duration = Duration.ofSeconds(8)) : InfoFetcher {
    private val client = HttpClient.newBuilder().followRedirects(HttpClient.Redirect.NORMAL).connectTimeout(timeout).build()

    override fun fetch(url: String): InfoFetch = try {
        val request = HttpRequest.newBuilder(URI(url)).timeout(timeout).header("User-Agent", "LagCheck").GET().build()
        val response = client.send(request, HttpResponse.BodyHandlers.ofString(Charsets.UTF_8))
        when (response.statusCode()) {
            200 -> InfoFetch.Body(response.body())
            404 -> InfoFetch.NotFound
            else -> InfoFetch.Failed
        }
    } catch (e: InterruptedException) {
        Thread.currentThread().interrupt()
        InfoFetch.Failed
    } catch (_: Exception) {
        InfoFetch.Failed
    }
}

/**
 * Informações de catálogo de um jogo, por plataforma:
 * - Steam: API pública da loja (`appdetails`), só com o download de imagens/dados ligado; resposta guardada em disco.
 * - Epic: catálogo local do próprio launcher (`catcache.bin`), sem rede.
 * - Xbox / Microsoft Store: catálogo público (`displaycatalog`) via [StoreCatalog], já cacheado em disco.
 *
 * Nunca lança por falha de rede ou de disco: o pior resultado é `null` e a interface omite os campos.
 */
class GameInfoService(
    private val cacheDir: File,
    private val enabled: () -> Boolean,
    private val epic: EpicCatalogSource,
    private val store: StoreCatalog,
    private val fetcher: InfoFetcher = HttpInfoFetcher(),
    private val now: () -> Long = System::currentTimeMillis,
    private val market: String = "br",
    private val language: String = "portuguese",
) : GameKindSource {
    override fun cached(game: PcGame): Boolean? = try {
        when (game.platform) {
            GamePlatform.STEAM -> steamAppId(game)?.let { readCache(File(cacheDir, "steam_$it.json"))?.info?.isGame }
            GamePlatform.EPIC_GAMES -> epic.info(game)?.isGame
            GamePlatform.XBOX -> store.cached(game.id.removePrefix("xbox_"))?.isGame
            GamePlatform.MANUAL -> null
        }
    } catch (_: Exception) {
        null
    }

    override suspend fun classify(game: PcGame): Boolean? = cached(game) ?: resolve(game)?.isGame

    private fun steamAppId(game: PcGame): String? =
        game.id.takeIf { it.startsWith("steam_") }?.removePrefix("steam_")?.takeIf { it.isNotEmpty() && it.all(Char::isDigit) }

    suspend fun resolve(game: PcGame): GameInfo? = withContext(Dispatchers.IO) {
        try {
            when (game.platform) {
                GamePlatform.STEAM -> steam(game)
                GamePlatform.EPIC_GAMES -> epic.info(game)
                GamePlatform.XBOX -> store.details(game.id.removePrefix("xbox_"))?.info
                GamePlatform.MANUAL -> null
            }?.takeUnless { it.isEmpty }
        } catch (e: kotlinx.coroutines.CancellationException) {
            throw e
        } catch (_: Exception) {
            null
        }
    }

    private fun steam(game: PcGame): GameInfo? {
        val appId = steamAppId(game) ?: return null
        val file = File(cacheDir, "steam_$appId.json")
        val cached = readCache(file)
        // Entrada gravada antes de existir a classificação (sem versão) é refeita uma vez.
        val classified = cached == null || cached.version >= CACHE_VERSION
        val fresh = cached != null && classified && now() - cached.fetchedAt < (if (cached.info == null) NEGATIVE_TTL_MS else POSITIVE_TTL_MS)
        if (fresh) return cached!!.info
        if (!enabled()) return cached?.info // sem permissão para rede: usa o que já tem, mesmo vencido

        return when (val r = fetcher.fetch("https://store.steampowered.com/api/appdetails?appids=$appId&l=$language&cc=$market")) {
            is InfoFetch.Body -> parseSteam(r.text, appId).also { writeCache(file, it) }
            is InfoFetch.NotFound -> null.also { writeCache(file, null) }
            is InfoFetch.Failed -> cached?.info // falha passageira: não grava, tenta de novo depois
        }
    }

    private data class Cached(val fetchedAt: Long, val info: GameInfo?, val version: Int)

    private fun readCache(file: File): Cached? = runCatching {
        if (!file.isFile) return null
        val obj = Json.parseToJsonElement(file.readText()) as? JsonObject ?: return null
        val at = (obj["fetchedAt"] as? JsonPrimitive)?.content?.toLongOrNull() ?: return null
        Cached(at, (obj["info"] as? JsonObject)?.let(::infoFromJson), (obj["v"] as? JsonPrimitive)?.content?.toIntOrNull() ?: 1)
    }.getOrNull()

    private fun writeCache(file: File, info: GameInfo?) {
        runCatching {
            cacheDir.mkdirs()
            val json = JsonObject(buildMap {
                put("fetchedAt", JsonPrimitive(now()))
                put("v", JsonPrimitive(CACHE_VERSION))
                info?.let { put("info", infoToJson(it)) }
            })
            val temp = File(cacheDir, file.name + ".tmp")
            temp.writeText(json.toString())
            if (!temp.renameTo(file)) { file.delete(); temp.renameTo(file) }
        }
    }

    companion object {
        /** 2: o cache passou a guardar a classificação jogo/software. */
        private const val CACHE_VERSION = 2
        const val POSITIVE_TTL_MS = 14L * 24 * 60 * 60 * 1000
        const val NEGATIVE_TTL_MS = 24L * 60 * 60 * 1000
        private const val MAX_DESCRIPTION = 600

        /**
         * Gêneros que a Steam usa para software (ids estáveis): Contabilidade, Modelagem e animação, Desenho e ilustração,
         * Produção de áudio, Educação, Edição de fotos, Treinamento, Produção de vídeo, Publicação web, Desenvolvimento
         * de jogos, Utilidades. Um item cujos gêneros são só estes não é jogo.
         */
        private val STEAM_SOFTWARE_GENRES = setOf(51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61)

        /** Steam: ids de categoria são estáveis e independem do idioma da resposta. */
        private val STEAM_MODES = mapOf(
            2 to GameModes.SINGLEPLAYER,
            1 to GameModes.MULTIPLAYER,
            49 to GameModes.MULTIPLAYER,
            36 to GameModes.ONLINE_MULTIPLAYER,
            9 to GameModes.COOP,
            38 to GameModes.ONLINE_COOP,
            20 to GameModes.MMO,
            27 to GameModes.CROSSPLAY,
        )

        internal fun parseSteam(body: String, appId: String): GameInfo? {
            val root = Json.parseToJsonElement(body) as? JsonObject ?: return null
            val entry = root[appId] as? JsonObject ?: return null
            if ((entry["success"] as? JsonPrimitive)?.content != "true") return null
            val data = entry["data"] as? JsonObject ?: return null

            fun text(name: String) = (data[name] as? JsonPrimitive)?.content?.let(::cleanText)?.takeIf { it.isNotBlank() }
            fun names(array: JsonElement?, field: String) = (array as? JsonArray).orEmpty()
                .mapNotNull { (it as? JsonObject)?.get(field)?.let { v -> (v as? JsonPrimitive)?.content } }
                .map(String::trim).filter(String::isNotEmpty)

            val release = (data["release_date"] as? JsonObject)?.takeUnless { (it["coming_soon"] as? JsonPrimitive)?.content == "true" }
                ?.get("date")?.let { (it as? JsonPrimitive)?.content }?.trim()?.takeIf { it.isNotEmpty() }
            val modes = (data["categories"] as? JsonArray).orEmpty()
                .mapNotNull { ((it as? JsonObject)?.get("id") as? JsonPrimitive)?.content?.toIntOrNull() }
                .mapNotNull(STEAM_MODES::get).distinct()

            val genreIds = (data["genres"] as? JsonArray).orEmpty()
                .mapNotNull { ((it as? JsonObject)?.get("id") as? JsonPrimitive)?.content?.toIntOrNull() }
            val type = (data["type"] as? JsonPrimitive)?.content
            val isGame = when {
                type == null -> null
                type != "game" -> false // dlc, demo, trilha, vídeo, aplicativo...
                genreIds.isNotEmpty() && genreIds.all { it in STEAM_SOFTWARE_GENRES } -> false
                else -> true
            }

            return GameInfo(
                description = text("short_description")?.take(MAX_DESCRIPTION),
                developer = stringList(data["developers"]).firstOrNull(),
                publisher = stringList(data["publishers"]).firstOrNull(),
                releaseDate = release,
                genres = names(data["genres"], "description"),
                modes = modes,
                isGame = isGame,
            ).takeUnless { it.isEmpty }
        }

        private fun stringList(element: JsonElement?): List<String> =
            (element as? JsonArray).orEmpty().mapNotNull { (it as? JsonPrimitive)?.content?.trim() }.filter(String::isNotEmpty)

        /** A loja manda texto com entidades HTML e, às vezes, tags; a interface só mostra texto puro. */
        internal fun cleanText(raw: String): String = raw
            .replace(Regex("<[^>]*>"), " ")
            .replace("&quot;", "\"").replace("&#39;", "'").replace("&apos;", "'")
            .replace("&lt;", "<").replace("&gt;", ">").replace("&nbsp;", " ").replace("&amp;", "&")
            .replace(Regex("\\s+"), " ").trim()

        internal fun infoToJson(info: GameInfo): JsonObject = JsonObject(buildMap {
            info.description?.let { put("description", JsonPrimitive(it)) }
            info.developer?.let { put("developer", JsonPrimitive(it)) }
            info.publisher?.let { put("publisher", JsonPrimitive(it)) }
            info.releaseDate?.let { put("releaseDate", JsonPrimitive(it)) }
            put("genres", JsonArray(info.genres.map(::JsonPrimitive)))
            put("modes", JsonArray(info.modes.map(::JsonPrimitive)))
            info.isGame?.let { put("isGame", JsonPrimitive(it)) }
        })

        internal fun infoFromJson(obj: JsonObject): GameInfo = GameInfo(
            description = (obj["description"] as? JsonPrimitive)?.content,
            developer = (obj["developer"] as? JsonPrimitive)?.content,
            publisher = (obj["publisher"] as? JsonPrimitive)?.content,
            releaseDate = (obj["releaseDate"] as? JsonPrimitive)?.content,
            genres = stringList(obj["genres"]),
            modes = stringList(obj["modes"]),
            isGame = (obj["isGame"] as? JsonPrimitive)?.content?.toBooleanStrictOrNull(),
        )
    }
}
