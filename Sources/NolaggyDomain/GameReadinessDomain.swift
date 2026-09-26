import Foundation

/// Veredito semântico e determinístico de prontidão competitiva (Decisões 50 e 51).
/// Substitui o score numérico como resultado protagonista da jornada.
public enum GameReadinessVerdict: String, Codable, CaseIterable, Equatable, Sendable {
    /// Condições observadas compatíveis com partida competitiva sólida (● PRONTO PARA RANKED).
    case ready = "ready"
    /// Jitter moderado, oscilações esporádicas ou impacto sob carga (▲ CONDIÇÕES INSTÁVEIS).
    case caution = "caution"
    /// Perda de pacotes prejudicial, latência excessiva ou instabilidade severa (▲ EU EVITARIA RANKED AGORA).
    case notReady = "not_ready"
    /// Respostas UDP insuficientes (< 10 amostras válidas) para emitir veredito seguro (— INCONCLUSIVO).
    case inconclusive = "inconclusive"

    public var titleKey: String {
        switch self {
        case .ready: return "game_readiness.verdict.ready"
        case .caution: return "game_readiness.verdict.caution"
        case .notReady: return "game_readiness.verdict.not_ready"
        case .inconclusive: return "game_readiness.verdict.inconclusive"
        }
    }

    public var defaultHeadline: String {
        switch self {
        case .ready: return "PRONTO PARA RANKED"
        case .caution: return "CONDIÇÕES INSTÁVEIS"
        case .notReady: return "EU EVITARIA RANKED AGORA"
        case .inconclusive: return "DADOS INSUFICIENTES"
        }
    }

    public var isReady: Bool {
        self == .ready
    }

    public var symbolName: String {
        switch self {
        case .ready: return "checkmark.circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .notReady: return "xmark.octagon.fill"
        case .inconclusive: return "minus.circle.fill"
        }
    }
}

/// Achado de rede honesto para a seção "O que encontramos" (Decisões 50 e 51).
/// Reporta o sintoma comprovado sem atribuir culpa causal falsa a Wi-Fi ou operadora sem probe isolado.
public struct NetworkFinding: Codable, Equatable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case packetLoss
        case latencySpikes
        case highLatency
        case highJitter
        case outOfOrderPackets
        case loadDegradation
        case normalDestination
        case stableRoute
        case localGateway
        case natTopology
        case insufficientData
    }

    public enum Severity: String, Codable, Sendable {
        case positive // Verde
        case warning  // Âmbar
        case negative // Vermelho
        case neutral  // Neutro/Cinza
    }

    public let kind: Kind
    public let severity: Severity
    public let labelKey: String
    public let detail: String?

    public init(kind: Kind, severity: Severity, labelKey: String, detail: String? = nil) {
        self.kind = kind
        self.severity = severity
        self.labelKey = labelKey
        self.detail = detail
    }
}

/// Avaliação completa de prontidão competitiva para a tela de resultado HIG Dark Competitive.
public struct GameReadinessEvaluation: Codable, Equatable, Sendable {
    public let verdict: GameReadinessVerdict
    public let headlineKey: String
    public let subtitleKey: String
    /// Valor normalizado de 0.0 a 1.0 para a barra contínua de estabilidade.
    public let stabilityRatio: Double
    public let stabilitySummaryKey: String
    public let findings: [NetworkFinding]
    public let pingMs: Double?
    public let jitterMs: Double?
    public let packetLossPercentage: Double?
    public let isUnderLoadAffected: Bool
    public let worstSpikeMs: Double?

    public init(
        verdict: GameReadinessVerdict,
        headlineKey: String,
        subtitleKey: String,
        stabilityRatio: Double,
        stabilitySummaryKey: String,
        findings: [NetworkFinding],
        pingMs: Double?,
        jitterMs: Double?,
        packetLossPercentage: Double?,
        isUnderLoadAffected: Bool,
        worstSpikeMs: Double? = nil
    ) {
        self.verdict = verdict
        self.headlineKey = headlineKey
        self.subtitleKey = subtitleKey
        self.stabilityRatio = stabilityRatio
        self.stabilitySummaryKey = stabilitySummaryKey
        self.findings = findings
        self.pingMs = pingMs
        self.jitterMs = jitterMs
        self.packetLossPercentage = packetLossPercentage
        self.isUnderLoadAffected = isUnderLoadAffected
        self.worstSpikeMs = worstSpikeMs
    }

    public static let inconclusive = GameReadinessEvaluation(
        verdict: .inconclusive,
        headlineKey: "game_readiness.verdict.inconclusive.headline",
        subtitleKey: "game_readiness.verdict.inconclusive.subtitle",
        stabilityRatio: 0.0,
        stabilitySummaryKey: "game_readiness.stability.inconclusive",
        findings: [
            NetworkFinding(
                kind: .insufficientData,
                severity: .neutral,
                labelKey: "game_readiness.finding.insufficient_samples"
            )
        ],
        pingMs: nil,
        jitterMs: nil,
        packetLossPercentage: nil,
        isUnderLoadAffected: false,
        worstSpikeMs: nil
    )
}

/// Avaliador determinístico de prontidão de rede para jogos (Decisões 50, 51 e 55).
/// Executa estritamente sobre evidências de medição UDP e perfil do jogo.
public enum GameReadinessEvaluator {
    public static let version = "readiness-v2.0"

    /// Avalia a prontidão a partir de um DeepCheckResult (repouso + impacto de carga opcional).
    public static func evaluate(
        deepCheckResult: DeepCheckResult?,
        profile: QualityProfileID
    ) -> GameReadinessEvaluation {
        guard let result = deepCheckResult else {
            return .inconclusive
        }
        return evaluate(
            qualityResult: result.restResult,
            loadImpact: result.metrics.loadImpact,
            profile: profile
        )
    }

    /// Avalia a prontidão a partir de QualityResult (repouso) e opcional impacto sob carga.
    public static func evaluate(
        qualityResult: QualityResult?,
        loadImpact: DeepCheckLoadImpact?,
        profile: QualityProfileID,
        confidence: MeasurementConfidence = .high,
        spikePattern: SpikePattern? = nil,
        gatewayOutcome: GatewayProbeOutcome = .unobservable,
        serverArchitecture: GameServerArchitecture = .dedicatedServer,
        natSnapshot: NATTopologySnapshot? = nil
    ) -> GameReadinessEvaluation {
        guard let qualityResult else {
            return .inconclusive
        }

        let metrics = qualityResult.metrics

        // Regra Inegociável: Menos de 10 respostas UDP válidas é estritamente inconclusivo.
        guard metrics.validResponseCount >= 10 else {
            return .inconclusive
        }

        let interpretation = ResultInterpreter.interpret(
            qualityResult,
            profile: profile,
            loadTier: loadImpact?.tier,
            gatewayOutcome: gatewayOutcome,
            spikePattern: spikePattern,
            serverArchitecture: serverArchitecture
        )
        let guardrails = QualityEvaluator.causeGuardrails(for: profile)

        // Margem de segurança de 10% para console/PC ou rota genérica (confiança medium) (Decisão 55)
        let marginFactor: Double = (confidence == .medium) ? 0.90 : 1.0
        let effectiveMaxLoss = guardrails.lossGuardrailPercentage * marginFactor
        let effectiveMaxP50 = guardrails.latencyGuardrailMilliseconds * marginFactor
        let effectiveCautionJitter = guardrails.jitterRiskMilliseconds * marginFactor

        let isLoadSevere = (loadImpact?.tier == .severe)
        let isLoadMaterial = (loadImpact?.tier == .material || loadImpact?.classification == .material)
        let hasPacketLoss = metrics.packetLossPercentage > effectiveMaxLoss || interpretation.primaryCauseKey == .packetLoss
        let hasHighLatency = (metrics.p50Milliseconds ?? 0) > effectiveMaxP50 || interpretation.primaryCauseKey == .highLatency

        let recurringSevereSpikes: Bool
        if let pattern = spikePattern {
            recurringSevereSpikes = pattern.severeCount >= 2 && pattern.isRecurring
        } else {
            recurringSevereSpikes = metrics.severeSpikeCount >= guardrails.severeSpikeGuardrailCount
        }

        let hasSevereSpikes = recurringSevereSpikes || metrics.severeSpikeCount >= guardrails.severeSpikeGuardrailCount || interpretation.primaryCauseKey == .severeSpikes
        let hasHighJitter = (metrics.jitterMilliseconds ?? 0) >= effectiveCautionJitter || interpretation.primaryCauseKey == .highJitter
        let hasRecurringSpikes = spikePattern?.isRecurring ?? false
        let hasOutOfOrder = metrics.outOfOrderCount >= 2 || metrics.outOfOrderRatePercentage >= 5.0

        // Latência de cauda (P95 vs P50):
        // Só é clinicamente relevante se houver dispersão relativa (>= 1.8) E absoluta significativa (delta >= 20ms e p95 > 45ms),
        // evitando falsos positivos em conexões ultrarrápidas de fibra (ex: 13ms p50 -> 24ms p95, delta de apenas 11ms).
        let p50Value = metrics.p50Milliseconds ?? 0
        let p95Value = metrics.p95Milliseconds ?? 0
        let isTailLatencyHigh = (metrics.p95ToP50Ratio ?? 0) >= 1.8 && (p95Value - p50Value) >= 20.0 && p95Value > 45.0
        let isGatewayDegraded = gatewayOutcome.isDegraded

        // 1. Determinação do Veredito (readiness-v2.0)
        let verdict: GameReadinessVerdict
        let headlineKey: String
        let subtitleKey: String

        if hasPacketLoss {
            verdict = .notReady
            headlineKey = "game_readiness.verdict.not_ready.headline"
            subtitleKey = "game_readiness.verdict.not_ready.packet_loss"
        } else if hasHighLatency {
            verdict = .notReady
            headlineKey = "game_readiness.verdict.not_ready.headline"
            subtitleKey = "game_readiness.verdict.not_ready.high_latency"
        } else if recurringSevereSpikes || hasSevereSpikes {
            verdict = .notReady
            headlineKey = "game_readiness.verdict.not_ready.headline"
            subtitleKey = "game_readiness.verdict.not_ready.severe_spikes"
        } else if isLoadSevere {
            verdict = .notReady
            headlineKey = "game_readiness.verdict.not_ready.headline"
            subtitleKey = "game_readiness.verdict.not_ready.load"
        } else if qualityResult.resultClass == .lagRisk {
            verdict = .notReady
            headlineKey = "game_readiness.verdict.not_ready.headline"
            subtitleKey = "game_readiness.verdict.not_ready.risk"
        } else if hasHighJitter {
            verdict = .caution
            headlineKey = "game_readiness.verdict.caution.headline"
            subtitleKey = "game_readiness.verdict.caution.jitter"
        } else if hasOutOfOrder {
            verdict = .caution
            headlineKey = "game_readiness.verdict.caution.headline"
            subtitleKey = "game_readiness.verdict.caution.out_of_order"
        } else if isLoadMaterial {
            verdict = .caution
            headlineKey = "game_readiness.verdict.caution.headline"
            subtitleKey = "game_readiness.verdict.caution.load"
        } else if hasRecurringSpikes {
            verdict = .caution
            headlineKey = "game_readiness.verdict.caution.headline"
            subtitleKey = "game_readiness.verdict.caution.spikes"
        } else if isTailLatencyHigh {
            verdict = .caution
            headlineKey = "game_readiness.verdict.caution.headline"
            subtitleKey = "game_readiness.verdict.caution.jitter"
        } else if isGatewayDegraded {
            verdict = .caution
            headlineKey = "game_readiness.verdict.caution.headline"
            subtitleKey = "game_readiness.verdict.caution.general"
        } else if qualityResult.resultClass == .unstable {
            verdict = .caution
            headlineKey = "game_readiness.verdict.caution.headline"
            subtitleKey = "game_readiness.verdict.caution.general"
        } else {
            verdict = .ready
            headlineKey = "game_readiness.verdict.ready.headline"
            subtitleKey = "game_readiness.verdict.ready.stable"
        }

        // 2. Construção dos Achados ("O Que Encontramos" — sem causalidade falsa)
        var findings: [NetworkFinding] = []

        // Enlace Wi-Fi Local (se houver degradação comprovada no primeiro salto)
        if isGatewayDegraded {
            findings.append(NetworkFinding(
                kind: .localGateway,
                severity: .negative,
                labelKey: "game_readiness.finding.local_gateway_degraded",
                detail: "Wi-Fi"
            ))
        }

        // Perda de pacotes
        if metrics.packetLossPercentage > 1.0 {
            findings.append(NetworkFinding(
                kind: .packetLoss,
                severity: .negative,
                labelKey: "game_readiness.finding.packet_loss_detected",
                detail: String(format: "%.1f%%", metrics.packetLossPercentage)
            ))
        } else {
            findings.append(NetworkFinding(
                kind: .packetLoss,
                severity: .positive,
                labelKey: "game_readiness.finding.no_packet_loss",
                detail: "0%"
            ))
        }

        // Latência alta acima do guardrail
        if hasHighLatency {
            let p50 = metrics.p50Milliseconds ?? 0
            findings.append(NetworkFinding(
                kind: .highLatency,
                severity: .negative,
                labelKey: "game_readiness.finding.high_latency_detected",
                detail: String(format: "%.0f ms", p50)
            ))
        }

        // Estabilidade / Picos de latência
        if hasSevereSpikes {
            findings.append(NetworkFinding(
                kind: .latencySpikes,
                severity: .negative,
                labelKey: "game_readiness.finding.severe_spikes_detected",
                detail: "\(metrics.severeSpikeCount)"
            ))
        } else if isTailLatencyHigh {
            findings.append(NetworkFinding(
                kind: .latencySpikes,
                severity: .warning,
                labelKey: "game_readiness.finding.tail_latency_elevated",
                detail: String(format: "%.1fx", metrics.p95ToP50Ratio ?? 0)
            ))
        } else if metrics.spikeCount > 0 || hasHighJitter {
            findings.append(NetworkFinding(
                kind: .latencySpikes,
                severity: .warning,
                labelKey: "game_readiness.finding.jitter_oscillations",
                detail: nil
            ))
        } else {
            findings.append(NetworkFinding(
                kind: .stableRoute,
                severity: .positive,
                labelKey: "game_readiness.finding.route_stable",
                detail: nil
            ))
        }

        // Pacotes fora de ordem na rota
        if metrics.outOfOrderCount > 0 {
            findings.append(NetworkFinding(
                kind: .outOfOrderPackets,
                severity: metrics.outOfOrderRatePercentage >= 10.0 ? .negative : .warning,
                labelKey: "game_readiness.finding.out_of_order_detected",
                detail: "\(metrics.outOfOrderCount)"
            ))
        }

        // Sob uso da rede / Carga
        if isLoadSevere {
            let increase = loadImpact?.increaseMilliseconds ?? 0
            findings.append(NetworkFinding(
                kind: .loadDegradation,
                severity: .negative,
                labelKey: "game_readiness.finding.load_degradation_detected",
                detail: String(format: "+%.0f ms", increase)
            ))
        } else if isLoadMaterial {
            let increase = loadImpact?.increaseMilliseconds ?? 0
            findings.append(NetworkFinding(
                kind: .loadDegradation,
                severity: .warning,
                labelKey: "game_readiness.finding.load_degradation_detected",
                detail: String(format: "+%.0f ms", increase)
            ))
        } else if loadImpact != nil {
            findings.append(NetworkFinding(
                kind: .loadDegradation,
                severity: .positive,
                labelKey: "game_readiness.finding.load_stable",
                detail: nil
            ))
        }

        // Topologia NAT (contextualizada por arquitetura de jogo) (Decisão 55)
        if (serverArchitecture == .peerToPeer || serverArchitecture == .hybrid), let nat = natSnapshot {
            findings.append(NetworkFinding(
                kind: .natTopology,
                severity: nat.natType.isMultiplayerRestricted ? .negative : .positive,
                labelKey: nat.natType.titleKey,
                detail: nat.natType.shortLabel
            ))
        }

        // Destino testado
        findings.append(NetworkFinding(
            kind: .normalDestination,
            severity: .positive,
            labelKey: "game_readiness.finding.destination_response_normal",
            detail: nil
        ))

        // 3. Cálculo da Proporção de Estabilidade (0.0 a 1.0)
        let consistency = metrics.components?.consistency ?? Double(qualityResult.finalScore)
        var stabilityRatio = max(0.0, min(1.0, consistency / 100.0))
        if isLoadMaterial {
            stabilityRatio = max(0.2, stabilityRatio * 0.8)
        }
        if verdict == .notReady {
            stabilityRatio = min(0.45, stabilityRatio)
        } else if verdict == .caution {
            stabilityRatio = min(0.75, max(0.50, stabilityRatio))
        } else if verdict == .ready {
            stabilityRatio = max(0.85, stabilityRatio)
        }

        let stabilitySummaryKey: String
        switch verdict {
        case .ready:
            stabilitySummaryKey = "game_readiness.stability.ready_summary"
        case .caution:
            stabilitySummaryKey = "game_readiness.stability.caution_summary"
        case .notReady:
            stabilitySummaryKey = "game_readiness.stability.not_ready_summary"
        case .inconclusive:
            stabilitySummaryKey = "game_readiness.stability.inconclusive"
        }

        return GameReadinessEvaluation(
            verdict: verdict,
            headlineKey: headlineKey,
            subtitleKey: subtitleKey,
            stabilityRatio: stabilityRatio,
            stabilitySummaryKey: stabilitySummaryKey,
            findings: findings,
            pingMs: metrics.p50Milliseconds,
            jitterMs: metrics.jitterMilliseconds,
            packetLossPercentage: metrics.packetLossPercentage,
            isUnderLoadAffected: isLoadMaterial,
            worstSpikeMs: metrics.worstSpikeMilliseconds
        )
    }
}
