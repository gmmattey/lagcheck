package com.lagcheck.android.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Mesmas regras de `parseApproxLocation` do site e de `ApproxLocationClient.decode` do iOS. */
class ApproxLocationClientTest {
    @Test
    fun decodesSiteResponse() {
        val body = """{"city":"Rio de Janeiro","country":"BR","lat":-23,"lon":-43.5}"""
        assertEquals(ApproxLocation("Rio de Janeiro", "BR", -23.0, -43.5), ApproxLocationClient.decode(body))
    }

    @Test
    fun decodesUnicodeEscapesAndNullCity() {
        val body = """{"city":"São Paulo","country":null,"lat":-23.5,"lon":-46.5}"""
        assertEquals(ApproxLocation("São Paulo", null, -23.5, -46.5), ApproxLocationClient.decode(body))
        assertNull(ApproxLocationClient.decode("""{"city":null,"country":"BR","lat":-15.5,"lon":-48}""")!!.city)
        assertNull(ApproxLocationClient.decode("""{"city":"  ","lat":1,"lon":2}""")!!.city)
    }

    @Test
    fun rejectsMissingOrOutOfRangeCoordinates() {
        assertNull(ApproxLocationClient.decode("""{"city":"X","lat":"10","lon":20}"""))
        assertNull(ApproxLocationClient.decode("""{"lat":91,"lon":0}"""))
        assertNull(ApproxLocationClient.decode("""{"lat":0,"lon":-181}"""))
        assertNull(ApproxLocationClient.decode("not json"))
    }
}
