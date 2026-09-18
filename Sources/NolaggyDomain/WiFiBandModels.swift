import Foundation

/// Razão pela qual a avaliação de banda Wi-Fi não pôde produzir um resultado conclusivo.
public enum WiFiBandInconclusiveReason: String, Codable, CaseIterable, Hashable, Sendable {
    case nonWiFiInterface
    case gatewayUnresponsive
    case insufficientSamples
}

/// Nível de confiança da estimativa de banda.
public enum WiFiBandAssessmentConfidence: String, Codable, CaseIterable, Hashable, Sendable {
    case high
    case medium
    case none
}

/// Diagnóstico estruturado da banda Wi-Fi e sua estabilidade física.
public enum WiFiBandDiagnostic: Codable, Hashable, Sendable {
    /// 2.4 GHz identificado com certeza sintática inequívoca pelo SSID.
    case confirmed24GHz(ssid: String?)
    /// 5 GHz ou 6 GHz identificado com certeza sintática inequívoca pelo SSID.
    case confirmed5GHzOrHigher(ssid: String?)
    /// Instabilidade e contenção de canal características de 2.4 GHz ou interferência severa.
    case suspected24GHzContention
    /// Conexão sem fio rápida, com baixo jitter local e sem sinais de contenção.
    case stableWiFi
    /// Diagnóstico inconclusivo por ausência de resposta do roteador, rede móvel ou dados insuficientes.
    case inconclusive(reason: WiFiBandInconclusiveReason)

    public var isSuspectOrConfirmed24GHz: Bool {
        switch self {
        case .confirmed24GHz, .suspected24GHzContention:
            return true
        case .confirmed5GHzOrHigher, .stableWiFi, .inconclusive:
            return false
        }
    }
}

/// Telemetria agregada da conexão local com o roteador (primeiro salto) e medições complementares.
public struct WiFiLocalTelemetry: Codable, Hashable, Sendable {
    public let gatewayRTTMedianMs: Double?
    public let gatewayJitterMs: Double?
    public let tailRatioP95P50: Double?
    public let loadDeltaP50Ms: Double?
    public let validSampleCount: Int
    public let plannedSampleCount: Int
    public let detectedSSID: String?
    public let isWiFi: Bool

    public init(
        gatewayRTTMedianMs: Double? = nil,
        gatewayJitterMs: Double? = nil,
        tailRatioP95P50: Double? = nil,
        loadDeltaP50Ms: Double? = nil,
        validSampleCount: Int = 0,
        plannedSampleCount: Int = 0,
        detectedSSID: String? = nil,
        isWiFi: Bool = true
    ) {
        self.gatewayRTTMedianMs = gatewayRTTMedianMs
        self.gatewayJitterMs = gatewayJitterMs
        self.tailRatioP95P50 = tailRatioP95P50
        self.loadDeltaP50Ms = loadDeltaP50Ms
        self.validSampleCount = validSampleCount
        self.plannedSampleCount = plannedSampleCount
        self.detectedSSID = detectedSSID
        self.isWiFi = isWiFi
    }
}

/// Resultado interpretado da análise de frequência Wi-Fi, contendo chaves de localização e telemetria.
public struct WiFiBandDiagnosticResult: Codable, Hashable, Sendable {
    public let diagnostic: WiFiBandDiagnostic
    public let confidence: WiFiBandAssessmentConfidence
    public let telemetry: WiFiLocalTelemetry
    public let titleKey: String
    public let messageKey: String
    public let actionKey: String?

    public init(
        diagnostic: WiFiBandDiagnostic,
        confidence: WiFiBandAssessmentConfidence,
        telemetry: WiFiLocalTelemetry,
        titleKey: String,
        messageKey: String,
        actionKey: String? = nil
    ) {
        self.diagnostic = diagnostic
        self.confidence = confidence
        self.telemetry = telemetry
        self.titleKey = titleKey
        self.messageKey = messageKey
        self.actionKey = actionKey
    }
}
