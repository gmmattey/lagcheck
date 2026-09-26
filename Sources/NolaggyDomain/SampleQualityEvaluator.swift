import Foundation

/// Diagnóstico estruturado da qualidade e densidade da amostra UDP (Decisão 55).
public struct SampleQualityAssessment: Equatable, Sendable {
    public enum Status: Equatable, Sendable {
        /// A amostragem está com qualidade aceitável e pode continuar.
        case normal
        /// A amostragem apresenta instabilidade ou perda extrema e deve ser abortada imediatamente.
        case shouldAbort(reason: InconclusiveReason)
    }

    public let status: Status
    public let consecutiveTimeouts: Int
    public let earlyLossPercentage: Double
    public let ruleVersion: String

    public init(
        status: Status,
        consecutiveTimeouts: Int,
        earlyLossPercentage: Double,
        ruleVersion: String = SampleQualityEvaluator.ruleVersion
    ) {
        self.status = status
        self.consecutiveTimeouts = consecutiveTimeouts
        self.earlyLossPercentage = earlyLossPercentage
        self.ruleVersion = ruleVersion
    }
}

/// Watchdog determinístico e puro para integridade e densidade da amostragem (Decisão 55).
/// Evita que conexões inoperantes forcem o jogador a aguardar 15 segundos desnecessariamente.
public enum SampleQualityEvaluator {
    public static let ruleVersion = "sample-quality-v1"

    /// Avalia a sequência de amostras recebidas até o momento na ordem de sequência de envio.
    public static func assess(samples: [ProbeSample]) -> SampleQualityAssessment {
        guard !samples.isEmpty else {
            return SampleQualityAssessment(
                status: .normal,
                consecutiveTimeouts: 0,
                earlyLossPercentage: 0.0
            )
        }

        // Ordenação temporal pela sequência de envio
        let sorted = samples.sorted(by: { $0.sequence < $1.sequence })

        // 1. Contagem de timeouts consecutivos no final da série (trailing timeouts)
        var trailingTimeouts = 0
        for sample in sorted.reversed() {
            if sample.outcome == .timeout || sample.outcome == .transportError || sample.outcome == .invalidResponse {
                trailingTimeouts += 1
            } else {
                break
            }
        }

        let nonReceivedCount = sorted.filter { $0.outcome != .received }.count
        let lossPercentage = Double(nonReceivedCount) / Double(sorted.count) * 100.0

        // 2. Aborto Precoce por Conexão Morta:
        // Se houver >= 4 timeouts consecutivos dentro dos primeiros 6 probes enviados
        if sorted.count <= 6 && trailingTimeouts >= 4 {
            return SampleQualityAssessment(
                status: .shouldAbort(reason: .poorSampleQuality),
                consecutiveTimeouts: trailingTimeouts,
                earlyLossPercentage: lossPercentage
            )
        }

        // 3. Taxa de Perda Inicial Excessiva:
        // Se houver >= 70% de perda nos primeiros 10 probes enviados (mínimo de 6 probes para relevância estatística)
        if sorted.count >= 6 && sorted.count <= 10 && lossPercentage >= 70.0 {
            return SampleQualityAssessment(
                status: .shouldAbort(reason: .poorSampleQuality),
                consecutiveTimeouts: trailingTimeouts,
                earlyLossPercentage: lossPercentage
            )
        }

        // 4. Sequência Tardia de Perdas (Desconexão Súbita):
        // Se em qualquer momento houver >= 6 timeouts consecutivos ininterruptos
        if trailingTimeouts >= 6 {
            return SampleQualityAssessment(
                status: .shouldAbort(reason: .poorSampleQuality),
                consecutiveTimeouts: trailingTimeouts,
                earlyLossPercentage: lossPercentage
            )
        }

        return SampleQualityAssessment(
            status: .normal,
            consecutiveTimeouts: trailingTimeouts,
            earlyLossPercentage: lossPercentage
        )
    }
}
