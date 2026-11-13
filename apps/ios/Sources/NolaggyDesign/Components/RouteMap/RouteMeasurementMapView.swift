import SwiftUI

/// Mapa de medição plano (grade 1,5° Natural Earth 110m, arcos de rota e sondas reais),
/// espelhado de `pages/lagcheck/src/lib/map/route-map.ts`.
public struct RouteMeasurementMapView: View {
    public let userPoint: MapGeoPoint?
    public let userLabel: String
    public let regions: [MapRegionSample]
    public let selectedRegionId: String?
    public let probeFlights: [MapProbeFlight]
    public let animate: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        userPoint: MapGeoPoint? = nil,
        userLabel: String = "Você",
        regions: [MapRegionSample] = [],
        selectedRegionId: String? = nil,
        probeFlights: [MapProbeFlight] = [],
        animate: Bool = true
    ) {
        self.userPoint = userPoint
        self.userLabel = userLabel
        self.regions = regions
        self.selectedRegionId = selectedRegionId
        self.probeFlights = probeFlights
        self.animate = animate
    }

    public var body: some View {
        TimelineView(.animation(paused: !animate || reduceMotion || probeFlights.isEmpty)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                drawMap(context: &context, size: size, now: now)
            }
        }
        .background(NLColor.deep)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(NLColor.borderHairline, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        if let selectedId = selectedRegionId,
           let region = regions.first(where: { $0.id == selectedId }) {
            if let ms = region.latencyMs {
                return "Mapa de rota: \(userLabel) até \(region.label), \(Int(ms.rounded())) milissegundos"
            }
            return "Mapa de rota: \(userLabel) até \(region.label)"
        }
        return "Mapa de medição com \(regions.count) regiões"
    }

    private func activeCamera(size: CGSize) -> MapCamera {
        var focusPoints: [MapGeoPoint] = []
        if let userPoint {
            focusPoints.append(userPoint)
        }
        if let selectedRegionId, let selectedCoord = RouteMapProjection.regionPoint(id: selectedRegionId) {
            focusPoints.append(selectedCoord)
            return RouteMapProjection.fitCamera(
                points: focusPoints,
                width: size.width,
                height: size.height,
                maxZoom: RouteMapProjection.routeMaxZoom
            )
        }
        if regions.isEmpty {
            return .world
        }
        let allPoints = focusPoints + regions.compactMap { RouteMapProjection.regionPoint(id: $0.id) }
        return RouteMapProjection.fitCamera(
            points: allPoints,
            width: size.width,
            height: size.height,
            maxZoom: RouteMapProjection.routeMaxZoom
        )
    }

    private func drawMap(context: inout GraphicsContext, size: CGSize, now: TimeInterval) {
        let width = Double(size.width)
        let height = Double(size.height)
        guard width > 0, height > 0 else { return }

        let camera = activeCamera(size: size)
        let dotRadius: CGFloat = camera.zoom > 2.0 ? 1.35 : 1.05
        let landColor = NLColor.textSecondary.opacity(0.34)

        // 1. Grade de pontos de terra (Natural Earth 110m)
        for point in RouteMapProjection.landPoints {
            let p = RouteMapProjection.project(lat: point.lat, lon: point.lon, camera: camera, width: width, height: height)
            guard p.x >= -2, p.x <= size.width + 2, p.y >= -2, p.y <= size.height + 2 else { continue }
            let rect = CGRect(x: p.x - dotRadius, y: p.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(landColor))
        }

        // 2. Pontos das regiões candidatas
        for region in regions {
            guard region.id != selectedRegionId,
                  let coord = RouteMapProjection.regionPoint(id: region.id) else { continue }
            let p = RouteMapProjection.project(lat: coord.lat, lon: coord.lon, camera: camera, width: width, height: height)
            let r: CGFloat = region.answered ? 3.0 : 2.2
            let color = region.answered ? NLColor.textSecondary : NLColor.textTertiary
            context.fill(
                Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                with: .color(color)
            )
        }

        // 3. Arcos de rota e sondas em voo (apenas a partir de medições reais)
        var userScreen: CGPoint?
        if let userPoint {
            userScreen = RouteMapProjection.project(lat: userPoint.lat, lon: userPoint.lon, camera: camera, width: width, height: height)
        }

        if let origin = userScreen {
            if let selectedRegionId,
               let targetCoord = RouteMapProjection.regionPoint(id: selectedRegionId) {
                let target = RouteMapProjection.project(lat: targetCoord.lat, lon: targetCoord.lon, camera: camera, width: width, height: height)
                let arc = RouteMapProjection.computeArc(from: origin, to: target)
                var path = Path()
                path.move(to: CGPoint(x: arc.x0, y: arc.y0))
                path.addQuadCurve(to: CGPoint(x: arc.x1, y: arc.y1), control: CGPoint(x: arc.cx, y: arc.cy))
                context.stroke(path, with: .color(NLColor.gamerPurple), lineWidth: 1.6)
            }

            if animate, !reduceMotion {
                for flight in probeFlights {
                    let elapsed = now - flight.startedAt
                    guard elapsed >= 0, elapsed <= flight.durationSeconds,
                          let targetCoord = RouteMapProjection.regionPoint(id: flight.regionId) else { continue }
                    let target = RouteMapProjection.project(lat: targetCoord.lat, lon: targetCoord.lon, camera: camera, width: width, height: height)
                    let arc = RouteMapProjection.computeArc(from: origin, to: target)

                    if flight.isSweep, flight.regionId != selectedRegionId {
                        var sweepPath = Path()
                        sweepPath.move(to: CGPoint(x: arc.x0, y: arc.y0))
                        sweepPath.addQuadCurve(to: CGPoint(x: arc.x1, y: arc.y1), control: CGPoint(x: arc.cx, y: arc.cy))
                        context.stroke(sweepPath, with: .color(NLColor.gamerPurple.opacity(0.22)), lineWidth: 1.0)
                    }

                    let progress = RouteMapProjection.ease(elapsed / max(flight.durationSeconds, 0.001))
                    let t = flight.isInbound ? (1.0 - progress) : progress
                    let pos = RouteMapProjection.bezierPoint(arc: arc, t: t)
                    let packetColor = flight.isInbound ? NLColor.textPrimary : NLColor.gamerPurple
                    let packetRadius: CGFloat = flight.isInbound ? 3.2 : 2.6
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: pos.x - packetRadius,
                            y: pos.y - packetRadius,
                            width: packetRadius * 2,
                            height: packetRadius * 2
                        )),
                        with: .color(packetColor)
                    )
                }
            }
        }

        // 4. Pinos principais e rótulos sem sobreposição
        var placedLabels: [CGRect] = []

        if let selectedRegionId,
           let targetCoord = RouteMapProjection.regionPoint(id: selectedRegionId) {
            let target = RouteMapProjection.project(lat: targetCoord.lat, lon: targetCoord.lon, camera: camera, width: width, height: height)
            let pinRect = CGRect(x: target.x - 4.5, y: target.y - 4.5, width: 9, height: 9)
            context.fill(Path(ellipseIn: pinRect), with: .color(NLColor.gamerPurple))
            context.stroke(Path(ellipseIn: pinRect), with: .color(NLColor.textPrimary), lineWidth: 1.2)

            if let region = regions.first(where: { $0.id == selectedRegionId }) {
                let text = region.latencyMs.map { "\(region.label) \(Int($0.rounded())) ms" } ?? region.label
                drawLabel(text, near: target, canvasSize: size, placed: &placedLabels, accent: true, context: &context)
            }
        }

        if let origin = userScreen {
            let pinRect = CGRect(x: origin.x - 4, y: origin.y - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: pinRect), with: .color(NLColor.textPrimary))
            drawLabel(userLabel, near: origin, canvasSize: size, placed: &placedLabels, accent: false, context: &context)
        }
    }

    private func drawLabel(
        _ text: String,
        near point: CGPoint,
        canvasSize: CGSize,
        placed: inout [CGRect],
        accent: Bool,
        context: inout GraphicsContext
    ) {
        let resolved = context.resolve(
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: accent ? .monospaced : .default))
                .foregroundColor(accent ? NLColor.gamerPurpleLight : NLColor.textPrimary)
        )
        let textSize = resolved.measure(in: canvasSize)
        let padX: CGFloat = 6
        let padY: CGFloat = 3
        let boxSize = CGSize(width: textSize.width + padX * 2, height: textSize.height + padY * 2)

        let candidates: [CGPoint] = [
            CGPoint(x: point.x - boxSize.width / 2, y: point.y - boxSize.height - 8),
            CGPoint(x: point.x - boxSize.width / 2, y: point.y + 8),
            CGPoint(x: point.x + 8, y: point.y - boxSize.height / 2),
            CGPoint(x: point.x - boxSize.width - 8, y: point.y - boxSize.height / 2)
        ]

        let chosen = candidates.first { origin in
            let rect = CGRect(origin: origin, size: boxSize)
            let inside = rect.minX >= 6 && rect.maxX <= canvasSize.width - 6 &&
                rect.minY >= 6 && rect.maxY <= canvasSize.height - 6
            return inside && !placed.contains(where: { RouteMapProjection.overlaps($0, rect) })
        }

        guard let origin = chosen else { return }
        let boxRect = CGRect(origin: origin, size: boxSize)
        placed.append(boxRect)

        let pill = Path(roundedRect: boxRect, cornerRadius: 6)
        context.fill(pill, with: .color(NLColor.deep.opacity(0.86)))
        context.stroke(pill, with: .color(NLColor.borderHairline), lineWidth: 1)
        context.draw(resolved, at: CGPoint(x: boxRect.midX, y: boxRect.midY), anchor: .center)
    }
}
