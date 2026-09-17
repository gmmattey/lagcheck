import XCTest
@testable import NolaggyDomain

final class RegionalSelectionRuleTests: XCTestCase {
    func testClearP50LeadSelectsFasterCandidate() throws {
        let snapshot = try makeSnapshot()

        let decision = try RegionalSelectionRule.select(
            snapshot: snapshot,
            preReadSamples: [
                "us-east-1": received(30, 31, 32),
                "us-east-2": received(38, 39, 40)
            ]
        )

        assertSelected(decision, regionID: "us-east-1", mode: .automatic, p50: 31, count: 3)
    }

    func testNearP50TiePrefersMoreValidResponsesThenCatalogPriority() throws {
        let snapshot = try makeSnapshot(priorities: ["us-east-1": 20, "us-east-2": 10])

        let moreResponses = try RegionalSelectionRule.select(
            snapshot: snapshot,
            preReadSamples: [
                "us-east-1": received(31, 31),
                "us-east-2": received(35, 35, 35)
            ]
        )
        assertSelected(moreResponses, regionID: "us-east-2", mode: .automatic, p50: 35, count: 3)

        let priority = try RegionalSelectionRule.select(
            snapshot: snapshot,
            preReadSamples: [
                "us-east-1": received(31, 31, 31),
                "us-east-2": received(35, 35, 35)
            ]
        )
        assertSelected(priority, regionID: "us-east-2", mode: .automatic, p50: 35, count: 3)
    }

    func testCompleteTieUsesLexicographicRegionID() throws {
        let snapshot = try makeSnapshot(priorities: ["us-east-1": 10, "us-east-2": 10])
        let decision = try RegionalSelectionRule.select(
            snapshot: snapshot,
            preReadSamples: ["us-east-1": received(35, 35), "us-east-2": received(35, 35)]
        )

        assertSelected(decision, regionID: "us-east-1", mode: .automatic, p50: 35, count: 2)
    }

    func testManualOverrideRestrictsPreReadToSelectedSignedCandidate() throws {
        let snapshot = try makeSnapshot()
        let decision = try RegionalSelectionRule.select(
            snapshot: snapshot,
            preReadSamples: [
                "us-east-1": received(20, 20, 20),
                "us-east-2": received(40, 41, 42)
            ],
            manualRegionID: "us-east-2"
        )

        assertSelected(decision, regionID: "us-east-2", mode: .manual, p50: 41, count: 3)
    }

    func testManualCandidateOutsideSnapshotIsRejected() throws {
        XCTAssertThrowsError(try RegionalSelectionRule.select(
            snapshot: makeSnapshot(),
            preReadSamples: [:],
            manualRegionID: "sa-east-1"
        )) { error in
            XCTAssertEqual(error as? RegionalSelectionError, .manualCandidateNotAllowed)
        }
    }

    func testNoCandidateWithTwoValidResponsesIsInconclusiveWithoutFallback() throws {
        let snapshot = try makeSnapshot()
        let decision = try RegionalSelectionRule.select(
            snapshot: snapshot,
            preReadSamples: [
                "us-east-1": [RegionalPreReadSample(outcome: .timeout)],
                "us-east-2": [RegionalPreReadSample(outcome: .received, roundTripMilliseconds: 35)]
            ]
        )

        XCTAssertEqual(decision, .inconclusive(.noViableRegionalCandidate))
    }

    func testSnapshotRejectsCandidatesOutsideItsSignedContext() throws {
        let current = try makeResolvedContext(regionID: "us-east-1", catalogVersion: "catalog-v2")
        let otherVersion = try makeResolvedContext(regionID: "us-east-2", catalogVersion: "catalog-v1")
        let candidates = [
            try RegionalSelectionCandidate(resolvedContext: current, priority: 0),
            try RegionalSelectionCandidate(resolvedContext: otherVersion, priority: 1)
        ]

        XCTAssertThrowsError(try RegionalSelectionSnapshot(
            catalogVersion: "catalog-v2", context: current.context, candidates: candidates
        )) { error in
            XCTAssertEqual(error as? RegionalSelectionError, .candidateOutsideSnapshot)
        }
    }
}

private extension RegionalSelectionRuleTests {
    func makeSnapshot(priorities: [String: Int] = ["us-east-1": 0, "us-east-2": 1]) throws -> RegionalSelectionSnapshot {
        let context = GameContext(gameID: "fortnite", market: "US", platform: .iphone)
        let candidates = try ["us-east-1", "us-east-2"].map { regionID in
            try RegionalSelectionCandidate(
                resolvedContext: makeResolvedContext(regionID: regionID, catalogVersion: "catalog-v2", context: context),
                priority: priorities[regionID]!
            )
        }
        return try RegionalSelectionSnapshot(catalogVersion: "catalog-v2", context: context, candidates: candidates)
    }

    func makeResolvedContext(
        regionID: String,
        catalogVersion: String,
        context: GameContext = GameContext(gameID: "fortnite", market: "US", platform: .iphone)
    ) throws -> ResolvedMeasurementContext {
        ResolvedMeasurementContext(
            context: context,
            catalogVersion: catalogVersion,
            profileID: .battleRoyaleCompetitive,
            regionID: regionID,
            destination: try ProbeDestination(host: "gamelift-ping.\(regionID).api.aws", port: 7770),
            strategy: .genericRegion,
            confidence: .medium
        )
    }

    func received(_ values: Double...) -> [RegionalPreReadSample] {
        values.map { RegionalPreReadSample(outcome: .received, roundTripMilliseconds: $0) }
    }

    func assertSelected(
        _ decision: RegionalSelectionDecision,
        regionID: String,
        mode: RegionalSelectionMode,
        p50: Double,
        count: Int
    ) {
        guard case let .selected(result) = decision else { return XCTFail("Expected a selected regional candidate.") }
        XCTAssertEqual(result.ruleVersion, "regional-selection-1")
        XCTAssertEqual(result.selected.regionID, regionID)
        XCTAssertEqual(result.mode, mode)
        XCTAssertEqual(result.p50Milliseconds, p50)
        XCTAssertEqual(result.validResponseCount, count)
    }
}
