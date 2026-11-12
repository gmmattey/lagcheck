import Foundation

/// Tipos de ação mapeados a partir de Deep Links e Universal Links (Decisão 76 e Decisão 112).
public enum AppDeepLink: Equatable, Sendable {
    case quickCheck(gameID: String?, platform: Platform?, declaredExternalLink: ExternalEquipmentLink?)
    case networkCockpit
    case gamesCatalog
    case home
    case hostDuel(payload: HostDuelPayload)
}

/// Parser puro e determinístico de URLs externas para navegação e automação (Decisão 76 e 112).
public enum DeepLinkParser {
    
    /// Analisa qualquer URL (esquema personalizado `lagcheck://` ou Universal Link canônico).
    public static func parse(url: URL) -> AppDeepLink? {
        // 0. Duelo de Host (Decisão 112: https://lagcheck.signallq.com/vs ou lagcheck://vs)
        if let duel = HostDuelPayload.parse(url: url) {
            return .hostDuel(payload: duel)
        }

        let scheme = url.scheme?.lowercased()
        guard scheme == "lagcheck" || scheme == "https" else {
            return nil
        }
        
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()
        
        // Universal Links são uma superfície pública estrita. O esquema
        // personalizado preserva as automações internas já existentes.
        if scheme == "https" {
            guard host == "lagcheck.signallq.com" else {
                return nil
            }
            guard path == "/check" || path == "/check/" || path == "/quicktest" || path == "/quicktest/" else {
                return nil
            }
        }
        
        // Extrai query parameters
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        
        let gameParam = queryItems.first(where: { $0.name.lowercased() == "game" || $0.name.lowercased() == "gameid" })?.value
        let platformParam = queryItems.first(where: { $0.name.lowercased() == "platform" })?.value
        let parsedPlatform: Platform? = platformParam.flatMap { Platform(rawValue: $0.lowercased()) }
        let externalLinkParam = queryItems.first(where: { $0.name.lowercased() == "external_link" })?.value
        let parsedExternalLink: ExternalEquipmentLink? = externalLinkParam.flatMap { ExternalEquipmentLink(rawValue: $0.lowercased()) }
        
        // 1. Rota de Medição / Check
        if host == "quicktest" || host == "test" || host == "check" ||
            path == "/quicktest" || path == "/test" || path == "/check" {
            return .quickCheck(gameID: gameParam, platform: parsedPlatform, declaredExternalLink: parsedExternalLink)
        }
        
        // 2. Rota de Catálogo de Jogos
        if host == "games" || host == "catalog" || path == "/games" || path == "/catalog" {
            return .gamesCatalog
        }
        
        // 3. Rota de Cockpit de Rede / Wi-Fi
        if host == "network" || host == "wifi" || host == "cockpit" ||
            path == "/network" || path == "/wifi" || path == "/cockpit" {
            return .networkCockpit
        }
        
        // 4. Rota Home
        if host == "home" || path == "/home" {
            return .home
        }
        
        if scheme == "https" && (path.isEmpty || path == "/") {
            return .home
        }
        
        return nil
    }
}
