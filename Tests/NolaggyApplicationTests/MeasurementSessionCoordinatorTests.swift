import XCTest
@testable import NolaggyApplication
@testable import NolaggyDomain

final class MeasurementSessionCoordinatorTests: XCTestCase {
    func testOnlyOneSessionCanBeActive() async throws {
        let coordinator = MeasurementSessionCoordinator()
        let context = GameContext(gameID: "pilot-game", market: "BR", platform: .iphone)

        let session = try await coordinator.begin(context: context)
        let activeSession = await coordinator.currentSession()
        XCTAssertEqual(activeSession, session)

        do {
            _ = try await coordinator.begin(context: context)
            XCTFail("A coordinator must reject a second active session.")
        } catch {
            XCTAssertEqual(error as? MeasurementSessionError, .alreadyActive)
        }
    }

    func testCancellingActiveSessionClearsIt() async throws {
        let coordinator = MeasurementSessionCoordinator()
        let session = try await coordinator.begin(
            context: GameContext(gameID: "pilot-game", market: "BR", platform: .iphone)
        )

        await coordinator.cancel(id: session.id)

        let activeSession = await coordinator.currentSession()
        XCTAssertNil(activeSession)
        let state = await coordinator.sessionState()
        XCTAssertEqual(
            state,
            .cancelled(session, .userInitiated)
        )
    }

    func testBackgroundDiscardsTheActiveQuickCheck() async throws {
        let coordinator = MeasurementSessionCoordinator(
            transport: DelayedTransport(),
            pathObserver: NoChangesObserver()
        )
        let session = try await coordinator.startQuickCheck(
            context: pilotContext,
            plan: pilotPlan
        )

        await coordinator.appDidEnterBackground()

        let activeSession = await coordinator.currentSession()
        let state = await coordinator.sessionState()
        XCTAssertNil(activeSession)
        XCTAssertEqual(
            state,
            .cancelled(session, .appEnteredBackground)
        )
    }

    func testPathChangeDiscardsTheActiveQuickCheck() async throws {
        let coordinator = MeasurementSessionCoordinator(
            transport: DelayedTransport(),
            pathObserver: ImmediateChangeObserver()
        )
        let session = try await coordinator.startQuickCheck(
            context: pilotContext,
            plan: pilotPlan
        )

        try await Task.sleep(for: .milliseconds(30))

        let activeSession = await coordinator.currentSession()
        let state = await coordinator.sessionState()
        XCTAssertNil(activeSession)
        XCTAssertEqual(
            state,
            .cancelled(session, .networkPathChanged)
        )
    }

    func testCompletionWithInsufficientResponsesIsInconclusiveAndNotActive() async throws {
        let coordinator = MeasurementSessionCoordinator(
            transport: ImmediateTransport(samples: Array(repeating: ProbeSample(sequence: 0, outcome: .timeout), count: 30)),
            pathObserver: NoChangesObserver()
        )
        let session = try await coordinator.startQuickCheck(context: pilotContext, plan: pilotPlan)

        try await Task.sleep(for: .milliseconds(30))

        let activeSession = await coordinator.currentSession()
        let state = await coordinator.sessionState()
        XCTAssertNil(activeSession)
        XCTAssertEqual(
            state,
            .completed(
                session,
                .inconclusive(
                    reason: .insufficientUDPResponses,
                    diagnostics: QualityMetrics(
                        validResponseCount: 0,
                        timeoutCount: 30,
                        invalidResponseCount: 0,
                        p50Milliseconds: nil,
                        p95Milliseconds: nil,
                        p99Milliseconds: nil,
                        jitterMilliseconds: nil,
                        packetLossPercentage: 100,
                        spikeCount: 0,
                        severeSpikeCount: 0,
                        spikeRatePercentage: 0,
                        p95ToP50Ratio: nil,
                        components: nil
                    )
                ),
                nil
            )
        )
    }

    func testPresentationNeverExposesScoreForInconclusiveEvaluation() {
        let presentation = QuickCheckPresentationMapper.map(
            .completed(
                MeasurementSession(context: pilotContext),
                .inconclusive(
                    reason: .insufficientUDPResponses,
                    diagnostics: emptyDiagnostics
                ),
                nil
            )
        )

        XCTAssertEqual(presentation, .inconclusive)
    }

    func testPresentationKeepsValidatedQualityResult() {
        let expected = QualityResult(
            metrics: QualityMetrics(
                validResponseCount: 30,
                timeoutCount: 0,
                invalidResponseCount: 0,
                p50Milliseconds: 24,
                p95Milliseconds: 28,
                p99Milliseconds: 30,
                jitterMilliseconds: 3,
                packetLossPercentage: 0,
                spikeCount: 1,
                severeSpikeCount: 0,
                spikeRatePercentage: 3.33,
                p95ToP50Ratio: 1.17,
                components: QualityComponents(
                    latency: 100,
                    loss: 100,
                    jitter: 100,
                    tail: 90,
                    spikes: 90,
                    consistency: 94,
                    stability: 90
                )
            ),
            rawScore: 92,
            finalScore: 92,
            resultClass: .excellent,
            appliedGuardrails: []
        )

        let presentation = QuickCheckPresentationMapper.map(
            .completed(MeasurementSession(context: pilotContext), .completed(expected), nil)
        )

        XCTAssertEqual(presentation, .result(expected))
    }

    func testCompletedQuickCheckPersistsOnlyFinalSnapshot() async throws {
        let repository = RecordingHistoryRepository()
        let coordinator = MeasurementSessionCoordinator(
            transport: ImmediateTransport(samples: receivedSamples(30)),
            pathObserver: NoChangesObserver(),
            historyRepository: repository
        )
        let resolved = try PilotCatalog.pilotBase.resolve(pilotContext)
        _ = try await coordinator.startQuickCheck(resolvedContext: resolved, plan: pilotPlan)
        try await Task.sleep(for: .milliseconds(30))

        let saved = await repository.entries
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.resolvedContext, resolved)
        XCTAssertEqual(saved.first?.result.metrics.worstSpikeMilliseconds, 30)
    }

    func testInconclusiveQuickCheckNeverPersistsSnapshot() async throws {
        let repository = RecordingHistoryRepository()
        let coordinator = MeasurementSessionCoordinator(
            transport: ImmediateTransport(samples: Array(repeating: ProbeSample(sequence: 0, outcome: .timeout), count: 30)),
            pathObserver: NoChangesObserver(),
            historyRepository: repository
        )
        _ = try await coordinator.startQuickCheck(resolvedContext: try PilotCatalog.pilotBase.resolve(pilotContext), plan: pilotPlan)
        try await Task.sleep(for: .milliseconds(30))

        let saved = await repository.entries
        XCTAssertTrue(saved.isEmpty)
    }

    private var pilotContext: GameContext {
        GameContext(gameID: "fortnite", market: "BR", platform: .iphone)
    }

    private var pilotPlan: QuickCheckPlan {
        QuickCheckPlan(endpoint: MeasurementEndpoint(host: "example.invalid", port: 7770, protocolKind: .gameLiftPing))
    }

    private var emptyDiagnostics: QualityMetrics {
        QualityMetrics(
            validResponseCount: 0,
            timeoutCount: 30,
            invalidResponseCount: 0,
            p50Milliseconds: nil,
            p95Milliseconds: nil,
            p99Milliseconds: nil,
            jitterMilliseconds: nil,
            packetLossPercentage: 100,
            spikeCount: 0,
            severeSpikeCount: 0,
            spikeRatePercentage: 0,
            p95ToP50Ratio: nil,
            components: nil
        )
    }

    private func receivedSamples(_ count: Int) -> [ProbeSample] {
        (0..<count).map { ProbeSample(sequence: $0, roundTripMilliseconds: 30, outcome: .received) }
    }
}

private actor RecordingHistoryRepository: MeasurementHistoryRepository {
    var entries: [MeasurementHistoryEntry] = []
    func save(_ entry: MeasurementHistoryEntry) { entries.append(entry) }
    func loadHistory() -> [MeasurementHistoryEntry] { entries }
    func deleteAll() { entries = [] }
}

private struct ImmediateTransport: MeasurementTransport {
    let samples: [ProbeSample]

    func collect(
        session: MeasurementSession,
        plan: QuickCheckPlan,
        onSample: @escaping @Sendable (ProbeSample) async -> Void
    ) async -> [ProbeSample] {
        samples
    }
}

private struct DelayedTransport: MeasurementTransport {
    func collect(
        session: MeasurementSession,
        plan: QuickCheckPlan,
        onSample: @escaping @Sendable (ProbeSample) async -> Void
    ) async -> [ProbeSample] {
        try? await Task.sleep(for: .seconds(1))
        return []
    }
}

private struct NoChangesObserver: NetworkPathObserver {
    func pathChanges() -> AsyncStream<Void> {
        AsyncStream { continuation in continuation.finish() }
    }
}

private struct ImmediateChangeObserver: NetworkPathObserver {
    func pathChanges() -> AsyncStream<Void> {
        AsyncStream { continuation in
            continuation.yield()
            continuation.finish()
        }
    }
}
