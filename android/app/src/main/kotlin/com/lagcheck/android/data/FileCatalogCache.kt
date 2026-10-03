package com.lagcheck.android.data

import android.content.Context
import android.util.Base64
import com.lagcheck.catalog.CatalogCache
import com.lagcheck.catalog.StoredCatalog
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File
import java.time.Instant

/**
 * Cache do último catálogo remoto que passou por assinatura e validação. Escrita atômica (arquivo temporário +
 * rename): queda de energia no meio não deixa um cache pela metade. Só entra aqui o que o verificador aceitou.
 */
class FileCatalogCache(context: Context) : CatalogCache {
    private val file = File(context.filesDir, "remote_catalog_cache.json")

    override suspend fun load(): StoredCatalog? = withContext(Dispatchers.IO) {
        runCatching {
            if (!file.exists()) return@runCatching null
            val json = JSONObject(file.readText())
            StoredCatalog(
                envelope = Base64.decode(json.getString("envelope"), Base64.NO_WRAP),
                refreshedAt = Instant.ofEpochMilli(json.getLong("refreshedAtMillis"))
            )
        }.getOrNull()
    }

    override suspend fun save(catalog: StoredCatalog) = withContext(Dispatchers.IO) {
        runCatching {
            val json = JSONObject()
                .put("refreshedAtMillis", catalog.refreshedAt.toEpochMilli())
                .put("envelope", Base64.encodeToString(catalog.envelope, Base64.NO_WRAP))
            val tmp = File(file.parentFile, file.name + ".tmp")
            tmp.writeText(json.toString())
            if (!tmp.renameTo(file)) { file.delete(); tmp.renameTo(file) }
        }
        Unit
    }
}
