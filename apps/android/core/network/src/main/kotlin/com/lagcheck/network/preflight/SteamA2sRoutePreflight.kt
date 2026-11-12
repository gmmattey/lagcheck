package com.lagcheck.network.preflight

import com.lagcheck.catalog.GameRoutePreflighting
import com.lagcheck.catalog.ProbeProtocolKind
import com.lagcheck.catalog.ResolvedMeasurementContext
import com.lagcheck.catalog.RouteIdentity
import java.io.IOException
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.SocketTimeoutException
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext

/**
 * Pré-validação curta e silenciosa de um candidato A2S já assinado. Não é scanner: abre no máximo um socket UDP
 * para o host/porta recebido, e o socket conectado só entrega datagramas daquele endpoint. Qualquer timeout,
 * erro de rede ou identidade divergente devolve `false` (e o fluxo cai na AWS assinada).
 */
class SteamA2sRoutePreflight(
    private val timeoutMillis: Long = 2_000,
    private val nanoTime: () -> Long = System::nanoTime
) : GameRoutePreflighting {

    override suspend fun validates(candidate: ResolvedMeasurementContext, identity: RouteIdentity): Boolean {
        if (candidate.destination.protocolKind != ProbeProtocolKind.STEAM_A2S) return false
        return withContext(Dispatchers.IO) {
            try {
                DatagramSocket().use { socket ->
                    socket.connect(InetAddress.getByName(candidate.destination.host), candidate.destination.port)
                    exchange(socket, SteamA2sPreflightMachine(identity))
                }
            } catch (e: CancellationException) {
                throw e
            } catch (_: IOException) {
                false
            } catch (_: SecurityException) {
                false
            }
        }
    }

    private suspend fun exchange(socket: DatagramSocket, machine: SteamA2sPreflightMachine): Boolean {
        val deadline = nanoTime() + timeoutMillis * 1_000_000L
        val buffer = ByteArray(2048)
        var outgoing = machine.initialRequest
        while (true) {
            socket.send(DatagramPacket(outgoing, outgoing.size))
            when (val step = machine.receive(receive(socket, buffer, deadline))) {
                is SteamA2sPreflightMachine.Step.Send -> outgoing = step.payload
                SteamA2sPreflightMachine.Step.Accept -> return true
                SteamA2sPreflightMachine.Step.Reject -> return false
            }
        }
    }

    /** Recebe em fatias curtas para respeitar o prazo total e o cancelamento da coroutine. */
    private suspend fun receive(socket: DatagramSocket, buffer: ByteArray, deadline: Long): ByteArray? {
        val packet = DatagramPacket(buffer, buffer.size)
        while (true) {
            currentCoroutineContext().ensureActive()
            val remainingMillis = (deadline - nanoTime()) / 1_000_000L
            if (remainingMillis <= 0) return null
            socket.soTimeout = minOf(remainingMillis, SLICE_MILLIS).toInt().coerceAtLeast(1)
            try {
                packet.length = buffer.size
                socket.receive(packet)
                return packet.data.copyOfRange(packet.offset, packet.offset + packet.length)
            } catch (_: SocketTimeoutException) {
                continue
            }
        }
    }

    private companion object { const val SLICE_MILLIS = 100L }
}
