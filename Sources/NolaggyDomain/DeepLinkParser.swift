import Foundation

/// Tipos de ação mapeados a partir de Deep Links e Universal Links (Decisão 76).
public enum AppDeepLink: Equatable, Sendable {
    case quickCheck(gameID: String?, platform: Platform?)
    case networkCockpit
    case gamesCatalog
    case home
}

/// Parser puro e determinístico de URLs externas para navegação e automação (Decisão 76).
public enum DeepLinkParser {
    
    /// Analisa qualquer URL (esquema personalizado `lagcheck://` ou universal `https://lagcheck.app/...`).
    public static func parse(url: URL) -> AppDeepLink? {
        let scheme = url.scheme?.lowercased()
        guard scheme == "lagcheck" || scheme == "https" else {
            return nil
        }
        
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()
        
        // Verifica se é um Universal Link (ex: https://lagcheck.app/...)
        if scheme == "https" {
            guard host == "lagcheck.app" || host == "www.lagcheck.app" || host == "check.lagcheck.app" else {
                return nil
            }
        }
        
        // Extrai query parameters
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        
        let gameParam = queryItems.first(where: { $0.name.lowercased() == "game" || $0.name.lowercased() == "gameid" })?.value
        let platformParam = queryItems.first(where: { $0.name.lowercased() == "platform" })?.value
        let parsedPlatform: Platform? = platformParam.flatMap { Platform(rawValue: $0.lowercased()) }
        
        // 1. Rota de Medição / Check
        if host == "quicktest" || host == "test" || host == "check" ||
            path == "/quicktest" || path == "/test" || path == "/check" {
            return .quickCheck(gameID: gameParam, platform: parsedPlatform)
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
