import Foundation

/// Estado persistido para avaliação de disparo do prompt de review (Decisão 77).
public struct ReviewPromptState: Equatable, Sendable, Codable {
    public var successfulReadyChecksCount: Int
    public var lastPromptedDate: Date?
    public var lastPromptedVersion: String?

    public init(
        successfulReadyChecksCount: Int = 0,
        lastPromptedDate: Date? = nil,
        lastPromptedVersion: String? = nil
    ) {
        self.successfulReadyChecksCount = successfulReadyChecksCount
        self.lastPromptedDate = lastPromptedDate
        self.lastPromptedVersion = lastPromptedVersion
    }
}

/// Política de negócio pura para elegibilidade de prompt de avaliação da loja (Decisão 77).
/// Garante momento de delight estrito (.ready), contagem mínima e proteção contra fadiga.
public enum ReviewPromptPolicy {
    /// Mínimo de medições completas com veredito positivo para demonstrar valor.
    public static let requiredSuccessfulReadyChecks: Int = 3

    /// Intervalo de cooldown entre prompts para evitar fadiga do usuário (90 dias).
    public static let cooldownIntervalSeconds: TimeInterval = 90 * 24 * 3600

    public static func shouldPrompt(
        verdict: GameReadinessVerdict,
        state: ReviewPromptState,
        currentAppVersion: String,
        currentDate: Date = Date()
    ) -> Bool {
        // 1. Momento de delight obrigatório: estritamente .ready (Pronto para Ranked)
        guard verdict == .ready else { return false }

        // 2. Prova de valor: acúmulo mínimo de 3 medições bem-sucedidas
        guard state.successfulReadyChecksCount >= requiredSuccessfulReadyChecks else { return false }

        // 3. Proteção de versão: no máximo 1 solicitação por versão/build do app
        if let lastVersion = state.lastPromptedVersion, lastVersion == currentAppVersion {
            return false
        }

        // 4. Cooldown de 90 dias entre solicitações
        if let lastDate = state.lastPromptedDate, currentDate.timeIntervalSince(lastDate) < cooldownIntervalSeconds {
            return false
        }

        return true
    }
}
