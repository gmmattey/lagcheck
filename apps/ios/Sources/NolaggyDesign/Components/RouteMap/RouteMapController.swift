import Foundation
import Observation

/// Estado observado de uma região durante a escolha do servidor.
public struct RouteMapRegionState: Equatable, Sendable {
    /// Menor RTT válido observado.
    public var ms: Double?
    public var answered: Bool
    /// Amostras já concluídas (respondidas ou não).
    public var count: Int
}

/// Pacote em voo no mapa. Toda instância nasce de um evento real do motor.
public struct RouteMapPacket: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        /// Varredura: sonda saindo para um servidor candidato.
        case sweepOut
        /// Varredura: resposta real voltando de um servidor candidato.
        case sweepIn
        /// Região escolhida: ida (420 ms) e volta proporcional ao RTT.
        case probe
    }

    public let regionId: String
    public let kind: Kind
    public let start: TimeInterval
    public let duration: TimeInterval
    public let returnDuration: TimeInterval

    public var isSweep: Bool { kind != .probe }
    public var end: TimeInterval { start + duration + (kind == .probe ? returnDuration : 0) }

    /// Fase e progresso com easing no instante `now`; `nil` antes de partir ou depois de chegar.
    public func flight(at now: TimeInterval) -> (outbound: Bool, t: Double)? {
        guard now >= start else { return nil }
        let elapsed = now - start
        switch kind {
        case .sweepOut:
            guard elapsed < duration else { return nil }
            return (true, RouteMapProjection.ease(elapsed / duration))
        case .sweepIn:
            guard elapsed < duration else { return nil }
            return (false, RouteMapProjection.ease(elapsed / duration))
        case .probe:
            if elapsed < duration { return (true, RouteMapProjection.ease(elapsed / duration)) }
            let back = elapsed - duration
            guard back < returnDuration else { return nil }
            return (false, RouteMapProjection.ease(back / returnDuration))
        }
    }
}

/// Máquina de estados do mapa de medição, porta direta de `RouteMap` do site
/// (`pages/lagcheck/src/lib/map/route-map.ts`): varredura dos servidores
/// candidatos, escolha da região com a câmera se aproximando e uma sonda por
/// resposta real. Tudo que se move vem de uma chamada feita por quem recebeu o
/// evento do motor; sem evento, nada se move.
@MainActor
@Observable
public final class RouteMapController {
    public static let probeOutSeconds: TimeInterval = 0.420
    public static let maxPackets = 6
    public static let sweepStaggerSeconds: TimeInterval = 0.045
    public static let sweepFlightSeconds: TimeInterval = 0.620
    public static let maxSweepPackets = 80
    /// Suavização da câmera por quadro: `k = 1 - exp(-dt * 3.2)`, como no site.
    public static let cameraRate = 3.2
    /// Tempo para a câmera assentar (resíduo abaixo de 0,1%).
    public static let cameraSettleSeconds: TimeInterval = 2.2
    /// Envios que chegam dentro desta janela formam uma leva e são escalonados no desenho.
    static let sweepBurstWindow: TimeInterval = 0.15

    /// `false`: desenha direto no enquadramento final, sem pacotes.
    public let animate: Bool
    public private(set) var user: MapGeoPoint?
    /// Cidade da localização aproximada (rótulo "Você · Cidade"), quando conhecida.
    public private(set) var userCity: String?
    public private(set) var locationUnavailable = false
    public private(set) var selectedId: String?
    public private(set) var selectedMs: Double?
    public private(set) var regions: [String: RouteMapRegionState] = [:]
    public private(set) var packets: [RouteMapPacket] = []
    /// Até quando há movimento (pacotes ou câmera). A view só roda quadros até aqui.
    public private(set) var motionDeadline: TimeInterval = 0

    @ObservationIgnored private var camera: MapCamera?
    @ObservationIgnored private var lastFrame: TimeInterval?
    @ObservationIgnored private var sweepBurstStart: TimeInterval = -.infinity
    @ObservationIgnored private var sweepBurstIndex = 0
    @ObservationIgnored private var cursorPhase: String?
    @ObservationIgnored private var cursorCount = 0
    /// Regiões que já receberam sonda enquanto "Você" ainda não tinha posição.
    @ObservationIgnored private var pendingSweep: [String] = []

    public init(animate: Bool = true) {
        self.animate = animate
    }

    public static var now: TimeInterval { Date().timeIntervalSinceReferenceDate }

    /// Nova sessão: volta à visão de todos os servidores, sem pacotes nem escolha.
    public func reset(at now: TimeInterval = RouteMapController.now) {
        selectedId = nil
        selectedMs = nil
        regions = [:]
        packets = []
        camera = nil
        lastFrame = nil
        sweepBurstStart = -.infinity
        sweepBurstIndex = 0
        cursorPhase = nil
        cursorCount = 0
        pendingSweep = []
        retarget(now)
    }

    /// Localização ainda sendo consultada: o mapa mostra os servidores e a
    /// varredura espera por "Você", como no site (`userLoc === undefined`).
    public func clearUser(at now: TimeInterval = RouteMapController.now) {
        user = nil
        userCity = nil
        locationUnavailable = false
        retarget(now)
    }

    /* ----- Entradas (todas vindas de medição real) ----- */

    /// Localização aproximada; `nil` quando indisponível (o mapa segue só com a região).
    public func setUser(_ point: MapGeoPoint?, city: String? = nil, at now: TimeInterval = RouteMapController.now) {
        user = point
        userCity = point == nil ? nil : city
        locationUnavailable = point == nil
        retarget(now)
        flushPendingSweep(now)
    }

    /// Envio real de uma sonda da escolha de servidor. As sondas de uma leva
    /// partem juntas; o escalonamento de 45 ms é só visual, como no site.
    public func regionSent(_ id: String, at now: TimeInterval = RouteMapController.now) {
        guard animate, selectedId == nil, RouteMapProjection.regionPoint(id: id) != nil else { return }
        guard user != nil else {
            // Como `startSweep()` do site: a leva espera a localização e parte quando ela chega.
            if !locationUnavailable, !pendingSweep.contains(id) { pendingSweep.append(id) }
            return
        }
        prune(now)
        guard packets.count < Self.maxSweepPackets else { return }
        if now - sweepBurstStart > Self.sweepBurstWindow {
            sweepBurstStart = now
            sweepBurstIndex = 0
        } else {
            sweepBurstIndex += 1
        }
        let start = max(now, sweepBurstStart + Double(sweepBurstIndex) * Self.sweepStaggerSeconds)
        append(RouteMapPacket(regionId: id, kind: .sweepOut, start: start, duration: Self.sweepFlightSeconds, returnDuration: 0))
    }

    /// Uma resposta (ou falta de resposta) de uma região durante a escolha.
    public func regionSample(_ id: String, ms: Double?, at now: TimeInterval = RouteMapController.now) {
        guard RouteMapProjection.regionPoint(id: id) != nil else { return }
        var state = regions[id] ?? RouteMapRegionState(ms: nil, answered: false, count: 0)
        state.count += 1
        let valid = ms.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        if let valid {
            state.answered = true
            state.ms = state.ms.map { min($0, valid) } ?? valid
        }
        regions[id] = state
        if animate, user != nil, selectedId == nil, let valid {
            prune(now)
            if packets.count < Self.maxSweepPackets {
                append(RouteMapPacket(
                    regionId: id, kind: .sweepIn, start: now,
                    duration: RouteMapProjection.returnFlightSeconds(rttMs: valid), returnDuration: 0
                ))
            }
        }
    }

    /// A região escolhida: a câmera se aproxima para enquadrar "Você" e a região.
    public func selectRegion(_ id: String, ms: Double? = nil, at now: TimeInterval = RouteMapController.now) {
        guard RouteMapProjection.regionPoint(id: id) != nil else { return }
        selectedId = id
        pendingSweep = []
        packets.removeAll { $0.isSweep }
        selectedMs = ms ?? regions[id]?.ms ?? selectedMs
        cursorPhase = nil
        cursorCount = 0
        retarget(now)
    }

    public func setSelectedMs(_ ms: Double?) {
        if selectedMs != ms { selectedMs = ms }
    }

    /// Uma resposta real da região escolhida: um ponto sai de "Você", chega e volta.
    public func probe(rttMs: Double, at now: TimeInterval = RouteMapController.now) {
        guard animate, user != nil, let selectedId, rttMs.isFinite, rttMs >= 0 else { return }
        prune(now)
        guard packets.count < Self.maxPackets else { return }
        append(RouteMapPacket(
            regionId: selectedId, kind: .probe, start: now,
            duration: Self.probeOutSeconds,
            returnDuration: RouteMapProjection.returnFlightSeconds(rttMs: rttMs)
        ))
    }

    /// Consome a lista de respostas válidas de uma fase, que só cresce enquanto
    /// a fase dura. Cada resposta nova vira exatamente uma sonda; trocar de fase
    /// reinicia o cursor, porque a lista recomeça vazia.
    public func ingestProbeResponses(_ rtts: [Double?], phase: String, at now: TimeInterval = RouteMapController.now) {
        if phase != cursorPhase || rtts.count < cursorCount {
            cursorPhase = phase
            cursorCount = 0
        }
        for rtt in rtts.dropFirst(cursorCount) {
            if let rtt { probe(rttMs: rtt, at: now) }
        }
        cursorCount = rtts.count
    }

    /// Mantém quadros rodando quando uma view nova passa a mostrar este mapa.
    public func viewAppeared(at now: TimeInterval = RouteMapController.now) {
        retarget(now)
    }

    /* ----- Câmera ----- */

    public func targetCamera(width: Double, height: Double) -> MapCamera {
        if let selectedId, let selected = RouteMapProjection.regionPoint(id: selectedId) {
            let points = user.map { [$0, selected] } ?? [selected]
            return RouteMapProjection.fitCamera(
                points: points, width: width, height: height,
                padX: min(110, width * 0.2), padY: 52,
                maxZoom: RouteMapProjection.routeMaxZoom
            )
        }
        return overviewCamera(width: width, height: height)
    }

    /// Procurando regiões: todas as candidatas à vista, mais "Você".
    public func overviewCamera(width: Double, height: Double) -> MapCamera {
        var points = Array(RouteMapProjection.regionCoordinates.values)
        if let user { points.append(user) }
        return RouteMapProjection.fitCamera(points: points, width: width, height: height, padX: 28, padY: 28)
    }

    /// Avança a câmera um quadro. Começa na visão geral (como o site, que nasce
    /// enquadrando todos os servidores) e se aproxima do alvo.
    public func advanceCamera(width: Double, height: Double, now: TimeInterval, reduceMotion: Bool) -> MapCamera {
        let target = targetCamera(width: width, height: height)
        guard animate, !reduceMotion else {
            camera = target
            lastFrame = nil
            return target
        }
        guard let current = camera else {
            let start = overviewCamera(width: width, height: height)
            camera = start
            lastFrame = now
            return start
        }
        let dt = lastFrame.map { min(max(now - $0, 0), 0.05) } ?? 0.016
        lastFrame = now
        let k = 1 - exp(-dt * Self.cameraRate)
        let next = MapCamera(
            lon: current.lon + (target.lon - current.lon) * k,
            lat: current.lat + (target.lat - current.lat) * k,
            zoom: current.zoom + (target.zoom - current.zoom) * k
        )
        camera = next
        return next
    }

    /// Região que lidera a varredura (menor RTT), enquanto nada foi escolhido.
    public var leaderId: String? {
        guard selectedId == nil else { return nil }
        var best: (id: String, ms: Double)?
        for (id, state) in regions {
            guard let ms = state.ms else { continue }
            if let current = best, ms > current.ms || (ms == current.ms && id >= current.id) { continue }
            best = (id, ms)
        }
        return best?.id
    }

    /* ----- Interno ----- */

    private func flushPendingSweep(_ now: TimeInterval) {
        let ids = pendingSweep
        pendingSweep = []
        guard animate, user != nil, selectedId == nil else { return }
        for (index, id) in ids.enumerated() where packets.count < Self.maxSweepPackets {
            append(RouteMapPacket(
                regionId: id, kind: .sweepOut,
                start: now + Double(index) * Self.sweepStaggerSeconds,
                duration: Self.sweepFlightSeconds, returnDuration: 0
            ))
        }
    }

    private func append(_ packet: RouteMapPacket) {
        packets.append(packet)
        extendMotion(to: packet.end)
    }

    private func prune(_ now: TimeInterval) {
        packets.removeAll { now >= $0.end }
    }

    private func retarget(_ now: TimeInterval) {
        extendMotion(to: now + Self.cameraSettleSeconds)
    }

    private func extendMotion(to deadline: TimeInterval) {
        if deadline > motionDeadline { motionDeadline = deadline }
    }
}

/// Ponto de origem aproximado de "Você".
///
/// O app não pede localização nem consulta serviço de IP no celular. A origem
/// é o ponto de referência do país configurado no aparelho (capital, ou centro
/// geográfico em países continentais grandes). Sem país conhecido, não há
/// origem: o mapa mostra a nota de localização indisponível, como o site.
public enum RouteMapOrigin {
    public static let countryPoints: [String: MapGeoPoint] = [
        "BR": MapGeoPoint(lat: -15.79, lon: -47.88),
        "US": MapGeoPoint(lat: 39.83, lon: -98.58),
        "CA": MapGeoPoint(lat: 45.42, lon: -75.70),
        "MX": MapGeoPoint(lat: 19.43, lon: -99.13),
        "AR": MapGeoPoint(lat: -34.60, lon: -58.38),
        "CL": MapGeoPoint(lat: -33.45, lon: -70.67),
        "CO": MapGeoPoint(lat: 4.71, lon: -74.07),
        "PE": MapGeoPoint(lat: -12.05, lon: -77.04),
        "UY": MapGeoPoint(lat: -34.90, lon: -56.16),
        "PY": MapGeoPoint(lat: -25.26, lon: -57.58),
        "BO": MapGeoPoint(lat: -16.50, lon: -68.15),
        "EC": MapGeoPoint(lat: -0.18, lon: -78.47),
        "VE": MapGeoPoint(lat: 10.48, lon: -66.90),
        "PT": MapGeoPoint(lat: 38.72, lon: -9.14),
        "ES": MapGeoPoint(lat: 40.42, lon: -3.70),
        "GB": MapGeoPoint(lat: 51.51, lon: -0.13),
        "IE": MapGeoPoint(lat: 53.35, lon: -6.26),
        "FR": MapGeoPoint(lat: 48.86, lon: 2.35),
        "DE": MapGeoPoint(lat: 52.52, lon: 13.40),
        "NL": MapGeoPoint(lat: 52.37, lon: 4.90),
        "IT": MapGeoPoint(lat: 41.90, lon: 12.50),
        "SE": MapGeoPoint(lat: 59.33, lon: 18.07),
        "PL": MapGeoPoint(lat: 52.23, lon: 21.01),
        "TR": MapGeoPoint(lat: 39.93, lon: 32.86),
        "ZA": MapGeoPoint(lat: -25.75, lon: 28.19),
        "AE": MapGeoPoint(lat: 24.45, lon: 54.38),
        "SA": MapGeoPoint(lat: 24.71, lon: 46.68),
        "IN": MapGeoPoint(lat: 28.61, lon: 77.21),
        "SG": MapGeoPoint(lat: 1.35, lon: 103.82),
        "ID": MapGeoPoint(lat: -6.21, lon: 106.85),
        "PH": MapGeoPoint(lat: 14.60, lon: 120.98),
        "JP": MapGeoPoint(lat: 35.68, lon: 139.69),
        "KR": MapGeoPoint(lat: 37.57, lon: 126.98),
        "AU": MapGeoPoint(lat: -35.28, lon: 149.13),
        "NZ": MapGeoPoint(lat: -41.29, lon: 174.78)
    ]

    public static func approximatePoint(countryCode: String?) -> MapGeoPoint? {
        guard let code = countryCode?.uppercased(), code.count == 2 else { return nil }
        return countryPoints[code]
    }
}
