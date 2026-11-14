import SwiftUI

/// Mapa de medição: mapa-múndi de pontos com "Você", as regiões medidas, o arco
/// da rota e as sondas reais. Desenho espelhado de `RouteMap.draw()` do site
/// (`pages/lagcheck/src/lib/map/route-map.ts`). Plano: sem gradiente, brilho,
/// halo nem onda expansiva. Só roda quadros enquanto há movimento.
public struct RouteMeasurementMapView: View {
    private let controller: RouteMapController
    private let userLabel: String
    private let unavailableLabel: String
    private let regionName: (String) -> String
    private let accessibilityText: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var idle = true

    public init(
        controller: RouteMapController,
        userLabel: String,
        unavailableLabel: String,
        accessibilityText: String,
        regionName: @escaping (String) -> String
    ) {
        self.controller = controller
        self.userLabel = userLabel
        self.unavailableLabel = unavailableLabel
        self.accessibilityText = accessibilityText
        self.regionName = regionName
    }

    public var body: some View {
        // Lido aqui para o SwiftUI observar as entradas do controlador.
        let snapshot = Snapshot(controller: controller)
        let deadline = controller.motionDeadline
        let moving = controller.animate && !reduceMotion && !idle

        TimelineView(.animation(paused: !moving)) { timeline in
            Canvas { context, size in
                draw(
                    snapshot: snapshot,
                    context: &context,
                    size: size,
                    now: moving ? timeline.date.timeIntervalSinceReferenceDate : RouteMapController.now
                )
            }
        }
        .background(NLColor.deep)
        .clipShape(RoundedRectangle(cornerRadius: NLRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NLRadius.md, style: .continuous)
                .stroke(NLColor.borderHairline, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isImage)
        .onAppear { controller.viewAppeared() }
        .task(id: deadline) {
            let remaining = deadline - RouteMapController.now
            guard remaining > 0 else {
                idle = true
                return
            }
            idle = false
            try? await Task.sleep(for: .seconds(remaining + 0.05))
            if !Task.isCancelled { idle = true }
        }
    }

    private struct Snapshot {
        let animate: Bool
        let user: MapGeoPoint?
        let userCity: String?
        let locationUnavailable: Bool
        let selectedId: String?
        let selectedMs: Double?
        let regions: [String: RouteMapRegionState]
        let packets: [RouteMapPacket]
        let leaderId: String?

        @MainActor
        init(controller: RouteMapController) {
            animate = controller.animate
            user = controller.user
            userCity = controller.userCity
            locationUnavailable = controller.locationUnavailable
            selectedId = controller.selectedId
            selectedMs = controller.selectedMs
            regions = controller.regions
            packets = controller.packets
            leaderId = controller.leaderId
        }
    }

    private static let sweepTrail = Color(red: 167 / 255, green: 139 / 255, blue: 250 / 255).opacity(0.22)
    private static let labelFill = Color(red: 11 / 255, green: 13 / 255, blue: 16 / 255).opacity(0.9)
    private static let labelStroke = Color(red: 244 / 255, green: 245 / 255, blue: 247 / 255).opacity(0.16)

    @MainActor
    private func draw(snapshot s: Snapshot, context: inout GraphicsContext, size: CGSize, now: TimeInterval) {
        let w = Double(size.width)
        let h = Double(size.height)
        guard w > 0, h > 0 else { return }
        let cam = controller.advanceCamera(width: w, height: h, now: now, reduceMotion: reduceMotion)
        let showPackets = s.animate && !reduceMotion

        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(NLColor.deep))

        // 1) Mapa de pontos
        let k = (w / 360.0) * cam.zoom
        let r = min(max(k * RouteMapGridData.step * 0.34, 0.8), 3.4)
        var land = Path()
        for point in RouteMapProjection.landPoints {
            let p = RouteMapProjection.project(lat: point.lat, lon: point.lon, camera: cam, width: w, height: h)
            if Double(p.x) < -r || Double(p.x) > w + r || Double(p.y) < -r || Double(p.y) > h + r { continue }
            land.addEllipse(in: CGRect(x: Double(p.x) - r, y: Double(p.y) - r, width: r * 2, height: r * 2))
        }
        context.fill(land, with: .color(NLColor.textSecondary.opacity(0.34)))

        let selectedGeo = s.selectedId.flatMap { RouteMapProjection.regionPoint(id: $0) }
        let userPt = s.user.map { RouteMapProjection.project(lat: $0.lat, lon: $0.lon, camera: cam, width: w, height: h) }
        let selectedPt = selectedGeo.map { RouteMapProjection.project(lat: $0.lat, lon: $0.lon, camera: cam, width: w, height: h) }

        // 2) Regiões candidatas
        for (id, geo) in RouteMapProjection.regionCoordinates where id != s.selectedId {
            let p = RouteMapProjection.project(lat: geo.lat, lon: geo.lon, camera: cam, width: w, height: h)
            if id == s.leaderId {
                context.fill(circle(p, 4.2), with: .color(NLColor.gamerPurpleLight))
            } else if s.regions[id]?.answered == true {
                context.fill(circle(p, 2.8), with: .color(NLColor.textSecondary))
            } else {
                context.stroke(circle(p, 2.8), with: .color(NLColor.textTertiary), lineWidth: 1.2)
            }
        }

        // 3) Arco e sondas em voo
        if let userPt, let selectedPt {
            let arc = RouteMapProjection.computeArc(from: userPt, to: selectedPt, maxHeight: h * 0.38)
            context.stroke(arcPath(arc), with: .color(NLColor.gamerPurple), lineWidth: 1.6)
            if showPackets {
                for packet in s.packets where !packet.isSweep {
                    guard let flight = packet.flight(at: now) else { continue }
                    let pos = RouteMapProjection.bezierPoint(arc: arc, t: flight.outbound ? flight.t : 1 - flight.t)
                    context.fill(circle(pos, 3.2), with: .color(flight.outbound ? NLColor.gamerPurpleLight : NLColor.textPrimary))
                }
            }
        }

        // 3b) Varredura: uma sonda por servidor candidato, com um traço fino enquanto está em voo
        if let userPt, selectedPt == nil, showPackets {
            for packet in s.packets where packet.isSweep {
                guard let flight = packet.flight(at: now),
                      let geo = RouteMapProjection.regionPoint(id: packet.regionId) else { continue }
                let rp = RouteMapProjection.project(lat: geo.lat, lon: geo.lon, camera: cam, width: w, height: h)
                let arc = RouteMapProjection.computeArc(from: userPt, to: rp, maxHeight: h * 0.38)
                context.stroke(arcPath(arc), with: .color(Self.sweepTrail), lineWidth: 1)
                let pos = RouteMapProjection.bezierPoint(arc: arc, t: flight.outbound ? flight.t : 1 - flight.t)
                context.fill(circle(pos, 2.6), with: .color(flight.outbound ? NLColor.gamerPurpleLight : NLColor.textPrimary))
            }
        }

        // 4) Pinos
        if let selectedPt {
            context.fill(circle(selectedPt, 5.6), with: .color(NLColor.gamerPurple))
            context.stroke(circle(selectedPt, 5.6), with: .color(NLColor.deep), lineWidth: 2)
        }
        if let userPt {
            context.fill(circle(userPt, 5), with: .color(NLColor.textPrimary))
            context.stroke(circle(userPt, 5), with: .color(NLColor.deep), lineWidth: 2)
        }

        // 5) Rótulos: sempre inteiros dentro do mapa e sem se sobrepor
        var placed: [CGRect] = []
        if let userPt {
            let youText = s.userCity.map { "\(userLabel) · \($0)" } ?? userLabel
            let text = Text(youText).font(.system(size: 12, weight: .semibold)).foregroundColor(NLColor.textPrimary)
            placed.append(drawLabel(text, anchor: userPt, above: true, others: placed, width: w, height: h, context: &context))
        }
        let labelId = s.selectedId ?? s.leaderId
        let labelPt = selectedPt ?? s.leaderId.flatMap { id in
            RouteMapProjection.regionPoint(id: id).map { RouteMapProjection.project(lat: $0.lat, lon: $0.lon, camera: cam, width: w, height: h) }
        }
        if let labelId, let labelPt {
            let ms = s.selectedId != nil ? s.selectedMs : s.regions[labelId]?.ms
            var text = Text(regionName(labelId)).font(.system(size: 12, weight: .semibold)).foregroundColor(NLColor.textPrimary)
            if let ms {
                text = text + Text(" · \(Int(ms.rounded())) ms")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(NLColor.gamerPurpleLight)
            }
            placed.append(drawLabel(text, anchor: labelPt, above: false, others: placed, width: w, height: h, context: &context))
        }

        // 6) Sem localização: nota discreta
        if s.locationUnavailable && s.animate {
            let note = context.resolve(Text(unavailableLabel).font(.system(size: 11)).foregroundColor(NLColor.textTertiary))
            context.draw(note, at: CGPoint(x: 14, y: h - 12), anchor: .bottomLeading)
        }
    }

    private func circle(_ center: CGPoint, _ radius: Double) -> Path {
        Path(ellipseIn: CGRect(x: Double(center.x) - radius, y: Double(center.y) - radius, width: radius * 2, height: radius * 2))
    }

    private func arcPath(_ arc: MapArc) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: arc.x0, y: arc.y0))
        path.addQuadCurve(to: CGPoint(x: arc.x1, y: arc.y1), control: CGPoint(x: arc.cx, y: arc.cy))
        return path
    }

    private func drawLabel(
        _ text: Text,
        anchor: CGPoint,
        above: Bool,
        others: [CGRect],
        width: Double,
        height: Double,
        context: inout GraphicsContext
    ) -> CGRect {
        let resolved = context.resolve(text)
        let textSize = resolved.measure(in: CGSize(width: width, height: height))
        let padX = 8.0
        let boxW = Double(textSize.width) + padX * 2
        let boxH = 24.0
        var box = CGRect(x: 0, y: 0, width: boxW, height: boxH)

        func place(_ isAbove: Bool) {
            box.origin.x = min(max(Double(anchor.x) - boxW / 2, 4), max(width - boxW - 4, 4))
            let y = isAbove ? Double(anchor.y) - 12 - boxH : Double(anchor.y) + 12
            box.origin.y = min(max(y, 4), max(height - boxH - 4, 4))
        }
        place(above)
        if others.contains(where: { RouteMapProjection.overlaps(box, $0) }) { place(!above) }
        if let other = others.first(where: { RouteMapProjection.overlaps(box, $0) }) {
            // Ainda sobrepõe: empurra para o lado, sem sair do mapa.
            box.origin.x = Double(other.maxX) + 6 + boxW <= width - 4 ? Double(other.maxX) + 6 : max(Double(other.minX) - boxW - 6, 4)
        }

        let pill = Path(roundedRect: box.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 6)
        context.fill(pill, with: .color(Self.labelFill))
        context.stroke(pill, with: .color(Self.labelStroke), lineWidth: 1)
        context.draw(resolved, at: CGPoint(x: box.minX + padX, y: box.midY + 0.5), anchor: .leading)
        return box
    }
}
