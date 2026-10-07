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

/// Avaliador determinístico de Causa Raiz (Puro Domínio, RFC e Decisão 75 / Architecture Plan §3.2).
public enum RootCauseEvaluator {
    public static let version = "root-cause-v1"

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

        // 1. Regra Gateway / Wi-Fi Local (Architecture Plan §3.2 regra 1):
        // Se observável e (RTT > 15ms OU perda local > 2%)
        let isLocalCulprit = gwObservable && ((gwRTT ?? 0.0) > 15.0 || gwLoss > 2.0)

        // 2. Regra Operadora / Rota Externa (Architecture Plan §3.2 regra 2):
        // Gateway limpo (<= 5ms e 0% perda) OU não observável, mas WAN tem perda > 1% ou jitter > 15ms
        let isWanUnstable = wanLoss > 1.0 || (wanJitter ?? 0.0) > 15.0
        let isGatewayPristine = gwObservable && ((gwRTT ?? 0.0) <= 5.0 && gwLoss == 0.0)

        let culprit: CulpritEntity
        if isLocalCulprit {
            culprit = .localWiFi
        } else if (isGatewayPristine || !gwObservable) && isWanUnstable {
            culprit = .internetProvider
        } else if platformDegraded && !isWanUnstable {
            // Regra 3: Plataforma degradada com rede limpa
            culprit = .gamePlatform
        } else if isGatewayPristine && !isWanUnstable && !platformDegraded {
            // Regra 4: Tudo Limpo (gateway pristino <= 5ms/0% perda, WAN estável e plataforma operacional)
            culprit = .allClear
        } else {
            // Regra 5: Ambiguidade / Limite Intermediário (ex: gateway 5-15ms com WAN instável, ou gateway unobservable)
            // Integridade diagnóstica (Decisão 50/75): sem evidência conclusiva, não emite nota/conclusão falsa
            culprit = .unobservable
        }

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
