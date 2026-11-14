import Foundation
import LagCheckEngine

// MARK: - Engine DTOs (ENGINE_CONTRACT.md)

public struct EnginePolicyDTO: Codable, Sendable {
    public let plannedProbeCount: Int
    public let sendIntervalMillis: Int64
    public let sendWindowMillis: Int64
    public let timeoutMillis: Int64
    public let closureMillis: Int64
    public let minimumValidResponses: Int
    public let ruleVersions: [String: [String: String]]
    /// Guardrail de perda por perfil: o mesmo corte do veredito vale para a recomendação (Decisão 136).
    public let lossGuardrailPercentage: [String: Double]
}

public struct EngineSampleDTO: Codable, Sendable {
    public let sequence: Int
    public let outcome: String
    public let rttMs: Double?
    public let arrivalIndex: Int?

    public init(sequence: Int, outcome: String, rttMs: Double?, arrivalIndex: Int? = nil) {
        self.sequence = sequence
        self.outcome = outcome
        self.rttMs = rttMs
        self.arrivalIndex = arrivalIndex
    }
}

public struct EngineGatewayDTO: Codable, Sendable {
    public let rttMs: Double?
    public let jitterMs: Double?
    public let validResponses: Int
    public let plannedResponses: Int
    public let isWifi: Bool

    public init(rttMs: Double?, jitterMs: Double?, validResponses: Int, plannedResponses: Int, isWifi: Bool = true) {
        self.rttMs = rttMs
        self.jitterMs = jitterMs
        self.validResponses = validResponses
        self.plannedResponses = plannedResponses
        self.isWifi = isWifi
    }
}

public struct EngineNatDTO: Codable, Sendable {
    public let type: String
    public let origin: String

    public init(type: String, origin: String = "STUN_APP") {
        self.type = type
        self.origin = origin
    }
}

/// Estado do roteador já classificado pelo motor (`LagCheckEngine.gatewayOutcome`).
public struct EngineGatewayOutcomeDTO: Codable, Sendable, Equatable {
    public let kind: String
    public let rttMs: Double?
    public let lossPercentage: Double?

    public init(kind: String, rttMs: Double? = nil, lossPercentage: Double? = nil) {
        self.kind = kind
        self.rttMs = rttMs
        self.lossPercentage = lossPercentage
    }

    public init(_ outcome: GatewayProbeOutcome) {
        switch outcome {
        case .stable(let rtt): self.init(kind: "STABLE", rttMs: rtt, lossPercentage: 0)
        case .degraded(let rtt, let loss): self.init(kind: "DEGRADED", rttMs: rtt, lossPercentage: loss)
        case .unobservable: self.init(kind: "UNOBSERVABLE")
        }
    }

    public var outcome: GatewayProbeOutcome {
        switch (kind, rttMs) {
        case ("STABLE", let rtt?): return .stable(rttMilliseconds: rtt)
        case ("DEGRADED", let rtt?): return .degraded(rttMilliseconds: rtt, lossPercentage: lossPercentage ?? 0)
        default: return .unobservable
        }
    }
}

public struct EngineRequestDTO: Codable, Sendable {
    public let source: String
    public let profile: String
    public let rest: [EngineSampleDTO]
    public let load: [EngineSampleDTO]?
    public let loadTransfer: String
    public let gateway: EngineGatewayDTO?
    public let gatewayOutcome: EngineGatewayOutcomeDTO?
    public let wifiBand: String?
    public let nat: EngineNatDTO?
    public let serverArchitecture: String
    public let gameId: String?
    public let uploadMbps: Double?

    public init(
        source: String = "APP_UDP",
        profile: String,
        rest: [EngineSampleDTO],
        load: [EngineSampleDTO]? = nil,
        loadTransfer: String = "NOT_RUN",
        gateway: EngineGatewayDTO? = nil,
        gatewayOutcome: EngineGatewayOutcomeDTO? = nil,
        wifiBand: String? = nil,
        nat: EngineNatDTO? = nil,
        serverArchitecture: String = "DEDICATED_SERVER",
        gameId: String? = nil,
        uploadMbps: Double? = nil
    ) {
        self.source = source
        self.profile = profile
        self.rest = rest
        self.load = load
        self.loadTransfer = loadTransfer
        self.gateway = gateway
        self.gatewayOutcome = gatewayOutcome
        self.wifiBand = wifiBand
        self.nat = nat
        self.serverArchitecture = serverArchitecture
        self.gameId = gameId
        self.uploadMbps = uploadMbps
    }
}

public struct EngineMetricDTO: Codable, Sendable {
    public let validResponseCount: Int
    public let timeoutCount: Int
    public let invalidResponseCount: Int
    public let p50Milliseconds: Double?
    public let p95Milliseconds: Double?
    public let p99Milliseconds: Double?
    public let jitterMilliseconds: Double?
    public let packetLossPercentage: Double
    public let spikeCount: Int
    public let severeSpikeCount: Int
    public let spikeRatePercentage: Double
    public let p95ToP50Ratio: Double?
    public let worstSpikeMilliseconds: Double?
    public let outOfOrderCount: Int
    public let outOfOrderRatePercentage: Double
    public let spikePattern: String
}

public struct EngineLoadImpactDTO: Codable, Sendable {
    public let tier: String
    public let deltaP50Milliseconds: Double
    public let deltaJitterMilliseconds: Double?
    public let deltaLossPercentage: Double?
    public let deltaSpikesCount: Int?
    public let bufferbloatGrade: String
}

public struct EngineFindingDTO: Codable, Sendable {
    public let kind: String
    public let severity: String
    public let key: String
    public let detail: String?
}

public struct EngineResponseDTO: Codable, Sendable {
    public let verdict: String
    public let headlineKey: String
    public let subtitleKey: String
    public let score: Int?
    public let isEstimate: Bool
    public let rest: EngineMetricDTO
    public let load: EngineMetricDTO?
    public let loadImpact: EngineLoadImpactDTO?
    public let spikePattern: String
    public let primaryCause: String?
    public let secondaryCauses: [String]
    public let findings: [EngineFindingDTO]
    public let recommendations: [String]
    public let inconclusiveReason: String?
    public let ruleVersions: [String: String]
}

// MARK: - Policy Provider

public enum EnginePolicyProvider {
    public static let policy: EnginePolicyDTO = {
        let jsonStr = LagCheckEngine.shared.policy()
        let data = jsonStr.data(using: .utf8) ?? Data()
        do {
            return try JSONDecoder().decode(EnginePolicyDTO.self, from: data)
        } catch {
            fatalError("Failed to decode LagCheckEngine policy: \(error)")
        }
    }()
}

// MARK: - Bridge Execution

public enum LagCheckEngineBridge {

    public static func evaluate(request: EngineRequestDTO) -> EngineResponseDTO {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(request),
              let jsonStr = String(data: data, encoding: .utf8) else {
            fatalError("Failed to encode EngineRequestDTO")
        }
        let responseJson = LagCheckEngine.shared.evaluate(requestJson: jsonStr)
        guard let responseData = responseJson.data(using: .utf8) else {
            fatalError("Failed to convert response JSON to Data")
        }
        do {
            return try JSONDecoder().decode(EngineResponseDTO.self, from: responseData)
        } catch {
            fatalError("Failed to decode EngineResponseDTO from: \(responseJson), error: \(error)")
        }
    }

    public static func toProfileKey(_ profile: QualityProfileID) -> String {
        switch profile {
        case .battleRoyaleCompetitive: return "BATTLE_ROYALE_COMPETITIVE"
        case .mobileRealtime: return "MOBILE_REALTIME"
        case .casualRealtime: return "CASUAL_REALTIME"
        }
    }

    public static func toOutcomeKey(_ outcome: ProbeOutcome) -> String {
        switch outcome {
        case .received: return "RECEIVED"
        case .timeout: return "TIMEOUT"
        case .transportError: return "TRANSPORT_ERROR"
        case .invalidResponse: return "INVALID_RESPONSE"
        }
    }

    public static func toSampleDTO(_ sample: ProbeSample) -> EngineSampleDTO {
        EngineSampleDTO(
            sequence: sample.sequence,
            outcome: toOutcomeKey(sample.outcome),
            rttMs: sample.roundTripMilliseconds,
            arrivalIndex: sample.arrivalIndex
        )
    }

    public static func toArchitectureKey(_ arch: GameServerArchitecture) -> String {
        switch arch {
        case .dedicatedServer: return "DEDICATED_SERVER"
        case .peerToPeer: return "PEER_TO_PEER"
        case .hybrid: return "HYBRID"
        }
    }

    public static func toSpikePattern(_ string: String, count: Int, severeCount: Int) -> SpikePattern {
        switch string.uppercased() {
        case "ISOLATED":
            return .isolated(count: count, severeCount: severeCount)
        case "RECURRING":
            return .recurring(count: count, severeCount: severeCount)
        default:
            return .none
        }
    }

    public static func mapMetrics(_ dto: EngineMetricDTO) -> QualityMetrics {
        QualityMetrics(
            validResponseCount: dto.validResponseCount,
            timeoutCount: dto.timeoutCount,
            invalidResponseCount: dto.invalidResponseCount,
            p50Milliseconds: dto.p50Milliseconds,
            p95Milliseconds: dto.p95Milliseconds,
            p99Milliseconds: dto.p99Milliseconds,
            jitterMilliseconds: dto.jitterMilliseconds,
            packetLossPercentage: dto.packetLossPercentage,
            spikeCount: dto.spikeCount,
            severeSpikeCount: dto.severeSpikeCount,
            spikeRatePercentage: dto.spikeRatePercentage,
            p95ToP50Ratio: dto.p95ToP50Ratio,
            worstSpikeMilliseconds: dto.worstSpikeMilliseconds,
            outOfOrderCount: dto.outOfOrderCount,
            outOfOrderRatePercentage: dto.outOfOrderRatePercentage,
            components: nil,
            spikePattern: toSpikePattern(dto.spikePattern, count: dto.spikeCount, severeCount: dto.severeSpikeCount)
        )
    }

    public static func toLoadTier(_ string: String) -> LoadDegradationTier {
        switch string.uppercased() {
        case "LIGHT": return .light
        case "MATERIAL": return .material
        case "SEVERE": return .severe
        default: return .none
        }
    }

    public static func toPrimaryCauseKey(_ string: String?) -> ResultPrimaryCauseKey {
        guard let string else { return .stableConnection }
        switch string.uppercased() {
        case "PACKET_LOSS": return .packetLoss
        case "HIGH_LATENCY": return .highLatency
        case "SEVERE_SPIKES": return .severeSpikes
        case "HIGH_JITTER": return .highJitter
        case "LOAD_DEGRADATION": return .loadDegradation
        case "LOAD_INSTABILITY": return .loadInstability
        case "TAIL_LATENCY": return .tailLatency
        case "OUT_OF_ORDER": return .outOfOrder
        default: return .stableConnection
        }
    }

    public static func toFindingKind(_ string: String) -> NetworkFinding.Kind {
        switch string.uppercased() {
        case "LOCAL_GATEWAY": return .localGateway
        case "PACKET_LOSS": return .packetLoss
        case "HIGH_LATENCY": return .highLatency
        case "LATENCY_SPIKES": return .latencySpikes
        case "OUT_OF_ORDER_PACKETS": return .outOfOrderPackets
        case "LOAD_DEGRADATION": return .loadDegradation
        case "NAT_TOPOLOGY": return .natTopology
        case "NORMAL_DESTINATION": return .normalDestination
        default: return .stableRoute
        }
    }

    public static func toFindingSeverity(_ string: String) -> NetworkFinding.Severity {
        switch string.uppercased() {
        case "POSITIVE": return .positive
        case "WARNING": return .warning
        case "NEGATIVE": return .negative
        default: return .neutral
        }
    }

    public static func toResultClass(_ score: Int) -> ResultClass {
        switch score {
        case 90...100: return .excellent
        case 75...89: return .great
        case 60...74: return .unstable
        default: return .lagRisk
        }
    }

    public static func buildSamplesFromMetrics(
        _ metrics: QualityMetrics,
        overrideSpikePattern: SpikePattern? = nil
    ) -> [EngineSampleDTO] {
        var samples: [EngineSampleDTO] = []
        let valid = max(0, metrics.validResponseCount)
        let timeouts = max(0, metrics.timeoutCount)
        let p50 = metrics.p50Milliseconds ?? 30.0
        let p95 = metrics.p95Milliseconds ?? p50
        let worst = metrics.worstSpikeMilliseconds ?? max(p95, 200.0)
        let jitter = metrics.jitterMilliseconds ?? 0.0

        let effectivePattern: SpikePattern = (overrideSpikePattern ?? metrics.spikePattern) ?? .none
        let severeCount: Int
        let isRecurring: Bool
        let totalSpikes: Int
        switch effectivePattern {
        case .isolated(let count, let severe):
            severeCount = severe
            isRecurring = false
            totalSpikes = count
        case .recurring(let count, let severe):
            severeCount = severe
            isRecurring = true
            totalSpikes = count
        case .none:
            severeCount = metrics.severeSpikeCount
            isRecurring = false
            totalSpikes = metrics.spikeCount
        }

        var severeIndices = Set<Int>()
        if severeCount > 0 {
            if isRecurring {
                // Picos recorrentes: dentro de janela curta (ex: seq 10, 12, 14, dist <= 4)
                for i in 0..<min(severeCount, valid) {
                    severeIndices.insert(10 + i * 2)
                }
            } else {
                // Picos isolados: distantes (ex: seq 5, seq 40, dist >= 5)
                let positions = [5, 40, 20, 50, 15, 45]
                for i in 0..<min(severeCount, positions.count) {
                    severeIndices.insert(positions[i])
                }
            }
        }

        let nonSevereSpikes = max(0, totalSpikes - severeCount)
        var normalSpikeIndices = Set<Int>()
        var added = 0
        var candidateSeq = 1
        while added < nonSevereSpikes && candidateSeq < valid {
            if !severeIndices.contains(candidateSeq) {
                normalSpikeIndices.insert(candidateSeq)
                added += 1
            }
            candidateSeq += 1
        }

        // Se houver cauda (P95 > P50) e sem spikes suficientes para formar cauda:
        var tailIndices = Set<Int>()
        let neededTail = max(4, valid - Int(floor(Double(valid - 1) * 0.95)))
        if p95 > p50 && (severeIndices.count + normalSpikeIndices.count) < neededTail {
            let tailCount = neededTail
            var tAdded = 0
            for seq in stride(from: valid - 1, through: 0, by: -1) {
                if tAdded >= tailCount { break }
                if !severeIndices.contains(seq) && !normalSpikeIndices.contains(seq) {
                    tailIndices.insert(seq)
                    tAdded += 1
                }
            }
        }

        // Mapeamento de chegada para out-of-order:
        var arrivalIndices = [Int](0..<valid)
        if metrics.outOfOrderCount > 0 {
            let pairs = min(metrics.outOfOrderCount, valid / 2)
            for i in 0..<pairs {
                let idx1 = 2 + i * 4
                let idx2 = 3 + i * 4
                if idx2 < valid {
                    arrivalIndices.swapAt(idx1, idx2)
                }
            }
        }

        for seq in 0..<valid {
            let rtt: Double
            if severeIndices.contains(seq) {
                rtt = max(200.0, worst)
            } else if normalSpikeIndices.contains(seq) {
                rtt = max(90.0, p95)
            } else if tailIndices.contains(seq) {
                rtt = p95
            } else if jitter > 0 && severeIndices.isEmpty && normalSpikeIndices.isEmpty {
                // Alterna em torno de p50 para reproduzir jitter sem alterar P50
                rtt = (seq % 2 == 0) ? max(1.0, p50 - jitter / 2.0) : (p50 + jitter / 2.0)
            } else {
                rtt = p50
            }
            let arrival = (metrics.outOfOrderCount > 0) ? arrivalIndices[seq] : seq
            samples.append(EngineSampleDTO(sequence: seq, outcome: "RECEIVED", rttMs: rtt, arrivalIndex: arrival))
        }

        let startTimeout = valid
        for seq in startTimeout..<(startTimeout + timeouts) {
            samples.append(EngineSampleDTO(sequence: seq, outcome: "TIMEOUT", rttMs: nil, arrivalIndex: seq))
        }

        return samples
    }

    /// Classifica o roteador pela regra do motor (≥ 3 respostas em 5, RTT ≤ 15 ms, sem perda, jitter ≤ 10 ms).
    public static func gatewayOutcome(for telemetry: WiFiLocalTelemetry) -> GatewayProbeOutcome {
        let dto = EngineGatewayDTO(
            rttMs: telemetry.gatewayRTTMedianMs,
            jitterMs: telemetry.gatewayJitterMs,
            validResponses: telemetry.validSampleCount,
            plannedResponses: telemetry.plannedSampleCount,
            isWifi: telemetry.isWiFi
        )
        guard let data = try? JSONEncoder().encode(dto), let json = String(data: data, encoding: .utf8),
              let out = LagCheckEngine.shared.gatewayOutcome(gatewayJson: json).data(using: .utf8),
              let decoded = try? JSONDecoder().decode(EngineGatewayOutcomeDTO.self, from: out) else {
            return .unobservable
        }
        return decoded.outcome
    }

    /// Culpado pela regra do motor (`root-cause-v2`). Sem roteador impecável, nunca culpa a operadora.
    public static func rootCauseCulprit(
        gatewayOutcome: GatewayProbeOutcome,
        wanMetrics: QualityMetrics,
        platformDegraded: Bool,
        platformServiceName: String?
    ) -> (culprit: CulpritEntity, ruleVersion: String) {
        struct Request: Encodable {
            let gateway: EngineGatewayOutcomeDTO
            let wanP50Ms: Double?
            let wanJitterMs: Double?
            let wanLossPercentage: Double
            let platformDegraded: Bool
            let platformServiceName: String?
        }
        struct Response: Decodable { let culprit: String; let ruleVersion: String }
        let request = Request(
            gateway: EngineGatewayOutcomeDTO(gatewayOutcome),
            wanP50Ms: wanMetrics.p50Milliseconds,
            wanJitterMs: wanMetrics.jitterMilliseconds,
            wanLossPercentage: wanMetrics.packetLossPercentage,
            platformDegraded: platformDegraded,
            platformServiceName: platformServiceName
        )
        guard let data = try? JSONEncoder().encode(request), let json = String(data: data, encoding: .utf8),
              let out = LagCheckEngine.shared.rootCause(requestJson: json).data(using: .utf8),
              let decoded = try? JSONDecoder().decode(Response.self, from: out),
              let culprit = CulpritEntity(rawValue: decoded.culprit) else {
            // Sem resposta do motor não há evidência: não culpa ninguém (Decisão 50).
            return (.unobservable, EnginePolicyProvider.policy.ruleVersions["BATTLE_ROYALE_COMPETITIVE"]?["rootCause"] ?? "root-cause-v2")
        }
        return (culprit, decoded.ruleVersion)
    }

    public static func buildRequest(
        qualityResult: QualityResult,
        loadImpact: DeepCheckLoadImpact?,
        profile: QualityProfileID,
        gatewayOutcome: GatewayProbeOutcome = .unobservable,
        spikePattern: SpikePattern? = nil,
        serverArchitecture: GameServerArchitecture = .dedicatedServer,
        natSnapshot: NATTopologySnapshot? = nil,
        loadProbeSamples: [ProbeSample]? = nil
    ) -> EngineRequestDTO {
        // Pacotes reais quando existem: o motor recalcula exatamente o que foi medido.
        // A série reconstruída a partir das métricas só serve para entradas antigas do histórico.
        let restSamples = qualityResult.samples.map { $0.map(toSampleDTO) }
            ?? buildSamplesFromMetrics(qualityResult.metrics, overrideSpikePattern: spikePattern)
        var loadSamples: [EngineSampleDTO]? = nil
        var loadTransfer = "NOT_RUN"

        if loadImpact != nil, let loadProbeSamples, !loadProbeSamples.isEmpty {
            loadTransfer = "MEASURED"
            loadSamples = loadProbeSamples.map(toSampleDTO)
        } else if let loadImpact {
            loadTransfer = "MEASURED"
            let delta = loadImpact.increaseMilliseconds
            let baseP50 = qualityResult.metrics.p50Milliseconds ?? 30.0
            let loadP50 = baseP50 + delta
            var lSamples: [EngineSampleDTO] = []
            for seq in 0..<qualityResult.metrics.validResponseCount {
                lSamples.append(EngineSampleDTO(sequence: seq, outcome: "RECEIVED", rttMs: loadP50))
            }
            loadSamples = lSamples
        }

        // O estado do roteador vai como foi classificado pelo motor a partir da medição real;
        // nada de RTT, jitter ou contagem de respostas inventados.
        let gatewayOutcomeDTO: EngineGatewayOutcomeDTO? = gatewayOutcome == .unobservable ? nil : EngineGatewayOutcomeDTO(gatewayOutcome)

        let natDTO: EngineNatDTO?
        if let nat = natSnapshot {
            let typeStr: String
            switch nat.natType {
            case .type1Open: typeStr = "TYPE_1_OPEN"
            case .type2Moderate: typeStr = "TYPE_2_MODERATE"
            case .type3Strict: typeStr = "TYPE_3_STRICT"
            case .inconclusive: typeStr = "INCONCLUSIVE"
            }
            natDTO = EngineNatDTO(type: typeStr)
        } else {
            natDTO = nil
        }

        return EngineRequestDTO(
            source: "APP_UDP",
            profile: toProfileKey(profile),
            rest: restSamples,
            load: loadSamples,
            loadTransfer: loadTransfer,
            gateway: nil,
            gatewayOutcome: gatewayOutcomeDTO,
            wifiBand: nil,
            nat: natDTO,
            serverArchitecture: toArchitectureKey(serverArchitecture),
            gameId: nil,
            uploadMbps: nil
        )
    }

    public static func mapGameReadinessEvaluation(
        response: EngineResponseDTO,
        confidence: MeasurementConfidence,
        deepCheckMetrics: DeepCheckMetrics?,
        qualityResult: QualityResult,
        loadImpact: DeepCheckLoadImpact?,
        serverArchitecture: GameServerArchitecture = .dedicatedServer,
        natSnapshot: NATTopologySnapshot? = nil
    ) -> GameReadinessEvaluation {
        let verdict: GameReadinessVerdict
        switch response.verdict.uppercased() {
        case "READY": verdict = .ready
        case "CAUTION": verdict = .caution
        case "NOT_READY": verdict = .notReady
        default: verdict = .inconclusive
        }

        var findings: [NetworkFinding] = response.findings.map { f in
            NetworkFinding(
                kind: toFindingKind(f.kind),
                severity: toFindingSeverity(f.severity),
                labelKey: f.key,
                detail: f.detail
            )
        }

        if (serverArchitecture == .peerToPeer || serverArchitecture == .hybrid), let nat = natSnapshot {
            if !findings.contains(where: { $0.kind == .natTopology }) {
                let sev: NetworkFinding.Severity = nat.natType.isMultiplayerRestricted ? .negative : .positive
                findings.append(NetworkFinding(
                    kind: .natTopology,
                    severity: sev,
                    labelKey: nat.natType.titleKey,
                    detail: nat.natType.shortLabel
                ))
            }
        }

        let isLoadMaterial = (loadImpact?.tier == .material || loadImpact?.tier == .severe)
        let metricsToUse = deepCheckMetrics ?? DeepCheckMetrics(
            rest: qualityResult.metrics,
            load: nil,
            loadImpact: loadImpact
        )

        var stabilityRatio: Double = Double(response.score ?? 50) / 100.0
        if verdict == .ready { stabilityRatio = max(0.85, stabilityRatio) }
        else if verdict == .caution { stabilityRatio = min(0.75, max(0.50, stabilityRatio)) }
        else if verdict == .notReady { stabilityRatio = min(0.45, stabilityRatio) }

        let stabilitySummaryKey: String
        switch verdict {
        case .ready: stabilitySummaryKey = "game_readiness.stability.ready_summary"
        case .caution: stabilitySummaryKey = "game_readiness.stability.caution_summary"
        case .notReady: stabilitySummaryKey = "game_readiness.stability.not_ready_summary"
        case .inconclusive: stabilitySummaryKey = "game_readiness.stability.inconclusive"
        }

        return GameReadinessEvaluation(
            verdict: verdict,
            headlineKey: response.headlineKey,
            subtitleKey: response.subtitleKey,
            stabilityRatio: stabilityRatio,
            stabilitySummaryKey: stabilitySummaryKey,
            findings: findings,
            pingMs: response.rest.p50Milliseconds,
            jitterMs: response.rest.jitterMilliseconds,
            packetLossPercentage: response.rest.packetLossPercentage,
            isUnderLoadAffected: isLoadMaterial,
            worstSpikeMs: response.rest.worstSpikeMilliseconds,
            score: response.score,
            metrics: metricsToUse
        )
    }

    public static func localizeRecommendation(key: String) -> ActionableRecommendation {
        switch key.uppercased() {
        case "APPROACH_ROUTER":
            return ActionableRecommendation(
                priority: 1,
                title: "Aproxime-se do Roteador",
                instruction: "Reduza a distância física ou obstáculos para eliminar a oscilação do sinal local.",
                evidenceBadge: "Wi-Fi Local"
            )
        case "SWITCH_TO_5GHZ", "USE_CABLE_OR_5GHZ":
            return ActionableRecommendation(
                priority: 1,
                title: "Troque para Wi-Fi 5 GHz",
                instruction: "Conecte-se na frequência 5 GHz para escapar da interferência de canais vizinhos.",
                evidenceBadge: "2.4 GHz Detectado"
            )
        case "AVOID_RANKED":
            return ActionableRecommendation(
                priority: 1,
                title: "Evite Partidas Ranqueadas",
                instruction: "A rota externa da operadora apresenta perda de pacotes e causará travamentos.",
                evidenceBadge: "Rota Externa"
            )
        case "PAUSE_DOWNLOADS":
            return ActionableRecommendation(
                priority: 2,
                title: "Pause Downloads e Streaming",
                instruction: "Limite o uso simultâneo da internet para impedir picos de latência na partida.",
                evidenceBadge: "Saturação sob Carga"
            )
        case "CHECK_LOCAL_INTERFERENCE":
            return ActionableRecommendation(
                priority: 2,
                title: "Verifique Interferências Locais",
                instruction: "Afaste dispositivos sem fio e fontes de interferência eletromagnética do roteador.",
                evidenceBadge: "Picos Recorrentes"
            )
        case "ENABLE_UPNP", "ENABLE_UPNP_OR_PORT_FORWARD":
            return ActionableRecommendation(
                priority: 2,
                title: "Habilite UPnP no Roteador",
                instruction: "Libere as portas automáticas no roteador para normalizar a conexão em partidas multiplayer.",
                evidenceBadge: "NAT Restrito"
            )
        case "ROUTE_INSTABILITY", "CONTACT_ISP":
            return ActionableRecommendation(
                priority: 2,
                title: "Instabilidade de Rota na Operadora",
                instruction: "Contate seu provedor para verificar o roteamento caso os micro-travamentos persistam.",
                evidenceBadge: "Rota Desordenada"
            )
        default:
            return ActionableRecommendation(
                priority: 7,
                title: "actionable_recommendation.generic.title",
                instruction: "actionable_recommendation.generic.instruction",
                evidenceBadge: nil
            )
        }
    }
}

// MARK: - Direct Native Sample Quality Watchdog Bridge

public enum KmpSampleQualityBridge {
    nonisolated(unsafe) private static let evaluatorClass: AnyObject? = NSClassFromString("LCESampleQualityEvaluator")
    private static let sampleClass = NSClassFromString("LCEProbeSample") as? NSObject.Type
    nonisolated(unsafe) private static let outcomeClass: AnyObject? = NSClassFromString("LCEProbeOutcome")
    private static let doubleClass = NSClassFromString("LCEDouble") as? NSObject.Type
    private static let intClass = NSClassFromString("LCEInt") as? NSObject.Type

    nonisolated(unsafe) private static let sharedEvaluator: AnyObject? = {
        guard let cls = evaluatorClass else { return nil }
        return cls.value(forKey: "shared") as AnyObject?
    }()

    nonisolated(unsafe) private static let outcomeReceived: AnyObject? = outcomeClass?.value(forKey: "received") as AnyObject?
    nonisolated(unsafe) private static let outcomeTimeout: AnyObject? = outcomeClass?.value(forKey: "timeout") as AnyObject?
    nonisolated(unsafe) private static let outcomeTransportError: AnyObject? = outcomeClass?.value(forKey: "transportError") as AnyObject?
    nonisolated(unsafe) private static let outcomeInvalidResponse: AnyObject? = outcomeClass?.value(forKey: "invalidResponse") as AnyObject?

    private static func toKmpOutcome(_ outcome: ProbeOutcome) -> AnyObject? {
        switch outcome {
        case .received: return outcomeReceived
        case .timeout: return outcomeTimeout
        case .transportError: return outcomeTransportError
        case .invalidResponse: return outcomeInvalidResponse
        }
    }

    private static func toKmpSample(_ sample: ProbeSample) -> AnyObject? {
        guard let sampleClass else { return nil }
        let outcomeObj = toKmpOutcome(sample.outcome)
        let rttObj: AnyObject? = sample.roundTripMilliseconds.flatMap { rtt in
            (doubleClass as? NSNumber.Type)?.init(value: rtt) ?? NSNumber(value: rtt)
        }
        let arrivalObj: AnyObject? = sample.arrivalIndex.flatMap { idx in
            (intClass as? NSNumber.Type)?.init(value: Int32(idx)) ?? NSNumber(value: Int32(idx))
        }

        let alloced = sampleClass.perform(NSSelectorFromString("alloc")).takeUnretainedValue()
        let selector = NSSelectorFromString("initWithSequence:roundTripMilliseconds:outcome:arrivalIndex:")
        guard let method = alloced.method(for: selector) else { return nil }
        typealias InitFunc = @convention(c) (AnyObject, Selector, Int32, AnyObject?, AnyObject?, AnyObject?) -> AnyObject
        let function = unsafeBitCast(method, to: InitFunc.self)
        return function(alloced, selector, Int32(sample.sequence), rttObj, outcomeObj, arrivalObj)
    }

    public static func assess(_ samples: [ProbeSample]) -> SampleQualityAssessment {
        guard let sharedEvaluator else {
            return SampleQualityAssessment(
                status: .normal,
                consecutiveTimeouts: 0,
                earlyLossPercentage: 0.0,
                ruleVersion: "sample-quality-v2"
            )
        }

        let kmpSamples = samples.compactMap { toKmpSample($0) }
        let selector = NSSelectorFromString("assessSamples:")
        guard let method = (sharedEvaluator as AnyObject).method(for: selector) else {
            return SampleQualityAssessment(status: .normal, consecutiveTimeouts: 0, earlyLossPercentage: 0.0)
        }
        typealias AssessFunc = @convention(c) (AnyObject, Selector, NSArray) -> AnyObject
        let function = unsafeBitCast(method, to: AssessFunc.self)
        let rawAssessment = function(sharedEvaluator, selector, kmpSamples as NSArray)

        let shouldAbort = (rawAssessment.value(forKey: "shouldAbort") as? Bool) ?? false
        let consecutiveTimeouts = (rawAssessment.value(forKey: "consecutiveTimeouts") as? Int32) ?? 0
        let earlyLoss = (rawAssessment.value(forKey: "earlyLossPercentage") as? Double) ?? 0.0
        let ruleVer = (rawAssessment.value(forKey: "ruleVersion") as? String) ?? "sample-quality-v2"
        let abortReasonObj = rawAssessment.value(forKey: "abortReason") as AnyObject?
        let abortReasonName = (abortReasonObj?.value(forKey: "name") as? String)

        let status: SampleQualityAssessment.Status
        if shouldAbort {
            let reason: InconclusiveReason = (abortReasonName == "POOR_SAMPLE_QUALITY")
                ? .poorSampleQuality
                : .insufficientUDPResponses
            status = .shouldAbort(reason: reason)
        } else {
            status = .normal
        }

        return SampleQualityAssessment(
            status: status,
            consecutiveTimeouts: Int(consecutiveTimeouts),
            earlyLossPercentage: earlyLoss,
            ruleVersion: ruleVer
        )
    }
}
