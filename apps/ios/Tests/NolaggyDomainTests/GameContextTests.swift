import XCTest
@testable import NolaggyDomain

final class GameContextTests: XCTestCase {
    func testContextPreservesPilotScope() {
        let context = GameContext(gameID: "pilot-game", market: "BR", platform: .iphone)

        XCTAssertEqual(context.gameID, "pilot-game")
        XCTAssertEqual(context.market, "BR")
        XCTAssertEqual(context.platform, .iphone)
        XCTAssertNil(context.declaredExternalLink)
    }

    func testPilotCatalogResolvesOnlyApprovedReferenceContext() throws {
        let resolved = try PilotCatalog.pilotBase.resolve(
            GameContext(gameID: "fortnite", market: "BR", platform: .iphone)
        )

        XCTAssertEqual(resolved.catalogVersion, "pilot-2026.09.08.1")
        XCTAssertEqual(resolved.profileID, .battleRoyaleCompetitive)
        XCTAssertEqual(resolved.regionID, "sa-east-1")
        XCTAssertEqual(resolved.destination.host, "gamelift-ping.sa-east-1.api.aws")
        XCTAssertEqual(resolved.destination.port, 7770)
        XCTAssertEqual(resolved.strategy, .genericRegion)
        XCTAssertEqual(resolved.confidence, .medium)
    }

    func testPilotCatalogRejectsAnyGameOutsidePilot() {
        XCTAssertThrowsError(
            try PilotCatalog.pilotBase.resolve(GameContext(gameID: "another-game", market: "BR", platform: .iphone))
        ) { error in
            XCTAssertEqual(error as? CatalogValidationError, .unsupportedGame)
        }
    }

    func testPilotCatalogRejectsUnsupportedMarketAndPlatform() {
        XCTAssertThrowsError(
            try PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "US", platform: .iphone))
        ) { error in
            XCTAssertEqual(error as? CatalogValidationError, .unsupportedMarket)
        }
        XCTAssertThrowsError(
            try PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "BR", platform: .pc))
        ) { error in
            XCTAssertEqual(error as? CatalogValidationError, .unsupportedPlatform)
        }
    }

    func testContextRejectsExternalEquipmentLinkForIPhone() {
        XCTAssertThrowsError(
            try PilotCatalog.pilotBase.resolve(
                GameContext(gameID: "fortnite", market: "BR", platform: .iphone, declaredExternalLink: .wifi)
            )
        ) { error in
            XCTAssertEqual(error as? CatalogValidationError, .externalEquipmentLinkNotApplicable)
        }
    }

    func testObservedPhoneNetworkPreservesDeclaredExternalLink() throws {
        let context = ResolvedMeasurementContext(
            context: GameContext(gameID: "fortnite", market: "BR", platform: .playstation, declaredExternalLink: .ethernet),
            catalogVersion: "catalog-1",
            profileID: .battleRoyaleCompetitive,
            regionID: "sa-east-1",
            destination: try ProbeDestination(host: "gamelift-ping.sa-east-1.api.aws", port: 7770),
            strategy: .genericRegion,
            confidence: .medium
        )

        let observed = context.withObservedPhoneNetwork(.cellular)

        XCTAssertEqual(observed.context.declaredExternalLink, .ethernet)
        XCTAssertEqual(observed.observedPhoneNetwork, .cellular)
        XCTAssertTrue(observed.hasCompleteConnectionFacts)
    }

    func testCatalogRejectsInvalidDestinationAndDanglingRegion() throws {
        XCTAssertThrowsError(try ProbeDestination(host: "GameLift.example", port: 7770)) { error in
            XCTAssertEqual(error as? CatalogValidationError, .invalidProbeHost)
        }

        let destination = try ProbeDestination(host: "probe.example", port: 7770)
        let region = try CatalogRegion(id: "sa-east-1", destination: destination)
        let game = try CatalogGame(
            id: "fortnite",
            market: "BR",
            supportedPlatforms: [.iphone],
            profileID: .battleRoyaleCompetitive,
            primaryRegionID: "missing-region",
            strategy: .genericRegion,
            confidence: .medium
        )
        XCTAssertThrowsError(try PilotCatalog(version: "test", regions: [region], games: [game])) { error in
            XCTAssertEqual(error as? CatalogValidationError, .unknownPrimaryRegion)
        }
    }

    func testGenericGamingContextInitializationAndInvariants() throws {
        let mobileContext = GameContext.genericGaming(market: "BR", platform: .iphone)
        XCTAssertTrue(mobileContext.isGenericGaming)
        XCTAssertEqual(mobileContext.gameID, GameContext.genericGamingID)
        XCTAssertEqual(mobileContext.market, "BR")
        XCTAssertEqual(mobileContext.platform, .iphone)
        XCTAssertNil(mobileContext.declaredExternalLink)
        XCTAssertNoThrow(try mobileContext.validateStructure())

        let consoleContext = GameContext.genericGaming(market: "BR", platform: .playstation, declaredExternalLink: .ethernet)
        XCTAssertTrue(consoleContext.isGenericGaming)
        XCTAssertEqual(consoleContext.platform, .playstation)
        XCTAssertEqual(consoleContext.declaredExternalLink, .ethernet)
        XCTAssertNoThrow(try consoleContext.validateStructure())

        let invalidMobileContext = GameContext.genericGaming(market: "BR", platform: .iphone, declaredExternalLink: .wifi)
        XCTAssertThrowsError(try invalidMobileContext.validateStructure()) { error in
            XCTAssertEqual(error as? CatalogValidationError, .externalEquipmentLinkNotApplicable)
        }
    }
}
