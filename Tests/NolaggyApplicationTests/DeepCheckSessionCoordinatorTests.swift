import XCTest
@testable import NolaggyApplication
@testable import NolaggyDomain

final class DeepCheckSessionCoordinatorTests: XCTestCase {
    func testRequiresWiFiBeforeCreatingASession() async throws {
        let coordinator = makeCoordinator(wifi: false)

        do {
            _ = try await coordinator.start(resolvedContext: resolvedContext, plan: plan)
            XCTFail("Deep Check must not start without Wi-Fi.")
        } catch {
            XCTAssertEqual(error as? DeepCheckSessionError, .requiresWiFi)
        }

        let activeSession = await coordinator.currentSession()
        let state = await coordinator.sessionState()
        XCTAssertNil(activeSession)
        XCTAssertEqual(state, .requiresWiFi)
    }

    func testLoadFailureKeepsValidRestResultAndSignalsUnavailability() async throws {
        let coordinator = makeCoordinator(
            transport: ScriptedTransport(samples: [received(30, rtt: 30), received(30, rtt: 80)]),
            load: FixedLoadTransport(outcome: .unavailable)
        )
        let session = try await coordinator.start(resolvedContext: resolvedContext, plan: plan)
        try await waitForCompletion(coordinator)

        let state = await coordinator.sessionState()
        guard case let .completed(finished, .completed(result), availability) = state else {
            return XCTFail("Expected completed Deep Check with valid rest result.")
        }
        XCTAssertEqual(finished, session)
        XCTAssertEqual(result.restResult.metrics.p50Milliseconds, 30)
        XCTAssertNil(result.metrics.load)
        XCTAssertNil(result.metrics.loadImpact)
        XCTAssertEqual(availability, .loadUnavailable)
    }

    func testKeepsRestAndLoadSeriesSeparate() async throws {
        let coordinator = makeCoordinator(
            transport: ScriptedTransport(samples: [received(30, rtt: 30), received(30, rtt: 80)]),
            load: FixedLoadTransport(outcome: .completed(bytesTransferred: 10_000_000))
        )
        _ = try await coordinator.start(resolvedContext: resolvedContext, plan: plan)
        try await waitForCompletion(coordinator)

        guard case let .completed(_, .completed(result), availability) = await coordinator.sessionState() else {
            return XCTFail("Expected completed Deep Check.")
        }
        XCTAssertEqual(result.restResult.metrics.p50Milliseconds, 30)
        XCTAssertEqual(result.metrics.load?.p50Milliseconds, 80)
        XCTAssertEqual(result.metrics.loadImpact?.increaseMilliseconds, 50)
        XCTAssertEqual(availability, .measured)
    }

    func testDeepCheckDispatchesTheResolvedMobileAndCasualProfiles() async throws {
        for profile in [QualityProfileID.mobileRealtime, .casualRealtime] {
            let coordinator = makeCoordinator(
                transport: ScriptedTransport(samples: [received(30, rtt: 80), received(30, rtt: 95)])
            )
            _ = try await coordinator.start(resolvedContext: try resolvedContext(profile: profile), plan: plan)
            try await waitForCompletion(coordinator)

            guard case let .completed(_, .completed(result), _) = await coordinator.sessionState(),
                  case let .completed(expected) = QualityEvaluator.evaluate(samples: received(30, rtt: 80), profile: profile) else {
                return XCTFail("Expected a Deep Check result for \(profile.rawValue).")
            }
            XCTAssertEqual(result.restResult, expected)
        }
    }

    func testInsufficientLoadUDPKeepsRestResultWithoutDeclaringTheDeepCheckInconclusive() async throws {
        let coordinator = makeCoordinator(
            transport: ScriptedTransport(samples: [received(30, rtt: 30), received(9, rtt: 80)]),
            load: FixedLoadTransport(outcome: .completed(bytesTransferred: 10_000_000))
        )
        _ = try await coordinator.start(resolvedContext: resolvedContext, plan: plan)
        try await waitForCompletion(coordinator)

        guard case let .completed(_, .completed(result), availability) = await coordinator.sessionState() else {
            return XCTFail("A valid rest phase must remain a completed Deep Check.")
        }
        XCTAssertEqual(result.restResult.metrics.p50Milliseconds, 30)
        XCTAssertNil(result.metrics.loadImpact)
        XCTAssertEqual(availability, .measured)
    }

    func testCompletedDeepCheckPersistsOnlyItsFinalSnapshot() async throws {
        let history = RecordingDeepHistoryRepository()
        let coordinator = DeepCheckSessionCoordinator(
            transport: ScriptedTransport(samples: [received(30, rtt: 30), received(30, rtt: 80)]),
            loadTransport: FixedLoadTransport(outcome: .completed(bytesTransferred: 10 * 1024 * 1024)),
            pathObserver: NoChangesObserver(),
            wifiAvailability: FixedWiFiAvailability(available: true),
            historyRepository: history
        )

        _ = try await coordinator.start(resolvedContext: resolvedContext, plan: plan)
        try await waitForCompletion(coordinator)

        let entries = await history.entries
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.kind, .deep)
        XCTAssertEqual(entries.first?.result.finalScore, 100)
        XCTAssertEqual(entries.first?.deepCheck?.metrics.loadImpact?.increaseMilliseconds, 50)
    }

    func testBackgroundCancelsAndDiscardsBothPhases() async throws {
        let coordinator = makeCoordinator(transport: DelayedTransport())
        let session = try await coordinator.start(resolvedContext: resolvedContext, plan: plan)
        await coordinator.appDidEnterBackground()
        try await Task.sleep(for: .milliseconds(30))

        let activeSession = await coordinator.currentSession()
        let state = await coordinator.sessionState()
        XCTAssertNil(activeSession)
        XCTAssertEqual(state, .cancelled(session, .appEnteredBackground))
    }

    func testPathChangeCancelsAndDiscardsBothPhases() async throws {
        let coordinator = DeepCheckSessionCoordinator(
            transport: DelayedTransport(),
            loadTransport: FixedLoadTransport(outcome: .completed(bytesTransferred: 1)),
            pathObserver: ImmediateChangeObserver(),
            wifiAvailability: FixedWiFiAvailability(available: true)
        )
        let session = try await coordinator.start(resolvedContext: resolvedContext, plan: plan)
        try await Task.sleep(for: .milliseconds(30))

        let activeSession = await coordinator.currentSession()
        let state = await coordinator.sessionState()
        XCTAssertNil(activeSession)
        XCTAssertEqual(state, .cancelled(session, .networkPathChanged))
    }

    func testPoorSampleQualityAbortsDeepCheckEarly() async throws {
        let coordinator = makeCoordinator(
            transport: ProgressTransport(samples: [
                [
                    ProbeSample(sequence: 0, roundTripMilliseconds: 25, outcome: .received),
                    ProbeSample(sequence: 1, outcome: .timeout),
                    ProbeSample(sequence: 2, outcome: .timeout),
                    ProbeSample(sequence: 3, outcome: .timeout),
                    ProbeSample(sequence: 4, outcome: .timeout),
                    ProbeSample(sequence: 5, outcome: .timeout),
                ],
                []
            ])
        )
        let session = try await coordinator.start(resolvedContext: resolvedContext, plan: plan)
        try await Task.sleep(for: .milliseconds(50))

        let activeSession = await coordinator.currentSession()
        let state = await coordinator.sessionState()
        XCTAssertNil(activeSession)
        XCTAssertEqual(state, .cancelled(session, .poorSampleQuality))
    }

    func testExposesSeparateRestSeriesDuringLoadAndClearsThemOnCancellation() async throws {
        let coordinator = makeCoordinator(
            transport: ProgressTransport(
                samples: [
                    [ProbeSample(sequence: 0, roundTripMilliseconds: 30, outcome: .received)],
                    [ProbeSample(sequence: 1, roundTripMilliseconds: 80, outcome: .received)]
                ]
            )
        )
        let session = try await coordinator.start(resolvedContext: resolvedContext, plan: plan)
        try await Task.sleep(for: .milliseconds(30))

        let progress = await coordinator.measurementProgress()
        XCTAssertEqual(progress?.phase, .load)
        XCTAssertEqual(progress?.receivedSamples.map(\.sequence), [1])
        XCTAssertEqual(progress?.restSamples.map(\.sequence), [0])

        await coordinator.cancel(id: session.id)
        let progressAfterCancellation = await coordinator.measurementProgress()
        XCTAssertNil(progressAfterCancellation)
    }

    private var resolvedContext: ResolvedMeasurementContext {
        get throws { try PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "BR", platform: .iphone)) }
    }

    private func resolvedContext(profile: QualityProfileID) throws -> ResolvedMeasurementContext {
        ResolvedMeasurementContext(
            context: GameContext(gameID: "profile-test", market: "BR", platform: .iphone),
            catalogVersion: "profile-test",
            profileID: profile,
            regionID: "sa-east-1",
            destination: try ProbeDestination(host: "example.invalid", port: 7770),
            strategy: .genericRegion,
            confidence: .medium
        )
    }

    private var plan: DeepCheckPlan {
        DeepCheckPlan(
            restProbePlan: QuickCheckPlan(endpoint: MeasurementEndpoint(host: "example.invalid", port: 7770, protocolKind: .gameLiftPing)),
            loadProbePlan: QuickCheckPlan(endpoint: MeasurementEndpoint(host: "example.invalid", port: 7770, protocolKind: .gameLiftPing)),
            loadRequest: LoadRequest(url: URL(string: "https://example.invalid/v1/load")!)
        )
    }

    private func makeCoordinator(
        transport: (any MeasurementTransport)? = nil,
        load: any LoadTransport = FixedLoadTransport(outcome: .completed(bytesTransferred: 1)),
        wifi: Bool = true
    ) -> DeepCheckSessionCoordinator {
        DeepCheckSessionCoordinator(
            transport: transport ?? ScriptedTransport(samples: [received(30, rtt: 30), received(30, rtt: 80)]),
            loadTransport: load,
            pathObserver: NoChangesObserver(),
            wifiAvailability: FixedWiFiAvailability(available: wifi)
        )
    }

    func testCellularRequiresConsentBeforeStarting() async throws {
        let probes = InvocationCountingMeasurementTransport()
        let load = InvocationCountingLoadTransport()
        let history = RecordingDeepHistoryRepository()
        let coordinator = DeepCheckSessionCoordinator(
            transport: probes,
            loadTransport: load,
            pathObserver: NoChangesObserver(),
            wifiAvailability: FixedInterfaceAvailability(interface: .cellular),
            historyRepository: history
        )

        do {
            _ = try await coordinator.start(resolvedContext: resolvedContext, plan: plan, hasCellularConsent: false)
            XCTFail("Deep Check on cellular must not start without explicit consent.")
        } catch {
            XCTAssertEqual(error as? DeepCheckSessionError, .requiresCellularConsent)
        }

        let state = await coordinator.sessionState()
        let activeSession = await coordinator.currentSession()
        let progress = await coordinator.measurementProgress()
        let probeCalls = await probes.invocationCount
        let loadCalls = await load.invocationCount
        let entries = await history.loadHistory()
        XCTAssertEqual(state, .requiresCellularConsent)
        XCTAssertNil(activeSession)
        XCTAssertNil(progress)
        XCTAssertEqual(probeCalls, 0)
        XCTAssertEqual(loadCalls, 0)
        XCTAssertTrue(entries.isEmpty)
    }

    func testCellularWithConsentExecutesAndPersistsCellularSnapshot() async throws {
        let history = RecordingDeepHistoryRepository()
        let coordinator = DeepCheckSessionCoordinator(
            transport: ScriptedTransport(samples: [received(30, rtt: 35), received(30, rtt: 85)]),
            loadTransport: FixedLoadTransport(outcome: .completed(bytesTransferred: 5_000_000)),
            pathObserver: NoChangesObserver(),
            wifiAvailability: FixedInterfaceAvailability(interface: .cellular),
            historyRepository: history
        )

        _ = try await coordinator.start(resolvedContext: resolvedContext, plan: plan, hasCellularConsent: true)
        try await waitForCompletion(coordinator)

        let state = await coordinator.sessionState()
        guard case let .completed(_, .completed(result), availability) = state else {
            return XCTFail("Expected completed Deep Check on cellular.")
        }
        XCTAssertEqual(result.restResult.metrics.p50Milliseconds, 35)
        XCTAssertEqual(availability, .measured)

        let entries = await history.loadHistory()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.resolvedContext.observedPhoneNetwork, .cellular)
    }

    func testWiFiExecutesAndPersistsWiFiSnapshot() async throws {
        let history = RecordingDeepHistoryRepository()
        let coordinator = DeepCheckSessionCoordinator(
            transport: ScriptedTransport(samples: [received(30, rtt: 25), received(30, rtt: 40)]),
            loadTransport: FixedLoadTransport(outcome: .completed(bytesTransferred: 10_000_000)),
            pathObserver: NoChangesObserver(),
            wifiAvailability: FixedInterfaceAvailability(interface: .wifi),
            historyRepository: history
        )

        _ = try await coordinator.start(resolvedContext: resolvedContext, plan: plan)
        try await waitForCompletion(coordinator)

        let entries = await history.loadHistory()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.resolvedContext.observedPhoneNetwork, .wifi)
    }

    func testObservedPhoneNetworkDoesNotReplaceDeclaredExternalEquipmentLink() async throws {
        let context = ResolvedMeasurementContext(
            context: GameContext(gameID: "fortnite", market: "BR", platform: .playstation, declaredExternalLink: .ethernet),
            catalogVersion: "test",
            profileID: .battleRoyaleCompetitive,
            regionID: "sa-east-1",
            destination: try ProbeDestination(host: "example.invalid", port: 7770),
            strategy: .genericRegion,
            confidence: .medium
        )
        let coordinator = makeCoordinator()

        let session = try await coordinator.start(resolvedContext: context, plan: plan)

        XCTAssertEqual(session.resolvedContext.context.declaredExternalLink, .ethernet)
        XCTAssertEqual(session.resolvedContext.observedPhoneNetwork, .wifi)
        await coordinator.cancel(id: session.id)
    }

    func testNetworkPathChangeDuringExecutionCancelsAndDiscardsPartialData() async throws {
        let history = RecordingDeepHistoryRepository()
        let coordinator = DeepCheckSessionCoordinator(
            transport: DelayedTransport(),
            loadTransport: FixedLoadTransport(outcome: .unavailable),
            pathObserver: ImmediateChangeObserver(),
            wifiAvailability: FixedInterfaceAvailability(interface: .wifi),
            historyRepository: history
        )

        _ = try await coordinator.start(resolvedContext: resolvedContext, plan: plan)
        try await Task.sleep(for: .milliseconds(50))

        let state = await coordinator.sessionState()
        guard case let .cancelled(_, reason) = state else {
            return XCTFail("Expected cancelled session due to network path change, got \(state)")
        }
        XCTAssertEqual(reason, .networkPathChanged)
        let progress = await coordinator.measurementProgress()
        XCTAssertNil(progress)
        let entries = await history.loadHistory()
        XCTAssertTrue(entries.isEmpty, "No partial data should be persisted on network change.")
    }

    func testInsufficientRestUDPResultsInInconclusiveAndDoesNotPersistToHistory() async throws {
        let history = RecordingDeepHistoryRepository()
        let coordinator = DeepCheckSessionCoordinator(
            transport: ScriptedTransport(samples: [received(5, rtt: 30), received(30, rtt: 80)]),
            loadTransport: FixedLoadTransport(outcome: .completed(bytesTransferred: 10_000_000)),
            pathObserver: NoChangesObserver(),
            wifiAvailability: FixedInterfaceAvailability(interface: .wifi),
            historyRepository: history
        )

        _ = try await coordinator.start(resolvedContext: resolvedContext, plan: plan)
        try await waitForCompletion(coordinator)

        let state = await coordinator.sessionState()
        guard case let .completed(_, evaluation, _) = state,
              case .inconclusive = evaluation else {
            return XCTFail("Expected inconclusive evaluation due to insufficient rest samples, got \(state)")
        }

        let entries = await history.loadHistory()
        XCTAssertTrue(entries.isEmpty, "Inconclusive results must never be persisted to history.")
    }

    private func received(_ count: Int, rtt: Double) -> [ProbeSample] {
        (0..<count).map { ProbeSample(sequence: $0, roundTripMilliseconds: rtt, outcome: .received) }
    }

    private func waitForCompletion(_ coordinator: DeepCheckSessionCoordinator) async throws {
        for _ in 0..<50 {
            if case .completed = await coordinator.sessionState() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("Deep Check did not finish.")
    }
}

private struct FixedInterfaceAvailability: WiFiAvailability {
    let interface: NetworkInterfaceType
    func isWiFiAvailable() async -> Bool { interface == .wifi }
    func isCellularAvailable() async -> Bool { interface == .cellular }
    func currentInterface() async -> NetworkInterfaceType { interface }
}

private actor ScriptedTransport: MeasurementTransport {
    private var samples: [[ProbeSample]]

    init(samples: [[ProbeSample]]) { self.samples = samples }

    func collect(session: MeasurementSession, plan: QuickCheckPlan, onSample: @escaping @Sendable (ProbeSample) async -> Void) async -> [ProbeSample] {
        samples.removeFirst()
    }
}

private struct DelayedTransport: MeasurementTransport {
    func collect(session: MeasurementSession, plan: QuickCheckPlan, onSample: @escaping @Sendable (ProbeSample) async -> Void) async -> [ProbeSample] {
        try? await Task.sleep(for: .seconds(1))
        return []
    }
}

private actor ProgressTransport: MeasurementTransport {
    private var samples: [[ProbeSample]]

    init(samples: [[ProbeSample]]) { self.samples = samples }

    func collect(session: MeasurementSession, plan: QuickCheckPlan, onSample: @escaping @Sendable (ProbeSample) async -> Void) async -> [ProbeSample] {
        let phaseSamples = samples.removeFirst()
        for sample in phaseSamples { await onSample(sample) }
        if phaseSamples.first?.sequence == 1 {
            try? await Task.sleep(for: .seconds(1))
        }
        return phaseSamples
    }
}

private struct FixedLoadTransport: LoadTransport {
    let outcome: LoadTransferOutcome
    func transfer(_: LoadRequest) async -> LoadTransferOutcome { outcome }
}

private actor InvocationCountingMeasurementTransport: MeasurementTransport {
    private(set) var invocationCount = 0

    func collect(session: MeasurementSession, plan: QuickCheckPlan, onSample: @escaping @Sendable (ProbeSample) async -> Void) async -> [ProbeSample] {
        invocationCount += 1
        return []
    }
}

private actor InvocationCountingLoadTransport: LoadTransport {
    private(set) var invocationCount = 0

    func transfer(_: LoadRequest) async -> LoadTransferOutcome {
        invocationCount += 1
        return .completed(bytesTransferred: 0)
    }
}

private struct FixedWiFiAvailability: WiFiAvailability {
    let available: Bool
    func isWiFiAvailable() async -> Bool { available }
}

private struct NoChangesObserver: NetworkPathObserver {
    func pathChanges() -> AsyncStream<Void> { AsyncStream { $0.finish() } }
}

private struct ImmediateChangeObserver: NetworkPathObserver {
    func pathChanges() -> AsyncStream<Void> {
        AsyncStream { continuation in
            continuation.yield()
            continuation.finish()
        }
    }
}

private actor RecordingDeepHistoryRepository: MeasurementHistoryRepository {
    var entries: [MeasurementHistoryEntry] = []
    func save(_ entry: MeasurementHistoryEntry) { entries.append(entry) }
    func loadHistory() -> [MeasurementHistoryEntry] { entries }
    func deleteAll() { entries = [] }
}
