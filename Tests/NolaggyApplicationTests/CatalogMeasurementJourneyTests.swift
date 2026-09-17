import XCTest
@testable import NolaggyApplication
@testable import NolaggyDomain

final class CatalogMeasurementJourneyTests: XCTestCase {
    func testDiscoveryExposesOnlyValidatedAvailableContexts() throws {
        let payload = try payload()

        let games = CatalogMeasurementJourney.availableGames(in: payload, market: "BR", platform: .iphone)

        XCTAssertEqual(games.map(\.id), [
            "fortnite", "call-of-duty-mobile", "free-fire", "pubg-mobile",
            "brawl-stars", "wild-rift", "roblox", "minecraft"
        ])
        XCTAssertEqual(games.first?.context.market, "BR")
        XCTAssertEqual(games.first?.context.platform, .iphone)
    }

    func testSchemaOneContextBuildsSingleSignedRegionalCandidate() throws {
        let payload = try payload()
        let context = GameContext(gameID: "fortnite", market: "BR", platform: .iphone)

        let snapshot = try CatalogMeasurementJourney.regionalSnapshot(for: context, in: payload)
        let view = CatalogMeasurementJourney.viewSnapshot(from: snapshot, in: payload, localeIdentifier: "pt_BR")

        XCTAssertEqual(snapshot.candidates.map(\.regionID), ["sa-east-1"])
        XCTAssertEqual(snapshot.candidates.map(\.priority), [0])
        XCTAssertEqual(view.candidates.first?.label, "São Paulo")
        XCTAssertEqual(view.candidates.first?.resolvedContext.destination.host, "gamelift-ping.sa-east-1.api.aws")
    }

    func testUnavailableContextCannotCreateRegionalSnapshot() throws {
        let payload = try payload(availableFortnite: false)

        XCTAssertThrowsError(try CatalogMeasurementJourney.regionalSnapshot(
            for: GameContext(gameID: "fortnite", market: "BR", platform: .iphone),
            in: payload
        )) { error in
            XCTAssertEqual(error as? CatalogMeasurementJourney.Error, .unavailableContext)
        }
    }

    private func payload(availableFortnite: Bool = true) throws -> RemoteCatalogPayload {
        let profiles = [
            RemoteCatalogProfile(id: "BATTLE_ROYALE_COMPETITIVE", ruleVersion: "pilot-2026.09.08.1"),
            RemoteCatalogProfile(id: "MOBILE_REALTIME", ruleVersion: "mobile-realtime-2026.09.08.1"),
            RemoteCatalogProfile(id: "CASUAL_REALTIME", ruleVersion: "casual-realtime-2026.09.08.1")
        ]
        let measurement = RemoteCatalogMeasurement(
            primaryRegion: "sa-east-1", strategy: .genericRegion, confidence: .medium, precisionKey: "regionalReference"
        )
        let context = RemoteCatalogGameContext(
            market: "BR", platforms: [.iphone], profileID: "BATTLE_ROYALE_COMPETITIVE",
            availability: availableFortnite ? .available : .unavailable,
            measurement: availableFortnite ? measurement : nil
        )
        let games = [
            RemoteCatalogGame(id: "fortnite", name: "Fortnite", contexts: [context]),
            RemoteCatalogGame(id: "call-of-duty-mobile", name: "Call of Duty: Mobile", contexts: [availableContext(profile: "BATTLE_ROYALE_COMPETITIVE", measurement: measurement)]),
            RemoteCatalogGame(id: "free-fire", name: "Free Fire", contexts: [availableContext(profile: "BATTLE_ROYALE_COMPETITIVE", measurement: measurement)]),
            RemoteCatalogGame(id: "pubg-mobile", name: "PUBG MOBILE", contexts: [availableContext(profile: "BATTLE_ROYALE_COMPETITIVE", measurement: measurement)]),
            RemoteCatalogGame(id: "brawl-stars", name: "Brawl Stars", contexts: [availableContext(profile: "MOBILE_REALTIME", measurement: measurement)]),
            RemoteCatalogGame(id: "wild-rift", name: "Wild Rift", contexts: [availableContext(profile: "MOBILE_REALTIME", measurement: measurement)]),
            RemoteCatalogGame(id: "roblox", name: "Roblox", contexts: [availableContext(profile: "CASUAL_REALTIME", measurement: measurement)]),
            RemoteCatalogGame(id: "minecraft", name: "Minecraft", contexts: [availableContext(profile: "CASUAL_REALTIME", measurement: measurement)])
        ]
        return RemoteCatalogPayload(
            schemaVersion: 1,
            catalogVersion: "test-v1",
            profiles: profiles,
            regions: [RemoteCatalogRegion(id: "sa-east-1", label: ["pt-BR": "São Paulo", "en": "São Paulo"], probe: try ProbeDestination(host: "gamelift-ping.sa-east-1.api.aws", port: 7770))],
            games: games
        )
    }

    private func unavailableContext(profile: String) -> RemoteCatalogGameContext {
        RemoteCatalogGameContext(market: "BR", platforms: [.iphone], profileID: profile, availability: .unavailable, measurement: nil)
    }

    private func availableContext(profile: String, measurement: RemoteCatalogMeasurement) -> RemoteCatalogGameContext {
        RemoteCatalogGameContext(market: "BR", platforms: [.iphone], profileID: profile, availability: .available, measurement: measurement)
    }
}
