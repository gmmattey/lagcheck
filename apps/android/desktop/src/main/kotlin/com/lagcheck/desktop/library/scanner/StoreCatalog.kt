package com.lagcheck.desktop.library.scanner

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.io.File
import java.net.URI
import java.net.URLEncoder
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Duration

/** O que o catálogo público da Microsoft Store diz sobre um pacote instalado. */
data class StoreProduct(
    val title: String,
    val isGame: Boolean,
    val posterUrl: String? = null,
    val heroUrl: String? = null,
    /** Descrição, estúdio, lançamento, gêneros e modos que a loja publicou. */
    val info: com.lagcheck.desktop.library.model.GameInfo? = null,
)

/** Consulta de um pacote ao catálogo da loja. `null` quando não foi possível saber (sem rede, sem permissão). */
fun interface StoreProductLookup {
    fun lookup(packageFamilyName: String): StoreProduct?
}

/**
 * Catálogo público da Microsoft Store (`displaycatalog`), a mesma fonte que a Xbox / Microsoft Store usam para
 * dizer se um pacote é jogo e qual a capa. Serve para jogos da Microsoft Store que não trazem `MicrosoftGame.config`.
 *
 * Só o nome da família do pacote é enviado, e só quando o usuário deixa o download de imagens ligado. O resultado
 * (inclusive "não é jogo") fica num arquivo local, então cada pacote é consultado uma única vez.
 */
class StoreCatalog(
    private val cacheFile: File,
    private val enabled: () -> Boolean,
    private val market: String = "BR",
    private val languages: String = "pt-BR,en-US",
    private val timeout: Duration = Duration.ofSeconds(8),
    private val client: HttpClient = HttpClient.newBuilder().followRedirects(HttpClient.Redirect.NORMAL).connectTimeout(timeout).build(),
) : StoreProductLookup {
    private val lock = Any()
    private var memory: MutableMap<String, StoreProduct>? = null

    /** Só o que já foi aprendido, sem rede. */
    fun cached(packageFamilyName: String): StoreProduct? = synchronized(lock) { load()[packageFamilyName] }

    /** Produto com as informações de catálogo; consulta a loja de novo se o que está em disco veio de antes delas existirem. */
    fun details(packageFamilyName: String): StoreProduct? {
        cached(packageFamilyName)?.takeIf { !it.isGame || it.info != null }?.let { return it }
        if (!enabled()) return cached(packageFamilyName)
        val product = fetch(packageFamilyName) ?: return cached(packageFamilyName)
        synchronized(lock) {
            load()[packageFamilyName] = product
            save()
        }
        return product
    }

    override fun lookup(packageFamilyName: String): StoreProduct? {
        cached(packageFamilyName)?.let { return it }
        if (!enabled()) return null
        val product = fetch(packageFamilyName) ?: return null
        synchronized(lock) {
            load()[packageFamilyName] = product
            save()
        }
        return product
    }

    private fun fetch(pfn: String): StoreProduct? = try {
        val query = "alternateId=PackageFamilyName&value=${URLEncoder.encode(pfn, Charsets.UTF_8)}&market=$market&languages=$languages&fieldsTemplate=Details"
        val request = HttpRequest.newBuilder(URI("https://displaycatalog.mp.microsoft.com/v7.0/products/lookup?$query"))
            .timeout(timeout).header("User-Agent", "LagCheck").GET().build()
        val response = client.send(request, HttpResponse.BodyHandlers.ofString(Charsets.UTF_8))
        when (response.statusCode()) {
            200 -> parseProduct(response.body()) ?: StoreProduct(pfn, isGame = false) // pacote fora da loja: não é jogo da loja
            404 -> StoreProduct(pfn, isGame = false)
            else -> null
        }
    } catch (e: InterruptedException) {
        Thread.currentThread().interrupt()
        null
    } catch (_: Exception) {
        null
    }

    private fun load(): MutableMap<String, StoreProduct> {
        memory?.let { return it }
        val map = mutableMapOf<String, StoreProduct>()
        runCatching {
            if (cacheFile.isFile) {
                (Json.parseToJsonElement(cacheFile.readText()) as? JsonObject)?.forEach { (pfn, value) ->
                    val obj = value as? JsonObject ?: return@forEach
                    map[pfn] = StoreProduct(
                        title = (obj["title"] as? JsonPrimitive)?.content ?: pfn,
                        isGame = (obj["isGame"] as? JsonPrimitive)?.content == "true",
                        posterUrl = (obj["posterUrl"] as? JsonPrimitive)?.content,
                        heroUrl = (obj["heroUrl"] as? JsonPrimitive)?.content,
                        info = (obj["info"] as? JsonObject)?.let(com.lagcheck.desktop.library.info.GameInfoService.Companion::infoFromJson),
                    )
                }
            }
        }
        memory = map
        return map
    }

    private fun save() {
        val json = JsonObject(
            memory.orEmpty().mapValues { (_, p) ->
                JsonObject(
                    buildMap {
                        put("title", JsonPrimitive(p.title))
                        put("isGame", JsonPrimitive(p.isGame))
                        p.posterUrl?.let { put("posterUrl", JsonPrimitive(it)) }
                        p.heroUrl?.let { put("heroUrl", JsonPrimitive(it)) }
                        p.info?.let { put("info", com.lagcheck.desktop.library.info.GameInfoService.Companion.infoToJson(it)) }
                    },
                )
            },
        )
        runCatching {
            cacheFile.parentFile?.mkdirs()
            val temp = File(cacheFile.parentFile, cacheFile.name + ".tmp")
            temp.writeText(json.toString())
            temp.renameTo(cacheFile).also { if (!it) { cacheFile.delete(); temp.renameTo(cacheFile) } }
        }
    }

    companion object {
        /** Host das imagens da Microsoft Store. */
        const val IMAGE_HOST = "store-images.s-microsoft.com"

        internal fun parseProduct(body: String): StoreProduct? {
            val root = Json.parseToJsonElement(body) as? JsonObject ?: return null
            val product = ((root["Products"] as? JsonArray)?.firstOrNull() as? JsonObject) ?: return null
            val isGame = (product["ProductType"] as? JsonPrimitive)?.content.equals("Game", ignoreCase = true)
            val localized = ((product["LocalizedProperties"] as? JsonArray)?.firstOrNull() as? JsonObject)
            val title = (localized?.get("ProductTitle") as? JsonPrimitive)?.content?.trim().orEmpty()
            val images = (localized?.get("Images") as? JsonArray).orEmpty().mapNotNull { it as? JsonObject }
            fun image(vararg purposes: String): String? = purposes.firstNotNullOfOrNull { purpose ->
                images.filter { (it["ImagePurpose"] as? JsonPrimitive)?.content == purpose }
                    .maxByOrNull { ((it["Width"] as? JsonPrimitive)?.content?.toIntOrNull() ?: 0) }
                    ?.let { (it["Uri"] as? JsonPrimitive)?.content }
            }?.let(::absolute)
            return StoreProduct(
                title = title.ifBlank { return null },
                isGame = isGame,
                posterUrl = image("Poster", "BoxArt")?.let { "$it?q=90&w=600&h=900" },
                heroUrl = image("SuperHeroArt", "Hero")?.let { "$it?q=90&w=1920&h=1080" },
                info = parseInfo(product, localized),
            )
        }

        /** Modos de jogo declarados pela loja (atributos do produto). */
        private val MODE_ATTRIBUTES = mapOf(
            "SinglePlayer" to com.lagcheck.desktop.library.model.GameModes.SINGLEPLAYER,
            "XblLocalMultiPlayer" to com.lagcheck.desktop.library.model.GameModes.MULTIPLAYER,
            "XblLocalCoop" to com.lagcheck.desktop.library.model.GameModes.COOP,
            "XblOnlineMultiPlayer" to com.lagcheck.desktop.library.model.GameModes.ONLINE_MULTIPLAYER,
            "XblOnlineCoop" to com.lagcheck.desktop.library.model.GameModes.ONLINE_COOP,
            "XblCrossPlatformMultiPlayer" to com.lagcheck.desktop.library.model.GameModes.CROSSPLAY,
            "XblCrossPlatformCoop" to com.lagcheck.desktop.library.model.GameModes.CROSSPLAY,
        )

        internal fun parseInfo(product: JsonObject, localized: JsonObject?): com.lagcheck.desktop.library.model.GameInfo? {
            fun text(obj: JsonObject?, name: String) = (obj?.get(name) as? JsonPrimitive)?.content?.trim()?.takeIf { it.isNotEmpty() }
            val properties = product["Properties"] as? JsonObject
            val market = ((product["MarketProperties"] as? JsonArray)?.firstOrNull() as? JsonObject)
            val description = (text(localized, "ShortDescription") ?: text(localized, "ProductDescription"))
                ?.let { raw -> raw.split(Regex("\r?\n\\s*\r?\n")).first().replace(Regex("\\s+"), " ").trim() }
                ?.take(600)?.takeIf { it.isNotEmpty() }
            val genres = (properties?.get("Categories") as? JsonArray).orEmpty().mapNotNull { (it as? JsonPrimitive)?.content?.trim() }.filter(String::isNotEmpty)
                .ifEmpty { listOfNotNull(text(properties, "Category")) }
            val modes = (properties?.get("Attributes") as? JsonArray).orEmpty()
                .mapNotNull { text(it as? JsonObject, "Name") }.mapNotNull(MODE_ATTRIBUTES::get).distinct()
            return com.lagcheck.desktop.library.model.GameInfo(
                description = description,
                developer = text(localized, "DeveloperName"),
                publisher = text(localized, "PublisherName"),
                releaseDate = text(market, "OriginalReleaseDate")?.take(10),
                genres = genres,
                modes = modes,
            ).takeUnless { it.isEmpty }
        }

        private fun absolute(uri: String) = if (uri.startsWith("//")) "https:$uri" else uri
    }
}
