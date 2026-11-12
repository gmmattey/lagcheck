package com.lagcheck.network.local

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.GatewayProbeOutcome
import com.lagcheck.domain.model.NatType
import com.lagcheck.network.stun.StunPacketCodec
import com.lagcheck.network.transport.LoopbackUdpServer
import java.nio.ByteBuffer
import kotlinx.coroutines.runBlocking
import org.junit.Test

class LocalProbesTest {
    private fun sequence(vararg rtts: Double?): GatewayExchange {
        val it = rtts.iterator()
        return GatewayExchange { _, _ -> if (it.hasNext()) it.next() else null }
    }

    // region Estatística do gateway (RTT determinístico)
    @Test fun cellularIsNeverProbed() = runBlocking {
        val t = GatewayProber(sequence(1.0)).probe("192.168.0.1", isWiFi = false)
        assertThat(t.isWiFi).isFalse()
        assertThat(t.plannedSampleCount).isEqualTo(0)
        assertThat(t.gatewayOutcome).isEqualTo(GatewayProbeOutcome.Unobservable)
    }

    @Test fun missingGatewayAddressIsUnobservableNotAGuess() = runBlocking {
        val t = GatewayProber(sequence(1.0)).probe(null, isWiFi = true)
        assertThat(t.plannedSampleCount).isEqualTo(5)
        assertThat(t.validSampleCount).isEqualTo(0)
        assertThat(t.gatewayRttMedianMs).isNull()
        assertThat(t.gatewayOutcome).isEqualTo(GatewayProbeOutcome.Unobservable)
    }

    @Test fun silentRouterNeverInventsSamples() = runBlocking {
        val t = GatewayProber(sequence(null, null, null, null, null)).probe("192.168.0.1", true)
        assertThat(t.validSampleCount).isEqualTo(0)
        assertThat(t.gatewayRttMedianMs).isNull()
        assertThat(t.gatewayOutcome).isEqualTo(GatewayProbeOutcome.Unobservable)
    }

    @Test fun medianJitterAndTailAreComputedFromRealSamples() = runBlocking {
        val t = GatewayProber(sequence(2.0, 4.0, 3.0, 10.0, 1.0)).probe("192.168.0.1", true)
        assertThat(t.validSampleCount).isEqualTo(5)
        assertThat(t.gatewayRttMedianMs).isEqualTo(3.0)
        assertThat(t.gatewayJitterMs!!).isWithin(1e-9).of((2.0 + 1.0 + 7.0 + 9.0) / 4)
        assertThat(t.tailRatioP95P50!!).isWithin(1e-9).of(10.0 / 3.0)
    }

    @Test fun evenSampleCountUsesTheMeanOfTheMiddlePair() = runBlocking {
        val t = GatewayProber(sequence(1.0, 2.0, 3.0, 4.0, null)).probe("g", true, sampleCount = 5)
        assertThat(t.validSampleCount).isEqualTo(4)
        assertThat(t.gatewayRttMedianMs).isEqualTo(2.5)
    }

    @Test fun lossMakesTheGatewayDegradedAndFastCleanMakesItStable() = runBlocking {
        val lossy = GatewayProber(sequence(2.0, 2.0, 2.0, 2.0, null)).probe("g", true)
        assertThat(lossy.gatewayOutcome).isEqualTo(GatewayProbeOutcome.Degraded(2.0, 20.0))
        val clean = GatewayProber(sequence(2.0, 2.2, 1.9, 2.1, 2.0)).probe("g", true)
        assertThat(clean.gatewayOutcome).isInstanceOf(GatewayProbeOutcome.Stable::class.java)
    }
    // endregion

    // region UDP/53 real em loopback
    private fun dnsReply(req: ByteArray, qr: Boolean = true, txOverride: Int? = null): ByteArray {
        val r = req.copyOf()
        if (qr) r[2] = (r[2].toInt() or 0x80).toByte()
        txOverride?.let { r[0] = (it shr 8).toByte(); r[1] = it.toByte() }
        return r
    }

    private suspend fun rtt(server: LoopbackUdpServer, timeout: Long = 300): Double? =
        UdpDnsGatewayExchange(port = server.port).roundTripMillis("127.0.0.1", timeout)

    @Test fun realDnsReplyYieldsAPlausibleRtt() = runBlocking {
        LoopbackUdpServer { req, _ -> listOf(dnsReply(req)) }.use { assertThat(rtt(it)).isIn(com.google.common.collect.Range.closed(0.0, 300.0)) }
    }

    @Test fun silentRouterTimesOut() = runBlocking {
        LoopbackUdpServer { _, _ -> emptyList() }.use { assertThat(rtt(it, 150)).isNull() }
    }

    @Test fun wrongTransactionIdIsNotAResponse() = runBlocking {
        LoopbackUdpServer { req, _ -> listOf(dnsReply(req, txOverride = ((req[0].toInt() and 0xFF) shl 8 or (req[1].toInt() and 0xFF)) xor 0x5555)) }
            .use { assertThat(rtt(it, 150)).isNull() }
    }

    @Test fun reflectedQueryWithoutQrBitIsNotAResponse() = runBlocking {
        LoopbackUdpServer { req, _ -> listOf(dnsReply(req, qr = false)) }.use { assertThat(rtt(it, 150)).isNull() }
    }

    @Test fun responseValidationRules() {
        val q = UdpDnsGatewayExchange.dnsQuery(0x1234)
        assertThat(q.size).isEqualTo(23)
        assertThat(UdpDnsGatewayExchange.isResponseTo(0x1234, q, q.size)).isFalse() // consulta (QR=0)
        assertThat(UdpDnsGatewayExchange.isResponseTo(0x1234, dnsReply(q), q.size)).isTrue()
        assertThat(UdpDnsGatewayExchange.isResponseTo(0x1235, dnsReply(q), q.size)).isFalse()
        assertThat(UdpDnsGatewayExchange.isResponseTo(0x1234, byteArrayOf(0x12, 0x34), 2)).isFalse()
    }
    // endregion

    // region STUN
    private fun stunResponse(req: ByteArray, ip: String, port: Int): ByteArray {
        val b = ByteBuffer.allocate(32)
        b.putShort(StunPacketCodec.BINDING_RESPONSE_TYPE).putShort(12).putInt(StunPacketCodec.MAGIC_COOKIE)
        b.put(req, 8, 12)
        b.putShort(StunPacketCodec.ATTR_XOR_MAPPED_ADDRESS).putShort(8)
        b.put(0).put(1).putShort((port xor (StunPacketCodec.MAGIC_COOKIE ushr 16)).toShort())
        val o = ip.split('.').map { it.toInt() }
        val ipInt = (o[0] shl 24) or (o[1] shl 16) or (o[2] shl 8) or o[3]
        b.putInt(ipInt xor StunPacketCodec.MAGIC_COOKIE)
        return b.array()
    }

    private fun exchangeFor(answers: Map<String, Pair<String, Int>?>) = StunExchange { packet, server, _ ->
        answers[server.host]?.let { (ip, port) -> stunResponse(packet, ip, port) }
    }

    private val a = StunServer("a", 1)
    private val b = StunServer("b", 1)

    private fun probe(ex: StunExchange, local: String? = "192.168.1.50") = runBlocking { StunTopologyProbe(a, b, 100, ex).probe(local) }

    @Test fun consistentMappingBehindAHomeRouterIsModerate() {
        val s = probe(exchangeFor(mapOf("a" to ("177.136.20.10" to 40000), "b" to ("177.136.20.10" to 40000))))
        assertThat(s.natType).isEqualTo(NatType.TYPE_2_MODERATE)
        assertThat(s.publicIpMasked).isEqualTo("177.136.***.***")
        assertThat(s.externalPort).isEqualTo(40000)
    }

    @Test fun differentPortsAcrossServersMeansStrictSymmetricNat() {
        val s = probe(exchangeFor(mapOf("a" to ("177.136.20.10" to 40000), "b" to ("177.136.20.10" to 40001))))
        assertThat(s.natType).isEqualTo(NatType.TYPE_3_STRICT)
        assertThat(s.doubleNatStatus.isImpacted).isFalse()
    }

    @Test fun differentPublicIpsAcrossServersMeansDoubleNat() {
        val s = probe(exchangeFor(mapOf("a" to ("177.136.20.10" to 40000), "b" to ("177.136.99.99" to 40000))))
        assertThat(s.natType).isEqualTo(NatType.TYPE_3_STRICT)
        assertThat(s.doubleNatStatus.isImpacted).isTrue()
    }

    @Test fun cgnatRangeIsDetected() {
        val s = probe(exchangeFor(mapOf("a" to ("100.70.15.22" to 40000), "b" to ("100.70.15.22" to 40000))))
        assertThat(s.cgnatStatus.isImpacted).isTrue()
        assertThat(s.natType).isEqualTo(NatType.TYPE_3_STRICT)
    }

    @Test fun onlyOneServerAnsweringDoesNotAccuseSymmetricNat() {
        val s = probe(exchangeFor(mapOf("a" to ("177.136.20.10" to 40000), "b" to null)))
        assertThat(s.natType).isEqualTo(NatType.TYPE_2_MODERATE)
    }

    @Test fun publicEqualsLocalIsOpen() {
        val s = probe(exchangeFor(mapOf("a" to ("177.136.20.10" to 40000), "b" to ("177.136.20.10" to 40000))), local = "177.136.20.10")
        assertThat(s.natType).isEqualTo(NatType.TYPE_1_OPEN)
    }

    @Test fun noAnswerIsInconclusiveNeverAGuess() {
        assertThat(probe(exchangeFor(mapOf("a" to null, "b" to null))).natType).isEqualTo(NatType.INCONCLUSIVE)
    }

    @Test fun responseWithoutMappedAddressIsInconclusiveNotZeroZeroZeroZero() {
        val header = StunExchange { packet, _, _ ->
            ByteBuffer.allocate(20).putShort(StunPacketCodec.BINDING_RESPONSE_TYPE).putShort(0).putInt(StunPacketCodec.MAGIC_COOKIE).put(packet, 8, 12).array()
        }
        assertThat(probe(header).natType).isEqualTo(NatType.INCONCLUSIVE)
    }

    @Test fun mismatchedTransactionIdIsIgnored() {
        val wrong = StunExchange { packet, _, _ -> stunResponse(packet.copyOf().also { it[8] = (it[8] + 1).toByte() }, "1.2.3.4", 5) }
        assertThat(probe(wrong).natType).isEqualTo(NatType.INCONCLUSIVE)
    }

    @Test fun realUdpStunRoundTripThroughLoopback() = runBlocking {
        LoopbackUdpServer { req, _ -> listOf(stunResponse(req, "177.136.20.10", 40000)) }.use { server ->
            val s = StunTopologyProbe(StunServer("127.0.0.1", server.port), StunServer("127.0.0.1", server.port), 500).probe("192.168.1.50")
            assertThat(s.natType).isEqualTo(NatType.TYPE_2_MODERATE)
        }
    }
    // endregion
}
