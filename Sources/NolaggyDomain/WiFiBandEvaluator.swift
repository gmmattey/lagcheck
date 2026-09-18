import Foundation

/// Motor puro e determinístico para avaliação da estabilidade de radiofrequência e inferência de banda Wi-Fi.
public enum WiFiBandEvaluator {

    public struct Thresholds: Sendable {
        public static let fastGatewayMedianRTTMaxMs: Double = 2.5
        public static let fastGatewayJitterMaxMs: Double = 1.5
        public static let highJitterContentionMs: Double = 15.0
        public static let minimumGatewayRTTForContentionMs: Double = 6.0
        public static let tailRatioContentionMin: Double = 1.45
        public static let severeLoadDeltaP50MinMs: Double = 35.0
        public static let minimumSamplesRequired: Int = 3
    }

    /// Avalia a telemetria fornecida e produz um diagnóstico objetivo com chaves de apresentação localizadas.
    public static func evaluate(telemetry: WiFiLocalTelemetry) -> WiFiBandDiagnosticResult {
        // 1. Gating obrigatório de interface: apenas redes Wi-Fi podem ser avaliadas.
        guard telemetry.isWiFi else {
            return makeResult(
                diagnostic: .inconclusive(reason: .nonWiFiInterface),
                confidence: .none,
                telemetry: telemetry
            )
        }

        // 2. Análise sintática inequívoca de SSID (se disponível)
        if let ssid = telemetry.detectedSSID {
            if hasExplicit5GHzPattern(ssid) {
                return makeResult(
                    diagnostic: .confirmed5GHzOrHigher(ssid: ssid),
                    confidence: .high,
                    telemetry: telemetry
                )
            }
            if hasExplicit24GHzPattern(ssid) {
                return makeResult(
                    diagnostic: .confirmed24GHz(ssid: ssid),
                    confidence: .high,
                    telemetry: telemetry
                )
            }
        }

        // 3. Verificação de resposta do gateway (se sondado)
        if telemetry.plannedSampleCount > 0 && telemetry.validSampleCount == 0 {
            return makeResult(
                diagnostic: .inconclusive(reason: .gatewayUnresponsive),
                confidence: .none,
                telemetry: telemetry
            )
        }

        // 4. Se houver amostras insuficientes para análise estatística
        if telemetry.plannedSampleCount > 0 && telemetry.validSampleCount < Thresholds.minimumSamplesRequired {
            return makeResult(
                diagnostic: .inconclusive(reason: .insufficientSamples),
                confidence: .none,
                telemetry: telemetry
            )
        }

        // 5. Avaliação do primeiro salto (gateway local)
        if let localJitter = telemetry.gatewayJitterMs, let localMedian = telemetry.gatewayRTTMedianMs {
            // Contenção severa ou assinatura de 2.4 GHz ruidoso
            let isHighJitter = localJitter > Thresholds.highJitterContentionMs
            let isAsymmetricTail = (telemetry.tailRatioP95P50 ?? 1.0) >= Thresholds.tailRatioContentionMin && localMedian >= Thresholds.minimumGatewayRTTForContentionMs

            if isHighJitter || isAsymmetricTail {
                return makeResult(
                    diagnostic: .suspected24GHzContention,
                    confidence: .medium,
                    telemetry: telemetry
                )
            }

            // Assinatura de enlace rápido (típico de 5 GHz / 6 GHz próximo)
            if localMedian <= Thresholds.fastGatewayMedianRTTMaxMs && localJitter <= Thresholds.fastGatewayJitterMaxMs {
                return makeResult(
                    diagnostic: .stableWiFi,
                    confidence: .high,
                    telemetry: telemetry
                )
            }
        }

        // 6. Avaliação complementar sob carga (Deep Check airtime starvation)
        if let loadDelta = telemetry.loadDeltaP50Ms, loadDelta >= Thresholds.severeLoadDeltaP50MinMs {
            return makeResult(
                diagnostic: .suspected24GHzContention,
                confidence: .medium,
                telemetry: telemetry
            )
        }

        // 7. Enlace estável por padrão caso não haja indicativo de contenção
        return makeResult(
            diagnostic: .stableWiFi,
            confidence: .medium,
            telemetry: telemetry
        )
    }

    // MARK: - Auxiliares de Padrão de SSID

    public static func hasExplicit5GHzPattern(_ ssid: String) -> Bool {
        let pattern = #"(?i)(?:^|[-_\s])(?:5G|5GHz|5\.0GHz|5_GHz|6G|6GHz|6E|WiFi6|WiFi7)(?:$|[-_\s])|(?i)(?:5G|5GHz|5\.0GHz|5_GHz|6G|6GHz|6E|WiFi6|WiFi7)$"#
        return ssid.range(of: pattern, options: .regularExpression) != nil
    }

    public static func hasExplicit24GHzPattern(_ ssid: String) -> Bool {
        let pattern = #"(?i)(?:^|[-_\s])(?:2\.4G|2\.4GHz|2G|2_4GHz)(?:$|[-_\s])|(?i)(?:2\.4G|2\.4GHz|2G|2_4GHz)$"#
        return ssid.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Mapeamento de Chaves de Localização

    private static func makeResult(
        diagnostic: WiFiBandDiagnostic,
        confidence: WiFiBandAssessmentConfidence,
        telemetry: WiFiLocalTelemetry
    ) -> WiFiBandDiagnosticResult {
        switch diagnostic {
        case .confirmed24GHz:
            return WiFiBandDiagnosticResult(
                diagnostic: diagnostic,
                confidence: confidence,
                telemetry: telemetry,
                titleKey: "network.band.confirmed_24.title",
                messageKey: "network.band.confirmed_24.message",
                actionKey: "network.band.action.settings"
            )
        case .confirmed5GHzOrHigher:
            return WiFiBandDiagnosticResult(
                diagnostic: diagnostic,
                confidence: confidence,
                telemetry: telemetry,
                titleKey: "network.band.confirmed_5.title",
                messageKey: "network.band.confirmed_5.message",
                actionKey: nil
            )
        case .suspected24GHzContention:
            return WiFiBandDiagnosticResult(
                diagnostic: diagnostic,
                confidence: confidence,
                telemetry: telemetry,
                titleKey: "network.band.suspected_24.title",
                messageKey: "network.band.suspected_24.message",
                actionKey: "network.band.action.deep_check"
            )
        case .stableWiFi:
            return WiFiBandDiagnosticResult(
                diagnostic: diagnostic,
                confidence: confidence,
                telemetry: telemetry,
                titleKey: "network.band.stable.title",
                messageKey: "network.band.stable.message",
                actionKey: nil
            )
        case .inconclusive:
            return WiFiBandDiagnosticResult(
                diagnostic: diagnostic,
                confidence: confidence,
                telemetry: telemetry,
                titleKey: "network.band.inconclusive.title",
                messageKey: "network.band.inconclusive.message",
                actionKey: nil
            )
        }
    }
}
