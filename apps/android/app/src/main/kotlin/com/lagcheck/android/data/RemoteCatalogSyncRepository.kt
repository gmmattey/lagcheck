package com.lagcheck.android.data

import android.content.Context
import android.content.SharedPreferences
import com.lagcheck.catalog.CatalogPayload
import com.lagcheck.catalog.RemoteCatalogVerifier
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

interface CatalogHttpTransport {
    data class Response(val statusCode: Int, val body: ByteArray, val etag: String?)
    fun fetch(url: String, etag: String?): Response
}

class HttpUrlConnectionCatalogTransport : CatalogHttpTransport {
    override fun fetch(url: String, etag: String?): CatalogHttpTransport.Response {
        val connection = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 8_000
            readTimeout = 10_000
            useCaches = false
            requestMethod = "GET"
            if (!etag.isNullOrBlank()) {
                setRequestProperty("If-None-Match", etag)
            }
        }
        return try {
            val code = connection.responseCode
            val stream = if (code in 200..299) connection.inputStream else connection.errorStream
            val bytes = stream?.use { it.readBytes() } ?: ByteArray(0)
            CatalogHttpTransport.Response(code, bytes, connection.getHeaderField("ETag"))
        } finally {
            connection.disconnect()
        }
    }
}

/**
 * Sincroniza o catálogo remoto (jogos, capas, rotas e regiões UDP) com fallback
 * imediato no envelope embarcado no APK e proteção contra downgrade de cobertura.
 */
class RemoteCatalogSyncRepository(
    private val bundledEnvelope: ByteArray,
    private val cacheFile: File,
    private val prefs: SharedPreferences,
    private val remoteUrl: String = DEFAULT_CATALOG_URL,
    private val transport: CatalogHttpTransport = HttpUrlConnectionCatalogTransport(),
    private val refreshIntervalMs: Long = DEFAULT_REFRESH_INTERVAL_MS
) {
    constructor(context: Context, bundledEnvelope: ByteArray) : this(
        bundledEnvelope = bundledEnvelope,
        cacheFile = File(context.filesDir, "catalog-v3.json"),
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    )

    fun loadLocal(): CatalogPayload? {
        if (cacheFile.exists()) {
            val cached = runCatching { decodeAndValidate(cacheFile.readBytes()) }.getOrNull()
            if (cached != null) return cached
        }
        return runCatching { RemoteCatalogVerifier.decodeBundled(bundledEnvelope) }.getOrNull()
    }

    fun syncIfNeeded(nowMs: Long = System.currentTimeMillis(), force: Boolean = false): CatalogPayload? {
        if (!force) {
            val lastChecked = prefs.getLong(KEY_LAST_CHECKED_AT, 0L)
            if (lastChecked > 0L && nowMs - lastChecked < refreshIntervalMs) {
                return null
            }
        }
        val savedEtag = prefs.getString(KEY_ETAG, null)
        val response = runCatching { transport.fetch(remoteUrl, savedEtag) }.getOrNull() ?: return null
        if (response.statusCode == HttpURLConnection.HTTP_NOT_MODIFIED) {
            prefs.edit().putLong(KEY_LAST_CHECKED_AT, nowMs).apply()
            return null
        }
        if (response.statusCode != HttpURLConnection.HTTP_OK) return null
        val payload = runCatching { decodeAndValidate(response.body) }.getOrNull() ?: return null

        runCatching {
            cacheFile.parentFile?.mkdirs()
            val tmp = File(cacheFile.parentFile, "${cacheFile.name}.tmp")
            tmp.writeBytes(response.body)
            if (!tmp.renameTo(cacheFile)) {
                cacheFile.writeBytes(response.body)
                tmp.delete()
            }
        }
        prefs.edit().apply {
            putLong(KEY_LAST_CHECKED_AT, nowMs)
            if (!response.etag.isNullOrBlank()) putString(KEY_ETAG, response.etag)
        }.apply()
        return payload
    }

    private fun decodeAndValidate(bytes: ByteArray): CatalogPayload {
        val payload = RemoteCatalogVerifier.decodeBundled(bytes)
        require(payload.regions.size >= MINIMUM_REGION_COUNT && payload.games.isNotEmpty()) {
            "Catálogo remoto incompleto"
        }
        return payload
    }

    companion object {
        const val DEFAULT_CATALOG_URL = "https://lagcheck.signallq.com/api/catalog-v3.json"
        const val MINIMUM_REGION_COUNT = 20
        const val DEFAULT_REFRESH_INTERVAL_MS = 6L * 60L * 60L * 1000L
        private const val PREFS_NAME = "lagcheck_remote_catalog_v3"
        private const val KEY_ETAG = "etag"
        private const val KEY_LAST_CHECKED_AT = "last_checked_at"
    }
}
