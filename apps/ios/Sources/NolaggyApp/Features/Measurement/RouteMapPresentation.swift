import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain
import NolaggyInfrastructure

/// Ligação entre o app e o mapa de medição (mesmo comportamento do site).
/// "Você" vem da localização aproximada pelo IP (endpoint do site, ~50 km),
/// como no site; se ela falhar, do país configurado no aparelho. A região, a
/// varredura e as sondas vêm só da medição.
@MainActor
enum RouteMapPresentation {
    /// Reserva quando a consulta por IP falha: ponto do país do aparelho, sem cidade.
    static var countryPoint: MapGeoPoint? {
        RouteMapOrigin.approximatePoint(countryCode: Locale.current.region?.identifier)
    }

    /// Resolve "Você": usa o resultado em memória na hora; senão deixa a
    /// varredura esperando (como o site) e consulta o IP em paralelo ao check.
    static func resolveUser(_ controller: RouteMapController) {
        Task { @MainActor in
            if let cached = await ApproxLocationClient.shared.cachedLocation() {
                controller.setUser(MapGeoPoint(lat: cached.lat, lon: cached.lon), city: cached.city)
                return
            }
            controller.clearUser()
            let location = await ApproxLocationClient.shared.location()
            if let location {
                controller.setUser(MapGeoPoint(lat: location.lat, lon: location.lon), city: location.city)
            } else {
                controller.setUser(countryPoint)
            }
        }
    }

    static func canDraw(regionID: String?) -> Bool {
        guard let regionID else { return false }
        return RouteMapProjection.regionPoint(id: regionID) != nil
    }

    static func regionName(_ id: String) -> String {
        let ident = AppLocalization.locale.identifier.lowercased()
        let lang = ident.hasPrefix("pt") ? "pt-BR" : (ident.hasPrefix("es") ? "es" : "en")
        return GlobalProbeRegistry.friendlyLabel(for: id, languageCode: lang)
    }

    /// Começo de um check: visão de todos os servidores, com "Você".
    static func beginSession(_ controller: RouteMapController) {
        controller.reset()
        resolveUser(controller)
    }

    /// Garante "Você" num mapa que não passou pela varredura.
    static func ensureUser(_ controller: RouteMapController) {
        if controller.user == nil && !controller.locationUnavailable {
            resolveUser(controller)
        }
    }

    /// Eventos reais da pré-leitura regional → varredura do mapa.
    static func preReadEventHandler(for controller: RouteMapController) -> RegionalPreReadEventHandler {
        { regionID, event in
            Task { @MainActor in
                switch event {
                case .sent: controller.regionSent(regionID)
                case let .answered(rtt): controller.regionSample(regionID, ms: rtt)
                case .unanswered: controller.regionSample(regionID, ms: nil)
                }
            }
        }
    }

    static func mapView(_ controller: RouteMapController) -> RouteMeasurementMapView {
        RouteMeasurementMapView(
            controller: controller,
            userLabel: AppLocalization.string("route_map.you", comment: ""),
            unavailableLabel: AppLocalization.string("route_map.unavailable", comment: ""),
            accessibilityText: AppLocalization.string("route_map.a11y", comment: ""),
            regionName: { regionName($0) }
        )
    }

    /// Mediana das respostas válidas da fase de repouso (rótulo "Região · N ms").
    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count % 2 == 1 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2
    }
}
