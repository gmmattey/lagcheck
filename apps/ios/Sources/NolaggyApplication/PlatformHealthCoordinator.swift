import Foundation
import NolaggyDomain

/// Coordenador da camada de aplicação para orquestrar diagnósticos de plataformas.
public final class PlatformHealthCoordinator: Sendable {
    private let provider: PlatformHealthProvider

    public init(provider: PlatformHealthProvider) {
        self.provider = provider
    }

    /// Obtém o status de saúde da plataforma especificada (ex: PlayStation, Xbox).
    /// Plataformas móveis ou locais sempre retornam operacional.
    public func healthStatus(for platform: Platform, market: String) async -> PlatformHealth {
        guard platform == .playstation || platform == .xbox || platform == .nintendo else {
            return PlatformHealth.operational(for: platform, serviceName: "Dispositivo Local")
        }
        return await provider.checkHealth(for: platform, market: market)
    }
}
