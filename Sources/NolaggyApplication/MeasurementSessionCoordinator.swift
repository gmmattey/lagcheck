import Foundation
import NolaggyDomain

public struct MeasurementSession: Equatable, Sendable {
    public let id: UUID
    public let resolvedContext: ResolvedMeasurementContext

    public var context: GameContext { resolvedContext.context }

    public init(id: UUID = UUID(), resolvedContext: ResolvedMeasurementContext) {
        self.id = id
        self.resolvedContext = resolvedContext
    }

    /// Somente para fakes de teste que não precisam resolver um catálogo real.
    public init(id: UUID = UUID(), context: GameContext) {
        self.id = id
        self.resolvedContext = ResolvedMeasurementContext(
            context: context,
            catalogVersion: "test",
            profileID: .battleRoyaleCompetitive,
            regionID: "test-region",
            destination: try! ProbeDestination(host: "example.invalid", port: 7770),
            strategy: .genericRegion,
            confidence: .medium
        )
    }
}

public struct MeasurementEndpoint: Equatable, Sendable {
    public let host: String
    public let port: UInt16
    public let protocolKind: ProbeProtocolKind

    public init(host: String, port: UInt16, protocolKind: ProbeProtocolKind) {
        self.host = host
        self.port = port
        self.protocolKind = protocolKind
    }
}

/// O plano é fixo no piloto. O transporte não tem liberdade para ampliar a janela ou usar fallback.
public struct QuickCheckPlan: Equatable, Sendable {
    public let endpoint: MeasurementEndpoint

    public init(endpoint: MeasurementEndpoint) {
        self.endpoint = endpoint
    }
}

public protocol MeasurementTransport: Sendable {
    /// Entrega somente amostras já correlacionadas. Não calcula score nem faz persistência.
    func collect(
        session: MeasurementSession,
        plan: QuickCheckPlan,
        onSample: @escaping @Sendable (ProbeSample) async -> Void
    ) async -> [ProbeSample]
}

/// O adaptador do iOS só publica mudanças relevantes; o coordenador invalida a sessão atual.
public protocol NetworkPathObserver: Sendable {
    func pathChanges() -> AsyncStream<Void>
}

public enum MeasurementCancellationReason: Equatable, Sendable {
    case userInitiated
    case appEnteredBackground
    case networkPathChanged
}

public enum MeasurementSessionState: Equatable, Sendable {
    case idle
    case measuring(MeasurementSession)
    case completed(MeasurementSession, MeasurementEvaluation, MeasurementHistoryEntry?)
    case cancelled(MeasurementSession, MeasurementCancellationReason)
}

public enum MeasurementSessionError: Error, Equatable, Sendable {
    case alreadyActive
}

/// Leituras recebidas até agora. Elas existem apenas durante a sessão e não são uma avaliação.
public struct MeasurementProgress: Equatable, Sendable {
    public let receivedSamples: [ProbeSample]

    public init(receivedSamples: [ProbeSample]) {
        self.receivedSamples = receivedSamples
    }
}

/// Autoridade do ciclo de vida. Persiste apenas o snapshot final já avaliado e descarta leitura parcial.
public actor MeasurementSessionCoordinator {
    private var activeSession: MeasurementSession?
    private var state: MeasurementSessionState = .idle
    private var partialSamples: [ProbeSample] = []
    private var finalSamples: [ProbeSample] = []
    private var measurementTask: Task<Void, Never>?
    private var pathTask: Task<Void, Never>?
    // A pré-leitura acontece antes da sessão de score, mas recebe os mesmos
    // sinais de ciclo de vida. Mantemos seus Tasks separados para não alterar
    // nem reaproveitar a janela de 30 probes do Quick Check.
    private var regionalPreReadTask: Task<RegionalSelectionDecision, Error>?
    private var regionalPathTask: Task<Void, Never>?
    private var regionalPreReadCoordinator: RegionalPreReadCoordinator?
    private var regionalPreReadID: UUID?
    private let transport: any MeasurementTransport
    private let pathObserver: any NetworkPathObserver
    private let historyRepository: any MeasurementHistoryRepository

    public init(
        transport: any MeasurementTransport = NoopMeasurementTransport(),
        pathObserver: any NetworkPathObserver = NoopNetworkPathObserver(),
        historyRepository: any MeasurementHistoryRepository = NoopMeasurementHistoryRepository()
    ) {
        self.transport = transport
        self.pathObserver = pathObserver
        self.historyRepository = historyRepository
    }

    public func begin(resolvedContext: ResolvedMeasurementContext) throws -> MeasurementSession {
        guard activeSession == nil, regionalPreReadTask == nil else { throw MeasurementSessionError.alreadyActive }

        let session = MeasurementSession(resolvedContext: resolvedContext)
        activeSession = session
        partialSamples = []
        finalSamples = []
        state = .measuring(session)
        return session
    }

    /// Compatibilidade do piloto enquanto o contexto único ainda é resolvido pelo catálogo-base.
    public func begin(context: GameContext) throws -> MeasurementSession {
        try begin(resolvedContext: MeasurementSession(context: context).resolvedContext)
    }

    public func startQuickCheck(resolvedContext: ResolvedMeasurementContext, plan: QuickCheckPlan) throws -> MeasurementSession {
        let session = try begin(resolvedContext: resolvedContext)
        let transport = transport
        let coordinator = self
        measurementTask = Task { [transport, coordinator] in
            let samples = await transport.collect(session: session, plan: plan) { sample in
                await coordinator.record(sample: sample, for: session.id)
            }
            await coordinator.finish(sessionID: session.id, samples: samples)
        }
        let pathChanges = pathObserver.pathChanges()
        pathTask = Task { [coordinator] in
            for await _ in pathChanges {
                await coordinator.cancel(id: session.id, reason: .networkPathChanged)
                return
            }
        }
        return session
    }

    public func startQuickCheck(context: GameContext, plan: QuickCheckPlan) throws -> MeasurementSession {
        try startQuickCheck(resolvedContext: PilotCatalog.pilotBase.resolve(context), plan: plan)
    }

    /// Executa a seleção regional antes de abrir uma sessão que gere score. Os
    /// candidatos já vêm materializados de um snapshot validado; esta ponte não
    /// resolve catálogo, não persiste e não mede nenhum destino livre.
    public func selectRegionalCandidate(
        snapshot: RegionalSelectionSnapshot,
        using preReadCoordinator: RegionalPreReadCoordinator,
        manualRegionID: String? = nil
    ) async throws -> RegionalSelectionDecision {
        guard activeSession == nil, regionalPreReadTask == nil else { throw MeasurementSessionError.alreadyActive }

        let preReadID = UUID()
        regionalPreReadID = preReadID
        regionalPreReadCoordinator = preReadCoordinator
        let task = Task {
            try await preReadCoordinator.select(snapshot: snapshot, manualRegionID: manualRegionID)
        }
        // Registra a tarefa antes de assinar o stream: um AsyncStream pode
        // publicar mudança imediatamente e precisa encontrar algo para cancelar.
        regionalPreReadTask = task
        let observer = pathObserver.pathChanges()
        let coordinator = self
        regionalPathTask = Task { [coordinator] in
            for await _ in observer {
                await coordinator.cancelRegionalPreRead()
                return
            }
        }
        defer {
            // Uma seleção cancelada pode terminar depois de outra ter iniciado.
            // Só a dona do identificador pode limpar seus próprios recursos.
            if regionalPreReadID == preReadID {
                regionalPathTask?.cancel()
                regionalPathTask = nil
                regionalPreReadCoordinator = nil
                regionalPreReadTask = nil
                regionalPreReadID = nil
            }
        }
        return try await task.value
    }

    /// Cancelamento explícito da pré-leitura, antes que uma rota seja escolhida.
    public func cancelRegionalPreRead() async {
        await regionalPreReadCoordinator?.cancel()
        regionalPreReadTask?.cancel()
        regionalPathTask?.cancel()
        regionalPreReadTask = nil
        regionalPathTask = nil
        regionalPreReadCoordinator = nil
        regionalPreReadID = nil
    }

    public func isRegionalPreReadActive() -> Bool { regionalPreReadTask != nil }

    public func cancel(id: UUID, reason: MeasurementCancellationReason = .userInitiated) {
        guard activeSession?.id == id else { return }
        let session = activeSession!
        activeSession = nil
        partialSamples = []
        finalSamples = []
        measurementTask?.cancel()
        pathTask?.cancel()
        measurementTask = nil
        pathTask = nil
        state = .cancelled(session, reason)
    }

    public func appDidEnterBackground() async {
        if let session = activeSession {
            cancel(id: session.id, reason: .appEnteredBackground)
        }
        await cancelRegionalPreRead()
    }

    public func currentSession() -> MeasurementSession? {
        activeSession
    }

    public func sessionState() -> MeasurementSessionState {
        state
    }

    public func measurementProgress() -> MeasurementProgress? {
        guard activeSession != nil else { return nil }
        return MeasurementProgress(receivedSamples: partialSamples)
    }

    /// Série concluída para Detalhes da medição atual. Não é persistida no Histórico.
    public func completedProbeSamples() -> [ProbeSample] {
        finalSamples
    }

    private func record(sample: ProbeSample, for sessionID: UUID) {
        guard activeSession?.id == sessionID else { return }
        guard sample.isValidResponse else { return }
        partialSamples.append(sample)
    }

    private func finish(sessionID: UUID, samples: [ProbeSample]) async {
        guard let session = activeSession, session.id == sessionID else { return }
        activeSession = nil
        partialSamples = []
        finalSamples = samples
        pathTask?.cancel()
        pathTask = nil
        measurementTask = nil
        let evaluation: MeasurementEvaluation
        switch session.resolvedContext.profileID {
        case .battleRoyaleCompetitive:
            evaluation = QualityEvaluator.evaluateBattleRoyaleCompetitive(samples: samples)
        case .mobileRealtime:
            evaluation = QualityEvaluator.evaluateMobileRealtime(samples: samples)
        case .casualRealtime:
            evaluation = QualityEvaluator.evaluateCasualRealtime(samples: samples)
        }
        let entry: MeasurementHistoryEntry?
        if case let .completed(result) = evaluation {
            let snapshot = MeasurementHistoryEntry.completedQuickCheck(
                resolvedContext: session.resolvedContext,
                result: result
            )
            // Falha local de armazenamento nunca invalida um resultado de rede já concluído.
            try? await historyRepository.save(snapshot)
            entry = snapshot
        } else {
            entry = nil
        }
        state = .completed(session, evaluation, entry)
    }
}

public struct NoopMeasurementTransport: MeasurementTransport {
    private let completionDelay: Duration

    /// Útil para previews e para a casca do piloto antes do adaptador UDP existir.
    /// Nunca entrega RTTs ou resultado positivo fabricado.
    public init(completionDelay: Duration = .zero) {
        self.completionDelay = completionDelay
    }

    public func collect(
        session: MeasurementSession,
        plan: QuickCheckPlan,
        onSample: @escaping @Sendable (ProbeSample) async -> Void
    ) async -> [ProbeSample] {
        if completionDelay > .zero {
            try? await Task.sleep(for: completionDelay)
        }
        return []
    }
}

public struct NoopNetworkPathObserver: NetworkPathObserver {
    public init() {}

    public func pathChanges() -> AsyncStream<Void> {
        AsyncStream { continuation in continuation.finish() }
    }
}
