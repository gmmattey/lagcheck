package com.lagcheck.session

import com.google.common.truth.Truth.assertThat
import com.google.common.truth.Truth.assertWithMessage
import com.lagcheck.catalog.CatalogPayload
import com.lagcheck.catalog.CatalogRoute
import com.lagcheck.catalog.GameContext
import com.lagcheck.catalog.GameRoutePreflighting
import com.lagcheck.catalog.MeasurementStrategy
import com.lagcheck.catalog.Platform
import com.lagcheck.catalog.ProbeDestination
import com.lagcheck.catalog.ProbeProtocolKind
import com.lagcheck.catalog.RemoteCatalogResolver
import com.lagcheck.catalog.RemoteCatalogVerifier
import com.lagcheck.catalog.RouteCandidate
import com.lagcheck.catalog.RouteIdentity
import com.lagcheck.catalog.RouteKind
import com.lagcheck.catalog.RouteStatus
import com.lagcheck.domain.model.MeasurementConfidence
import java.io.File
import java.time.Instant
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Test

/** Seleção automática de rota própria (Decisões 37, 38/39, 78): mesmos vetores de decisão do iOS. */
class AutomaticGameRouteResolverTest {
    private val now = Instant.parse("2026-10-20T00:00:00Z")
    private val root: File = generateSequence(File(System.getProperty("user.dir")).absoluteFile) { it.parentFile }
        .first { File(it, "worker/catalog/catalog-v3.candidate.json").exists() }
    private val signed = RemoteCatalogVerifier.decodeBundled(File(root, "worker/catalog/catalog-v3.candidate.json").readBytes())
    private val identity = RouteIdentity(730, "csgo", "Community")
    private val request = GameContext("fortnite", "BR", Platform.MOBILE)

    private fun candidate(id: String, priority: Int) = RouteCandidate(
        id = id, priority = priority,
        destination = ProbeDestination("$id.community.example", 27015, ProbeProtocolKind.STEAM_A2S),
        regionId = "sa-east-1", identity = identity, operatorEvidenceUrl = "https://operator.example/$id"
    )

    /** Payload sintético: troca a rota própria pendente de fortnite/mobile por uma ativa com os candidatos dados. */
    private fun payloadWithActiveOwned(candidates: List<RouteCandidate>): CatalogPayload = signed.copy(
        games = signed.games.map { game ->
            if (game.id != "fortnite") game else game.copy(contexts = game.contexts.map { ctx ->
                if ("iphone" !in ctx.platformKeys) ctx else ctx.copy(routes = ctx.routes!!.map { r ->
                    if (r.kind != RouteKind.GAME_OWNED) r else r.copy(
                        status = RouteStatus.ACTIVE, destination = null, strategy = MeasurementStrategy.DEDICATED_SERVER,
                        confidence = MeasurementConfidence.HIGH, precisionKey = "dedicatedServer",
                        selectionMaxCandidates = 3, selectionMode = "automaticValidatedCandidates", candidates = candidates
                    )
                })
            })
        }
    )

    private fun accepting(vararg ids: String) = GameRoutePreflighting { ctx, _ -> ids.any { ctx.routeId!!.endsWith("-$it") } }

    @Test fun routeDecisionMatchesSharedVectors() = runBlocking {
        val vectors = Json.parseToJsonElement(File(root, "ios/Tests/Vectors/steam-a2s-preflight-vectors.json").readText())
            .jsonObject["routeDecisionVectors"]!!.jsonArray
        assertThat(vectors).hasSize(5)
        for (v in vectors.map { it.jsonObject }) {
            val id = v["id"]!!.jsonPrimitive.content
            val specs = v["candidates"]!!.jsonArray.map { it.jsonObject }
            val payload = payloadWithActiveOwned(specs.map { candidate(it["id"]!!.jsonPrimitive.content, it["priority"]!!.jsonPrimitive.int) })
            val accepted = specs.filter { it["preflight"]!!.jsonPrimitive.content == "accept" }.map { it["id"]!!.jsonPrimitive.content }
            val resolved = AutomaticGameRouteResolver.resolve(request, payload, accepting(*accepted.toTypedArray()), now)!!
            val expected = v["expectedRoute"]!!.jsonPrimitive.content
            if (expected == "aws-fallback") {
                assertWithMessage(id).that(resolved.routeKind).isEqualTo(RouteKind.AWS_FALLBACK)
                assertWithMessage(id).that(resolved.destination.protocolKind).isEqualTo(ProbeProtocolKind.GAMELIFT_PING)
            } else {
                assertWithMessage(id).that(resolved.routeKind).isEqualTo(RouteKind.GAME_OWNED)
                assertWithMessage(id).that(resolved.routeId).endsWith("-$expected")
            }
        }
    }

    @Test fun planRegionalFallsBackToAwsReferenceWhenNothingValidates() = runBlocking {
        val payload = payloadWithActiveOwned(listOf(candidate("a", 10)))
        val plan = MeasurementPlanner.planRegionalAutomatic(payload, "fortnite", "Mobile", accepting(), now = now)!!
        assertThat(plan.isGameOwned).isFalse()
        assertThat(plan.snapshot.candidates.map { it.resolvedContext.routeKind }.toSet()).containsExactly(RouteKind.AWS_FALLBACK)
        assertThat(plan.snapshot.candidates.size).isGreaterThan(1) // pré-leitura multirregional (Decisão 90)
    }

    @Test fun planRegionalUsesOnlyTheValidatedOwnedRoute() = runBlocking {
        val payload = payloadWithActiveOwned(listOf(candidate("a", 10), candidate("b", 20)))
        val plan = MeasurementPlanner.planRegionalAutomatic(payload, "fortnite", "Mobile", accepting("b"), now = now)!!
        assertThat(plan.isGameOwned).isTrue()
        assertThat(plan.snapshot.candidates.single().resolvedContext.destination.host).isEqualTo("b.community.example")
    }

    @Test fun plainResolveNeverMeasuresAnOwnedCandidateWithoutPreflight() {
        val payload = payloadWithActiveOwned(listOf(candidate("a", 10)))
        val resolved = (RemoteCatalogResolver.resolve(request, payload, now) as com.lagcheck.catalog.RemoteCatalogResolution.Available).context
        assertThat(resolved.routeKind).isEqualTo(RouteKind.AWS_FALLBACK)
    }

    /** Bloqueio de ativação: sem PCAP real nenhuma rota própria está ativa no envelope assinado. */
    @Test fun signedCatalogHasNoActiveGameOwnedRoute() {
        val owned: List<CatalogRoute> = signed.games.flatMap { it.contexts }.flatMap { it.routes.orEmpty() }.filter { it.kind == RouteKind.GAME_OWNED }
        assertThat(owned).isNotEmpty()
        assertThat(owned.map { it.status }.toSet()).containsExactly(RouteStatus.PENDING)
        assertThat(owned.all { it.candidates == null && it.destination == null }).isTrue()
    }
}
