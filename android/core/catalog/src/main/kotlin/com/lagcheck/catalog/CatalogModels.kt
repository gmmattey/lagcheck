package com.lagcheck.catalog

import com.lagcheck.domain.model.MeasurementConfidence
import com.lagcheck.domain.model.QualityProfileId
import java.time.Instant

enum class MeasurementStrategy(val raw: String) { GENERIC_REGION("genericRegion"), DEDICATED_SERVER("dedicatedServer") }

enum class ProbeProtocolKind(val raw: String) {
    GAMELIFT_PING("gameLiftPing"), PLAYFAB_QOS("playFabQoS"), STEAM_A2S("steamA2S")
}

/**
 * Plataforma do pedido. O catálogo v3 assinado só publica `iphone|playstation|xbox|pc|nintendo`.
 * `MOBILE` (celular Android) usa o contexto `android` se o catálogo um dia publicar e, até lá, o contexto
 * `iphone`, cujas rotas são as mesmas (Decisão 68). Nenhuma assinatura é reinterpretada: só a escolha do contexto.
 */
enum class Platform(val catalogKeys: List<String>) {
    MOBILE(listOf("android", "iphone")),
    PLAYSTATION(listOf("playstation")),
    XBOX(listOf("xbox")),
    PC(listOf("pc")),
    NINTENDO(listOf("nintendo"));

    companion object {
        val knownCatalogKeys: Set<String> = setOf("iphone", "android", "playstation", "xbox", "pc", "nintendo")
    }
}

data class ProbeDestination(val host: String, val port: Int, val protocolKind: ProbeProtocolKind)

data class CatalogDestinationEvidence(val id: String, val sourceUrl: String, val reviewedAt: String)

data class CatalogRegion(
    val id: String,
    val label: Map<String, String>,
    val probe: ProbeDestination,
    val evidence: CatalogDestinationEvidence?
)

enum class RouteKind(val raw: String) { GAME_OWNED("gameOwned"), AWS_FALLBACK("awsFallback") }
enum class RouteStatus(val raw: String) { ACTIVE("active"), PENDING("pending"), UNAVAILABLE("unavailable") }

data class RouteIdentity(val appId: Int, val gameDirectory: String, val serverNamePrefix: String?)

data class RouteCandidate(
    val id: String,
    val priority: Int,
    val destination: ProbeDestination,
    val regionId: String,
    val identity: RouteIdentity,
    val operatorEvidenceUrl: String
)

data class CatalogRoute(
    val id: String,
    val kind: RouteKind,
    val status: RouteStatus,
    val regionId: String,
    val destination: ProbeDestination?,
    val strategy: MeasurementStrategy,
    val confidence: MeasurementConfidence,
    val precisionKey: String,
    val validUntil: String?,
    val selectionMaxCandidates: Int?,
    val candidates: List<RouteCandidate>?,
    val selectionMode: String? = null
)

data class CatalogGameContext(
    val market: String,
    /** Chaves cruas do catálogo (ex.: "iphone"), não o enum de pedido. */
    val platformKeys: Set<String>,
    val profileId: String,
    val availableForMeasurement: Boolean,
    val hasLegacyMeasurement: Boolean,
    val routes: List<CatalogRoute>?
)

data class CatalogArtwork(val path: String, val sha256: String)

data class CatalogRating(
    val verified: Boolean,
    val value: Double?,
    val scale: Double?,
    val sourceName: String,
    val sourceUrl: String?,
    val updatedAt: String?
)

data class CatalogGame(
    val id: String,
    val name: String,
    val artwork: CatalogArtwork?,
    val rating: CatalogRating?,
    val contexts: List<CatalogGameContext>
)

data class CatalogProfile(val id: String, val ruleVersion: String)

data class CatalogPayload(
    val schemaVersion: Int,
    val catalogVersion: String,
    val assetBaseUrl: String?,
    val profiles: List<CatalogProfile>,
    val regions: List<CatalogRegion>,
    val games: List<CatalogGame>
)

/** Pedido de medição: jogo + mercado + plataforma. */
data class GameContext(val gameId: String, val market: String = "BR", val platform: Platform = Platform.MOBILE) {
    val isGenericGaming: Boolean get() = gameId == GENERIC_GAMING_ID

    companion object {
        const val GENERIC_GAMING_ID = "generic-gaming"
        fun genericGaming(market: String = "BR", platform: Platform = Platform.MOBILE) =
            GameContext(GENERIC_GAMING_ID, market, platform)
    }
}

/** Contexto já resolvido contra um catálogo validado. É tudo que o transporte precisa. */
data class ResolvedMeasurementContext(
    val context: GameContext,
    val catalogVersion: String,
    val profileId: QualityProfileId,
    val profileRuleVersion: String,
    val regionId: String,
    val destination: ProbeDestination,
    val strategy: MeasurementStrategy,
    val confidence: MeasurementConfidence,
    val precisionKey: String,
    val routeId: String? = null,
    val routeKind: RouteKind? = null
)

sealed class RemoteCatalogResolution {
    data class Available(val context: ResolvedMeasurementContext) : RemoteCatalogResolution()
    data object Unavailable : RemoteCatalogResolution()
}

enum class RemoteCatalogError {
    MALFORMED_ENVELOPE, UNSUPPORTED_ENVELOPE_SCHEMA, UNSUPPORTED_ALGORITHM, INVALID_DATES, EXPIRED,
    INVALID_BASE64, INVALID_SIGNATURE, PAYLOAD_TOO_LARGE, MALFORMED_PAYLOAD, VERSION_MISMATCH,
    DUPLICATE_PROFILE, DUPLICATE_REGION, DUPLICATE_GAME, INVALID_GAME, INVALID_CONTEXT, UNKNOWN_PROFILE,
    UNKNOWN_REGION, INVALID_AVAILABILITY, INVALID_ROUTE, INVALID_ARTWORK, INVALID_RATING, UNSUPPORTED_CATALOG
}

class RemoteCatalogException(val error: RemoteCatalogError, cause: Throwable? = null) :
    Exception(error.name, cause)

class CatalogResolutionException(message: String) : Exception(message)

internal fun String.toInstantOrNull(): Instant? = try { Instant.parse(this) } catch (_: Exception) { null }

/** Candidato próprio já resolvido, ainda NÃO elegível: só vira rota depois da pré-validação de identidade. */
data class OwnedRouteCandidate(val context: ResolvedMeasurementContext, val identity: RouteIdentity, val priority: Int)

/** Política automática de uma rota v3: candidatos próprios assinados (ordem determinística) e a AWS assinada como retorno. */
data class RoutePlan(val ownedCandidates: List<OwnedRouteCandidate>, val fallback: ResolvedMeasurementContext)

/**
 * Porta para a pré-validação de uma rota própria. Recebe só candidato do catálogo assinado; a implementação
 * nunca descobre nem percorre outros hosts. Qualquer falha devolve `false`.
 */
fun interface GameRoutePreflighting {
    suspend fun validates(candidate: ResolvedMeasurementContext, identity: RouteIdentity): Boolean
}
