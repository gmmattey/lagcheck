import Foundation
import NolaggyDomain

public enum DebugCatalogBase {
    /// O recurso pertence ao framework de infraestrutura, não ao bundle da UI.
    /// A composição só recebe bytes do envelope; validação continua no domínio.
    public static func envelopeData() -> Data? {
        Bundle(for: InfrastructureBundleMarker.self).url(forResource: "DebugCatalogBase", withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) }
    }
}

private final class InfrastructureBundleMarker {}

/// Fonte de verdade local do catálogo. O envelope assinado acompanha cada
/// build e é sempre validado antes de a UI conhecer jogos, regiões ou rotas.
/// Não há atualização HTTP nem cache persistente: uma versão antiga do Worker
/// jamais pode reduzir a cobertura global do app para São Paulo.
public struct BundledCatalogRepository: Sendable {
    private let envelopeData: Data
    private let now: @Sendable () -> Date

    public init(
        envelopeData: Data,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.envelopeData = envelopeData
        self.now = now
    }

    public func load() throws -> RemoteCatalogPayload {
        try RemoteCatalogVerifier.verifyAndDecode(envelopeData: envelopeData, now: now())
    }
}
