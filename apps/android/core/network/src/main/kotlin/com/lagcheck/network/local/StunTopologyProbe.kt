package com.lagcheck.network.local

import com.lagcheck.domain.model.NatTopologySnapshot
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
 * A consulta STUN atual abre um socket novo por troca. Assim, portas ou endereços diferentes entre
 * servidores não descrevem um único mapeamento NAT e uma resposta isolada tampouco caracteriza
 * topologia. Sem uma sonda que mantenha o mesmo socket e controle os destinos, o resultado precisa
 * permanecer inconclusivo.
 */
class StunTopologyProbe(
    @Suppress("UNUSED_PARAMETER") primary: StunServer = StunServer("stun.l.google.com", 19302),
    @Suppress("UNUSED_PARAMETER") secondary: StunServer = StunServer("stun1.l.google.com", 19302),
    @Suppress("UNUSED_PARAMETER") timeoutMillis: Long = 2_000,
    @Suppress("UNUSED_PARAMETER") exchange: StunExchange = UdpStunExchange()
) {
    @Suppress("UNUSED_PARAMETER")
    suspend fun probe(localIp: String?): NatTopologySnapshot = NatTopologySnapshot.INCONCLUSIVE
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
