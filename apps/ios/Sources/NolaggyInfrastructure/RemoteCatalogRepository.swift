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

/// Fonte de verdade local do catálogo. O arquivo acompanha cada build e é
/// sempre validado (tamanho, schema e regras de negócio) antes de a UI conhecer
/// jogos, regiões ou rotas. Não há atualização HTTP, cache persistente,
/// assinatura nem validade (Decisão 106): uma versão antiga do Worker jamais
/// pode reduzir a cobertura global do app para São Paulo.
public struct BundledCatalogRepository: Sendable {
    private let catalogData: Data

    public init(envelopeData: Data) {
        self.catalogData = envelopeData
    }

    public func load() throws -> RemoteCatalogPayload {
        try RemoteCatalogVerifier.decodeBundled(catalogData)
    }
}
