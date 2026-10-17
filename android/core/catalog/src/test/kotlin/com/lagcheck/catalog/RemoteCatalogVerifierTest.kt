package com.lagcheck.catalog

import com.google.common.truth.Truth.assertThat
import com.lagcheck.catalog.CatalogTestSupport.NOW
import com.lagcheck.catalog.CatalogTestSupport.context
import com.lagcheck.catalog.CatalogTestSupport.defaultGame
import com.lagcheck.catalog.CatalogTestSupport.defaultRegion
import com.lagcheck.catalog.CatalogTestSupport.envelope
import com.lagcheck.catalog.CatalogTestSupport.newKeyPair
import com.lagcheck.catalog.CatalogTestSupport.payload
import com.lagcheck.catalog.CatalogTestSupport.rawPublicKeyBase64
import com.lagcheck.catalog.CatalogTestSupport.route
import com.lagcheck.catalog.CatalogTestSupport.realEnvelopeBytes
import java.time.Instant
import java.util.Base64
import org.junit.Assert.assertThrows
import org.junit.Test

class RemoteCatalogVerifierTest {
    private val kp = newKeyPair()
    private val key = rawPublicKeyBase64(kp)
    private val realCatalogNow = Instant.parse("2026-10-20T00:00:00Z")

    private fun verify(env: ByteArray, now: Instant = NOW) = RemoteCatalogVerifier.verifyAndDecode(env, now, key)
    private fun expect(error: RemoteCatalogError, env: ByteArray, now: Instant = NOW) {
        val e = assertThrows(RemoteCatalogException::class.java) { verify(env, now) }
        assertThat(e.error).isEqualTo(error)
    }

    // region Envelope real publicado pelo Worker (assinado com a chave privada do dono do produto)

    @Test fun realPublishedEnvelopeVerifiesWithProductionKey() {
        val p = RemoteCatalogVerifier.verifyAndDecode(realEnvelopeBytes(), realCatalogNow)
        assertThat(p.schemaVersion).isEqualTo(3)
        assertThat(p.catalogVersion).isEqualTo("catalog-v3-2026.10.17.3")
        assertThat(p.games).hasSize(48)
        assertThat(p.regions.map { it.id }).containsExactly(
            "sa-east-1", "us-east-1", "us-east-2", "us-west-1", "us-west-2", "ca-central-1",
            "eu-central-1", "eu-west-1", "eu-west-2", "eu-west-3", "eu-north-1", "eu-south-1",
            "ap-northeast-1", "ap-northeast-2", "ap-northeast-3", "ap-southeast-1", "ap-southeast-2",
            "ap-south-1", "ap-east-1", "me-south-1", "af-south-1"
        ).inOrder()
        assertThat(p.profiles).hasSize(3)
    }

    @Test fun realEnvelopeIsRejectedAfterExpiry() {
        val e = assertThrows(RemoteCatalogException::class.java) {
            RemoteCatalogVerifier.verifyAndDecode(realEnvelopeBytes(), Instant.parse("2026-11-16T01:03:54Z"))
        }
        assertThat(e.error).isEqualTo(RemoteCatalogError.EXPIRED)
    }

    @Test fun realEnvelopeIsRejectedBeforeIssue() {
        val e = assertThrows(RemoteCatalogException::class.java) {
            RemoteCatalogVerifier.verifyAndDecode(realEnvelopeBytes(), Instant.parse("2026-10-17T00:19:59Z"))
        }
        assertThat(e.error).isEqualTo(RemoteCatalogError.EXPIRED)
    }

    @Test fun realEnvelopeWithTamperedPayloadIsRejected() {
        val text = realEnvelopeBytes().toString(Charsets.UTF_8)
        val b64 = Regex("\"payloadBase64\"\\s*:\\s*\"([^\"]+)\"").find(text)!!.groupValues[1]
        val payload = Base64.getDecoder().decode(b64).toString(Charsets.UTF_8).replace("sa-east-1", "us-east-1")
        val tampered = text.replace(b64, Base64.getEncoder().encodeToString(payload.toByteArray()))
        val e = assertThrows(RemoteCatalogException::class.java) {
            RemoteCatalogVerifier.verifyAndDecode(tampered.toByteArray(), realCatalogNow)
        }
        assertThat(e.error).isEqualTo(RemoteCatalogError.INVALID_SIGNATURE)
    }

    @Test fun realEnvelopeUnderAnotherKeyIsRejected() {
        val e = assertThrows(RemoteCatalogException::class.java) {
            RemoteCatalogVerifier.verifyAndDecode(realEnvelopeBytes(), realCatalogNow, key)
        }
        assertThat(e.error).isEqualTo(RemoteCatalogError.INVALID_SIGNATURE)
    }

    // endregion

    @Test fun validSyntheticCatalogPasses() {
        val p = verify(envelope(payload(), kp))
        assertThat(p.games.single().id).isEqualTo("g")
    }

    @Test fun malformedEnvelope() = expect(RemoteCatalogError.MALFORMED_ENVELOPE, "not json".toByteArray())

    @Test fun missingEnvelopeFields() = expect(RemoteCatalogError.MALFORMED_ENVELOPE, """{"schemaVersion":3}""".toByteArray())

    @Test fun schemaTwoIsNotAcceptedOnAndroid() =
        expect(RemoteCatalogError.UNSUPPORTED_ENVELOPE_SCHEMA, envelope(payload(), kp, schemaVersion = 2))

    @Test fun wrongAlgorithm() = expect(RemoteCatalogError.UNSUPPORTED_ALGORITHM, envelope(payload(), kp, algorithm = "RSA"))

    @Test fun validityLongerThanThirtyDaysIsRejected() =
        expect(RemoteCatalogError.INVALID_DATES, envelope(payload(), kp, expiresAt = "2026-10-21T15:30:00Z"))

    @Test fun expiresBeforeIssued() =
        expect(RemoteCatalogError.INVALID_DATES, envelope(payload(), kp, issuedAt = "2026-10-01T00:00:00Z", expiresAt = "2026-09-01T00:00:00Z"))

    @Test fun invalidBase64() {
        val env = envelope(payload(), kp).toString(Charsets.UTF_8).replace(Regex("\"signatureBase64\":\"[^\"]+\""), "\"signatureBase64\":\"@@@\"")
        expect(RemoteCatalogError.INVALID_BASE64, env.toByteArray())
    }

    @Test fun versionMismatchBetweenEnvelopeAndPayload() =
        expect(RemoteCatalogError.VERSION_MISMATCH, envelope(payload(catalogVersion = "other"), kp, catalogVersion = "test-catalog"))

    @Test fun oversizedPayload() {
        val big = payload(games = defaultGame(name = "x".repeat(140_000)))
        expect(RemoteCatalogError.PAYLOAD_TOO_LARGE, envelope(big, kp))
    }

    @Test fun malformedPayloadJson() = expect(RemoteCatalogError.MALFORMED_PAYLOAD, envelope("""{"schemaVersion":3}""", kp))

    // region Regras de negócio (cada uma com payload assinado por chave de teste)

    @Test fun assetBaseMustBeHttps() = expect(RemoteCatalogError.INVALID_GAME, envelope(payload(assetBase = "http://x.com/"), kp))

    @Test fun duplicateGame() =
        expect(RemoteCatalogError.DUPLICATE_GAME, envelope(payload(games = defaultGame() + "," + defaultGame()), kp))

    @Test fun duplicateRegion() =
        expect(RemoteCatalogError.DUPLICATE_REGION, envelope(payload(regions = defaultRegion() + "," + defaultRegion()), kp))

    @Test fun profileWithWrongRuleVersionIsRejected() =
        expect(
            RemoteCatalogError.UNKNOWN_PROFILE,
            envelope(payload(profiles = """{"id":"BATTLE_ROYALE_COMPETITIVE","ruleVersion":"pilot-2099"}"""), kp)
        )

    @Test fun regionHostMustMatchGameLiftPattern() =
        expect(RemoteCatalogError.UNKNOWN_REGION, envelope(payload(regions = defaultRegion(host = "evil.example.com")), kp))

    @Test fun regionPortMustBe7770() =
        expect(RemoteCatalogError.UNKNOWN_REGION, envelope(payload(regions = defaultRegion(port = 9999)), kp))

    @Test fun regionOutsideHomologatedSetIsRejected() =
        expect(RemoteCatalogError.UNKNOWN_REGION, envelope(payload(regions = defaultRegion(id = "xx-fake-1")), kp))

    @Test fun artworkMustLiveUnderArtworkAndHaveSha256() {
        expect(RemoteCatalogError.INVALID_GAME, envelope(payload(games = defaultGame(artwork = """{"path":"../x.jpg","sha256":"${"a".repeat(64)}"}""")), kp))
        expect(RemoteCatalogError.INVALID_GAME, envelope(payload(games = defaultGame(artwork = """{"path":"artwork/x.jpg","sha256":"zz"}""")), kp))
    }

    @Test fun verifiedRatingRequiresSource() =
        expect(
            RemoteCatalogError.INVALID_GAME,
            envelope(payload(games = defaultGame(rating = """{"status":"verified","value":4.5,"scale":5,"sourceName":"x"}""")), kp)
        )

    @Test fun unavailableContextIsRejected() =
        expect(RemoteCatalogError.INVALID_AVAILABILITY, envelope(payload(games = defaultGame(contexts = context(availability = "unavailable"))), kp))

    @Test fun contextNeedsActiveAwsFallback() =
        expect(
            RemoteCatalogError.INVALID_ROUTE,
            envelope(payload(games = defaultGame(contexts = context(routes = route(status = "pending")))), kp)
        )

    @Test fun awsFallbackMustBeGenericMedium() =
        expect(
            RemoteCatalogError.INVALID_ROUTE,
            envelope(payload(games = defaultGame(contexts = context(routes = route(confidence = "high")))), kp)
        )

    @Test fun pendingOwnedRouteCannotCarryDestination() {
        val owned = route(id = "g-owned", kind = "gameOwned", status = "pending", region = "g-br", strategy = "dedicatedServer",
            confidence = "high", precision = "dedicatedServer", extra = ""","destination":{"host":"a","port":1,"protocolKind":"steamA2S"}""")
        expect(RemoteCatalogError.INVALID_ROUTE, envelope(payload(games = defaultGame(contexts = context(routes = "$owned,${route()}"))), kp))
    }

    @Test fun pendingOwnedRouteWithoutHostIsAccepted() {
        val owned = route(id = "g-owned", kind = "gameOwned", status = "pending", region = "g-br", strategy = "dedicatedServer",
            confidence = "high", precision = "dedicatedServer")
        val p = verify(envelope(payload(games = defaultGame(contexts = context(routes = "$owned,${route()}"))), kp))
        assertThat(p.games.single().contexts.single().routes).hasSize(2)
    }

    private fun activeOwnedRoute(
        mode: String = "automaticValidatedCandidates", appId: Int = 730, evidence: String = "https://operator.example/pcap"
    ): String {
        val candidate = """{"id":"c1","priority":10,"host":"c1.community.example","queryPort":27015,"region":"g-br",""" +
            """"expectedIdentity":{"appID":$appId,"gameDirectory":"csgo","namePrefix":"Community"},"operatorEvidenceURL":"$evidence"}"""
        val selection = ""","selection":{"mode":"$mode","maxCandidates":3,"candidates":[$candidate]}"""
        val owned = route(id = "g-owned", kind = "gameOwned", status = "active", region = "g-br", strategy = "dedicatedServer",
            confidence = "high", precision = "dedicatedServer", extra = selection)
        return "$owned,${route()}"
    }

    @Test fun activeOwnedRouteWithSignedSteamCandidateIsAcceptedAndKeepsIdentity() {
        val p = verify(envelope(payload(games = defaultGame(contexts = context(routes = activeOwnedRoute()))), kp))
        val owned = p.games.single().contexts.single().routes!!.first { it.kind == RouteKind.GAME_OWNED }
        assertThat(owned.candidates!!.single().identity).isEqualTo(RouteIdentity(730, "csgo", "Community"))
        assertThat(owned.candidates!!.single().operatorEvidenceUrl).isEqualTo("https://operator.example/pcap")
    }

    @Test fun activeOwnedRouteNeedsAutomaticValidatedSelectionMode() =
        expect(RemoteCatalogError.INVALID_ROUTE, envelope(payload(games = defaultGame(contexts = context(routes = activeOwnedRoute(mode = "firstResponder")))), kp))

    @Test fun activeOwnedCandidateNeedsHttpsOperatorEvidence() =
        expect(RemoteCatalogError.INVALID_ROUTE, envelope(payload(games = defaultGame(contexts = context(routes = activeOwnedRoute(evidence = "http://operator.example")))), kp))

    @Test fun activeOwnedCandidateAppIdMustFitA2SInfoSixteenBits() {
        expect(RemoteCatalogError.INVALID_ROUTE, envelope(payload(games = defaultGame(contexts = context(routes = activeOwnedRoute(appId = 65_536)))), kp))
        expect(RemoteCatalogError.INVALID_ROUTE, envelope(payload(games = defaultGame(contexts = context(routes = activeOwnedRoute(appId = 0)))), kp))
    }

    @Test fun duplicatePlatformInSameMarketIsRejected() =
        expect(
            RemoteCatalogError.INVALID_CONTEXT,
            envelope(payload(games = defaultGame(contexts = context() + "," + context())), kp)
        )

    @Test fun unknownPlatformKeyIsRejected() =
        expect(RemoteCatalogError.INVALID_CONTEXT, envelope(payload(games = defaultGame(contexts = context(platforms = "\"gameboy\""))), kp))

    @Test fun legacyMeasurementFieldIsRejectedInSchema3() =
        expect(
            RemoteCatalogError.INVALID_CONTEXT,
            envelope(payload(games = defaultGame(contexts = context(measurement = """{"primaryRegion":"sa-east-1"}"""))), kp)
        )

    @Test fun unknownProfileInContext() =
        expect(RemoteCatalogError.INVALID_CONTEXT, envelope(payload(games = defaultGame(contexts = context(profile = "NOPE"))), kp))

    @Test fun gameIdMustBeLowercaseAscii() =
        expect(RemoteCatalogError.INVALID_GAME, envelope(payload(games = defaultGame(id = "Bad_ID")), kp))

    // endregion
}
