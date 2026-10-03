package com.lagcheck.network.engine

import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.network.stun.StunPacketCodec
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.isActive
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.DatagramChannel
import kotlin.coroutines.coroutineContext

/**
 * Motor de medição UDP determinístico em Kotlin Coroutines e Java NIO (Decisões 50 e 58).
 * Executa probes STUN contra servidores de referência e emite amostras em tempo real via Flow.
 */
class UdpMeasurementEngine(
    private val host: String = "stun.l.google.com",
    private val port: Int = 19302,
    private val plannedProbes: Int = 30,
    private val timeoutMillis: Long = 1000L,
    private val intervalMillis: Long = 100L
) {

    fun executeMeasurement(): Flow<ProbeSample> = flow {
        val serverAddress = InetSocketAddress(host, port)
        var highestSequenceReceived = -1

        DatagramChannel.open().use { channel ->
            channel.configureBlocking(false)
            channel.connect(serverAddress)

            val receiveBuffer = ByteBuffer.allocate(512)

            for (seq in 1..plannedProbes) {
                if (!coroutineContext.isActive) break

                val request = StunPacketCodec.buildBindingRequest()
                val sendBuffer = ByteBuffer.wrap(request.packetBytes)
                val startTimeNanos = System.nanoTime()

                channel.send(sendBuffer, serverAddress)

                var received = false
                val deadline = System.currentTimeMillis() + timeoutMillis

                while (System.currentTimeMillis() < deadline && coroutineContext.isActive) {
                    receiveBuffer.clear()
                    val sender = channel.receive(receiveBuffer)

                    if (sender != null) {
                        receiveBuffer.flip()
                        val responseBytes = ByteArray(receiveBuffer.remaining())
                        receiveBuffer.get(responseBytes)

                        val parsed = StunPacketCodec.parseBindingResponse(responseBytes, request.transactionId)
                        if (parsed != null) {
                            val rttMillis = (System.nanoTime() - startTimeNanos) / 1_000_000.0
                            val isOutOfOrder = seq < highestSequenceReceived
                            if (seq > highestSequenceReceived) {
                                highestSequenceReceived = seq
                            }

                            emit(
                                ProbeSample(
                                    sequenceNumber = seq,
                                    roundTripMillis = rttMillis,
                                    outcome = ProbeSample.Outcome.SUCCESS,
                                    isOutOfOrder = isOutOfOrder
                                )
                            )
                            received = true
                            break
                        }
                    }
                    delay(5)
                }

                if (!received && coroutineContext.isActive) {
                    emit(
                        ProbeSample(
                            sequenceNumber = seq,
                            roundTripMillis = null,
                            outcome = ProbeSample.Outcome.TIMEOUT
                        )
                    )
                }

                delay(intervalMillis)
            }
        }
    }.flowOn(Dispatchers.IO)
}
