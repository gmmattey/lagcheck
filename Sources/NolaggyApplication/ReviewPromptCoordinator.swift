import Foundation
import NolaggyDomain

/// Interface de persistência desacoplada para o estado do prompt de review (Decisão 77).
public protocol ReviewPromptStore: Sendable {
    func loadState() -> ReviewPromptState
    func saveState(_ state: ReviewPromptState)
}

/// Implementação padrão de persistência via UserDefaults.
public final class UserDefaultsReviewPromptStore: ReviewPromptStore, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let key: String

    public init(
        userDefaults: UserDefaults = .standard,
        key: String = "com.lagcheck.review_prompt_state"
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    public func loadState() -> ReviewPromptState {
        guard let data = userDefaults.data(forKey: key),
              let state = try? JSONDecoder().decode(ReviewPromptState.self, from: data) else {
            return ReviewPromptState()
        }
        return state
    }

    public func saveState(_ state: ReviewPromptState) {
        if let data = try? JSONEncoder().encode(state) {
            userDefaults.set(data, forKey: key)
        }
    }
}

/// Implementação em memória para testes unitários ou isolamento.
public final class InMemoryReviewPromptStore: ReviewPromptStore, @unchecked Sendable {
    private var state: ReviewPromptState
    private let lock = NSLock()

    public init(initialState: ReviewPromptState = ReviewPromptState()) {
        self.state = initialState
    }

    public func loadState() -> ReviewPromptState {
        lock.lock()
        defer { lock.unlock() }
        return state
    }

    public func saveState(_ state: ReviewPromptState) {
        lock.lock()
        defer { lock.unlock() }
        self.state = state
    }
}

/// Coordenador de aplicação para gerenciamento de review na loja (Decisão 77).
public final class ReviewPromptCoordinator: @unchecked Sendable {
    private let store: ReviewPromptStore
    private let appVersionProvider: @Sendable () -> String
    private let lock = NSLock()

    public init(
        store: ReviewPromptStore = UserDefaultsReviewPromptStore(),
        appVersionProvider: @escaping @Sendable () -> String = {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        }
    ) {
        self.store = store
        self.appVersionProvider = appVersionProvider
    }

    /// Registra a conclusão de uma medição com seu veredito.
    /// Retorna `true` apenas se a política autorizar a exibição imediata do prompt.
    @discardableResult
    public func recordMeasurementCompleted(
        verdict: GameReadinessVerdict,
        now: Date = Date()
    ) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        var state = store.loadState()
        if verdict == .ready {
            state.successfulReadyChecksCount += 1
        }

        let currentVersion = appVersionProvider()
        let shouldPrompt = ReviewPromptPolicy.shouldPrompt(
            verdict: verdict,
            state: state,
            currentAppVersion: currentVersion,
            currentDate: now
        )

        store.saveState(state)
        return shouldPrompt
    }

    /// Registra que o diálogo de review foi de fato apresentado ao usuário.
    /// Evita consumir o cooldown e limite de versão prematuramente caso a tela seja fechada antes.
    public func recordPromptPresented(now: Date = Date()) {
        lock.lock()
        defer { lock.unlock() }

        var state = store.loadState()
        state.lastPromptedDate = now
        state.lastPromptedVersion = appVersionProvider()
        store.saveState(state)
    }

    /// Consulta o estado atual (para telemetria ou inspeção).
    public func currentState() -> ReviewPromptState {
        lock.lock()
        defer { lock.unlock() }
        return store.loadState()
    }
}
