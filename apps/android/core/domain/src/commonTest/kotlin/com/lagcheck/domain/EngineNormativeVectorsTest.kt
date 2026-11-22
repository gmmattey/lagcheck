package com.lagcheck.domain

import com.lagcheck.domain.vectors.NormativeVectors
import com.lagcheck.domain.vectors.VGateway
import com.lagcheck.domain.vectors.VLoadTransfer
import com.lagcheck.engine.LagCheckEngine
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.double
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Vetores normativos executados pelo contrato público nos três alvos KMP. */
class EngineNormativeVectorsTest {
    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun decision135VectorsRunThroughTheJsonFacade() {
        NormativeVectors.all.forEach { vector ->
            val response = json.parseToJsonElement(LagCheckEngine.evaluate(vector.requestJson())).jsonObject
            val expected = vector.expected
            assertEquals(expected.verdict.name, response.string("verdict"), vector.id)
            if (expected.assertNoScore) assertNull(response["score"]?.jsonPrimitive?.contentOrNull, vector.id)
            expected.score?.let { assertEquals(it.toString(), response.string("score"), vector.id) }
            expected.loadTier?.let { assertEquals(it.name, response["loadImpact"]?.jsonObject?.string("tier"), vector.id) }
            expected.loadTransfer?.let { assertEquals(it.name, response.string("loadTransfer"), vector.id) }
            expected.primaryCause?.let { assertEquals(it, response.string("primaryCause"), vector.id) }
            expected.spikePattern?.let { assertEquals(it, response.string("spikePattern"), vector.id) }
            expected.packetLossPercentage?.let {
                val actual = response["rest"]!!.jsonObject["packetLossPercentage"]!!.jsonPrimitive.double
                assertTrue(kotlin.math.abs(actual - it) < 0.000001, "${vector.id}: expected $it, got $actual")
            }
            val recommendations = response["recommendations"]!!.jsonArray.map { it.jsonPrimitive.content }.toSet()
            expected.mustHaveRecommendations.forEach { assertTrue(it in recommendations, "${vector.id}: missing $it") }
            expected.mustNotHaveRecommendations.forEach { assertFalse(it in recommendations, "${vector.id}: unexpected $it") }
            val causes = buildSet<String> {
                response["primaryCause"]?.jsonPrimitive?.contentOrNull?.let { add(it) }
                response["secondaryCauses"]?.jsonArray?.forEach { add(it.jsonPrimitive.content) }
            }
            expected.mustNotHaveCauses.forEach { assertFalse(it in causes, "${vector.id}: unexpected cause $it") }
        }
    }

    private fun com.lagcheck.domain.vectors.Vector.requestJson(): String = json.encodeToString(JsonObject.serializer(), buildJsonObject {
        put("source", source.name)
        put("profile", profile.name)
        put("rest", rest.toJson())
        load?.let { put("load", it.toJson()) }
        put("loadTransfer", loadTransfer.name)
        put("gateway", buildJsonObject {
            put("validResponses", when (gateway) { VGateway.UNOBSERVABLE -> 0; VGateway.DEGRADED -> 3; VGateway.STABLE -> 5 })
            put("plannedResponses", 5)
            put("rttMs", if (gateway == VGateway.DEGRADED) 25.0 else 2.0)
        })
    })

    private fun List<com.lagcheck.domain.vectors.VSample>.toJson(): JsonArray = buildJsonArray {
        this@toJson.forEach { sample -> add(buildJsonObject {
            put("sequence", sample.sequence)
            put("outcome", sample.outcome.name)
            sample.rttMs?.let { put("rttMs", it) }
        }) }
    }

    private fun JsonObject.string(name: String): String? = this[name]?.jsonPrimitive?.contentOrNull
}
