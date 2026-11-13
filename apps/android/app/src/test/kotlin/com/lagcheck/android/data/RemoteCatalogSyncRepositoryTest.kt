package com.lagcheck.android.data

import android.content.SharedPreferences
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.io.File
import java.nio.file.Files
import java.util.Base64

class RemoteCatalogSyncRepositoryTest {
    @Test
    fun syncUpdatesCacheAndRejectsDegradedPayload() {
        val baseBytes = File("src/main/assets/catalog-base.json").readBytes()
        val tempDir = Files.createTempDirectory("catalog-sync-test").toFile()
        try {
            val cacheFile = File(tempDir, "catalog-v3.json")
            val prefs = InMemorySharedPreferences()
            val updatedBytes = makeEnvelope(baseBytes, version = "v1-remote-android", maxRegions = null)
            val degradedBytes = makeEnvelope(baseBytes, version = "v1-shrunk", maxRegions = 1)
            val transport = FakeCatalogTransport(
                listOf(
                    CatalogHttpTransport.Response(200, updatedBytes, "\"etag-1\""),
                    CatalogHttpTransport.Response(304, ByteArray(0), null),
                    CatalogHttpTransport.Response(200, degradedBytes, "\"etag-2\"")
                )
            )
            val repo = RemoteCatalogSyncRepository(
                bundledEnvelope = baseBytes,
                cacheFile = cacheFile,
                prefs = prefs,
                transport = transport,
                refreshIntervalMs = 0L
            )

            val initial = repo.loadLocal()
            assertEquals("catalog-v3-2026.10.18.1", initial?.catalogVersion)

            val synced = repo.syncIfNeeded(force = true)
            assertEquals("v1-remote-android", synced?.catalogVersion)
            assertEquals("v1-remote-android", repo.loadLocal()?.catalogVersion)

            assertNull(repo.syncIfNeeded(force = true))
            assertNull(repo.syncIfNeeded(force = true))
            assertEquals("v1-remote-android", repo.loadLocal()?.catalogVersion)
        } finally {
            tempDir.deleteRecursively()
        }
    }

    private fun makeEnvelope(baseBytes: ByteArray, version: String, maxRegions: Int?): ByteArray {
        val envText = String(baseBytes, Charsets.UTF_8)
        val b64Match = Regex(""""payloadBase64"\s*:\s*"([^"]+)"""").find(envText)
        var payloadText = if (b64Match != null) {
            String(Base64.getDecoder().decode(b64Match.groupValues[1]), Charsets.UTF_8)
        } else {
            envText
        }
        payloadText = payloadText.replace("catalog-v3-2026.10.18.1", version)
        if (maxRegions != null) {
            // Substitui a lista de regiões por apenas 1 região para testar a trava contra downgrade.
            payloadText = payloadText.replace(
                Regex(""""regions"\s*:\s*\[.*?],"games""""),
                """"regions":[{"id":"sa-east-1","label":{"pt-BR":"São Paulo","en":"São Paulo","es":"São Paulo"},"probe":{"host":"gamelift-ping.sa-east-1.api.aws","port":7770,"protocolKind":"gameLiftPing"}}],"games""""
            )
        }
        return payloadText.toByteArray(Charsets.UTF_8)
    }
}

private class FakeCatalogTransport(
    private val responses: List<CatalogHttpTransport.Response>
) : CatalogHttpTransport {
    private var idx = 0
    override fun fetch(url: String, etag: String?): CatalogHttpTransport.Response {
        val current = responses[minOf(idx, responses.lastIndex)]
        idx += 1
        return current
    }
}

private class InMemorySharedPreferences : SharedPreferences {
    private val map = mutableMapOf<String, Any?>()
    override fun getAll(): MutableMap<String, *> = map.toMutableMap()
    override fun getString(key: String?, defValue: String?): String? = map[key] as? String ?: defValue
    override fun getStringSet(key: String?, defValues: MutableSet<String>?): MutableSet<String>? = defValues
    override fun getInt(key: String?, defValue: Int): Int = map[key] as? Int ?: defValue
    override fun getLong(key: String?, defValue: Long): Long = map[key] as? Long ?: defValue
    override fun getFloat(key: String?, defValue: Float): Float = map[key] as? Float ?: defValue
    override fun getBoolean(key: String?, defValue: Boolean): Boolean = map[key] as? Boolean ?: defValue
    override fun contains(key: String?): Boolean = map.containsKey(key)
    override fun edit(): SharedPreferences.Editor = Editor(map)
    override fun registerOnSharedPreferenceChangeListener(listener: SharedPreferences.OnSharedPreferenceChangeListener?) {}
    override fun unregisterOnSharedPreferenceChangeListener(listener: SharedPreferences.OnSharedPreferenceChangeListener?) {}

    private class Editor(private val map: MutableMap<String, Any?>) : SharedPreferences.Editor {
        private val pending = mutableMapOf<String, Any?>()
        override fun putString(key: String?, value: String?): SharedPreferences.Editor = apply { if (key != null) pending[key] = value }
        override fun putStringSet(key: String?, values: MutableSet<String>?): SharedPreferences.Editor = this
        override fun putInt(key: String?, value: Int): SharedPreferences.Editor = apply { if (key != null) pending[key] = value }
        override fun putLong(key: String?, value: Long): SharedPreferences.Editor = apply { if (key != null) pending[key] = value }
        override fun putFloat(key: String?, value: Float): SharedPreferences.Editor = apply { if (key != null) pending[key] = value }
        override fun putBoolean(key: String?, value: Boolean): SharedPreferences.Editor = apply { if (key != null) pending[key] = value }
        override fun remove(key: String?): SharedPreferences.Editor = apply { if (key != null) pending[key] = null }
        override fun clear(): SharedPreferences.Editor = apply { map.clear(); pending.clear() }
        override fun commit(): Boolean { apply(); return true }
        override fun apply() {
            for ((k, v) in pending) {
                if (v == null) map.remove(k) else map[k] = v
            }
            pending.clear()
        }
    }
}
