package com.lagcheck.catalog

import java.time.Duration
import java.time.Instant

fun interface CatalogFetcher {
    suspend fun fetchCatalog(): ByteArray
}

class StoredCatalog(val envelope: ByteArray, val refreshedAt: Instant)

interface CatalogCache {
    suspend fun load(): StoredCatalog?
    suspend fun save(catalog: StoredCatalog)
}

enum class CatalogSource { BUNDLED_BASE, CACHED_REMOTE }

class LoadedCatalog(val payload: CatalogPayload, val source: CatalogSource)

/**
 * Mantém só catálogos que já passaram por assinatura, validade e regras de negócio. A base embarcada é o
 * fallback funcional; a atualização é assíncrona, no máximo uma tentativa por dia, e nunca bloqueia a Home.
 * Toda falha mantém o catálogo que já era válido (mesmo contrato do `RemoteCatalogRepository` do iOS).
 */
class RemoteCatalogRepository(
    private val baseEnvelope: ByteArray,
    private val fetcher: CatalogFetcher,
    private val cache: CatalogCache,
    private val clock: () -> Instant = Instant::now,
    private val validator: (ByteArray, Instant) -> CatalogPayload = { bytes, now -> RemoteCatalogVerifier.verifyAndDecode(bytes, now) }
) {
    suspend fun loadedCatalogForLaunch(): LoadedCatalog {
        val now = clock()
        val base = validator(baseEnvelope, now)
        val cached = cache.load()?.let { runCatching { validator(it.envelope, now) }.getOrNull() }
        return if (cached != null && cached.schemaVersion >= base.schemaVersion) {
            LoadedCatalog(cached, CatalogSource.CACHED_REMOTE)
        } else {
            LoadedCatalog(base, CatalogSource.BUNDLED_BASE)
        }
    }

    /** Retorna true se um catálogo novo e válido foi gravado no cache. */
    suspend fun refreshIfDue(): Boolean {
        val now = clock()
        val stored = cache.load()
        if (stored != null && Duration.between(stored.refreshedAt, now) < REFRESH_INTERVAL) {
            val base = runCatching { validator(baseEnvelope, now) }.getOrNull()
            val cached = runCatching { validator(stored.envelope, now) }.getOrNull()
            if (base != null && cached != null && cached.schemaVersion >= base.schemaVersion) return false
        }
        val data = runCatching { fetcher.fetchCatalog() }.getOrNull() ?: return false
        if (runCatching { validator(data, now) }.isFailure) return false
        cache.save(StoredCatalog(data, now))
        return true
    }

    companion object {
        val REFRESH_INTERVAL: Duration = Duration.ofHours(24)
    }
}
