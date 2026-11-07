package com.lagcheck.desktop.location

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class IpLocationClientTest {
    private val client = IpLocationClient()

    @Test fun `accepts a complete worker response`() {
        val value = client.decode("{\"city\":\"Rio\",\"country\":\"BR\",\"lat\":-22.5,\"lon\":-43.0}")
        assertEquals("Rio", value?.city)
        assertEquals(-22.5, value?.lat)
    }

    @Test fun `rejects malformed and out of range worker responses`() {
        assertNull(client.decode("{bad}"))
        assertNull(client.decode("{\"city\":null,\"country\":null,\"lat\":91,\"lon\":0}"))
    }
}
