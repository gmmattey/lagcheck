package com.lagcheck.domain.rules

import com.lagcheck.domain.model.AppDeepLink
import com.lagcheck.domain.model.DeepLinkParser
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class DeepLinkParserTest {

    @Test
    fun testParsesCustomSchemeQuickTest() {
        val result = DeepLinkParser.parse("lagcheck://quicktest")
        assertEquals(AppDeepLink.QuickCheck(null, null), result)
    }

    @Test
    fun testParsesCustomSchemeCheckWithGameAndPlatform() {
        val result = DeepLinkParser.parse("lagcheck://check?game=valorant&platform=pc")
        assertEquals(AppDeepLink.QuickCheck("valorant", "pc"), result)
    }

    @Test
    fun testRejectsInvalidPlatformAndAcceptsEncodedGame() {
        val invalidPlatform = DeepLinkParser.parse("lagcheck://check?game=valorant&platform=smartfridge")
        assertEquals(AppDeepLink.QuickCheck("valorant", null), invalidPlatform)

        val encoded = DeepLinkParser.parse("https://lagcheck.app/check?GAME=call%20of%20duty")
        assertEquals(AppDeepLink.QuickCheck("call of duty", null), encoded)
    }

    @Test
    fun testParsesUniversalLinkWithGame() {
        val result = DeepLinkParser.parse("https://lagcheck.app/check?game=fortnite")
        assertEquals(AppDeepLink.QuickCheck("fortnite", null), result)
    }

    @Test
    fun testParsesNetworkCockpit() {
        assertEquals(AppDeepLink.NetworkCockpit, DeepLinkParser.parse("lagcheck://network"))
        assertEquals(AppDeepLink.NetworkCockpit, DeepLinkParser.parse("lagcheck://wifi"))
    }

    @Test
    fun testParsesGamesCatalog() {
        assertEquals(AppDeepLink.GamesCatalog, DeepLinkParser.parse("lagcheck://games"))
    }

    @Test
    fun testParsesHome() {
        assertEquals(AppDeepLink.Home, DeepLinkParser.parse("lagcheck://home"))
    }

    @Test
    fun testRejectsUnrecognizedSchemesAndDomains() {
        assertNull(DeepLinkParser.parse("noping://check"))
        assertNull(DeepLinkParser.parse("http://lagcheck.app/check"))
        assertNull(DeepLinkParser.parse("https://evil.com/check"))
        assertNull(DeepLinkParser.parse("lagcheck://arbitraryhost"))
    }
}
