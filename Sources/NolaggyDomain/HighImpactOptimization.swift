import Foundation
import SwiftUI

/// Representa a oportunidade de otimização única de maior impacto para o jogador.
public struct HighImpactOptimization: Equatable, Sendable {
    public let title: String
    public let impactBadge: String
    public let systemImage: String
    public let instruction: String
    public let isCritical: Bool

    public init(
        title: String,
        impactBadge: String,
        systemImage: String,
        instruction: String,
        isCritical: Bool
    ) {
        self.title = title
        self.impactBadge = impactBadge
        self.systemImage = systemImage
        self.instruction = instruction
        self.isCritical = isCritical
    }
}

/// Avaliador hierárquico que extrai a oportunidade de otimização de MAIOR IMPACTO para o resultado.
public enum HighImpactOptimizationEvaluator {

    public static func evaluateSingleTopOptimization(
        targetPlatform: Platform,
        evaluation: GameReadinessEvaluation,
        isWiFi: Bool
    ) -> HighImpactOptimization {
        let isConsoleOrPC = (targetPlatform != .iphone)

        // 1. Prioridade Máxima: Wi-Fi em Console/PC ou Frequência 2.4 GHz detectada
        if isConsoleOrPC && isWiFi {
            return HighImpactOptimization(
                title: "Conectar via Cabo Ethernet (Cat6)",
                impactBadge: "Maior Impacto",
                systemImage: "cable.connector",
                instruction: "Ligue o cabo de rede direto no roteador para eliminar o jitter e oscilações locais em \(targetPlatform.displayName).",
                isCritical: true
            )
        }

        if evaluation.findings.contains(where: { $0.kind == .localGateway || $0.labelKey.contains("wifi") }) {
            return HighImpactOptimization(
                title: "Migrar para Wi-Fi 5 GHz",
                impactBadge: "Maior Impacto",
                systemImage: "wifi.exclamationmark",
                instruction: "Conecte-se na frequência 5 GHz do roteador ou aproxime-se para estabilizar o sinal de entrada.",
                isCritical: true
            )
        }

        // 2. Degradação sob Carga (Bufferbloat)
        if evaluation.findings.contains(where: { $0.kind == .loadDegradation }) {
            return HighImpactOptimization(
                title: "Ativar SQM / Pausar Downloads",
                impactBadge: "Bufferbloat Detectado",
                systemImage: "arrow.triangle.2.circlepath",
                instruction: "Ative QoS SQM (CAKE ou FQ-CoDel) no roteador ou pause downloads pesados na sua rede durante a partida.",
                isCritical: true
            )
        }

        // 3. Perda de Pacotes na Rota WAN
        if evaluation.findings.contains(where: { $0.kind == .packetLoss }) {
            return HighImpactOptimization(
                title: "Verificar Rota com a Operadora",
                impactBadge: "Perda na Rota",
                systemImage: "phone.badge.waveform.fill",
                instruction: "Exporte o relatório em PDF e solicite à sua operadora uma verificação de atenuação e estabilidade da linha.",
                isCritical: true
            )
        }

        // 4. NAT Restrito / CGNAT
        if evaluation.findings.contains(where: { $0.kind == .natTopology }) {
            return HighImpactOptimization(
                title: "Habilitar UPnP / IP Público",
                impactBadge: "NAT Restrito",
                systemImage: "lock.shield",
                instruction: "Ative UPnP no roteador ou solicite à operadora um IP público dinâmico para matchmaking sem bloqueios.",
                isCritical: false
            )
        }

        // 5. Spikes Recorrentes de Latência
        if evaluation.findings.contains(where: { $0.kind == .latencySpikes }) {
            return HighImpactOptimization(
                title: "Fechar Aplicações Concorrentes",
                impactBadge: "Oscilação",
                systemImage: "exclamationmark.triangle.fill",
                instruction: "Feche atualizações em segundo plano e sincronizações de nuvem que possam disputar a conexão.",
                isCritical: false
            )
        }

        // 6. Conexão Saudável (Ready)
        if evaluation.verdict == .ready {
            let desc = isConsoleOrPC
                ? "Conexão sólida com latência mínima. Usar cabo Ethernet garante estabilidade máxima contra oscilações externas."
                : "Rota de baixa latência e jitter controlado. Mantenha os downloads pausados na rede para assegurar precisão em partida."
            return HighImpactOptimization(
                title: "Setup de Alta Performance",
                impactBadge: "Recomendação Pró",
                systemImage: "checkmark.seal.fill",
                instruction: desc,
                isCritical: false
            )
        }

        // Fallback genérico para instabilidade
        return HighImpactOptimization(
            title: "Reiniciar Equipamento de Borda",
            impactBadge: "Recomendado",
            systemImage: "power",
            instruction: "Reinicie o modem e o roteador para limpar tabelas de estado e restabelecer uma rota limpa com a operadora.",
            isCritical: false
        )
    }
}
