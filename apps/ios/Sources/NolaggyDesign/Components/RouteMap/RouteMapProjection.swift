import CoreGraphics
import Foundation

/// Ponto geográfico (latitude/longitude em graus decimais).
public struct MapGeoPoint: Equatable, Sendable {
    public let lat: Double
    public let lon: Double

    public init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }
}

/// Câmera equiretangular do mapa de medição.
public struct MapCamera: Equatable, Sendable {
    public let lon: Double
    public let lat: Double
    public let zoom: Double

    public static let world = MapCamera(lon: 0, lat: 12, zoom: 1)

    public init(lon: Double, lat: Double, zoom: Double) {
        self.lon = lon
        self.lat = lat
        self.zoom = zoom
    }
}

/// Arco quadrático de Bézier entre origem e destino na tela.
public struct MapArc: Equatable, Sendable {
    public let x0: Double
    public let y0: Double
    public let x1: Double
    public let y1: Double
    public let cx: Double
    public let cy: Double
}

/// Ponto de terra parseado da grade 1,5° Natural Earth 110m.
public struct MapLandPoint: Equatable, Sendable {
    public let lat: Double
    public let lon: Double
}

/// Regras determinísticas de projeção, câmera, arcos e movimento espelhadas de `pages/lagcheck/src/lib/map/`.
public enum RouteMapProjection {
    public static let routeMaxZoom: Double = 3.4
    public static let minZoom: Double = 1.0
    public static let maxZoom: Double = 7.0
    private static let minLonSpan: Double = 8.0
    private static let minLatSpan: Double = 5.0

    public static let regionCoordinates: [String: MapGeoPoint] = [
        "sa-east-1": MapGeoPoint(lat: -23.55, lon: -46.63),
        "us-east-1": MapGeoPoint(lat: 38.95, lon: -77.45),
        "us-east-2": MapGeoPoint(lat: 39.96, lon: -83.00),
        "us-west-1": MapGeoPoint(lat: 37.34, lon: -121.89),
        "us-west-2": MapGeoPoint(lat: 45.52, lon: -122.68),
        "ca-central-1": MapGeoPoint(lat: 45.42, lon: -75.70),
        "eu-central-1": MapGeoPoint(lat: 50.11, lon: 8.68),
        "eu-west-1": MapGeoPoint(lat: 53.35, lon: -6.26),
        "eu-west-2": MapGeoPoint(lat: 51.51, lon: -0.13),
        "eu-west-3": MapGeoPoint(lat: 48.86, lon: 2.35),
        "eu-north-1": MapGeoPoint(lat: 59.33, lon: 18.07),
        "eu-south-1": MapGeoPoint(lat: 45.46, lon: 9.19),
        "ap-northeast-1": MapGeoPoint(lat: 35.68, lon: 139.69),
        "ap-northeast-2": MapGeoPoint(lat: 37.57, lon: 126.98),
        "ap-northeast-3": MapGeoPoint(lat: 34.69, lon: 135.50),
        "ap-southeast-1": MapGeoPoint(lat: 1.35, lon: 103.82),
        "ap-southeast-2": MapGeoPoint(lat: -33.87, lon: 151.21),
        "ap-south-1": MapGeoPoint(lat: 19.08, lon: 72.88),
        "ap-east-1": MapGeoPoint(lat: 22.32, lon: 114.17),
        "me-south-1": MapGeoPoint(lat: 26.22, lon: 50.59),
        "af-south-1": MapGeoPoint(lat: -33.92, lon: 18.42)
    ]

    public static let landPoints: [MapLandPoint] = {
        var points: [MapLandPoint] = []
        points.reserveCapacity(5200)
        for (rowIndex, line) in RouteMapGridData.rows.enumerated() {
            let lat = RouteMapGridData.latTop - (Double(rowIndex) + 0.5) * RouteMapGridData.step
            for (colIndex, char) in line.utf8.enumerated() where char == 49 {
                let lon = -180.0 + (Double(colIndex) + 0.5) * RouteMapGridData.step
                points.append(MapLandPoint(lat: lat, lon: lon))
            }
        }
        return points
    }()

    public static func regionPoint(id: String) -> MapGeoPoint? {
        regionCoordinates[id]
    }

    /// Zoom 1 mostra 360° de longitude na largura do mapa.
    public static func project(
        lat: Double,
        lon: Double,
        camera: MapCamera,
        width: Double,
        height: Double
    ) -> CGPoint {
        let k = (width / 360.0) * camera.zoom
        return CGPoint(
            x: width / 2.0 + (lon - camera.lon) * k,
            y: height / 2.0 - (lat - camera.lat) * k
        )
    }

    public static func fitCamera(
        points: [MapGeoPoint],
        width: Double,
        height: Double,
        padX: Double = 56,
        padY: Double = 40,
        maxZoom: Double = maxZoom
    ) -> MapCamera {
        guard !points.isEmpty, width > 0, height > 0 else { return .world }
        let lons = points.map(\.lon)
        let lats = points.map(\.lat)
        guard let minLon = lons.min(), let maxLon = lons.max(),
              let minLat = lats.min(), let maxLat = lats.max() else {
            return .world
        }
        let lonSpan = max(maxLon - minLon, minLonSpan)
        let latSpan = max(maxLat - minLat, minLatSpan)
        let availX = max(width - padX * 2.0, 20.0)
        let availY = max(height - padY * 2.0, 20.0)
        let zoomByLon = (availX * 360.0) / (width * lonSpan)
        // Como no site: k = zoom * largura / 360 vale para os dois eixos.
        let zoomByLat = (availY * 360.0) / (width * latSpan)
        let zoom = min(maxZoom, max(minZoom, min(zoomByLon, zoomByLat)))
        return MapCamera(
            lon: (maxLon + minLon) / 2.0,
            lat: (maxLat + minLat) / 2.0,
            zoom: zoom
        )
    }

    /// Arco quadrático entre dois pontos de tela, abaulado para cima.
    public static func computeArc(from p0: CGPoint, to p1: CGPoint, maxHeight: Double = 170) -> MapArc {
        let dx = Double(p1.x - p0.x)
        let dy = Double(p1.y - p0.y)
        let d = max(hypot(dx, dy), 1.0)
        let h = min(max(d * 0.3, 24.0), maxHeight)
        var nx = -dy / d
        var ny = dx / d
        if ny > 0 {
            nx = -nx
            ny = -ny
        }
        return MapArc(
            x0: Double(p0.x),
            y0: Double(p0.y),
            x1: Double(p1.x),
            y1: Double(p1.y),
            cx: (Double(p0.x) + Double(p1.x)) / 2.0 + nx * h,
            cy: (Double(p0.y) + Double(p1.y)) / 2.0 + ny * h
        )
    }

    public static func bezierPoint(arc: MapArc, t: Double) -> CGPoint {
        let c = min(max(t, 0.0), 1.0)
        let u = 1.0 - c
        return CGPoint(
            x: u * u * arc.x0 + 2.0 * u * c * arc.cx + c * c * arc.x1,
            y: u * u * arc.y0 + 2.0 * u * c * arc.cy + c * c * arc.y1
        )
    }

    /// Easing cúbico simétrico.
    public static func ease(_ t: Double) -> Double {
        let c = min(max(t, 0.0), 1.0)
        return c < 0.5 ? 4.0 * c * c * c : 1.0 - pow(-2.0 * c + 2.0, 3.0) / 2.0
    }

    /// Duração do voo de volta de uma sonda: proporcional ao RTT, entre 300 e 700 ms.
    public static func returnFlightSeconds(rttMs: Double) -> TimeInterval {
        min(max(rttMs * 8.0, 300.0), 700.0) / 1000.0
    }

    public static func overlaps(_ a: CGRect, _ b: CGRect, margin: CGFloat = 4) -> Bool {
        a.minX < b.maxX + margin &&
            a.maxX + margin > b.minX &&
            a.minY < b.maxY + margin &&
            a.maxY + margin > b.minY
    }
}
