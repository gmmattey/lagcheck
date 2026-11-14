package com.lagcheck.network.preflight

import com.google.common.truth.Truth.assertThat
import com.google.common.truth.Truth.assertWithMessage
import com.lagcheck.catalog.RouteIdentity
import java.io.File
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Test

/** Mesmos vetores de `apps/ios/Tests/Vectors/steam-a2s-preflight-vectors.json` usados pelo iOS (`SteamA2SPreflightMachine`). */
class SteamA2sPreflightMachineTest {
    private fun hex(b: ByteArray) = b.joinToString("") { "%02x".format(it) }
    private fun bytes(h: String) = ByteArray(h.length / 2) { h.substring(it * 2, it * 2 + 2).toInt(16).toByte() }

    private val vectors: JsonObject = run {
        val root = generateSequence(File(System.getProperty("user.dir")).absoluteFile) { it.parentFile }
            .first { File(it, "ios/Tests/Vectors/steam-a2s-preflight-vectors.json").exists() }
        Json.parseToJsonElement(File(root, "ios/Tests/Vectors/steam-a2s-preflight-vectors.json").readText()).jsonObject
    }

    @Test fun machineMatchesSharedVectors() {
        val list = vectors["preflightVectors"]!!.jsonArray
        assertThat(list).hasSize(15)
        for (v in list.map { it.jsonObject }) {
            val id = v["id"]!!.jsonPrimitive.content
            val identity = v["identity"]!!.jsonObject
            val machine = SteamA2sPreflightMachine(
                RouteIdentity(
                    identity["appID"]!!.jsonPrimitive.int,
                    identity["gameDirectory"]!!.jsonPrimitive.content,
                    identity["namePrefix"]?.takeIf { it !is JsonNull }?.jsonPrimitive?.content
                )
            )
            val sends = mutableListOf(hex(machine.initialRequest))
            var decision: String? = null
            for (event in v["events"] as JsonArray) {
                when (val step = machine.receive(if (event is JsonNull) null else bytes(event.jsonPrimitive.content))) {
                    is SteamA2sPreflightMachine.Step.Send -> sends += hex(step.payload)
                    SteamA2sPreflightMachine.Step.Accept -> decision = "accept"
                    SteamA2sPreflightMachine.Step.Reject -> decision = "reject"
                }
                if (decision != null) break
            }
            assertWithMessage(id).that(decision).isEqualTo(v["expectedDecision"]!!.jsonPrimitive.content)
            assertWithMessage(id).that(sends).isEqualTo(v["expectedSends"]!!.jsonArray.map { it.jsonPrimitive.content })
        }
    }

    @Test fun machineNeverAcceptsAfterRejecting() {
        val machine = SteamA2sPreflightMachine(RouteIdentity(730, "csgo", null))
        assertThat(machine.receive(null)).isEqualTo(SteamA2sPreflightMachine.Step.Reject)
        val info = bytes("ffffffff4911" + "686f737400" + "6d617000" + "6373676f00" + "67616d6500" + "da02")
        assertThat(machine.receive(info)).isEqualTo(SteamA2sPreflightMachine.Step.Reject)
    }
}
