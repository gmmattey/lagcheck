package com.lagcheck.catalog

import com.google.common.truth.Truth.assertThat
import com.lagcheck.catalog.CatalogTestSupport.realEnvelopeBytes
import java.time.Duration
import java.time.Instant
import kotlinx.coroutines.runBlocking
import org.junit.Test

class RemoteCatalogRepositoryTest {
    private val realCatalogNow = Instant.parse("2026-10-20T00:00:00Z")
    private class MemoryCache(var stored: StoredCatalog? = null) : CatalogCache {
        var saves = 0
        override suspend fun load() = stored
        override suspend fun save(catalog: StoredCatalog) { stored = catalog; saves++ }
    }

    private class Fetcher(var result: () -> ByteArray) : CatalogFetcher {
        var calls = 0
        override suspend fun fetchCatalog(): ByteArray { calls++; return result() }
    }

    private val real = realEnvelopeBytes()
    private var clock: Instant = realCatalogNow

    private fun repo(f: Fetcher, c: MemoryCache) = RemoteCatalogRepository(real, f, c, { clock })

    @Test fun launchWithoutCacheUsesBundledBase() = runBlocking {
        val loaded = repo(Fetcher { real }, MemoryCache()).loadedCatalogForLaunch()
        assertThat(loaded.source).isEqualTo(CatalogSource.BUNDLED_BASE)
        assertThat(loaded.payload.games).hasSize(48)
    }

    @Test fun refreshStoresOnlyValidatedCatalog() = runBlocking {
        val cache = MemoryCache()
        val fetcher = Fetcher { real }
        assertThat(repo(fetcher, cache).refreshIfDue()).isTrue()
        assertThat(cache.saves).isEqualTo(1)
        assertThat(repo(fetcher, cache).loadedCatalogForLaunch().source).isEqualTo(CatalogSource.CACHED_REMOTE)
    }

    @Test fun invalidRemoteIsNeverCached() = runBlocking {
        val cache = MemoryCache()
        assertThat(repo(Fetcher { "{}".toByteArray() }, cache).refreshIfDue()).isFalse()
        assertThat(cache.saves).isEqualTo(0)
    }

    @Test fun networkFailureKeepsWorkingCatalog() = runBlocking {
        val cache = MemoryCache()
        val r = repo(Fetcher { throw java.io.IOException("offline") }, cache)
        assertThat(r.refreshIfDue()).isFalse()
        assertThat(r.loadedCatalogForLaunch().source).isEqualTo(CatalogSource.BUNDLED_BASE)
    }

    @Test fun atMostOneAttemptPerDay() = runBlocking {
        val cache = MemoryCache(StoredCatalog(real, realCatalogNow))
        val fetcher = Fetcher { real }
        clock = realCatalogNow.plus(Duration.ofHours(23))
        assertThat(repo(fetcher, cache).refreshIfDue()).isFalse()
        assertThat(fetcher.calls).isEqualTo(0)
        clock = realCatalogNow.plus(Duration.ofHours(25))
        assertThat(repo(fetcher, cache).refreshIfDue()).isTrue()
        assertThat(fetcher.calls).isEqualTo(1)
    }

    @Test fun corruptCacheFallsBackToBase() = runBlocking {
        val cache = MemoryCache(StoredCatalog("garbage".toByteArray(), realCatalogNow))
        assertThat(repo(Fetcher { real }, cache).loadedCatalogForLaunch().source).isEqualTo(CatalogSource.BUNDLED_BASE)
    }

    @Test fun validCacheIsPreferredWhenItMatchesTheRenewedBaseSchema() = runBlocking {
        clock = Instant.parse("2026-10-20T00:00:00Z")
        val validCache = RemoteCatalogVerifier.verifyAndDecode(real, realCatalogNow)
        val cacheBytes = "cache".toByteArray()
        val cache = MemoryCache(StoredCatalog(cacheBytes, clock))
        val repo = RemoteCatalogRepository(real, Fetcher { real }, cache, { clock }) { bytes, now ->
            if (bytes === cacheBytes) validCache else RemoteCatalogVerifier.verifyAndDecode(bytes, now)
        }
        val loaded = repo.loadedCatalogForLaunch()
        assertThat(loaded.source).isEqualTo(CatalogSource.CACHED_REMOTE)
        assertThat(loaded.payload.games).hasSize(48)
    }

    @Test fun renewedBaseStartsWithoutAnyCacheAfterPreviousExpiry() = runBlocking {
        clock = Instant.parse("2026-10-20T00:00:00Z")
        val loaded = repo(Fetcher { real }, MemoryCache()).loadedCatalogForLaunch()
        assertThat(loaded.source).isEqualTo(CatalogSource.BUNDLED_BASE)
        assertThat(loaded.payload.games).hasSize(48)
    }

    @Test fun refreshStillRunsWhenOnlyTheBaseIsExpired() = runBlocking {
        clock = Instant.parse("2026-11-17T00:00:00Z")
        val fresh = RemoteCatalogVerifier.verifyAndDecode(real, realCatalogNow)
        val cache = MemoryCache()
        val fetcher = Fetcher { "novo".toByteArray() }
        val repo = RemoteCatalogRepository(real, fetcher, cache, { clock }) { bytes, now ->
            if (String(bytes) == "novo") fresh else RemoteCatalogVerifier.verifyAndDecode(bytes, now)
        }
        assertThat(repo.refreshIfDue()).isTrue()
        assertThat(repo.loadedCatalogForLaunch().source).isEqualTo(CatalogSource.CACHED_REMOTE)
    }
}
