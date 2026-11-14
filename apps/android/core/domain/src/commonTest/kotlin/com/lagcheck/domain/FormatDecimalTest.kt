package com.lagcheck.domain

import com.lagcheck.domain.util.formatDecimal
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class FormatDecimalTest {

    @Test
    fun testCommonTestSanity() {
        assertTrue(true, "commonTest sanity check across JVM, iOS and JS")
    }

    /** Valores conferidos com `String.format(Locale.ROOT, ...)` no JDK 17 (jshell). */
    @Test
    fun testFormatDecimalMatchesJavaStringFormat() {
        val cases = listOf(
            Triple(2.675, 1, "2.7"), Triple(2.675, 2, "2.68"), Triple(2.675, 0, "3"),
            Triple(0.125, 1, "0.1"), Triple(0.125, 2, "0.13"), Triple(0.125, 0, "0"),
            Triple(1.005, 1, "1.0"), Triple(1.005, 2, "1.01"), Triple(1.005, 0, "1"),
            Triple(99.95, 1, "100.0"), Triple(99.95, 2, "99.95"), Triple(99.95, 0, "100"),
            Triple(0.05, 1, "0.1"), Triple(0.05, 2, "0.05"), Triple(0.05, 0, "0"),
            Triple(1.25, 1, "1.3"), Triple(1.25, 2, "1.25"), Triple(1.25, 0, "1"),
            Triple(2.5, 1, "2.5"), Triple(2.5, 2, "2.50"), Triple(2.5, 0, "3"),
            Triple(3.3333333, 1, "3.3"), Triple(3.3333333, 2, "3.33"), Triple(3.3333333, 0, "3"),
            Triple(0.15, 1, "0.2"), Triple(1.45, 1, "1.5"),
            Triple(16.6666666667, 1, "16.7"), Triple(16.6666666667, 2, "16.67"), Triple(16.6666666667, 0, "17"),
            Triple(0.0, 1, "0.0"), Triple(30.0, 0, "30"), Triple(1.6666666666666667, 1, "1.7"),
            Triple(-1.25, 1, "-1.3"), Triple(0.0000001, 2, "0.00"), Triple(123456789.0, 1, "123456789.0"),
        )
        for ((value, decimals, expected) in cases) {
            assertEquals(expected, formatDecimal(value, decimals), "formatDecimal($value, $decimals)")
        }
    }
}
