import Foundation
import NolaggyDomain

/// Disponibilidade de Wi-Fi separada do observador de mudanças para que o pré-requisito
/// do Deep Check seja verificável sem depender de `NWPathMonitor` em testes.
public protocol WiFiAvailability: Sendable {
    func isWiFiAvailable() async -> Bool
}

public struct DeepCheckPlan: Equatable, Sendable {
    public let restProbePlan: QuickCheckPlan
    public let loadProbePlan: QuickCheckPlan
    public let loadRequest: LoadRequest

    public init(restProbePlan: QuickCheckPlan, loadProbePlan: QuickCheckPlan, loadRequest: LoadRequest) {
        self.restProbePlan = restProbePlan
        self.loadProbePlan = loadProbePlan
        self.loadRequest = loadRequest
    }
}

/// A carga não carrega contexto de jogo, pessoa ou sessão; é apenas o limite técnico
/// para o adaptador HTTP autorizado.
public struct LoadRequest: Equatable, Sendable {
    public let url: URL
    public let maximumBytes: Int
    public let maximumDuration: Duration

    public init(url: URL, maximumBytes: Int = 10 * 1024 * 1024, maximumDuration: Duration = .seconds(15)) {
        self.url = url
        self.maximumBytes = maximumBytes
        self.maximumDuration = maximumDuration
    }
}

public enum LoadTransferOutcome: Equatable, Sendable {
    case completed(bytesTransferred: Int)
    case unavailable
}

public protocol LoadTransport: Sendable {
    func transfer(_ request: LoadRequest) async -> LoadTransferOutcome
}

public enum DeepCheckPhase: Equatable, Sendable {
    case rest
    case load
}

/// Explica à apresentação se a ausência da leitura sob carga veio do transporte HTTP.
/// Dados UDP insuficientes na segunda fase continuam sendo uma medição sem impacto,
/// não uma falha de carga.
public enum DeepCheckLoadAvailability: Equatable, Sendable {
    case measured
    case loadUnavailable
}

public enum DeepCheckSessionState: Equatable, Sendable {
    case idle
    case requiresWiFi
    case measuring(MeasurementSession, DeepCheckPhase)
    case completed(MeasurementSession, DeepCheckEvaluation, DeepCheckLoadAvailability)
    case cancelled(MeasurementSession, MeasurementCancellationReason)
}

/// Amostras válidas da fase em curso, destinadas apenas à apresentação ao vivo.
/// A sessão as descarta ao cancelar ou concluir; histórico nunca as recebe.
public struct DeepCheckMeasurementProgress: Equatable, Sendable {
    public let phase: DeepCheckPhase
    public let receivedSamples: [ProbeSample]
    /// Série concluída de repouso exposta somente enquanto a fase de carga está ativa.
    /// A apresentação pode desenhá-la como referência, sem misturar as distribuições.
    public let restSamples: [ProbeSample]

    public init(phase: DeepCheckPhase, receivedSamples: [ProbeSample], restSamples: [ProbeSample] = []) {
        self.phase = phase
        self.receivedSamples = receivedSamples
        self.restSamples = restSamples
    }
}

public enum DeepCheckSessionError: Error, Equatable, Sendable {
    case requiresWiFi
    case alreadyActive
}

/// Orquestra as duas fases sem misturar suas amostras. Persiste somente o snapshot
/// final por meio do repositório; não produz UI nem reavalia o score do repouso.
public actor DeepCheckSessionCoordinator {
    private var activeSession: MeasurementSession?
    private var state: DeepCheckSessionState = .idle
    private var activePhase: DeepCheckPhase?
    private var partialSamples: [ProbeSample] = []
    private var completedRestSamples: [ProbeSample] = []
    private var executionTask: Task<Void, Never>?
    private var pathTask: Task<Void, Never>?
    private let transport: any MeasurementTransport
    private let loadTransport: any LoadTransport
    private let pathObserver: any NetworkPathObserver
    private let wifiAvailability: any WiFiAvailability
    private let historyRepository: any MeasurementHistoryRepository

    public init(
        transport: any MeasurementTransport,
        loadTransport: any LoadTransport,
        pathObserver: any NetworkPathObserver,
        wifiAvailability: any WiFiAvailability,
        historyRepository: any MeasurementHistoryRepository = NoopMeasurementHistoryRepository()
    ) {
        self.transport = transport
        self.loadTransport = loadTransport
        self.pathObserver = pathObserver
        self.wifiAvailability = wifiAvailability
        self.historyRepository = historyRepository
    }

    @discardableResult
    public func start(resolvedContext: ResolvedMeasurementContext, plan: DeepCheckPlan) async throws -> MeasurementSession {
        guard activeSession == nil else { throw DeepCheckSessionError.alreadyActive }
        guard await wifiAvailability.isWiFiAvailable() else {
            state = .requiresWiFi
            throw DeepCheckSessionError.requiresWiFi
        }

        let session = MeasurementSession(resolvedContext: resolvedContext)
        activeSession = session
        activePhase = .rest
        partialSamples = []
        completedRestSamples = []
        state = .measuring(session, .rest)

        let coordinator = self
        let observer = pathObserver.pathChanges()
        pathTask = Task { [coordinator] in
            for await _ in observer {
                await coordinator.cancel(id: session.id, reason: .networkPathChanged)
                return
            }
        }
        let transport = transport
        let loadTransport = loadTransport
        let wifiAvailability = wifiAvailability
        executionTask = Task { [coordinator, transport, loadTransport, wifiAvailability] in
            let restSamples = await transport.collect(session: session, plan: plan.restProbePlan) { sample in
                await coordinator.record(sample: sample, for: session.id, phase: .rest)
            }
            await coordinator.beginLoadPhase(
                sessionID: session.id,
                session: session,
                restSamples: restSamples,
                plan: plan,
                transport: transport,
                loadTransport: loadTransport,
                wifiAvailability: wifiAvailability
            )
        }
        return session
    }

    public func cancel(id: UUID, reason: MeasurementCancellationReason = .userInitiated) {
        guard activeSession?.id == id else { return }
        let session = activeSession!
        activeSession = nil
        activePhase = nil
        partialSamples = []
        completedRestSamples = []
        executionTask?.cancel()
        pathTask?.cancel()
        executionTask = nil
        pathTask = nil
        state = .cancelled(session, reason)
    }

    public func appDidEnterBackground() {
        guard let session = activeSession else { return }
        cancel(id: session.id, reason: .appEnteredBackground)
    }

    public func currentSession() -> MeasurementSession? { activeSession }
    public func sessionState() -> DeepCheckSessionState { state }

    public func measurementProgress() -> DeepCheckMeasurementProgress? {
        guard activeSession != nil, let activePhase else { return nil }
        return DeepCheckMeasurementProgress(phase: activePhase, receivedSamples: partialSamples, restSamples: completedRestSamples)
    }

    private func beginLoadPhase(
        sessionID: UUID,
        session: MeasurementSession,
        restSamples: [ProbeSample],
        plan: DeepCheckPlan,
        transport: any MeasurementTransport,
        loadTransport: any LoadTransport,
        wifiAvailability: any WiFiAvailability
    ) async {
        guard activeSession?.id == sessionID else { return }
        guard await wifiAvailability.isWiFiAvailable() else {
            cancel(id: sessionID, reason: .networkPathChanged)
            return
        }
        activePhase = .load
        partialSamples = []
        completedRestSamples = restSamples.filter(\.isValidResponse)
        state = .measuring(session, .load)

        let coordinator = self
        async let loadSamples = transport.collect(session: session, plan: plan.loadProbePlan) { sample in
            await coordinator.record(sample: sample, for: sessionID, phase: .load)
        }
        async let loadOutcome = loadTransport.transfer(plan.loadRequest)
        let (samples, outcome) = await (loadSamples, loadOutcome)
        await finish(sessionID: sessionID, session: session, restSamples: restSamples, loadSamples: samples, loadOutcome: outcome)
    }

    private func finish(
        sessionID: UUID,
        session: MeasurementSession,
        restSamples: [ProbeSample],
        loadSamples: [ProbeSample],
        loadOutcome: LoadTransferOutcome
    ) async {
        guard activeSession?.id == sessionID else { return }
        activeSession = nil
        activePhase = nil
        partialSamples = []
        completedRestSamples = []
        pathTask?.cancel()
        pathTask = nil
        executionTask = nil
        let evaluation: DeepCheckEvaluation
        switch session.resolvedContext.profileID {
        case .battleRoyaleCompetitive:
            evaluation = DeepCheckEvaluator.evaluateBattleRoyaleCompetitive(
                restSamples: restSamples,
                loadSamples: loadOutcome == .unavailable ? nil : loadSamples
            )
        case .mobileRealtime:
            evaluation = DeepCheckEvaluator.evaluateMobileRealtime(
                restSamples: restSamples,
                loadSamples: loadOutcome == .unavailable ? nil : loadSamples
            )
        case .casualRealtime:
            evaluation = DeepCheckEvaluator.evaluateCasualRealtime(
                restSamples: restSamples,
                loadSamples: loadOutcome == .unavailable ? nil : loadSamples
            )
        }
        let availability: DeepCheckLoadAvailability = loadOutcome == .unavailable ? .loadUnavailable : .measured
        if case let .completed(result) = evaluation {
            // O histórico recebe somente o fato final: repouso e complemento agregado de carga.
            try? await historyRepository.save(.completedDeepCheck(resolvedContext: session.resolvedContext, result: result))
        }
        state = .completed(session, evaluation, availability)
    }

    private func record(sample: ProbeSample, for sessionID: UUID, phase: DeepCheckPhase) {
        guard activeSession?.id == sessionID, activePhase == phase, sample.isValidResponse else { return }
        partialSamples.append(sample)
    }
}

public struct NoopWiFiAvailability: WiFiAvailability {
    public init() {}
    public func isWiFiAvailable() async -> Bool { false }
}

public struct NoopLoadTransport: LoadTransport {
    public init() {}
    public func transfer(_: LoadRequest) async -> LoadTransferOutcome { .unavailable }
}
