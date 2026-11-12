import XCTest
@testable import NolaggyApplication
@testable import NolaggyDomain

final class RegionalPreReadLifecycleTests: XCTestCase {
    func testManualCancellationDiscardsRegionalPreRead() async throws {
        let lifecycle = MeasurementSessionCoordinator(pathObserver: SilentRegionalPathObserver())
        let snapshot = try snapshot()
        let selection = Task {
            try await lifecycle.selectRegionalCandidate(
                snapshot: snapshot,
                using: RegionalPreReadCoordinator(collector: DelayedRegionalCollector())
            )
        }

        try await waitUntilActive(lifecycle)
        await lifecycle.cancelRegionalPreRead()

        await assertCancelled(selection)
        let active = await lifecycle.isRegionalPreReadActive()
        XCTAssertFalse(active)
    }

    func testBackgroundDiscardsRegionalPreRead() async throws {
        let lifecycle = MeasurementSessionCoordinator(pathObserver: SilentRegionalPathObserver())
        let snapshot = try snapshot()
        let selection = Task {
            try await lifecycle.selectRegionalCandidate(
                snapshot: snapshot,
                using: RegionalPreReadCoordinator(collector: DelayedRegionalCollector())
            )
        }

        try await waitUntilActive(lifecycle)
        await lifecycle.appDidEnterBackground()

        await assertCancelled(selection)
        let active = await lifecycle.isRegionalPreReadActive()
        XCTAssertFalse(active)
    }

    func testNetworkPathChangeDiscardsRegionalPreRead() async throws {
        let lifecycle = MeasurementSessionCoordinator(pathObserver: ImmediateRegionalPathObserver())
        let snapshot = try snapshot()
        let selection = Task {
            try await lifecycle.selectRegionalCandidate(
                snapshot: snapshot,
                using: RegionalPreReadCoordinator(collector: DelayedRegionalCollector())
            )
        }

        await assertCancelled(selection)
        let active = await lifecycle.isRegionalPreReadActive()
        XCTAssertFalse(active)
    }

    private func waitUntilActive(_ lifecycle: MeasurementSessionCoordinator) async throws {
        for _ in 0..<20 {
            if await lifecycle.isRegionalPreReadActive() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("A pré-leitura deveria estar ativa antes do cancelamento.")
    }

    private func assertCancelled(_ task: Task<RegionalSelectionDecision, Error>) async {
        do {
            _ = try await task.value
            XCTFail("A pré-leitura deveria descartar a sessão após cancelamento.")
        } catch is CancellationError {
            // Esperado: não há decisão regional parcial para reaproveitar.
        } catch {
            XCTFail("Erro inesperado: \(error)")
        }
    }

    private func snapshot() throws -> RegionalSelectionSnapshot {
        let context = GameContext(gameID: "fortnite", market: "BR", platform: .iphone)
        let resolved = ResolvedMeasurementContext(
            context: context,
            catalogVersion: "regional-test-v1",
            profileID: .battleRoyaleCompetitive,
            regionID: "sa-east-1",
            destination: try ProbeDestination(host: "reference.invalid", port: 7770),
            strategy: .genericRegion,
            confidence: .medium
        )
        return try RegionalSelectionSnapshot(
            catalogVersion: resolved.catalogVersion,
            context: context,
            candidates: [try RegionalSelectionCandidate(resolvedContext: resolved, priority: 0)]
        )
    }
}

private struct DelayedRegionalCollector: RegionalPreReadCollecting {
    func collect(candidate: RegionalSelectionCandidate) async -> [RegionalPreReadSample] {
        try? await Task.sleep(for: .seconds(1))
        return []
    }
}

private struct SilentRegionalPathObserver: NetworkPathObserver {
    func pathChanges() -> AsyncStream<Void> { AsyncStream { $0.finish() } }
}

private struct ImmediateRegionalPathObserver: NetworkPathObserver {
    func pathChanges() -> AsyncStream<Void> {
        AsyncStream {
            $0.yield()
            $0.finish()
        }
    }
}
