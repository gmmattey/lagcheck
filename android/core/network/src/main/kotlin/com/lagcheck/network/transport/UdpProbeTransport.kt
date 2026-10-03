package com.lagcheck.network.transport

import com.lagcheck.catalog.ProbeDestination
import com.lagcheck.catalog.ProbeProtocolKind
import com.lagcheck.domain.model.InconclusiveReason
import com.lagcheck.domain.model.ProbeAcceptancePolicy
import com.lagcheck.domain.model.ProbeOutcome
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.rules.SampleQualityEvaluator
import com.lagcheck.network.codec.PingBeaconCodec
import com.lagcheck.network.codec.PingBeaconPayload
import com.lagcheck.network.codec.PlayFabQosCodec
import com.lagcheck.network.codec.PlayFabQosPayload
import com.lagcheck.network.codec.SteamQueryA2sCodec
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.IOException
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.SocketException
import java.net.SocketTimeoutException
import java.security.SecureRandom
import java.util.UUID
import java.util.concurrent.atomic.AtomicLong

/** Plano de uma fase de medição. Padrão de produto: 30 probes, 1 a cada 500 ms, fechamento em 17 s, timeout individual de 2 s. */
data class ProbePlan(
    val count: Int = ProbeAcceptancePolicy.PLANNED_PROBE_COUNT,
    val intervalMillis: Long = ProbeAcceptancePolicy.SEND_INTERVAL_MILLIS,
    val closureMillis: Long = ProbeAcceptancePolicy.CLOSURE_MILLIS,
    val probeTimeoutMillis: Long = ProbeAcceptancePolicy.TIMEOUT_MILLIS,
    /** Aborta cedo conexão claramente morta (sample-quality-v1), sem fazer a pessoa esperar 17 s. */
    val abortOnPoorQuality: Boolean = true
)

sealed class ProbeProgress {
    data class Sent(val sequence: Int, val plannedCount: Int) : ProbeProgress()
    data class Received(val sample: ProbeSample) : ProbeProgress()
}

class ProbeCollection(val samples: List<ProbeSample>, val abortReason: InconclusiveReason?) {
    val aborted: Boolean get() = abortReason != null
}

/**
 * Transporte UDP do Android. Mede somente o destino do catálogo assinado e nunca tenta outro protocolo
 * (sem fallback HTTP/ICMP). Cancelar a coroutine fecha o socket imediatamente.
 */
class UdpProbeTransport(
    private val nanoTime: () -> Long = System::nanoTime,
    private val random: SecureRandom = SecureRandom()
) {
    suspend fun collect(
        destination: ProbeDestination,
        plan: ProbePlan = ProbePlan(),
        onProgress: (ProbeProgress) -> Unit = {}
    ): ProbeCollection = withContext(Dispatchers.IO) {
        val generated = generateProbes(plan.count, destination.protocolKind)
        val ledger = ProbeLedger(generated.probes, plan.probeTimeoutMillis * 1_000_000L, generated.validator)

        val address = try {
            InetAddress.getByName(destination.host)
        } catch (e: IOException) {
            return@withContext allTransportErrors(plan.count)
        }

        var socket: DatagramSocket? = null
        try {
            socket = try {
                DatagramSocket().apply { soTimeout = RECEIVE_POLL_MILLIS; connect(address, destination.port) }
            } catch (e: IOException) {
                return@withContext allTransportErrors(plan.count)
            }

            val steamToken = AtomicLong(NO_TOKEN)
            coroutineScope {
                val receiver = launch {
                    val buffer = ByteArray(2048)
                    val packet = DatagramPacket(buffer, buffer.size)
                    while (isActive) {
                        try {
                            packet.length = buffer.size
                            socket.receive(packet)
                        } catch (_: SocketTimeoutException) {
                            continue
                        } catch (_: SocketException) {
                            break // socket fechado pelo fluxo principal
                        }
                        val at = nanoTime()
                        val response = packet.data.copyOfRange(packet.offset, packet.offset + packet.length)
                        if (destination.protocolKind == ProbeProtocolKind.STEAM_A2S && SteamQueryA2sCodec.isChallengeResponse(response)) {
                            SteamQueryA2sCodec.decodeChallenge(response)?.let { steamToken.set(it) }
                            continue
                        }
                        ledger.accept(response, at)?.let { onProgress(ProbeProgress.Received(it)) }
                    }
                }

                // Steam A2S exige o challenge antes dos probes de medição.
                if (destination.protocolKind == ProbeProtocolKind.STEAM_A2S) {
                    val initial = SteamQueryA2sCodec.encodeInitialRequest()
                    runCatching { socket.send(DatagramPacket(initial, initial.size)) }
                    repeat(6) {
                        if (steamToken.get() != NO_TOKEN) return@repeat
                        delay(50)
                    }
                }

                // t0 é obtido imediatamente antes do primeiro envio; os payloads já estão prontos.
                val start = nanoTime()
                var abortReason: InconclusiveReason? = null
                for ((sequence, basePayload) in generated.probes) {
                    currentCoroutineContext().ensureActive()
                    delayUntil(start + sequence * plan.intervalMillis * 1_000_000L)

                    val payload = if (destination.protocolKind == ProbeProtocolKind.STEAM_A2S && steamToken.get() != NO_TOKEN) {
                        SteamQueryA2sCodec.encodeAuthenticatedRequest(steamToken.get())
                    } else basePayload

                    ledger.register(sequence, payload, nanoTime())
                    try {
                        socket.send(DatagramPacket(payload, payload.size))
                    } catch (_: IOException) {
                        ledger.markTransportError(sequence)
                    }
                    onProgress(ProbeProgress.Sent(sequence, plan.count))

                    if (plan.abortOnPoorQuality) {
                        val assessment = SampleQualityEvaluator.assess(ledger.snapshot(nanoTime()))
                        if (assessment.shouldAbort) { abortReason = assessment.abortReason; break }
                    }
                }

                if (abortReason == null) delayUntil(start + plan.closureMillis * 1_000_000L)
                receiver.cancel()
                ProbeCollection(ledger.finish(), abortReason)
            }
        } finally {
            socket?.close() // também no cancelamento: nenhum socket vaza
        }
    }

    private suspend fun delayUntil(deadlineNanos: Long) {
        val remainingMillis = (deadlineNanos - nanoTime()) / 1_000_000L
        if (remainingMillis > 0) delay(remainingMillis)
    }

    private fun allTransportErrors(count: Int) =
        ProbeCollection(List(count) { ProbeSample(it, outcome = ProbeOutcome.TRANSPORT_ERROR) }, null)

    private class Generated(val probes: List<Pair<Int, ByteArray>>, val validator: (ByteArray, ByteArray) -> Boolean)

    private fun generateProbes(count: Int, kind: ProbeProtocolKind): Generated = when (kind) {
        ProbeProtocolKind.GAMELIFT_PING -> {
            val session = UUID.randomUUID()
            Generated(
                List(count) { it to PingBeaconCodec.encode(PingBeaconPayload(session, it.toLong(), random.nextLong())) },
                PingBeaconCodec::isExactEcho
            )
        }
        ProbeProtocolKind.PLAYFAB_QOS -> {
            val session = UUID.randomUUID()
            Generated(
                List(count) { it to PlayFabQosCodec.encode(PlayFabQosPayload(session, it.toLong(), random.nextLong())) },
                PlayFabQosCodec::isValidEcho
            )
        }
        ProbeProtocolKind.STEAM_A2S -> {
            val initial = SteamQueryA2sCodec.encodeInitialRequest()
            Generated(List(count) { it to initial }) { _, response -> SteamQueryA2sCodec.isValidInfoResponse(response) }
        }
    }

    private companion object {
        const val RECEIVE_POLL_MILLIS = 25
        const val NO_TOKEN = -1L
    }
}
