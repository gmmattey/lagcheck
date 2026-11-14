package com.lagcheck.core.designsystem.components.map

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min

/** Estado observado de uma região durante a escolha do servidor. */
data class RouteMapRegionState(
    /** Menor RTT válido observado. */
    val ms: Double?,
    val answered: Boolean,
    /** Amostras já concluídas (respondidas ou não). */
    val count: Int
)

/** Pacote em voo no mapa. Toda instância nasce de um evento real do motor. */
data class RouteMapPacket(
    val regionId: String,
    val kind: Kind,
    val startMs: Long,
    val durationMs: Long,
    val returnDurationMs: Long = 0L
) {
    enum class Kind {
        /** Varredura: sonda saindo para um servidor candidato. */
        SWEEP_OUT,
        /** Varredura: resposta real voltando de um servidor candidato. */
        SWEEP_IN,
        /** Região escolhida: ida (420 ms) e volta proporcional ao RTT. */
        PROBE
    }

    /** Fase e progresso com easing. */
    data class Flight(val outbound: Boolean, val t: Double)

    val isSweep: Boolean get() = kind != Kind.PROBE
    val endMs: Long get() = startMs + durationMs + if (kind == Kind.PROBE) returnDurationMs else 0L

    /** Nulo antes de partir ou depois de chegar. */
    fun flight(nowMs: Long): Flight? {
        if (nowMs < startMs) return null
        val elapsed = (nowMs - startMs).toDouble()
        return when (kind) {
            Kind.SWEEP_OUT -> if (elapsed < durationMs) Flight(true, RouteMapProjection.ease(elapsed / durationMs)) else null
            Kind.SWEEP_IN -> if (elapsed < durationMs) Flight(false, RouteMapProjection.ease(elapsed / durationMs)) else null
            Kind.PROBE -> when {
                elapsed < durationMs -> Flight(true, RouteMapProjection.ease(elapsed / durationMs))
                elapsed - durationMs < returnDurationMs ->
                    Flight(false, RouteMapProjection.ease((elapsed - durationMs) / returnDurationMs))
                else -> null
            }
        }
    }
}

/**
 * Máquina de estados do mapa de medição, porta direta de `RouteMap` do site (`pages/lagcheck/src/lib/map/route-map.ts`)
 * e espelho de `RouteMapController.swift`: varredura dos servidores candidatos, escolha da região com a câmera se
 * aproximando e uma sonda por resposta real. Tudo que se move vem de uma chamada feita por quem recebeu o evento do
 * motor; sem evento, nada se move. Chame sempre na thread principal.
 */
class RouteMapController(
    /** `false`: desenha direto no enquadramento final, sem pacotes. */
    val animate: Boolean = true
) {
    var user: MapGeoPoint? by mutableStateOf(null)
        private set
    /** Cidade da localização aproximada (rótulo "Você · Cidade"), quando conhecida. */
    var userCity: String? by mutableStateOf(null)
        private set
    var locationUnavailable: Boolean by mutableStateOf(false)
        private set
    var selectedId: String? by mutableStateOf(null)
        private set
    var selectedMs: Double? by mutableStateOf(null)
        private set
    var regions: Map<String, RouteMapRegionState> by mutableStateOf(emptyMap())
        private set
    var packets: List<RouteMapPacket> by mutableStateOf(emptyList())
        private set
    /** Até quando há movimento (pacotes ou câmera). O mapa só roda quadros até aqui. */
    var motionDeadlineMs: Long by mutableStateOf(0L)
        private set

    private var camera: MapCamera? = null
    private var lastFrameMs: Long? = null
    private var sweepBurstStartMs: Long = Long.MIN_VALUE / 2
    private var sweepBurstIndex = 0
    private var cursorPhase: String? = null
    private var cursorCount = 0
    /** Regiões que já receberam sonda enquanto "Você" ainda não tinha posição. */
    private val pendingSweep = mutableListOf<String>()

    /** Nova sessão: volta à visão de todos os servidores, sem pacotes nem escolha. */
    fun reset(nowMs: Long = now()) {
        selectedId = null
        selectedMs = null
        regions = emptyMap()
        packets = emptyList()
        camera = null
        lastFrameMs = null
        sweepBurstStartMs = Long.MIN_VALUE / 2
        sweepBurstIndex = 0
        cursorPhase = null
        cursorCount = 0
        pendingSweep.clear()
        retarget(nowMs)
    }

    /** Localização ainda sendo consultada: a varredura espera por "Você", como no site (`userLoc === undefined`). */
    fun clearUser(nowMs: Long = now()) {
        user = null
        userCity = null
        locationUnavailable = false
        retarget(nowMs)
    }

    /* ----- Entradas (todas vindas de medição real) ----- */

    /** Localização aproximada; nulo quando indisponível (o mapa segue só com a região). */
    fun setUser(point: MapGeoPoint?, city: String? = null, nowMs: Long = now()) {
        user = point
        userCity = if (point == null) null else city
        locationUnavailable = point == null
        retarget(nowMs)
        flushPendingSweep(nowMs)
    }

    /** Envio real de uma sonda da escolha de servidor. A leva parte junta; o escalonamento de 45 ms é só visual. */
    fun regionSent(id: String, nowMs: Long = now()) {
        if (!animate || selectedId != null || RouteMapProjection.regionPoint(id) == null) return
        if (user == null) {
            // Como `startSweep()` do site: a leva espera a localização e parte quando ela chega.
            if (!locationUnavailable && id !in pendingSweep) pendingSweep.add(id)
            return
        }
        prune(nowMs)
        if (packets.size >= MAX_SWEEP_PACKETS) return
        if (nowMs - sweepBurstStartMs > SWEEP_BURST_WINDOW_MS) {
            sweepBurstStartMs = nowMs
            sweepBurstIndex = 0
        } else {
            sweepBurstIndex += 1
        }
        val start = max(nowMs, sweepBurstStartMs + sweepBurstIndex * SWEEP_STAGGER_MS)
        append(RouteMapPacket(id, RouteMapPacket.Kind.SWEEP_OUT, start, SWEEP_FLIGHT_MS))
    }

    /** Uma resposta (ou falta de resposta) de uma região durante a escolha. */
    fun regionSample(id: String, ms: Double?, nowMs: Long = now()) {
        if (RouteMapProjection.regionPoint(id) == null) return
        val previous = regions[id] ?: RouteMapRegionState(null, false, 0)
        val valid = ms?.takeIf { it.isFinite() && it >= 0.0 }
        val next = if (valid != null) {
            previous.copy(ms = previous.ms?.let { min(it, valid) } ?: valid, answered = true, count = previous.count + 1)
        } else {
            previous.copy(count = previous.count + 1)
        }
        regions = regions + (id to next)
        if (animate && user != null && selectedId == null && valid != null) {
            prune(nowMs)
            if (packets.size < MAX_SWEEP_PACKETS) {
                append(RouteMapPacket(id, RouteMapPacket.Kind.SWEEP_IN, nowMs, RouteMapProjection.returnFlightMs(valid)))
            }
        }
    }

    /** A região escolhida: a câmera se aproxima para enquadrar "Você" e a região. */
    fun selectRegion(id: String, ms: Double? = null, nowMs: Long = now()) {
        if (RouteMapProjection.regionPoint(id) == null) return
        selectedId = id
        pendingSweep.clear()
        packets = packets.filterNot { it.isSweep }
        selectedMs = ms ?: regions[id]?.ms ?: selectedMs
        cursorPhase = null
        cursorCount = 0
        retarget(nowMs)
    }

    fun updateSelectedMs(ms: Double?) {
        if (selectedMs != ms) selectedMs = ms
    }

    /** Uma resposta real da região escolhida: um ponto sai de "Você", chega e volta. */
    fun probe(rttMs: Double, nowMs: Long = now()) {
        val region = selectedId ?: return
        if (!animate || user == null || !rttMs.isFinite() || rttMs < 0.0) return
        prune(nowMs)
        if (packets.size >= MAX_PACKETS) return
        append(RouteMapPacket(region, RouteMapPacket.Kind.PROBE, nowMs, PROBE_OUT_MS, RouteMapProjection.returnFlightMs(rttMs)))
    }

    /**
     * Consome a lista de respostas válidas de uma fase, que só cresce enquanto a fase dura. Cada resposta nova vira
     * exatamente uma sonda; trocar de fase reinicia o cursor, porque a lista recomeça vazia.
     */
    fun ingestProbeResponses(rtts: List<Double?>, phase: String, nowMs: Long = now()) {
        if (phase != cursorPhase || rtts.size < cursorCount) {
            cursorPhase = phase
            cursorCount = 0
        }
        rtts.drop(cursorCount).forEach { rtt -> if (rtt != null) probe(rtt, nowMs) }
        cursorCount = rtts.size
    }

    /** Mantém quadros rodando quando uma tela nova passa a mostrar este mapa. */
    fun viewAppeared(nowMs: Long = now()) = retarget(nowMs)

    /* ----- Câmera ----- */

    fun targetCamera(width: Float, height: Float): MapCamera {
        val selected = selectedId?.let { RouteMapProjection.regionPoint(it) }
        if (selected != null) {
            val points = listOfNotNull(user, selected)
            return RouteMapProjection.fitCamera(
                points = points, width = width, height = height,
                padX = min(110.0, width * 0.2), padY = 52.0,
                maxZoom = RouteMapProjection.ROUTE_MAX_ZOOM
            )
        }
        return overviewCamera(width, height)
    }

    /** Procurando regiões: todas as candidatas à vista, mais "Você". */
    fun overviewCamera(width: Float, height: Float): MapCamera {
        val points = RouteMapProjection.REGION_COORDINATES.values.toMutableList()
        user?.let { points.add(it) }
        return RouteMapProjection.fitCamera(points, width, height, padX = 28.0, padY = 28.0)
    }

    /** Avança a câmera um quadro. Começa na visão geral (como o site) e se aproxima do alvo. */
    fun advanceCamera(width: Float, height: Float, nowMs: Long, reduceMotion: Boolean): MapCamera {
        val target = targetCamera(width, height)
        if (!animate || reduceMotion) {
            camera = target
            lastFrameMs = null
            return target
        }
        val current = camera
        if (current == null) {
            val start = overviewCamera(width, height)
            camera = start
            lastFrameMs = nowMs
            return start
        }
        val dt = lastFrameMs?.let { min(max((nowMs - it) / 1000.0, 0.0), 0.05) } ?: 0.016
        lastFrameMs = nowMs
        val k = 1 - exp(-dt * CAMERA_RATE)
        val next = MapCamera(
            lon = current.lon + (target.lon - current.lon) * k,
            lat = current.lat + (target.lat - current.lat) * k,
            zoom = current.zoom + (target.zoom - current.zoom) * k
        )
        camera = next
        return next
    }

    /** Região que lidera a varredura (menor RTT), enquanto nada foi escolhido. */
    val leaderId: String?
        get() {
            if (selectedId != null) return null
            return regions.entries
                .filter { it.value.ms != null }
                .minWithOrNull(compareBy<Map.Entry<String, RouteMapRegionState>>({ it.value.ms!! }, { it.key }))
                ?.key
        }

    /* ----- Interno ----- */

    private fun flushPendingSweep(nowMs: Long) {
        val ids = pendingSweep.toList()
        pendingSweep.clear()
        if (!animate || user == null || selectedId != null) return
        ids.forEachIndexed { index, id ->
            if (packets.size < MAX_SWEEP_PACKETS) {
                append(RouteMapPacket(id, RouteMapPacket.Kind.SWEEP_OUT, nowMs + index * SWEEP_STAGGER_MS, SWEEP_FLIGHT_MS))
            }
        }
    }

    private fun append(packet: RouteMapPacket) {
        packets = packets + packet
        extendMotion(packet.endMs)
    }

    private fun prune(nowMs: Long) {
        if (packets.any { nowMs >= it.endMs }) packets = packets.filter { nowMs < it.endMs }
    }

    private fun retarget(nowMs: Long) = extendMotion(nowMs + CAMERA_SETTLE_MS)

    private fun extendMotion(deadline: Long) {
        if (deadline > motionDeadlineMs) motionDeadlineMs = deadline
    }

    companion object {
        const val PROBE_OUT_MS = 420L
        const val MAX_PACKETS = 6
        const val SWEEP_STAGGER_MS = 45L
        const val SWEEP_FLIGHT_MS = 620L
        const val MAX_SWEEP_PACKETS = 80
        /** Suavização da câmera por quadro: `k = 1 - exp(-dt * 3.2)`, como no site. */
        const val CAMERA_RATE = 3.2
        /** Tempo para a câmera assentar (resíduo abaixo de 0,1%). */
        const val CAMERA_SETTLE_MS = 2200L
        /** Envios dentro desta janela formam uma leva e são escalonados no desenho. */
        const val SWEEP_BURST_WINDOW_MS = 150L

        /** Relógio monotônico do mapa, em milissegundos. */
        fun now(): Long = System.nanoTime() / 1_000_000L
    }
}

/**
 * Ponto de origem aproximado de "Você". O app não pede localização nem consulta serviço de IP no celular: a origem é
 * o ponto de referência do país configurado no aparelho. Sem país conhecido, não há origem e o mapa mostra a nota de
 * localização indisponível, como o site. Mesma tabela do iOS (`RouteMapOrigin`).
 */
object RouteMapOrigin {
    val COUNTRY_POINTS: Map<String, MapGeoPoint> = mapOf(
        "BR" to MapGeoPoint(-15.79, -47.88),
        "US" to MapGeoPoint(39.83, -98.58),
        "CA" to MapGeoPoint(45.42, -75.70),
        "MX" to MapGeoPoint(19.43, -99.13),
        "AR" to MapGeoPoint(-34.60, -58.38),
        "CL" to MapGeoPoint(-33.45, -70.67),
        "CO" to MapGeoPoint(4.71, -74.07),
        "PE" to MapGeoPoint(-12.05, -77.04),
        "UY" to MapGeoPoint(-34.90, -56.16),
        "PY" to MapGeoPoint(-25.26, -57.58),
        "BO" to MapGeoPoint(-16.50, -68.15),
        "EC" to MapGeoPoint(-0.18, -78.47),
        "VE" to MapGeoPoint(10.48, -66.90),
        "PT" to MapGeoPoint(38.72, -9.14),
        "ES" to MapGeoPoint(40.42, -3.70),
        "GB" to MapGeoPoint(51.51, -0.13),
        "IE" to MapGeoPoint(53.35, -6.26),
        "FR" to MapGeoPoint(48.86, 2.35),
        "DE" to MapGeoPoint(52.52, 13.40),
        "NL" to MapGeoPoint(52.37, 4.90),
        "IT" to MapGeoPoint(41.90, 12.50),
        "SE" to MapGeoPoint(59.33, 18.07),
        "PL" to MapGeoPoint(52.23, 21.01),
        "TR" to MapGeoPoint(39.93, 32.86),
        "ZA" to MapGeoPoint(-25.75, 28.19),
        "AE" to MapGeoPoint(24.45, 54.38),
        "SA" to MapGeoPoint(24.71, 46.68),
        "IN" to MapGeoPoint(28.61, 77.21),
        "SG" to MapGeoPoint(1.35, 103.82),
        "ID" to MapGeoPoint(-6.21, 106.85),
        "PH" to MapGeoPoint(14.60, 120.98),
        "JP" to MapGeoPoint(35.68, 139.69),
        "KR" to MapGeoPoint(37.57, 126.98),
        "AU" to MapGeoPoint(-35.28, 149.13),
        "NZ" to MapGeoPoint(-41.29, 174.78)
    )

    fun approximatePoint(countryCode: String?): MapGeoPoint? {
        val code = countryCode?.uppercase() ?: return null
        if (code.length != 2) return null
        return COUNTRY_POINTS[code]
    }
}
