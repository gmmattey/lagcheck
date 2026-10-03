package com.lagcheck.catalog

import com.lagcheck.domain.model.MeasurementConfidence
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.rules.QualityEvaluator
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonObject
import java.net.URI
import java.time.Duration
import java.time.Instant
import java.util.Base64

/** Chaves públicas Ed25519 do catálogo (iguais às do iOS). A privada nunca está no app nem no Worker. */
object CatalogSigningKeys {
    const val V3_PUBLIC_KEY_BASE64 = "oe/5VSQfhWcma+W6DdUzAESJpjgTrLtkXAcT0nEbDwo="
}

/**
 * Verifica assinatura, validade, schema e regras de negócio do catálogo. Nenhuma UI interpreta JSON remoto:
 * só o `CatalogPayload` validado sai daqui. Android aceita apenas o schema 3 (o único publicado em produção).
 */
object RemoteCatalogVerifier {
    const val ROUTED_SCHEMA_VERSION = 3
    const val ALGORITHM = "Ed25519"
    const val MAXIMUM_PAYLOAD_BYTES = 64 * 1024
    private val MAX_VALIDITY: Duration = Duration.ofDays(30)

    fun verifyAndDecode(
        envelopeJson: ByteArray,
        now: Instant = Instant.now(),
        publicKeyBase64: String = CatalogSigningKeys.V3_PUBLIC_KEY_BASE64
    ): CatalogPayload {
        val envelope = try {
            Json.parseToJsonElement(envelopeJson.toString(Charsets.UTF_8)).jsonObject
        } catch (e: Exception) {
            throw RemoteCatalogException(RemoteCatalogError.MALFORMED_ENVELOPE, e)
        }
        val schemaVersion = envelope.int("schemaVersion") ?: throw RemoteCatalogException(RemoteCatalogError.MALFORMED_ENVELOPE)
        val catalogVersion = envelope.string("catalogVersion")
        val issuedAtRaw = envelope.string("issuedAt")
        val expiresAtRaw = envelope.string("expiresAt")
        val algorithm = envelope.string("algorithm")
        val payloadB64 = envelope.string("payloadBase64")
        val signatureB64 = envelope.string("signatureBase64")
        if (catalogVersion == null || issuedAtRaw == null || expiresAtRaw == null || algorithm == null ||
            payloadB64 == null || signatureB64 == null
        ) throw RemoteCatalogException(RemoteCatalogError.MALFORMED_ENVELOPE)

        if (schemaVersion != ROUTED_SCHEMA_VERSION) throw RemoteCatalogException(RemoteCatalogError.UNSUPPORTED_ENVELOPE_SCHEMA)
        if (algorithm != ALGORITHM) throw RemoteCatalogException(RemoteCatalogError.UNSUPPORTED_ALGORITHM)

        val issuedAt = issuedAtRaw.toInstantOrNull()
        val expiresAt = expiresAtRaw.toInstantOrNull()
        if (issuedAt == null || expiresAt == null || !expiresAt.isAfter(issuedAt) ||
            Duration.between(issuedAt, expiresAt) > MAX_VALIDITY
        ) throw RemoteCatalogException(RemoteCatalogError.INVALID_DATES)
        if (issuedAt.isAfter(now) || !expiresAt.isAfter(now)) throw RemoteCatalogException(RemoteCatalogError.EXPIRED)

        val payload: ByteArray
        val signature: ByteArray
        val publicKey: ByteArray
        try {
            payload = Base64.getDecoder().decode(payloadB64)
            signature = Base64.getDecoder().decode(signatureB64)
            publicKey = Base64.getDecoder().decode(publicKeyBase64)
        } catch (e: IllegalArgumentException) {
            throw RemoteCatalogException(RemoteCatalogError.INVALID_BASE64, e)
        }
        if (payload.size > MAXIMUM_PAYLOAD_BYTES) throw RemoteCatalogException(RemoteCatalogError.PAYLOAD_TOO_LARGE)
        // A assinatura incide sobre os bytes decodificados de payloadBase64, nunca sobre o JSON do envelope.
        if (!Ed25519.verify(publicKey, payload, signature)) throw RemoteCatalogException(RemoteCatalogError.INVALID_SIGNATURE)

        val decoded = try {
            decodePayload(Json.parseToJsonElement(payload.toString(Charsets.UTF_8)).jsonObject)
        } catch (e: RemoteCatalogException) {
            throw e
        } catch (e: Exception) {
            throw RemoteCatalogException(RemoteCatalogError.MALFORMED_PAYLOAD, e)
        }
        if (decoded.schemaVersion != schemaVersion || decoded.catalogVersion != catalogVersion) {
            throw RemoteCatalogException(RemoteCatalogError.VERSION_MISMATCH)
        }
        validate(decoded)
        return decoded
    }

    // region Decodificação

    private fun decodePayload(o: JsonObject): CatalogPayload {
        fun bad(): Nothing = throw RemoteCatalogException(RemoteCatalogError.MALFORMED_PAYLOAD)
        val profiles = o.array("profiles")?.map {
            val p = it.jsonObject
            CatalogProfile(p.string("id") ?: bad(), p.string("ruleVersion") ?: bad())
        } ?: bad()
        val regions = o.array("regions")?.map { decodeRegion(it.jsonObject) } ?: bad()
        val games = o.array("games")?.map { decodeGame(it.jsonObject) } ?: bad()
        return CatalogPayload(
            schemaVersion = o.int("schemaVersion") ?: bad(),
            catalogVersion = o.string("catalogVersion") ?: bad(),
            assetBaseUrl = o.string("assetBaseURL"),
            profiles = profiles,
            regions = regions,
            games = games
        )
    }

    private fun decodeDestination(o: JsonObject, forcedKind: ProbeProtocolKind? = null, portKey: String = "port"): ProbeDestination {
        val kind = forcedKind ?: ProbeProtocolKind.entries.firstOrNull { it.raw == o.string("protocolKind") }
            ?: throw RemoteCatalogException(RemoteCatalogError.MALFORMED_PAYLOAD)
        val port = o.int(portKey) ?: throw RemoteCatalogException(RemoteCatalogError.MALFORMED_PAYLOAD)
        val host = o.string("host") ?: throw RemoteCatalogException(RemoteCatalogError.MALFORMED_PAYLOAD)
        if (port !in 1..65535) throw RemoteCatalogException(RemoteCatalogError.MALFORMED_PAYLOAD)
        return ProbeDestination(host, port, kind)
    }

    private fun decodeRegion(o: JsonObject): CatalogRegion {
        fun bad(): Nothing = throw RemoteCatalogException(RemoteCatalogError.MALFORMED_PAYLOAD)
        val label = (o["label"] as? JsonObject)?.mapValues { (it.value as? JsonPrimitive)?.contentOrNull ?: bad() } ?: bad()
        val evidence = (o["evidence"] as? JsonObject)?.let {
            CatalogDestinationEvidence(it.string("id") ?: bad(), it.string("sourceURL") ?: bad(), it.string("reviewedAt") ?: bad())
        }
        return CatalogRegion(o.string("id") ?: bad(), label, decodeDestination(o["probe"]?.jsonObject ?: bad()), evidence)
    }

    private fun decodeGame(o: JsonObject): CatalogGame {
        fun bad(): Nothing = throw RemoteCatalogException(RemoteCatalogError.MALFORMED_PAYLOAD)
        val artwork = (o["artwork"] as? JsonObject)?.let { CatalogArtwork(it.string("path") ?: bad(), it.string("sha256") ?: bad()) }
        val rating = (o["rating"] as? JsonObject)?.let {
            val status = it.string("status") ?: bad()
            CatalogRating(
                verified = status == "verified",
                value = (it["value"] as? JsonPrimitive)?.doubleOrNull,
                scale = (it["scale"] as? JsonPrimitive)?.doubleOrNull,
                sourceName = it.string("sourceName") ?: bad(),
                sourceUrl = it.string("sourceURL"),
                updatedAt = it.string("updatedAt")
            ).also { _ -> if (status != "verified" && status != "pendingVerification") bad() }
        }
        val contexts = o.array("contexts")?.map { decodeContext(it.jsonObject) } ?: bad()
        return CatalogGame(o.string("id") ?: bad(), o.string("name") ?: bad(), artwork, rating, contexts)
    }

    private fun decodeContext(o: JsonObject): CatalogGameContext {
        fun bad(): Nothing = throw RemoteCatalogException(RemoteCatalogError.MALFORMED_PAYLOAD)
        val platforms = o.array("platforms")?.map { (it as? JsonPrimitive)?.contentOrNull ?: bad() }?.toSet() ?: bad()
        val availability = o.string("availability") ?: bad()
        if (availability != "available" && availability != "unavailable") bad()
        return CatalogGameContext(
            market = o.string("market") ?: bad(),
            platformKeys = platforms,
            profileId = o.string("profileID") ?: bad(),
            availableForMeasurement = availability == "available",
            hasLegacyMeasurement = o["measurement"].let { it != null && it !is JsonNull },
            routes = o.array("routes")?.map { decodeRoute(it.jsonObject) }
        )
    }

    private fun decodeRoute(o: JsonObject): CatalogRoute {
        fun bad(): Nothing = throw RemoteCatalogException(RemoteCatalogError.MALFORMED_PAYLOAD)
        val selection = o["selection"] as? JsonObject
        val candidates = selection?.array("candidates")?.map { decodeCandidate(it.jsonObject) }
        return CatalogRoute(
            id = o.string("id") ?: bad(),
            kind = RouteKind.entries.firstOrNull { it.raw == o.string("kind") } ?: bad(),
            status = RouteStatus.entries.firstOrNull { it.raw == o.string("status") } ?: bad(),
            regionId = o.string("regionID") ?: bad(),
            destination = (o["destination"] as? JsonObject)?.let { decodeDestination(it) },
            strategy = MeasurementStrategy.entries.firstOrNull { it.raw == o.string("strategy") } ?: bad(),
            confidence = when (o.string("confidence")) {
                "medium" -> MeasurementConfidence.MEDIUM
                "high" -> MeasurementConfidence.HIGH
                else -> bad()
            },
            precisionKey = o.string("precisionKey") ?: bad(),
            validUntil = o.string("validUntil"),
            selectionMaxCandidates = selection?.int("maxCandidates"),
            candidates = candidates
        )
    }

    private fun decodeCandidate(o: JsonObject): RouteCandidate {
        fun bad(): Nothing = throw RemoteCatalogException(RemoteCatalogError.MALFORMED_PAYLOAD)
        val identity = o["expectedIdentity"] as? JsonObject ?: bad()
        return RouteCandidate(
            id = o.string("id") ?: bad(),
            priority = o.int("priority") ?: bad(),
            destination = decodeDestination(o, ProbeProtocolKind.STEAM_A2S, portKey = "queryPort"),
            regionId = o.string("region") ?: bad(),
            identity = RouteIdentity(identity.int("appID") ?: bad(), identity.string("gameDirectory") ?: bad(), identity.string("namePrefix")),
            operatorEvidenceUrl = o.string("operatorEvidenceURL") ?: bad()
        )
    }

    // endregion

    // region Validação de negócio (schema 3, espelho de validateRoutedPayload)

    private fun validate(p: CatalogPayload) {
        fun fail(e: RemoteCatalogError): Nothing = throw RemoteCatalogException(e)
        val base = p.assetBaseUrl?.let { runCatching { URI(it) }.getOrNull() }
        if (p.catalogVersion.isEmpty() || base == null || base.scheme != "https") fail(RemoteCatalogError.INVALID_GAME)
        if (p.profiles.map { it.id }.toSet().size != p.profiles.size) fail(RemoteCatalogError.DUPLICATE_PROFILE)
        if (p.regions.map { it.id }.toSet().size != p.regions.size) fail(RemoteCatalogError.DUPLICATE_REGION)
        if (p.games.map { it.id }.toSet().size != p.games.size) fail(RemoteCatalogError.DUPLICATE_GAME)

        val profiles = p.profiles.associateBy { it.id }
        if (!profiles.values.all { prof ->
                val id = QualityProfileId.fromRaw(prof.id) ?: return@all false
                QualityEvaluator.supports(id, prof.ruleVersion)
            }
        ) fail(RemoteCatalogError.UNKNOWN_PROFILE)

        val regions = p.regions.associateBy { it.id }
        if (!regions.values.all {
                it.id in GlobalProbeRegions.allowedRegionIds &&
                    it.probe.host == "gamelift-ping.${it.id}.api.aws" &&
                    it.probe.port == 7770 && it.probe.protocolKind == ProbeProtocolKind.GAMELIFT_PING
            }
        ) fail(RemoteCatalogError.UNKNOWN_REGION)

        for (game in p.games) {
            val artwork = game.artwork
            val rating = game.rating
            if (!validIdentifier(game.id) || game.name.isEmpty() || game.contexts.isEmpty() ||
                artwork == null || !validArtwork(artwork) || rating == null || !validRating(rating)
            ) fail(RemoteCatalogError.INVALID_GAME)

            val covered = mutableSetOf<String>()
            for (ctx in game.contexts) {
                if (!validMarket(ctx.market) || ctx.platformKeys.isEmpty() || profiles[ctx.profileId] == null ||
                    !ctx.platformKeys.all { it in Platform.knownCatalogKeys }
                ) fail(RemoteCatalogError.INVALID_CONTEXT)
                for (platform in ctx.platformKeys) if (!covered.add("${ctx.market}:$platform")) fail(RemoteCatalogError.INVALID_CONTEXT)
                if (ctx.hasLegacyMeasurement) fail(RemoteCatalogError.INVALID_CONTEXT)
                val routes = ctx.routes
                if (!ctx.availableForMeasurement || routes.isNullOrEmpty()) fail(RemoteCatalogError.INVALID_AVAILABILITY)
                if (routes.map { it.id }.toSet().size != routes.size ||
                    routes.none { it.kind == RouteKind.AWS_FALLBACK && it.status == RouteStatus.ACTIVE }
                ) fail(RemoteCatalogError.INVALID_ROUTE)
                routes.forEach { validateRoute(it, regions) }
            }
        }
    }

    private fun validateRoute(route: CatalogRoute, regions: Map<String, CatalogRegion>) {
        fun fail(): Nothing = throw RemoteCatalogException(RemoteCatalogError.INVALID_ROUTE)
        if (!validIdentifier(route.id) || !validIdentifier(route.regionId) || route.precisionKey.isEmpty()) fail()
        route.validUntil?.let { if (it.toInstantOrNull() == null) fail() }
        when (route.kind) {
            RouteKind.AWS_FALLBACK -> {
                val region = regions[route.regionId]
                if (route.status != RouteStatus.ACTIVE ||
                    route.strategy != MeasurementStrategy.GENERIC_REGION ||
                    route.confidence != MeasurementConfidence.MEDIUM ||
                    route.precisionKey != "regionalReference" ||
                    region == null ||
                    (route.destination != null && route.destination != region.probe)
                ) fail()
            }
            RouteKind.GAME_OWNED -> {
                if (route.status == RouteStatus.ACTIVE) {
                    val candidates = route.candidates
                    if (route.destination != null || route.selectionMaxCandidates != 3 || candidates.isNullOrEmpty() ||
                        candidates.size > 3 ||
                        candidates.map { it.id }.toSet().size != candidates.size ||
                        candidates.map { "${it.destination.host}:${it.destination.port}" }.toSet().size != candidates.size ||
                        route.strategy != MeasurementStrategy.DEDICATED_SERVER ||
                        route.confidence != MeasurementConfidence.HIGH ||
                        route.precisionKey != "dedicatedServer" ||
                        !candidates.all(::validCandidate)
                    ) fail()
                } else if (route.destination != null || route.candidates != null) fail()
            }
        }
    }

    private fun validCandidate(c: RouteCandidate): Boolean {
        if (!validIdentifier(c.id) || c.priority < 0 || c.destination.protocolKind != ProbeProtocolKind.STEAM_A2S ||
            !validIdentifier(c.regionId) || c.identity.appId <= 0 || c.identity.gameDirectory.isEmpty() ||
            c.identity.gameDirectory.length > 80 || c.identity.gameDirectory != c.identity.gameDirectory.lowercase() ||
            c.identity.gameDirectory.contains('\u0000') || !isHttps(c.operatorEvidenceUrl)
        ) return false
        val prefix = c.identity.serverNamePrefix ?: return true
        return prefix.isNotEmpty() && prefix.length <= 80 && prefix.none { it.code in 0..31 || it.code in 127..159 }
    }

    private fun validIdentifier(v: String) =
        v.isNotEmpty() && v == v.lowercase() && v.all { it.code < 128 && (it.isLetterOrDigit() || it == '-') }

    private fun validMarket(v: String) = v.length == 2 && v == v.uppercase() && v.all { it.isLetter() }

    private fun validArtwork(a: CatalogArtwork) =
        a.path.startsWith("artwork/") && !a.path.contains("..") &&
            a.sha256.length == 64 && a.sha256.all { it in '0'..'9' || it in 'a'..'f' || it in 'A'..'F' }

    private fun validRating(r: CatalogRating): Boolean {
        if (r.verified) {
            val v = r.value ?: return false
            val s = r.scale ?: return false
            val url = r.sourceUrl ?: return false
            val updated = r.updatedAt ?: return false
            return v >= 0 && s > 0 && v <= s && r.sourceName.isNotEmpty() && isHttps(url) && updated.toInstantOrNull() != null
        }
        return r.value == null && r.scale == null && r.sourceUrl == null && r.updatedAt == null && r.sourceName.isNotEmpty()
    }

    private fun isHttps(url: String) = runCatching { URI(url) }.getOrNull()?.scheme == "https"

    // endregion

    private fun JsonObject.string(key: String): String? = (this[key] as? JsonPrimitive)?.takeIf { it.isString }?.contentOrNull
    private fun JsonObject.int(key: String): Int? = (this[key] as? JsonPrimitive)?.takeIf { !it.isString }?.intOrNull
    private fun JsonObject.array(key: String): JsonArray? = this[key] as? JsonArray
}
