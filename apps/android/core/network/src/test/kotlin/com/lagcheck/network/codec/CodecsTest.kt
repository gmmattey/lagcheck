package com.lagcheck.network.codec

import com.google.common.truth.Truth.assertThat
import java.util.UUID
import org.junit.Test

/** Vetores byte a byte portados de PingBeacon/PlayFabQoS/SteamQueryA2S PayloadCodecTests.swift. */
class CodecsTest {
    private val session = UUID.fromString("00112233-4455-6677-8899-AABBCCDDEEFF")
    private fun bytes(vararg v: Int) = ByteArray(v.size) { v[it].toByte() }

    private val sessionBytes = intArrayOf(0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF)

    @Test fun pingBeaconEncodesTheDocumented33BytePayload() {
        val encoded = PingBeaconCodec.encode(PingBeaconPayload(session, 0x01020304, 0x0102030405060708))
        val expected = bytes(0x4E, 0x4C, 0x50, 0x47, 0x01, *sessionBytes, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08)
        assertThat(encoded).isEqualTo(expected)
        assertThat(encoded.size).isEqualTo(33)
        val decoded = PingBeaconCodec.decode(encoded)!!
        assertThat(decoded.sessionId).isEqualTo(session)
        assertThat(decoded.sequence).isEqualTo(0x01020304L)
        assertThat(decoded.nonce).isEqualTo(0x0102030405060708)
    }

    @Test fun pingBeaconSequenceAboveIntMaxRoundTripsAsUnsigned() {
        val encoded = PingBeaconCodec.encode(PingBeaconPayload(session, 0xFFFFFFFFL, 1))
        assertThat(PingBeaconCodec.decode(encoded)!!.sequence).isEqualTo(0xFFFFFFFFL)
    }

    @Test fun pingBeaconRejectsMalformedAndRequiresExactEcho() {
        val encoded = PingBeaconCodec.encode(PingBeaconPayload(UUID.randomUUID(), 3, 7))
        val different = encoded.copyOf().also { it[0] = 0 }
        assertThat(PingBeaconCodec.decode(encoded.copyOf(32))).isNull()
        assertThat(PingBeaconCodec.decode(different)).isNull()
        assertThat(PingBeaconCodec.isExactEcho(encoded, encoded.copyOf())).isTrue()
        assertThat(PingBeaconCodec.isExactEcho(encoded, different)).isFalse()
        assertThat(PingBeaconCodec.isExactEcho(encoded, encoded.copyOf(32))).isFalse()
    }

    @Test fun playFabEncodesAndValidatesFlippedEcho() {
        val encoded = PlayFabQosCodec.encode(PlayFabQosPayload(session, 0x01020304, 0x0102030405060708, 0))
        val expected = bytes(0xFF, 0xFF, 0x50, 0x01, *sessionBytes, 0x01, 0x02, 0x03, 0x04, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x00)
        assertThat(encoded).isEqualTo(expected)
        assertThat(PlayFabQosCodec.decode(encoded)!!.sessionId).isEqualTo(session)

        val flipped = encoded.copyOf().also { it[0] = 0; it[1] = 0 }
        assertThat(PlayFabQosCodec.isValidEcho(encoded, flipped)).isTrue()
        // Eco literal (cabeçalho ainda 0xFFFF) não vale: o servidor precisa ter respondido.
        assertThat(PlayFabQosCodec.isValidEcho(encoded, encoded.copyOf())).isFalse()
        val corrupted = flipped.copyOf().also { it[20] = (it[20] + 1).toByte() }
        assertThat(PlayFabQosCodec.isValidEcho(encoded, corrupted)).isFalse()
        assertThat(PlayFabQosCodec.isValidEcho(encoded, flipped.copyOf(32))).isFalse()
    }

    @Test fun steamInitialAndAuthenticatedRequests() {
        val initial = SteamQueryA2sCodec.encodeInitialRequest()
        assertThat(initial).isEqualTo(
            bytes(0xFF, 0xFF, 0xFF, 0xFF, 0x54, 0x53, 0x6F, 0x75, 0x72, 0x63, 0x65, 0x20, 0x45, 0x6E, 0x67, 0x69, 0x6E, 0x65, 0x20, 0x51, 0x75, 0x65, 0x72, 0x79, 0x00)
        )
        assertThat(initial.size).isEqualTo(25)
        val auth = SteamQueryA2sCodec.encodeAuthenticatedRequest(0x12345678)
        assertThat(auth.size).isEqualTo(29)
        assertThat(auth.copyOfRange(25, 29)).isEqualTo(bytes(0x78, 0x56, 0x34, 0x12))
    }

    @Test fun steamChallengeTokenIsLittleEndianUnsigned() {
        val challenge = bytes(0xFF, 0xFF, 0xFF, 0xFF, 0x41, 0x78, 0x56, 0x34, 0x12)
        assertThat(SteamQueryA2sCodec.isChallengeResponse(challenge)).isTrue()
        assertThat(SteamQueryA2sCodec.decodeChallenge(challenge)).isEqualTo(0x12345678L)
        // Token com bit alto não pode virar negativo.
        assertThat(SteamQueryA2sCodec.decodeChallenge(bytes(0xFF, 0xFF, 0xFF, 0xFF, 0x41, 0xFF, 0xFF, 0xFF, 0xFF))).isEqualTo(0xFFFFFFFFL)
        assertThat(SteamQueryA2sCodec.decodeChallenge(bytes(0xFF, 0xFF, 0xFF, 0xFF, 0x41, 0x01, 0x02))).isNull()
        assertThat(SteamQueryA2sCodec.decodeChallenge(bytes(0x00, 0xFF, 0xFF, 0xFF, 0x41, 0x78, 0x56, 0x34, 0x12))).isNull()
        assertThat(SteamQueryA2sCodec.decodeChallenge(bytes(0xFF, 0xFF, 0xFF, 0xFF, 0x49, 0x78, 0x56, 0x34, 0x12))).isNull()
    }

    @Test fun steamInfoResponseValidationAndIdentity() {
        val valid = bytes(0xFF, 0xFF, 0xFF, 0xFF, 0x49, 0x11, 0x52, 0x75, 0x73, 0x74, 0x20, 0x53, 0x65, 0x72, 0x76, 0x65, 0x72, 0x00)
        assertThat(SteamQueryA2sCodec.isValidInfoResponse(valid)).isTrue()
        assertThat(SteamQueryA2sCodec.isValidInfoResponse(bytes(0xFF, 0xFF, 0xFF, 0xFF))).isFalse()
        assertThat(SteamQueryA2sCodec.isValidInfoResponse(ByteArray(0))).isFalse()
        assertThat(SteamQueryA2sCodec.isValidInfoResponse(bytes(0xFE, 0xFF, 0xFF, 0xFF, 0x49))).isFalse()
        assertThat(SteamQueryA2sCodec.isValidInfoResponse(bytes(0xFF, 0xFF, 0xFF, 0xFF, 0x41, 0x78, 0x56, 0x34, 0x12))).isFalse()

        val packet = bytes(0xFF, 0xFF, 0xFF, 0xFF, 0x49, 0x11) +
            "SP Community #1\u0000de_dust2\u0000csgo\u0000Counter-Strike 2\u0000".toByteArray() + bytes(0xDA, 0x02)
        val info = SteamQueryA2sCodec.decodeInfo(packet)!!
        assertThat(info.name).isEqualTo("SP Community #1")
        assertThat(info.gameDirectory).isEqualTo("csgo")
        assertThat(info.appId).isEqualTo(730)
    }
}
