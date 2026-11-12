package com.lagcheck.network.local

import com.lagcheck.domain.model.WiFiLocalTelemetry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.IOException
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.SocketTimeoutException
import java.security.SecureRandom
import kotlin.math.abs
import kotlin.math.ceil

/** Uma consulta ao gateway: devolve o RTT em ms só se houve resposta confirmada; senão `null`. */
fun interface GatewayExchange {
    suspend fun roundTripMillis(address: String, timeoutMillis: Long): Double?
}

/**
 * Sonda o primeiro salto (roteador) para separar o enlace local da rota externa (Decisões 50 e 55).
 *
 * - O RTT é medido por consulta DNS real (porta 53) com validação do Transaction ID.
 * - Nunca trata "enviado" como RTT. Sem resposta confirmada, não existe amostra.
 * - Roteador que não responde na 53 fica `Unobservable`: nunca vira acusação ao Wi-Fi.
 */
class GatewayProber(private val exchange: GatewayExchange = UdpDnsGatewayExchange()) {

    suspend fun probe(
        gatewayAddress: String?,
        isWiFi: Boolean,
        sampleCount: Int = 5,
        timeoutPerSampleMillis: Long = 500
    ): WiFiLocalTelemetry {
        if (!isWiFi) return WiFiLocalTelemetry(validSampleCount = 0, plannedSampleCount = 0, isWiFi = false)
        if (gatewayAddress == null) return WiFiLocalTelemetry(validSampleCount = 0, plannedSampleCount = sampleCount, isWiFi = true)

        val rtts = mutableListOf<Double>()
        repeat(sampleCount) { exchange.roundTripMillis(gatewayAddress, timeoutPerSampleMillis)?.let(rtts::add) }
        if (rtts.isEmpty()) return WiFiLocalTelemetry(validSampleCount = 0, plannedSampleCount = sampleCount, isWiFi = true)

        val sorted = rtts.sorted()
        val median = if (sorted.size % 2 == 1) sorted[sorted.size / 2]
        else (sorted[sorted.size / 2 - 1] + sorted[sorted.size / 2]) / 2.0
        val jitter = if (rtts.size > 1) (0 until rtts.size - 1).sumOf { abs(rtts[it + 1] - rtts[it]) } / (rtts.size - 1) else 0.0
        val p95Index = (ceil(sorted.size * 0.95).toInt() - 1).coerceIn(0, sorted.size - 1)
        val tail = if (median > 0) sorted[p95Index] / median else 1.0

        return WiFiLocalTelemetry(
            gatewayRttMedianMs = median,
            gatewayJitterMs = jitter,
            tailRatioP95P50 = tail,
            validSampleCount = rtts.size,
            plannedSampleCount = sampleCount,
            isWiFi = true
        )
    }
}

/** Troca real por UDP/53. */
class UdpDnsGatewayExchange(
    private val nanoTime: () -> Long = System::nanoTime,
    private val random: SecureRandom = SecureRandom(),
    private val port: Int = DNS_PORT
) : GatewayExchange {

    override suspend fun roundTripMillis(address: String, timeoutMillis: Long): Double? = withContext(Dispatchers.IO) {
        val txId = 1 + random.nextInt(0xFFFE) // 1..0xFFFE
        val query = dnsQuery(txId)
        try {
            DatagramSocket().use { socket ->
                socket.soTimeout = timeoutMillis.toInt().coerceAtLeast(1)
                socket.connect(InetAddress.getByName(address), port)
                val start = nanoTime()
                socket.send(DatagramPacket(query, query.size))
                val buffer = ByteArray(512)
                val packet = DatagramPacket(buffer, buffer.size)
                socket.receive(packet)
                val end = nanoTime()
                if (!isResponseTo(txId, packet.data, packet.length)) null else (end - start) / 1_000_000.0
            }
        } catch (_: SocketTimeoutException) {
            null
        } catch (_: IOException) {
            null
        }
    }

    companion object {
        const val DNS_PORT = 53

        /** Query DNS RFC 1035 mínima (A de "local", RD=1). O conteúdo da resposta não importa, só que veio. */
        fun dnsQuery(txId: Int): ByteArray = byteArrayOf(
            (txId shr 8).toByte(), txId.toByte(),
            0x01, 0x00, // flags: consulta padrão, RD
            0x00, 0x01, // QDCOUNT
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x05, 'l'.code.toByte(), 'o'.code.toByte(), 'c'.code.toByte(), 'a'.code.toByte(), 'l'.code.toByte(), 0x00,
            0x00, 0x01, // QTYPE A
            0x00, 0x01 // QCLASS IN
        )

        /**
         * Resposta válida = Transaction ID igual E bit QR ligado. O bit QR é um endurecimento em relação ao iOS: sem ele,
         * um datagrama que apenas reflete a nossa própria consulta passaria como "resposta do roteador".
         */
        fun isResponseTo(txId: Int, data: ByteArray, length: Int): Boolean {
            if (length < 3) return false
            val responseTx = ((data[0].toInt() and 0xFF) shl 8) or (data[1].toInt() and 0xFF)
            val isResponseFlag = (data[2].toInt() and 0x80) != 0
            return responseTx == txId && isResponseFlag
        }
    }
}
