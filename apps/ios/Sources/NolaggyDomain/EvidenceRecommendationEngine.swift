import Foundation

/// Arquitetura de rede do jogo para contextualização de topologia NAT (Decisão 55).
public enum GameServerArchitecture: String, Codable, CaseIterable, Hashable, Sendable {
    case dedicatedServer
    case peerToPeer
    case hybrid
}

/// Recomendação acionável e fundamentada por evidência diagnóstica real (Decisão 55).
public struct ActionableRecommendation: Codable, Equatable, Hashable, Sendable {
    public let priority: Int
    public let title: String
    public let instruction: String
    public let evidenceBadge: String

    public init(priority: Int, title: String, instruction: String, evidenceBadge: String) {
        self.priority = priority
        self.title = title
        self.instruction = instruction
        self.evidenceBadge = evidenceBadge
    }
}

/// Evidência agregada observada para alimentar o motor de recomendações (Decisão 55).
public struct DiagnosticEvidence: Equatable, Sendable {
    public let gatewayOutcome: GatewayProbeOutcome
    public let wifiBand: WiFiBandDiagnostic?
    public let wifiBandConfidence: WiFiBandAssessmentConfidence?
    public let loadTier: LoadDegradationTier?
    public let packetLossPercentage: Double
    public let spikePattern: SpikePattern?
    public let tailRatio: Double?
    public let natType: NATType?
    public let serverArchitecture: GameServerArchitecture
    public let outOfOrderCount: Int

    public init(
        gatewayOutcome: GatewayProbeOutcome = .unobservable,
        wifiBand: WiFiBandDiagnostic? = nil,
        wifiBandConfidence: WiFiBandAssessmentConfidence? = nil,
        loadTier: LoadDegradationTier? = nil,
        packetLossPercentage: Double = 0.0,
        spikePattern: SpikePattern? = nil,
        tailRatio: Double? = nil,
        natType: NATType? = nil,
        serverArchitecture: GameServerArchitecture = .dedicatedServer,
        outOfOrderCount: Int = 0
    ) {
        self.gatewayOutcome = gatewayOutcome
        self.wifiBand = wifiBand
        self.wifiBandConfidence = wifiBandConfidence
        self.loadTier = loadTier
        self.packetLossPercentage = packetLossPercentage
        self.spikePattern = spikePattern
        self.tailRatio = tailRatio
        self.natType = natType
        self.serverArchitecture = serverArchitecture
        self.outOfOrderCount = outOfOrderCount
    }
}

/// Motor determinístico que gera de 1 a 3 recomendações diretamente ligadas às evidências comprovadas.
public enum EvidenceRecommendationEngine {
    public static func generateRecommendations(evidence: DiagnosticEvidence) -> [ActionableRecommendation] {
        var recommendations: [ActionableRecommendation] = []

        // 1. Enlace local degradado
        if evidence.gatewayOutcome.isDegraded {
            recommendations.append(ActionableRecommendation(
                priority: 1,
                title: "Aproxime-se do Roteador",
                instruction: "Reduza a distância física ou obstáculos para eliminar a oscilação do sinal local.",
                evidenceBadge: "Wi-Fi Local"
            ))
        }

        // 2. Frequência 2.4 GHz confirmada ou fortemente suspeita
        if let band = evidence.wifiBand, band.isSuspectOrConfirmed24GHz,
           (evidence.wifiBandConfidence == .high || evidence.wifiBandConfidence == .medium) {
            recommendations.append(ActionableRecommendation(
                priority: 1,
                title: "Troque para Wi-Fi 5 GHz",
                instruction: "Conecte-se na frequência 5 GHz para escapar da interferência de canais vizinhos.",
                evidenceBadge: "2.4 GHz Detectado"
            ))
        }

        // 3. Perda de pacotes na rota externa (WAN)
        if evidence.packetLossPercentage > 1.0 && !evidence.gatewayOutcome.isDegraded {
            recommendations.append(ActionableRecommendation(
                priority: 1,
                title: "Evite Partidas Ranqueadas",
                instruction: "A rota externa da operadora apresenta perda de pacotes e causará travamentos.",
                evidenceBadge: "Rota Externa"
            ))
        }

        // 4. Degradação sob carga (Bufferbloat)
        if evidence.loadTier == .material || evidence.loadTier == .severe {
            recommendations.append(ActionableRecommendation(
                priority: 2,
                title: "Pause Downloads e Streaming",
                instruction: "Limite o uso simultâneo da internet para impedir picos de latência na partida.",
                evidenceBadge: "Saturação sob Carga"
            ))
        }

        // 5. Spikes recorrentes com enlace local limpo
        if let pattern = evidence.spikePattern, pattern.isRecurring, evidence.gatewayOutcome.isStable {
            recommendations.append(ActionableRecommendation(
                priority: 2,
                title: "Verifique Interferências Locais",
                instruction: "Afaste dispositivos sem fio e fontes de interferência eletromagnética do roteador.",
                evidenceBadge: "Picos Recorrentes"
            ))
        }

        // 6. NAT Restrito em jogos P2P / híbridos
        if evidence.natType == .type3Strict && (evidence.serverArchitecture == .peerToPeer || evidence.serverArchitecture == .hybrid) {
            recommendations.append(ActionableRecommendation(
                priority: 2,
                title: "Habilite UPnP no Roteador",
                instruction: "Libere as portas automáticas no roteador para normalizar a conexão em partidas multiplayer.",
                evidenceBadge: "NAT Restrito"
            ))
        }

        // 7. Pacotes fora de ordem na rota externa
        if evidence.outOfOrderCount >= 2 && !evidence.gatewayOutcome.isDegraded {
            recommendations.append(ActionableRecommendation(
                priority: 2,
                title: "Instabilidade de Rota na Operadora",
                instruction: "Contate seu provedor para verificar o roteamento caso os micro-travamentos persistam.",
                evidenceBadge: "Rota Desordenada"
            ))
        }

        // Ordena por prioridade (menor número = maior prioridade) e limita a no máximo 3 cards
        return Array(recommendations.sorted(by: { $0.priority < $1.priority }).prefix(3))
    }
}
