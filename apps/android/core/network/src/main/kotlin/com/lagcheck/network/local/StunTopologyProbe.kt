package com.lagcheck.network.local

import com.lagcheck.domain.model.NatTopologySnapshot
import com.lagcheck.domain.rules.NatTopologyEvaluator
import com.lagcheck.network.stun.StunPacketCodec
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.IOException
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.SocketTimeoutException

data class StunServer(val host: String, val port: Int)

fun interface StunExchange {
    /** Envia `packet` e devolve a resposta bruta, ou `null` em erro/timeout. */
    suspend fun exchange(packet: ByteArray, server: StunServer, timeoutMillis: Long): ByteArray?
}

/**
 * Sondagem STUN dupla (custo zero, Decisão 32) para classificar o NAT sem infraestrutura própria.
 * Dois servidores independentes expõem NAT simétrico (porta mapeada diferente) e NAT duplo (IP público diferente).
 */
class StunTopologyProbe(
    private val primary: StunServer = StunServer("stun.l.google.com", 19302),
    private val secondary: StunServer = StunServer("stun1.l.google.com", 19302),
    private val timeoutMillis: Long = 2_000,
    private val exchange: StunExchange = UdpStunExchange()
) {
    suspend fun probe(localIp: String?): NatTopologySnapshot {
        val first = bind(primary) ?: return NatTopologySnapshot.INCONCLUSIVE
        val second = bind(secondary)
        val (consistent, doubleHop) = when {
            second == null -> true to false // só um respondeu: nada contradiz o resultado único
            first.publicIp != second.publicIp -> false to true
            first.port != second.port -> false to false
            else -> true to false
        }
        return NatTopologyEvaluator.evaluate(localIp, first.publicIp, first.port, consistent, doubleHop)
            .copy(serverHost = primary.host)
    }

    private suspend fun bind(server: StunServer): StunPacketCodec.StunResponse? {
        val request = StunPacketCodec.buildBindingRequest()
        val response = exchange.exchange(request.packetBytes, server, timeoutMillis) ?: return null
        return StunPacketCodec.parseBindingResponse(response, request.transactionId)
    }
}

class UdpStunExchange : StunExchange {
    override suspend fun exchange(packet: ByteArray, server: StunServer, timeoutMillis: Long): ByteArray? = withContext(Dispatchers.IO) {
        try {
            DatagramSocket().use { socket ->
                socket.soTimeout = timeoutMillis.toInt().coerceAtLeast(1)
                socket.connect(InetAddress.getByName(server.host), server.port)
                socket.send(DatagramPacket(packet, packet.size))
                val buffer = ByteArray(1024)
                val reply = DatagramPacket(buffer, buffer.size)
                socket.receive(reply)
                reply.data.copyOfRange(0, reply.length)
            }
        } catch (_: SocketTimeoutException) {
            null
        } catch (_: IOException) {
            null
        }
    }
}
