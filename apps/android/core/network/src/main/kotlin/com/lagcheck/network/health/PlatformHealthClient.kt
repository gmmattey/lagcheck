package com.lagcheck.network.health

import com.lagcheck.catalog.Platform
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL

/**
 * Status público das redes de console (PSN, Xbox, Nintendo), direto nos CDNs das fabricantes: custo zero, sem Worker,
 * sem identificação. Só PlayStation, Xbox e Nintendo consultam; celular e PC não têm rede de console a checar.
 * Falha de rede, HTTP diferente de 200 ou formato inesperado = `Unknown` (nunca alerta, nunca "operacional" inventado).
 */
class PlatformHealthClient(
    private val fetch: suspend (String) -> ByteArray? = ::httpGet,
    private val cacheTtlMillis: Long = 10 * 60 * 1000L,
    private val clock: () -> Long = System::currentTimeMillis
) {
    private class Cached(val health: PlatformHealth, val expiresAt: Long)

    private val cache = HashMap<String, Cached>()
    private val lock = Mutex()

    suspend fun check(platform: Platform, market: String = "BR"): PlatformHealth? {
        if (platform != Platform.PLAYSTATION && platform != Platform.XBOX && platform != Platform.NINTENDO) return null
        val key = "${platform.name}_${market.uppercase()}"
        lock.withLock { cache[key]?.takeIf { clock() < it.expiresAt } }?.let { return it.health }

        val health = when (platform) {
            Platform.PLAYSTATION -> fetch(psnUrl(market))?.let { PlatformHealthParsers.parsePlayStation(it, market) }
                ?: PlatformHealth.unknown(platform, PlatformHealthParsers.PSN)
            Platform.XBOX -> fetch(xboxUrl(market))?.let(PlatformHealthParsers::parseXbox)
                ?: PlatformHealth.unknown(platform, PlatformHealthParsers.XBOX)
            else -> fetch(NINTENDO_URL)?.let(PlatformHealthParsers::parseNintendo)
                ?: PlatformHealth.unknown(platform, PlatformHealthParsers.NINTENDO)
        }
        lock.withLock { cache[key] = Cached(health, clock() + cacheTtlMillis) }
        return health
    }

    companion object {
        private val AMERICAS = setOf("BR", "US", "CA", "MX", "CL", "AR", "PE", "CO", "PA", "CR", "EC", "GT", "SV", "PY", "HN", "NI", "UY", "BO")
        const val NINTENDO_URL = "https://www.nintendo.co.jp/netinfo/en_US/status.json"

        fun psnUrl(market: String) =
            "https://status.playstation.com/data/statuses/region/${if (market.uppercase() in AMERICAS) "SCEA" else "SCEE"}.json"

        fun xboxUrl(market: String): String {
            val m = market.uppercase()
            return "https://xnotify.xboxlive.com/servicestatusv6/$m/${if (m == "BR") "pt-BR" else "en-US"}"
        }

        private const val MAX_BYTES = 512 * 1024

        suspend fun httpGet(url: String): ByteArray? = withContext(Dispatchers.IO) {
            runCatching {
                val c = (URL(url).openConnection() as HttpURLConnection).apply {
                    requestMethod = "GET"; useCaches = false
                    connectTimeout = 3_000; readTimeout = 3_000
                    setRequestProperty("Accept", "application/json")
                    setRequestProperty("User-Agent", "LagCheck/1.0 (Android)")
                }
                try {
                    if (c.responseCode != 200) null
                    else c.inputStream.use { it.readNBytes(MAX_BYTES + 1) }.takeIf { it.size <= MAX_BYTES }
                } finally { c.disconnect() }
            }.getOrNull()
        }
    }
}
