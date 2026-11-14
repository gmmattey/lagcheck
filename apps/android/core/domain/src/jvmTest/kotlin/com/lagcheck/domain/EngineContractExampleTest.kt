package com.lagcheck.domain

import com.lagcheck.engine.LagCheckEngine
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.File

/** Contrato público: política exposta e exemplo real gravado em build/ para o ENGINE_CONTRACT.md. */
class EngineContractExampleTest {
    private val pretty = Json { prettyPrint = true }

    @Test
    fun policyExposesSamplingPlanV2() {
        val policy = Json.parseToJsonElement(LagCheckEngine.policy()).jsonObject
        assertEquals(60, policy["plannedProbeCount"]!!.jsonPrimitive.int)
        assertEquals(30_000, policy["sendWindowMillis"]!!.jsonPrimitive.int)
        assertEquals(32_000, policy["closureMillis"]!!.jsonPrimitive.int)
        assertEquals(20, policy["minimumValidResponses"]!!.jsonPrimitive.int)
    }

    @Test
    fun writesRealExample() {
        val rest = (0 until 60).joinToString(",") { if (it == 59) """{"sequence":$it,"outcome":"TIMEOUT"}""" else """{"sequence":$it,"outcome":"RECEIVED","rttMs":${30 + it % 3}.0}""" }
        val load = (0 until 60).joinToString(",") { """{"sequence":$it,"outcome":"RECEIVED","rttMs":${48 + it % 3}.0}""" }
        val request = """{"source":"APP_UDP","profile":"BATTLE_ROYALE_COMPETITIVE","rest":[$rest],"load":[$load],"loadTransfer":"MEASURED","gateway":{"rttMs":3.0,"validResponses":5,"plannedResponses":5},"serverArchitecture":"DEDICATED_SERVER","uploadMbps":8.0}"""
        val response = LagCheckEngine.evaluate(request)
        val parsed = Json.parseToJsonElement(response).jsonObject
        assertEquals("CAUTION", parsed["verdict"]!!.jsonPrimitive.content)
        val out = File("build/engine-contract-example.txt")
        out.writeText(pretty.encodeToString(JsonObject.serializer(), Json.parseToJsonElement(request).jsonObject) + "\n----\n" + pretty.encodeToString(JsonObject.serializer(), parsed) + "\n----\n" + pretty.encodeToString(JsonObject.serializer(), Json.parseToJsonElement(LagCheckEngine.policy()).jsonObject))
    }
}
