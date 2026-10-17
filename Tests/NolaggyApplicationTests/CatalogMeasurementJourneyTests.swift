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

    func testDiscoveryCarriesOnlyTheSignedArtworkReferenceToTheUI() throws {
        let base = try payload()
        let artwork = RemoteCatalogArtwork(
            path: "artwork/fortnite-editorial.webp",
            sha256: String(repeating: "a", count: 64)
        )
        let first = try XCTUnwrap(base.games.first)
        let enrichedFortnite = RemoteCatalogGame(
            id: first.id,
            name: first.name,
            contexts: first.contexts,
            artwork: artwork
        )
        let payload = RemoteCatalogPayload(
            schemaVersion: base.schemaVersion,
            catalogVersion: base.catalogVersion,
            profiles: base.profiles,
            regions: base.regions,
            games: [enrichedFortnite] + Array(base.games.dropFirst()),
            assetBaseURL: "https://catalog.example.invalid/"
        )

        let game = try XCTUnwrap(
            CatalogMeasurementJourney.availableGames(in: payload, market: "BR", platform: .iphone)
                .first(where: { $0.id == "fortnite" })
        )

        XCTAssertEqual(game.artwork, artwork)
        XCTAssertEqual(game.assetBaseURL, "https://catalog.example.invalid/")
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

    func testManualGlobalCandidateEnrichesSnapshotAndResolvesFriendlyLabel() throws {
        let payload = try payload()
        let context = GameContext(gameID: "fortnite", market: "BR", platform: .iphone)

        let snapshot = try CatalogMeasurementJourney.regionalSnapshot(for: context, in: payload, manualRegionID: "us-east-1")
        let viewPt = CatalogMeasurementJourney.viewSnapshot(from: snapshot, in: payload, localeIdentifier: "pt_BR")
        let viewEn = CatalogMeasurementJourney.viewSnapshot(from: snapshot, in: payload, localeIdentifier: "en_US")

        XCTAssertEqual(snapshot.candidates.map(\.regionID), ["sa-east-1", "us-east-1"])
        let manualCandidate = snapshot.candidates.first(where: { $0.regionID == "us-east-1" })
        XCTAssertNotNil(manualCandidate)
        XCTAssertEqual(manualCandidate?.resolvedContext.destination.host, "gamelift-ping.us-east-1.api.aws")
        XCTAssertEqual(manualCandidate?.resolvedContext.destination.port, 7770)

        XCTAssertEqual(viewPt.candidates.first(where: { $0.regionID == "us-east-1" })?.label, "Virgínia do Norte")
        XCTAssertEqual(viewEn.candidates.first(where: { $0.regionID == "us-east-1" })?.label, "N. Virginia")
    }

    func testSpanishViewSnapshotResolvesSpanishLabel() throws {
        let payload = try payload()
        let context = GameContext(gameID: "fortnite", market: "BR", platform: .iphone)

        let snapshot = try CatalogMeasurementJourney.regionalSnapshot(for: context, in: payload, manualRegionID: "us-east-1")
        let viewEs = CatalogMeasurementJourney.viewSnapshot(from: snapshot, in: payload, localeIdentifier: "es_ES")

        XCTAssertEqual(viewEs.candidates.first(where: { $0.regionID == "us-east-1" })?.label, "Virginia del Norte")
    }

    func testResolvedMarketResolvesAvailableMarketOrGracefulFallback() throws {
        let payload = try payload()

        // Quando o sistema do usuário está no Brasil, resolve "BR"
        let marketBR = CatalogMeasurementJourney.resolvedMarket(in: payload, preferred: "BR")
        XCTAssertEqual(marketBR, "BR")

        // Quando o sistema do usuário está na Espanha ("ES"), faz fallback elegante para o mercado ativo do catálogo ("BR") sem quebrar
        let marketES = CatalogMeasurementJourney.resolvedMarket(in: payload, preferred: "ES")
        XCTAssertEqual(marketES, "BR")

        // Quando o sistema do usuário está na Alemanha ("DE"), faz fallback elegante
        let marketDE = CatalogMeasurementJourney.resolvedMarket(in: payload, preferred: "DE")
        XCTAssertEqual(marketDE, "BR")
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

    func testAutomaticOwnedRouteTriesSignedA2SCandidatesInPriorityOrderAndKeepsCandidateInRouteFact() async throws {
        let payload = try routedPayload()
        let context = GameContext(gameID: "route-fixture", market: "BR", platform: .pc)

        let resolved = try await AutomaticGameRouteResolver.resolve(
            context,
            in: payload,
            preflighting: StubRoutePreflight(acceptedRouteIDs: ["community-br-second"])
        )

        XCTAssertEqual(resolved?.routeKind, .gameOwned)
        XCTAssertEqual(resolved?.routeID, "community-br-community-br-second")
        XCTAssertEqual(resolved?.candidateID, "community-br-second")
        XCTAssertEqual(resolved?.destination.host, "community-br-second.community.example")
    }

    func testAutomaticOwnedRouteFallsBackToSignedAWSWhenNoIdentityPasses() async throws {
        let payload = try routedPayload()
        let context = GameContext(gameID: "route-fixture", market: "BR", platform: .pc)

        let resolved = try await AutomaticGameRouteResolver.resolve(
            context,
            in: payload,
            preflighting: StubRoutePreflight(acceptedRouteIDs: [])
        )

        XCTAssertEqual(resolved?.routeKind, .awsFallback)
        XCTAssertEqual(resolved?.routeID, "aws-sa-east-1")
        XCTAssertEqual(resolved?.destination.protocolKind, .gameLiftPing)
    }

    /// Vetores de decisão compartilhados com Android (`tools/vectors/steam-a2s-preflight-vectors.json`).
    func testRouteDecisionMatchesSharedVectors() async throws {
        let vectors = try SharedRouteDecisionVectors.load()
        XCTAssertEqual(vectors.routeDecisionVectors.count, 5)
        for vector in vectors.routeDecisionVectors {
            let payload = try routedPayload(candidates: vector.candidates.map { ($0.id, $0.priority) })
            let accepted = Set(vector.candidates.filter { $0.preflight == "accept" }.map(\.id))
            let resolved = try await AutomaticGameRouteResolver.resolve(
                GameContext(gameID: "route-fixture", market: "BR", platform: .pc),
                in: payload,
                preflighting: StubRoutePreflight(acceptedRouteIDs: accepted)
            )
            if vector.expectedRoute == "aws-fallback" {
                XCTAssertEqual(resolved?.routeKind, .awsFallback, vector.id)
                XCTAssertEqual(resolved?.destination.protocolKind, .gameLiftPing, vector.id)
            } else {
                XCTAssertEqual(resolved?.routeKind, .gameOwned, vector.id)
                XCTAssertEqual(resolved?.candidateID, vector.expectedRoute, vector.id)
            }
        }
    }

    func testNormalCatalogResolutionNeverMeasuresAutomaticCandidateWithoutPreflight() throws {
        let payload = try routedPayload()
        let context = GameContext(gameID: "route-fixture", market: "BR", platform: .pc)

        guard case let .available(resolved) = try RemoteCatalogVerifier.resolve(context, in: payload) else {
            return XCTFail("Expected signed fallback")
        }
        XCTAssertEqual(resolved.routeKind, .awsFallback)
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

    private func routedPayload() throws -> RemoteCatalogPayload {
        try routedPayload(candidates: [("community-br-first", 10), ("community-br-second", 20)])
    }

    private func routedPayload(candidates specs: [(id: String, priority: Int)]) throws -> RemoteCatalogPayload {
        let profile = RemoteCatalogProfile(id: "CASUAL_REALTIME", ruleVersion: "casual-realtime-2026.09.08.1")
        let region = RemoteCatalogRegion(
            id: "sa-east-1",
            label: ["pt-BR": "São Paulo"],
            probe: try ProbeDestination(host: "gamelift-ping.sa-east-1.api.aws", port: 7770, protocolKind: .gameLiftPing)
        )
        let identity = RemoteCatalogRouteIdentity(expectedAppID: 730, expectedGameDirectory: "csgo", expectedServerNamePrefix: "Community")
        let candidates = try specs.enumerated().map { index, spec in
            RemoteCatalogRouteCandidate(
                id: spec.id, priority: spec.priority,
                destination: try ProbeDestination(host: "\(spec.id).community.example", port: UInt16(27019 + index), protocolKind: .steamA2S),
                regionID: "sa-east-1", identity: identity, operatorEvidenceURL: "https://operator.example/\(spec.id)"
            )
        }
        let owned = RemoteCatalogRoute(
            id: "community-br", kind: .gameOwned, status: .active, regionID: "sa-east-1",
            strategy: .dedicatedServer, confidence: .high, precisionKey: "dedicatedServer",
            selection: RemoteCatalogRouteSelection(candidates: candidates)
        )
        let fallback = RemoteCatalogRoute(
            id: "aws-sa-east-1", kind: .awsFallback, status: .active, regionID: "sa-east-1",
            strategy: .genericRegion, confidence: .medium, precisionKey: "regionalReference"
        )
        return RemoteCatalogPayload(
            schemaVersion: 3, catalogVersion: "test-v3", profiles: [profile], regions: [region],
            games: [RemoteCatalogGame(
                id: "route-fixture", name: "Route Fixture",
                contexts: [RemoteCatalogGameContext(market: "BR", platforms: [.pc], profileID: profile.id, availability: .available, measurement: nil, routes: [owned, fallback])]
            )],
            assetBaseURL: "https://catalog.example/"
        )
    }

    func testGenericGamingGameFactoryBuildsValidJourneyGame() throws {
        let game = CatalogMeasurementJourney.genericGamingGame(
            market: "BR",
            platform: .playstation,
            declaredExternalLink: .ethernet,
            localizedName: "Conexão Geral para Jogos"
        )

        XCTAssertEqual(game.id, GameContext.genericGamingID)
        XCTAssertEqual(game.name, "Conexão Geral para Jogos")
        XCTAssertEqual(game.context.market, "BR")
        XCTAssertEqual(game.context.platform, .playstation)
        XCTAssertEqual(game.context.declaredExternalLink, .ethernet)
        XCTAssertEqual(game.profileID, .battleRoyaleCompetitive)
        XCTAssertNil(game.artwork)
    }
}

private struct StubRoutePreflight: GameRoutePreflighting {
    let acceptedRouteIDs: Set<String>

    func validates(candidate: ResolvedMeasurementContext, identity: RemoteCatalogRouteIdentity) async -> Bool {
        guard let routeID = candidate.routeID else { return false }
        return acceptedRouteIDs.contains { routeID.hasSuffix($0) }
    }
}

private struct SharedRouteDecisionVectors: Decodable {
    struct Candidate: Decodable { let id: String; let priority: Int; let preflight: String }
    struct Vector: Decodable { let id: String; let candidates: [Candidate]; let expectedRoute: String }
    let routeDecisionVectors: [Vector]

    static func load(file: StaticString = #filePath) throws -> SharedRouteDecisionVectors {
        var url = URL(fileURLWithPath: "\(file)")
        for _ in 0..<3 { url.deleteLastPathComponent() }
        url.appendPathComponent("tools/vectors/steam-a2s-preflight-vectors.json")
        return try JSONDecoder().decode(SharedRouteDecisionVectors.self, from: Data(contentsOf: url))
    }
}
