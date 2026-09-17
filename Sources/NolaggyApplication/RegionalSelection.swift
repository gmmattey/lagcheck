import Foundation
import NolaggyDomain

/// Snapshot imutável aberto antes da pré-leitura. A UI recebe somente estes
/// candidatos já validados; ela não conhece host, porta ou JSON remoto.
public struct RegionalSelectionViewSnapshot: Equatable, Sendable {
    public let catalogVersion: String
    public let ruleVersion: String
    public let candidates: [Candidate]

    public struct Candidate: Equatable, Sendable, Identifiable {
        public let regionID: String
        public let label: String
        public let priority: Int
        public let resolvedContext: ResolvedMeasurementContext

        public var id: String { regionID }

        public init(regionID: String, label: String, priority: Int, resolvedContext: ResolvedMeasurementContext) {
            self.regionID = regionID
            self.label = label
            self.priority = priority
            self.resolvedContext = resolvedContext
        }
    }

    public init(catalogVersion: String, ruleVersion: String = "regional-selection-1", candidates: [Candidate]) {
        self.catalogVersion = catalogVersion
        self.ruleVersion = ruleVersion
        self.candidates = candidates
    }
}

/// A seleção regional é sempre automática (ou aplica a preferência manual
/// salva em Configurações como override silencioso). Não há mais estado de
/// tela pedindo confirmação de uma sugestão: só o carregamento breve da
/// pré-leitura e a falha quando nenhum candidato é viável.
public enum RegionalSelectionPresentation: Equatable, Sendable {
    case confirming
    case noViableCandidate
}
