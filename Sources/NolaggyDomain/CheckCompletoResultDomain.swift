import Foundation

/// Vereditos canônicos e curtos da tela de resultado do Check Completo (Decisão 35/36).
/// Sem termos proibidos como "Pronto para jogar" ou "Conexão perfeita".
public enum CheckCompletoVerdict: String, Codable, CaseIterable, Equatable, Sendable {
    /// Resultado saudável: sem perda, latência normal e carga estável.
    case held = "check_completo.verdict.held"
    /// Instabilidade geral observada em repouso (jitter elevado, picos severos ou latência alta).
    case oscillated = "check_completo.verdict.oscillated"
    /// A rota sofreu degradação material durante a fase sob carga controlada.
    case loadHeavy = "check_completo.verdict.load_heavy"
    /// Perda relevante de pacotes ou timeouts detectados.
    case deliveryFailed = "check_completo.verdict.delivery_failed"
    /// Respostas UDP insuficientes para uma medição confiável.
    case inconclusive = "check_completo.verdict.inconclusive"

    public var titleKey: String { rawValue }
}

/// Estado ótico dos nós na Trilha Consolidada HIG.
public enum ConsolidatedTrailNodeState: String, Codable, CaseIterable, Equatable, Sendable {
    case check = "check"
    case attention = "attention"
    case neutral = "neutral"

    public var isPositive: Bool {
        self == .check
    }
}

/// Snapshot imutável dos 5 nós da Trilha Consolidada.
public struct ConsolidatedTrailSnapshot: Codable, Equatable, Sendable {
    public let networkState: ConsolidatedTrailNodeState
    public let responseState: ConsolidatedTrailNodeState
    public let deliveryState: ConsolidatedTrailNodeState
    public let loadState: ConsolidatedTrailNodeState
    public let regionState: ConsolidatedTrailNodeState

    public init(
        networkState: ConsolidatedTrailNodeState,
        responseState: ConsolidatedTrailNodeState,
        deliveryState: ConsolidatedTrailNodeState,
        loadState: ConsolidatedTrailNodeState,
        regionState: ConsolidatedTrailNodeState
    ) {
        self.networkState = networkState
        self.responseState = responseState
        self.deliveryState = deliveryState
        self.loadState = loadState
        self.regionState = regionState
    }

    /// Snapshot para resultado inconclusivo (sem check positivo em nós de rota).
    public static let inconclusive = ConsolidatedTrailSnapshot(
        networkState: .check,
        responseState: .neutral,
        deliveryState: .neutral,
        loadState: .neutral,
        regionState: .neutral
    )
}

/// Estado semântico dos itens na Faixa de Compatibilidade da Sessão.
public enum SessionCompatibilityState: String, Codable, CaseIterable, Equatable, Sendable {
    case check = "check"
    case attention = "attention"
    case neutral = "neutral"
}

/// Snapshot da compatibilidade da sessão para Multiplayer, Calls e Streaming.
public struct SessionCompatibilitySnapshot: Codable, Equatable, Sendable {
    public let multiplayer: SessionCompatibilityState
    public let calls: SessionCompatibilityState
    public let streaming: SessionCompatibilityState

    public init(
        multiplayer: SessionCompatibilityState,
        calls: SessionCompatibilityState,
        streaming: SessionCompatibilityState = .neutral
    ) {
        self.multiplayer = multiplayer
        self.calls = calls
        self.streaming = streaming
    }

    /// Estado neutro quando a medição é inconclusiva.
    public static let inconclusive = SessionCompatibilitySnapshot(
        multiplayer: .neutral,
        calls: .neutral,
        streaming: .neutral
    )
}

/// Avaliador determinístico do resultado do Check Completo.
public enum CheckCompletoResultEvaluator {

    /// Avalia o veredito curto e sem ruído da medição.
    public static func evaluateVerdict(
        result: DeepCheckResult?,
        profile: QualityProfileID
    ) -> CheckCompletoVerdict {
        guard let result else {
            return .inconclusive
        }

        let interpretation = ResultInterpreter.interpret(result.restResult, profile: profile)

        // 1. Falha de entrega (perda de pacotes) tem máxima precedência
        if interpretation.primaryCauseKey == .packetLoss {
            return .deliveryFailed
        }

        // 2. Impacto material sob carga (delta P50 >= 20ms)
        if let impact = result.metrics.loadImpact, impact.classification == .material {
            return .loadHeavy
        }

        // 3. Instabilidade na rota observada (latência alta, jitter ou picos severos)
        switch interpretation.primaryCauseKey {
        case .highLatency, .highJitter, .severeSpikes:
            return .oscillated
        case .stableConnection:
            return .held
        case .packetLoss:
            return .deliveryFailed
        }
    }

    /// Avalia a Trilha Consolidada de 5 nós.
    public static func evaluateTrail(
        result: DeepCheckResult?,
        profile: QualityProfileID
    ) -> ConsolidatedTrailSnapshot {
        guard let result else {
            return .inconclusive
        }

        let interpretation = ResultInterpreter.interpret(result.restResult, profile: profile)

        // Nó 1: Wi-Fi / Rede móvel (sempre verificado na medição concluída)
        let networkState: ConsolidatedTrailNodeState = .check

        // Nó 2: Resposta UDP da região de referência
        let hasValidUDPResponse = result.restResult.metrics.validResponseCount > 0 && result.restResult.metrics.p50Milliseconds != nil
        let responseState: ConsolidatedTrailNodeState = hasValidUDPResponse ? .check : .attention

        // Nó 3: Entrega (verificação de perda de pacotes ou timeouts)
        let deliveryState: ConsolidatedTrailNodeState = (interpretation.primaryCauseKey == .packetLoss) ? .attention : .check

        // Nó 4: Carga (comportamento durante a fase sob carga)
        let loadState: ConsolidatedTrailNodeState
        if let impact = result.metrics.loadImpact {
            loadState = (impact.classification == .material) ? .attention : .check
        } else {
            loadState = .neutral
        }

        // Nó 5: Região de referência
        let regionState: ConsolidatedTrailNodeState = (interpretation.primaryCauseKey == .highLatency) ? .attention : .check

        return ConsolidatedTrailSnapshot(
            networkState: networkState,
            responseState: responseState,
            deliveryState: deliveryState,
            loadState: loadState,
            regionState: regionState
        )
    }

    /// Avalia a Faixa de Compatibilidade da Sessão com base em evidências determinísticas.
    public static func evaluateCompatibility(
        result: DeepCheckResult?,
        natSnapshot: NATTopologySnapshot?,
        profile: QualityProfileID
    ) -> SessionCompatibilitySnapshot {
        guard let result else {
            return .inconclusive
        }

        let interpretation = ResultInterpreter.interpret(result.restResult, profile: profile)
        let hasRouteInstability = interpretation.primaryCauseKey != .stableConnection
        let isLoadMaterial = result.metrics.loadImpact?.classification == .material
        let hasAnyRouteIssue = hasRouteInstability || isLoadMaterial

        // Avaliação de NAT
        let natEvaluated = natSnapshot != nil && natSnapshot?.natType != .inconclusive
        let hasNATIssue = natSnapshot?.hasAnyMultiplayerIssue ?? false

        // 1. Multiplayer:
        // - Check: UDP válido, sem causa crítica de rota e sem restrição de NAT detectada.
        // - Atenção: perda, instabilidade, latência crítica ou NAT restrito/CGNAT/duplo NAT.
        // - Neutro: inconclusivo ou topologia NAT não avaliada.
        let multiplayerState: SessionCompatibilityState
        if !natEvaluated {
            multiplayerState = .neutral
        } else if hasAnyRouteIssue || hasNATIssue {
            multiplayerState = .attention
        } else {
            multiplayerState = .check
        }

        // 2. Calls:
        // - Check: UDP válido, rota estável e sem restrição relevante de NAT.
        // - Atenção: perda, instabilidade, NAT restrito, CGNAT ou duplo NAT.
        // - Neutro: sem telemetria de topologia suficiente.
        let callsState: SessionCompatibilityState
        if !natEvaluated {
            callsState = .neutral
        } else if hasAnyRouteIssue || hasNATIssue {
            callsState = .attention
        } else {
            callsState = .check
        }

        // 3. Streaming:
        // - Sempre neutro no escopo atual.
        let streamingState: SessionCompatibilityState = .neutral

        return SessionCompatibilitySnapshot(
            multiplayer: multiplayerState,
            calls: callsState,
            streaming: streamingState
        )
    }
}
