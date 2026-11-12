package com.lagcheck.desktop.ui.map

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.Color
import com.lagcheck.desktop.ds.LcColor

/**
 * Ponto geográfico com nome amigável e coordenadas (latitude, longitude).
 */
data class MapPoint(
    val name: String,
    val lat: Double,
    val lon: Double
)

/**
 * Direção de viagem do pacote de telemetria.
 */
enum class PacketPhase {
    OUTBOUND, // Saindo de "Você" rumo à região
    INBOUND   // Voltando da região rumo a "Você"
}

/**
 * Estado interno de um pacote de sonda em voo.
 */
class PacketState(
    val probeIndex: Int,
    var phase: PacketPhase,
    var startTimeNanos: Long,
    var durationNanos: Long,
    var lost: Boolean = false,
    var color: Color = LcColor.AccentLight,
    var progress: Float = 0f,
    var elapsedFraction: Float = 0f,
    var finished: Boolean = false
)

/**
 * Onda expansiva de impacto emitida por um pino quando sondas partem ou chegam.
 */
class WaveRing(
    val lat: Double,
    val lon: Double,
    val maxRadiusPx: Float,
    val durationNanos: Long,
    val color: Color,
    val startTimeNanos: Long
)

/**
 * Estado reativo e observável para o componente de mapa de rota.
 *
 * Contrato canônico:
 * - reset()
 * - onProbeSent(index)
 * - onProbeReturned(index, rttMs)
 * - onProbeLost(index)
 * - reducedMotion
 */
class RouteMapState {

    /** Quando ativo, desativa pacotes voando e pulsos, usando câmera estática imediata. */
    var reducedMotion: Boolean by mutableStateOf(false)

    /** Lista reativa de pacotes atualmente em trânsito. */
    val packets = mutableStateListOf<PacketState>()

    /** Lista reativa de anéis de onda em expansão. */
    val rings = mutableStateListOf<WaveRing>()

    /** Histórico de RTTs de sondas concluídas para cálculo da mediana em tempo real. */
    val rttHistory = mutableStateListOf<Double>()

    /** Mediana dos RTTs registrados até o momento, ou nulo se nenhuma sonda respondeu. */
    val medianRttMs: Double?
        get() {
            if (rttHistory.isEmpty()) return null
            val sorted = rttHistory.sorted()
            val size = sorted.size
            return if (size % 2 == 1) {
                sorted[size / 2]
            } else {
                (sorted[size / 2 - 1] + sorted[size / 2]) / 2.0
            }
        }

    /** Indica se há animações em curso (evita rodar o loop de renderização em repouso). */
    var hasActiveAnimations: Boolean by mutableStateOf(false)
        private set

    companion object {
        /** Duração padrão do voo de ida em nanosegundos (420 ms). */
        const val DEFAULT_FLY_DURATION_NANOS = 420_000_000L
        /** Duração da onda expansiva ao atingir um pino (800 ms). */
        const val RING_DURATION_NANOS = 800_000_000L
        /** Limite de percurso da sonda perdida (some exatamente a 58% do caminho). */
        const val LOST_THRESHOLD = 0.58f
    }

    /**
     * Limpa todo o estado do mapa, voltando ao repouso sem pacotes, anéis ou RTTs.
     */
    fun reset() {
        packets.clear()
        rings.clear()
        rttHistory.clear()
        hasActiveAnimations = false
    }

    /**
     * Notifica o disparo de uma sonda real partindo de "Você" em direção à região.
     */
    fun onProbeSent(index: Int) {
        onProbeSentInternal(index, System.nanoTime())
    }

    internal fun onProbeSentInternal(index: Int, nowNanos: Long) {
        if (reducedMotion) return

        // Remove eventual pacote prévio do mesmo índice para evitar duplicatas
        packets.removeAll { it.probeIndex == index }

        val packet = PacketState(
            probeIndex = index,
            phase = PacketPhase.OUTBOUND,
            startTimeNanos = nowNanos,
            durationNanos = DEFAULT_FLY_DURATION_NANOS,
            lost = false,
            color = LcColor.AccentLight,
            progress = 0f,
            elapsedFraction = 0f
        )
        packets.add(packet)
        hasActiveAnimations = true
    }

    /**
     * Notifica a chegada de uma resposta de sonda válida com o RTT medido.
     * Dispara o pacote de retorno verde rumo a "Você" e atualiza a mediana.
     */
    fun onProbeReturned(index: Int, rttMs: Double) {
        onProbeReturnedInternal(index, rttMs, System.nanoTime())
    }

    internal fun onProbeReturnedInternal(index: Int, rttMs: Double, nowNanos: Long) {
        rttHistory.add(rttMs)

        if (reducedMotion) return

        val existing = packets.firstOrNull { it.probeIndex == index }
        val flyDuration = ((rttMs * 8.0).coerceIn(300.0, 700.0) * 1_000_000L).toLong()

        if (existing != null) {
            existing.phase = PacketPhase.INBOUND
            existing.startTimeNanos = nowNanos
            existing.durationNanos = flyDuration
            existing.color = LcColor.Good
            existing.lost = false
            existing.progress = 0f
            existing.elapsedFraction = 0f
            existing.finished = false
        } else {
            val returnPacket = PacketState(
                probeIndex = index,
                phase = PacketPhase.INBOUND,
                startTimeNanos = nowNanos,
                durationNanos = flyDuration,
                lost = false,
                color = LcColor.Good,
                progress = 0f,
                elapsedFraction = 0f
            )
            packets.add(returnPacket)
        }
        hasActiveAnimations = true
    }

    /**
     * Notifica a perda de pacote na sonda.
     * A sonda avançará até 58% do trajeto e desaparecerá com uma marca em coral (#FF5A36).
     */
    fun onProbeLost(index: Int) {
        onProbeLostInternal(index, System.nanoTime())
    }

    internal fun onProbeLostInternal(index: Int, nowNanos: Long) {
        val existing = packets.firstOrNull { it.probeIndex == index }
        if (existing != null) {
            existing.lost = true
            // Se já tiver passado dos 58%, finaliza imediatamente
            if (existing.elapsedFraction >= LOST_THRESHOLD) {
                existing.finished = true
                existing.progress = LOST_THRESHOLD
                packets.removeAll { it.finished }
            }
        } else {
            val packet = PacketState(
                probeIndex = index,
                phase = PacketPhase.OUTBOUND,
                startTimeNanos = nowNanos,
                durationNanos = DEFAULT_FLY_DURATION_NANOS,
                lost = true,
                color = LcColor.AccentLight,
                progress = 0f,
                elapsedFraction = 0f
            )
            packets.add(packet)
        }
        hasActiveAnimations = true
    }

    /**
     * Atualiza a física de pacotes e ondas com base no tempo atual.
     * Retorna se ainda restam animações em execução.
     */
    fun updateTime(nowNanos: Long, user: MapPoint? = null, region: MapPoint? = null): Boolean {
        if (reducedMotion) {
            packets.clear()
            rings.clear()
            hasActiveAnimations = false
            return false
        }

        val itP = packets.iterator()
        while (itP.hasNext()) {
            val p = itP.next()
            val elapsedNanos = nowNanos - p.startTimeNanos
            val e = (elapsedNanos.toDouble() / p.durationNanos.toDouble()).toFloat()
            p.elapsedFraction = e

            if (p.lost && e >= LOST_THRESHOLD) {
                // Pacote perdido some ao atingir 58%
                p.finished = true
                p.progress = LOST_THRESHOLD
                itP.remove()
                continue
            }

            if (e >= 1.0f) {
                p.finished = true
                p.progress = 1.0f
                // Se era retorno e chegou em "Você", solta anel verde
                if (p.phase == PacketPhase.INBOUND && user != null) {
                    rings.add(
                        WaveRing(
                            lat = user.lat,
                            lon = user.lon,
                            maxRadiusPx = 60f,
                            durationNanos = RING_DURATION_NANOS,
                            color = LcColor.Good,
                            startTimeNanos = nowNanos
                        )
                    )
                }
                itP.remove()
                continue
            }

            val t = ease(e.coerceIn(0f, 1f))
            p.progress = if (p.phase == PacketPhase.OUTBOUND) t else 1f - t
        }

        // Atualiza anéis de onda
        val itR = rings.iterator()
        while (itR.hasNext()) {
            val ring = itR.next()
            if (nowNanos - ring.startTimeNanos >= ring.durationNanos) {
                itR.remove()
            }
        }

        hasActiveAnimations = packets.isNotEmpty() || rings.isNotEmpty()
        return hasActiveAnimations
    }

    /**
     * Registra onda de impacto (anel) manualmente em um ponto específico.
     */
    fun emitRing(lat: Double, lon: Double, maxRadiusPx: Float, color: Color, nowNanos: Long = System.nanoTime()) {
        if (reducedMotion) return
        rings.add(
            WaveRing(
                lat = lat,
                lon = lon,
                maxRadiusPx = maxRadiusPx,
                durationNanos = RING_DURATION_NANOS,
                color = color,
                startTimeNanos = nowNanos
            )
        )
        hasActiveAnimations = true
    }
}
