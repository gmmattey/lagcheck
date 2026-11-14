import Foundation

/// Entidade causadora primária isolada de oscilação ou degradação na conexão.
/// Decisão 75 (Fase 2 / Item 5) — Preserva a integridade diagnóstica (Decisão 50).
public enum CulpritEntity: String, Codable, CaseIterable, Sendable {
    /// Roteador local / Wi-Fi doméstico (RTT gateway > 15ms ou perda local > 2%).
    case localWiFi
    /// Provedor de Internet / Rota externa (Gateway limpo <= 5ms/0% perda, mas WAN com perda > 1% ou jitter > 15ms).
    case internetProvider
    /// Servidores centrais da publicadora/plataforma (CDN de status oficial em alerta, com rede limpa).
    case gamePlatform
    /// Todos os probes observados com excelente estabilidade e sem perda.
    case allClear
    /// Enlace não observável (firewall bloqueando probe local) sem evidência conclusiva.
    case unobservable
}

/// Relatório imutável de evidências do Isolador de Causa Raiz ("De Quem é a Culpa?").
/// Modelo puro de domínio para auditoria e apresentação da telemetria de rede.
public struct RootCauseIsolationReport: Codable, Equatable, Sendable {
    public let primaryCulprit: CulpritEntity
    
    // Probe 1: Gateway Local (Wi-Fi/LAN)
    public let localGatewayRTTMs: Double?
    public let localGatewayPacketLoss: Double
    public let localGatewayObservable: Bool
    
    // Probe 2: Rota Operadora / WAN
    public let wanMedianRTTMs: Double?
    public let wanJitterMs: Double?
    public let wanPacketLoss: Double
    
    // Probe 3: Status da Plataforma / Jogo
    public let platformDegraded: Bool
    public let platformServiceName: String?
    
    public let evaluatedAt: Date

    public init(
        primaryCulprit: CulpritEntity,
        localGatewayRTTMs: Double?,
        localGatewayPacketLoss: Double,
        localGatewayObservable: Bool,
        wanMedianRTTMs: Double?,
        wanJitterMs: Double?,
        wanPacketLoss: Double,
        platformDegraded: Bool,
        platformServiceName: String?,
        evaluatedAt: Date = Date()
    ) {
        self.primaryCulprit = primaryCulprit
        self.localGatewayRTTMs = localGatewayRTTMs
        self.localGatewayPacketLoss = localGatewayPacketLoss
        self.localGatewayObservable = localGatewayObservable
        self.wanMedianRTTMs = wanMedianRTTMs
        self.wanJitterMs = wanJitterMs
        self.wanPacketLoss = wanPacketLoss
        self.platformDegraded = platformDegraded
        self.platformServiceName = platformServiceName
        self.evaluatedAt = evaluatedAt
    }
}

/// Fachada fina do isolamento de causa raiz no motor compartilhado (Decisões 50, 75, 134 e 135).
public enum RootCauseEvaluator {
    public static var version: String {
        EnginePolicyProvider.policy.ruleVersions["BATTLE_ROYALE_COMPETITIVE"]?["rootCause"] ?? "root-cause-v2"
    }

    /// Avalia os 3 probes isoladamente e retorna a entidade responsável com evidência matemática.
    public static func evaluate(
        gatewayOutcome: GatewayProbeOutcome,
        wanMetrics: QualityMetrics,
        platformDegraded: Bool,
        platformServiceName: String? = nil,
        now: Date = Date()
    ) -> RootCauseIsolationReport {
        let gwObservable = (gatewayOutcome != .unobservable)
        let gwRTT = gatewayOutcome.rttMs
        let gwLoss: Double
        if case .degraded(_, let loss) = gatewayOutcome {
            gwLoss = loss
        } else {
            gwLoss = 0.0
        }

        let wanRTT = wanMetrics.p50Milliseconds
        let wanJitter = wanMetrics.jitterMilliseconds
        let wanLoss = wanMetrics.packetLossPercentage

        // Regra no motor compartilhado (root-cause-v2): culpar a operadora exige roteador impecável;
        // roteador não observável nunca culpa ninguém (Decisões 50 e 135, item 7).
        let culprit = LagCheckEngineBridge.rootCauseCulprit(
            gatewayOutcome: gatewayOutcome,
            wanMetrics: wanMetrics,
            platformDegraded: platformDegraded,
            platformServiceName: platformServiceName
        ).culprit

        return RootCauseIsolationReport(
            primaryCulprit: culprit,
            localGatewayRTTMs: gwRTT,
            localGatewayPacketLoss: gwLoss,
            localGatewayObservable: gwObservable,
            wanMedianRTTMs: wanRTT,
            wanJitterMs: wanJitter,
            wanPacketLoss: wanLoss,
            platformDegraded: platformDegraded,
            platformServiceName: platformServiceName,
            evaluatedAt: now
        )
    }
}
