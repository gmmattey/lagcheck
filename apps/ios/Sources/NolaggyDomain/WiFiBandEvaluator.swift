import Foundation

/// Motor puro e determinístico para avaliação da estabilidade de radiofrequência e inferência de banda Wi-Fi.
public enum WiFiBandEvaluator {

    public struct Thresholds: Sendable {
        public static let fastGatewayMedianRTTMaxMs: Double = 15.0
        public static let fastGatewayJitterMaxMs: Double = 8.0
        public static let highJitterContentionMs: Double = 22.0
        public static let minimumGatewayRTTForContentionMs: Double = 20.0
        public static let tailRatioContentionMin: Double = 1.6
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

        // 2. SSID, RTT e jitter não são evidência de frequência/canal no iOS.
        // O nome escolhido pelo roteador não confirma a rádio em uso.

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
            // Contenção severa no enlace local. Não confirma 2.4 GHz.
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

        // 6. Se o enlace local foi medido e não apresentou anomalias de contenção
        if telemetry.gatewayRTTMedianMs != nil {
            return makeResult(
                diagnostic: .stableWiFi,
                confidence: .medium,
                telemetry: telemetry
            )
        }

        // 7. Sem SSID explícito e sem medição local válida, não se afirma frequência com confiança (Decisão 50/55)
        return makeResult(
            diagnostic: .stableWiFi,
            confidence: .none,
            telemetry: telemetry
        )
    }

    // MARK: - Auxiliares de Padrão de SSID

    // Mantidos para compatibilidade de importação, mas não são usados para
    // afirmar frequência: iOS não entrega esse dado por API pública.

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
