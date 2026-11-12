package com.lagcheck.desktop

import com.lagcheck.catalog.CatalogPayload
import com.lagcheck.catalog.GameContext
import com.lagcheck.catalog.Platform
import com.lagcheck.catalog.RemoteCatalogResolution
import com.lagcheck.catalog.RemoteCatalogResolver
import com.lagcheck.catalog.RemoteCatalogVerifier
import com.lagcheck.network.transport.UdpProbeTransport
import com.lagcheck.network.worker.HttpLoadTransport
import com.lagcheck.domain.model.OfficialGameCatalog
import com.lagcheck.session.CheckOrchestrator
import com.lagcheck.session.CheckProgress
import com.lagcheck.session.CheckResult

data class GameEntry(val id: String, val name: String, val artworkResource: String?)
data class MeasuredRegion(val id: String, val label: String)
data class Outcome(val result: CheckResult, val region: MeasuredRegion)

/** Protótipo: o mesmo Check do Android (repouso + carga) a partir do PC, usando o catálogo embarcado. */
object Measurement {
    private val orchestrator = CheckOrchestrator(UdpProbeTransport(), HttpLoadTransport())

    private val payload: CatalogPayload? by lazy {
        Measurement::class.java.getResourceAsStream("/catalog-base.json")?.use { runCatching { RemoteCatalogVerifier.decodeBundled(it.readBytes()) }.getOrNull() }
    }

    private fun resolve(gameId: String?) = payload?.let {
        runCatching {
            val ctx = if (gameId == null) GameContext.genericGaming(platform = Platform.PC) else GameContext(gameId, "BR", Platform.PC)
            (RemoteCatalogResolver.resolve(ctx, it) as? RemoteCatalogResolution.Available)?.context
        }.getOrNull()
    }

    /** Só jogos que o catálogo assinado deixa medir a partir de um PC. Nada é inventado. */
    val games: List<GameEntry> by lazy {
        val approvedArtwork = OfficialGameCatalog.games.associate { it.id to it.drawableResName }
        payload?.games.orEmpty().filter { resolve(it.id) != null }.map {
            GameEntry(it.id, it.name, approvedArtwork[it.id].orEmpty().ifBlank { null })
        }.sortedBy { it.name }
    }

    fun measuredRegion(gameId: String?): MeasuredRegion? {
        val context = resolve(gameId) ?: return null
        val label = payload?.regions?.firstOrNull { it.id == context.regionId }?.label?.get("pt-BR") ?: context.regionId
        return MeasuredRegion(context.regionId, label)
    }

    suspend fun run(gameId: String?, onProgress: (CheckProgress) -> Unit): Outcome? {
        val context = resolve(gameId) ?: return null
        val region = measuredRegion(gameId) ?: return null
        return Outcome(orchestrator.run(context, onProgress = onProgress), region)
    }
}
