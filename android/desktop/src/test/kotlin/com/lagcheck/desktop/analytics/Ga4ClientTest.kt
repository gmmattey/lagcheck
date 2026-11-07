package com.lagcheck.desktop.analytics

import java.net.URI
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class Ga4ClientTest {
    private class FakeTransport : Ga4Transport {
        var calls = 0
        var body = ""
        override fun post(uri: URI, body: String) { calls++; this.body = body }
    }

    @Test fun `completed event uses the Android contract and no forbidden field`() {
        val fake = FakeTransport()
        val client = Ga4Client(Ga4Config(true, "G-123", "secret"), fake)
        client.send(ProductAnalyticsEvent.LagcheckCompleted("valorant", "pc", "unknown", "br-sao-paulo", "ready", 12), true)
        assertEquals(1, fake.calls)
        assertTrue(fake.body.contains("lagcheck_completed"))
        listOf("ip", "ssid", "bssid", "mac", "lat", "lon", "host", "user").forEach { assertFalse(fake.body.lowercase().contains("\\\"$it")) }
    }

    @Test fun `disabled collection and missing configuration never call transport`() {
        val fake = FakeTransport()
        val event = ProductAnalyticsEvent.GameSelected("valorant")
        assertFalse(Ga4Client(Ga4Config(true, "G-123", "secret"), fake).send(event, false))
        assertFalse(Ga4Client(Ga4Config(false, "", ""), fake).send(event, true))
        assertEquals(0, fake.calls)
    }

    @Test fun `payload escapes quotes slashes and control characters`() {
        val body = Ga4Client().payloadJson("id\n\u0000", Ga4Payload("game\tselected", mapOf("name\r" to "a\\b\"c\u0001\u000c")))
        assertTrue(body.contains("id\\n\\u0000"))
        assertTrue(body.contains("game\\tselected"))
        assertTrue(body.contains("name\\r"))
        assertTrue(body.contains("a\\\\b\\\"c\\u0001\\f"))
        assertFalse(body.any { it.code in 0..0x1F })
    }
}
