import CryptoKit
import XCTest
@testable import NolaggyDomain

final class RemoteCatalogTests: XCTestCase {
    func testValidSignedCatalogResolvesPublishedProfileContexts() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let payload = debugPayload()
        let verified = try verify(payload, with: privateKey)

        let fortnite = try RemoteCatalogVerifier.resolve(
            GameContext(gameID: "fortnite", market: "BR", platform: .iphone), in: verified
        )
        let minecraft = try RemoteCatalogVerifier.resolve(
            GameContext(gameID: "minecraft", market: "BR", platform: .iphone), in: verified
        )

        guard case let .available(context) = fortnite else { return XCTFail("Fortnite must be the only Debug context available.") }
        XCTAssertEqual(context.destination.host, "gamelift-ping.sa-east-1.api.aws")
        XCTAssertEqual(context.strategy, .genericRegion)
        XCTAssertEqual(context.confidence, .medium)
        guard case .available = minecraft else { return XCTFail("Minecraft must use the approved regional-reference strategy in v2.") }
    }

    func testPublishedDebugEnvelopeFeedsAllEightBRIPhoneContextsWithoutFortniteFallback() throws {
        let payload = try RemoteCatalogVerifier.verifyAndDecode(
            envelopeData: try publishedDebugEnvelopeData(),
            now: ISO8601DateFormatter().date(from: "2026-09-08T12:00:00Z")!
        )
        let expectedProfiles: [String: QualityProfileID] = [
            "fortnite": .battleRoyaleCompetitive,
            "call-of-duty-mobile": .battleRoyaleCompetitive,
            "free-fire": .battleRoyaleCompetitive,
            "pubg-mobile": .battleRoyaleCompetitive,
            "brawl-stars": .mobileRealtime,
            "wild-rift": .mobileRealtime,
            "roblox": .casualRealtime,
            "minecraft": .casualRealtime
        ]

        XCTAssertEqual(payload.catalogVersion, "debug-2026.09.08.2")
        XCTAssertEqual(payload.games.map(\.id).sorted(), expectedProfiles.keys.sorted())

        for (gameID, expectedProfile) in expectedProfiles {
            let gameContext = GameContext(gameID: gameID, market: "BR", platform: .iphone)
            let resolution = try RemoteCatalogVerifier.resolve(gameContext, in: payload)
            guard case let .available(resolved) = resolution else {
                return XCTFail("\(gameID) must be available in the published BR catalog.")
            }
            XCTAssertEqual(resolved.context.gameID, gameID)
            XCTAssertEqual(resolved.profileID, expectedProfile)
            XCTAssertEqual(resolved.profileRuleVersion, QualityEvaluator.ruleVersion(for: expectedProfile))
            XCTAssertEqual(resolved.regionID, "sa-east-1")
            XCTAssertEqual(resolved.strategy, .genericRegion)
            XCTAssertEqual(resolved.confidence, .medium)
            XCTAssertEqual(resolved.precisionKey, "regionalReference")
            XCTAssertTrue(QualityEvaluator.supports(profile: resolved.profileID, ruleVersion: resolved.profileRuleVersion))

            let snapshot = try RemoteCatalogVerifier.regionalSelectionSnapshot(gameContext, in: payload)
            XCTAssertEqual(snapshot.candidates.count, 1)
            XCTAssertEqual(snapshot.candidates[0].regionID, "sa-east-1")
            XCTAssertEqual(snapshot.candidates[0].resolvedContext.context.gameID, gameID)

            guard case .completed = QualityEvaluator.evaluate(samples: receivedSamples(), profile: resolved.profileID) else {
                return XCTFail("\(gameID) must be evaluable by its own profile.")
            }
        }
    }

    func testTamperedPayloadIsRejectedBeforeJSONValidation() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let payload = debugPayload()
        let signed = try signedEnvelope(payload, with: privateKey)
        let envelope = SignedCatalogEnvelope(
            schemaVersion: signed.schemaVersion,
            catalogVersion: signed.catalogVersion,
            issuedAt: signed.issuedAt,
            expiresAt: signed.expiresAt,
            algorithm: signed.algorithm,
            payloadBase64: Data("{\"tampered\":true}".utf8).base64EncodedString(),
            signatureBase64: signed.signatureBase64
        )

        XCTAssertThrowsError(try decode(envelope, publicKey: privateKey.publicKey)) { error in
            XCTAssertEqual(error as? RemoteCatalogError, .invalidSignature)
        }
    }

    func testExpiredEnvelopeIsRejectedEvenWhenItsSignatureIsValid() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let envelope = try signedEnvelope(debugPayload(), with: privateKey, expiresAt: "2026-09-08T11:00:00Z")

        XCTAssertThrowsError(try decode(envelope, publicKey: privateKey.publicKey)) { error in
            XCTAssertEqual(error as? RemoteCatalogError, .expired)
        }
    }

    func testAvailableContextWithoutAValidatedMeasurementIsRejected() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        var payload = debugPayload()
        var games = payload.games
        games[0] = RemoteCatalogGame(id: "fortnite", name: "Fortnite", contexts: [RemoteCatalogGameContext(
            market: "BR", platforms: [.iphone], profileID: "BATTLE_ROYALE_COMPETITIVE", availability: .available, measurement: nil
        )])
        payload = RemoteCatalogPayload(schemaVersion: payload.schemaVersion, catalogVersion: payload.catalogVersion, profiles: payload.profiles, regions: payload.regions, games: games)

        XCTAssertThrowsError(try verify(payload, with: privateKey)) { error in
            XCTAssertEqual(error as? RemoteCatalogError, .invalidAvailability)
        }
    }

    func testUnavailableContextIsRejectedByTheV2AvailabilityPolicy() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        var payload = debugPayload()
        var games = payload.games
        games[1] = RemoteCatalogGame(id: "call-of-duty-mobile", name: "Call of Duty: Mobile", contexts: [RemoteCatalogGameContext(
            market: "BR", platforms: [.iphone], profileID: "MOBILE_REALTIME", availability: .unavailable,
            measurement: RemoteCatalogMeasurement(primaryRegion: "sa-east-1", strategy: .genericRegion, confidence: .medium, precisionKey: "regionalReference")
        )])
        payload = RemoteCatalogPayload(schemaVersion: payload.schemaVersion, catalogVersion: payload.catalogVersion, profiles: payload.profiles, regions: payload.regions, games: games)

        XCTAssertThrowsError(try verify(payload, with: privateKey)) { error in
            XCTAssertEqual(error as? RemoteCatalogError, .invalidAvailability)
        }
    }

    func testSchemaTwoBuildsSelectionSnapshotFromExplicitCandidateAndPriority() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let verified = try verify(schemaTwoPayload(), with: privateKey)

        let snapshot = try RemoteCatalogVerifier.regionalSelectionSnapshot(
            GameContext(gameID: "fortnite", market: "BR", platform: .iphone), in: verified
        )

        XCTAssertEqual(snapshot.catalogVersion, "debug-2026.09.08.3")
        XCTAssertEqual(snapshot.candidates.map(\.regionID), ["sa-east-1"])
        XCTAssertEqual(snapshot.candidates.map(\.priority), [10])
    }

    func testSchemaTwoRejectsMissingPriorityForCandidate() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        var payload = schemaTwoPayload()
        var games = payload.games
        games[0] = RemoteCatalogGame(id: "fortnite", name: "Fortnite", contexts: [RemoteCatalogGameContext(
            market: "BR", platforms: [.iphone], profileID: "BATTLE_ROYALE_COMPETITIVE", availability: .available,
            measurement: RemoteCatalogMeasurement(
                candidateRegionIDs: ["sa-east-1"], candidatePriorities: [:],
                strategy: .genericRegion, confidence: .medium, precisionKey: "regionalReference"
            )
        )])
        payload = RemoteCatalogPayload(schemaVersion: payload.schemaVersion, catalogVersion: payload.catalogVersion, profiles: payload.profiles, regions: payload.regions, games: games)

        XCTAssertThrowsError(try verify(payload, with: privateKey)) { error in
            XCTAssertEqual(error as? RemoteCatalogError, .invalidAvailability)
        }
    }

    func testSchemaTwoRejectsUnknownOrDuplicateCandidates() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        for (candidateIDs, priorities) in [
            (["unknown-region"], ["unknown-region": 10]),
            (["sa-east-1", "sa-east-1"], ["sa-east-1": 10])
        ] {
            var payload = schemaTwoPayload()
            var games = payload.games
            games[0] = RemoteCatalogGame(id: "fortnite", name: "Fortnite", contexts: [RemoteCatalogGameContext(
                market: "BR", platforms: [.iphone], profileID: "BATTLE_ROYALE_COMPETITIVE", availability: .available,
                measurement: RemoteCatalogMeasurement(
                    candidateRegionIDs: candidateIDs,
                    candidatePriorities: priorities,
                    strategy: .genericRegion, confidence: .medium, precisionKey: "regionalReference"
                )
            )])
            payload = RemoteCatalogPayload(schemaVersion: payload.schemaVersion, catalogVersion: payload.catalogVersion, profiles: payload.profiles, regions: payload.regions, games: games)

            XCTAssertThrowsError(try verify(payload, with: privateKey)) { error in
                XCTAssertEqual(error as? RemoteCatalogError, .invalidAvailability)
            }
        }
    }

    func testSchemaOneRejectsCandidateFieldsToKeepCompatibilityExplicit() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        var payload = debugPayload()
        var games = payload.games
        games[0] = RemoteCatalogGame(id: "fortnite", name: "Fortnite", contexts: [RemoteCatalogGameContext(
            market: "BR", platforms: [.iphone], profileID: "BATTLE_ROYALE_COMPETITIVE", availability: .available,
            measurement: RemoteCatalogMeasurement(
                primaryRegion: "sa-east-1", candidateRegionIDs: ["sa-east-1"], candidatePriorities: ["sa-east-1": 0],
                strategy: .genericRegion, confidence: .medium, precisionKey: "regionalReference"
            )
        )])
        payload = RemoteCatalogPayload(schemaVersion: payload.schemaVersion, catalogVersion: payload.catalogVersion, profiles: payload.profiles, regions: payload.regions, games: games)

        XCTAssertThrowsError(try verify(payload, with: privateKey)) { error in
            XCTAssertEqual(error as? RemoteCatalogError, .invalidAvailability)
        }
    }

    func testConsolePlatformsResolveForCrossplayGamesUsingTheSameRegionalReference() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        var payload = debugPayload()
        var games = payload.games
        games[0] = crossplayGame(id: "fortnite", name: "Fortnite", profileID: "BATTLE_ROYALE_COMPETITIVE", platforms: [.iphone, .playstation, .xbox])
        games[6] = crossplayGame(id: "roblox", name: "Roblox", profileID: "CASUAL_REALTIME", platforms: [.iphone, .xbox])
        games[7] = crossplayGame(id: "minecraft", name: "Minecraft", profileID: "CASUAL_REALTIME", platforms: [.iphone, .playstation, .xbox])
        payload = RemoteCatalogPayload(schemaVersion: payload.schemaVersion, catalogVersion: payload.catalogVersion, profiles: payload.profiles, regions: payload.regions, games: games)
        let verified = try verify(payload, with: privateKey)

        for (gameID, platform) in [("fortnite", Platform.playstation), ("fortnite", .xbox), ("roblox", .xbox), ("minecraft", .playstation), ("minecraft", .xbox)] {
            let resolution = try RemoteCatalogVerifier.resolve(
                GameContext(gameID: gameID, market: "BR", platform: platform, equipmentConnection: .wifi), in: verified
            )
            guard case let .available(resolved) = resolution else {
                return XCTFail("\(gameID) must resolve on \(platform) using the same regional reference.")
            }
            XCTAssertEqual(resolved.destination.host, "gamelift-ping.sa-east-1.api.aws")
            XCTAssertEqual(resolved.strategy, .genericRegion)
        }

        XCTAssertThrowsError(try RemoteCatalogVerifier.resolve(
            GameContext(gameID: "roblox", market: "BR", platform: .playstation, equipmentConnection: .wifi), in: verified
        ))
    }

    func testCatalogRejectsAPlatformOutsideTheGameApprovedCeiling() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        for (gameID, name, profileID, disallowedPlatform) in [
            ("roblox", "Roblox", "CASUAL_REALTIME", Platform.playstation),
            ("wild-rift", "League of Legends: Wild Rift", "MOBILE_REALTIME", Platform.xbox),
            ("free-fire", "Free Fire", "BATTLE_ROYALE_COMPETITIVE", Platform.playstation)
        ] {
            var payload = debugPayload()
            var games = payload.games
            let index = games.firstIndex { $0.id == gameID }!
            games[index] = crossplayGame(id: gameID, name: name, profileID: profileID, platforms: [.iphone, disallowedPlatform])
            payload = RemoteCatalogPayload(schemaVersion: payload.schemaVersion, catalogVersion: payload.catalogVersion, profiles: payload.profiles, regions: payload.regions, games: games)

            XCTAssertThrowsError(try verify(payload, with: privateKey)) { error in
                XCTAssertEqual(error as? RemoteCatalogError, .unsupportedDebugCatalog)
            }
        }
    }

    func testProfileWithUnsupportedRuleVersionIsRejectedBeforeResolution() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        var payload = debugPayload()
        var profiles = payload.profiles
        profiles[1] = RemoteCatalogProfile(id: "MOBILE_REALTIME", ruleVersion: "mobile-realtime-unknown")
        payload = RemoteCatalogPayload(schemaVersion: payload.schemaVersion, catalogVersion: payload.catalogVersion, profiles: profiles, regions: payload.regions, games: payload.games)

        XCTAssertThrowsError(try verify(payload, with: privateKey)) { error in
            XCTAssertEqual(error as? RemoteCatalogError, .unknownProfile)
        }
    }
}

private extension RemoteCatalogTests {
    func verify(_ payload: RemoteCatalogPayload, with privateKey: Curve25519.Signing.PrivateKey) throws -> RemoteCatalogPayload {
        try decode(try signedEnvelope(payload, with: privateKey), publicKey: privateKey.publicKey)
    }

    func decode(_ envelope: SignedCatalogEnvelope, publicKey: Curve25519.Signing.PublicKey) throws -> RemoteCatalogPayload {
        try RemoteCatalogVerifier.verifyAndDecode(
            envelopeData: try JSONEncoder().encode(envelope),
            publicKeyBase64: publicKey.rawRepresentation.base64EncodedString(),
            now: ISO8601DateFormatter().date(from: "2026-09-08T12:00:00Z")!
        )
    }

    func signedEnvelope(
        _ payload: RemoteCatalogPayload,
        with privateKey: Curve25519.Signing.PrivateKey,
        expiresAt: String = "2026-10-08T00:00:00Z"
    ) throws -> SignedCatalogEnvelope {
        let payloadData = try JSONEncoder().encode(payload)
        return SignedCatalogEnvelope(
            schemaVersion: payload.schemaVersion,
            catalogVersion: payload.catalogVersion,
            issuedAt: "2026-09-08T00:00:00Z",
            expiresAt: expiresAt,
            algorithm: "Ed25519",
            payloadBase64: payloadData.base64EncodedString(),
            signatureBase64: try privateKey.signature(for: payloadData).base64EncodedString()
        )
    }

    func debugPayload() -> RemoteCatalogPayload {
        let profiles = [
            RemoteCatalogProfile(id: "BATTLE_ROYALE_COMPETITIVE", ruleVersion: "pilot-2026.09.08.1"),
            RemoteCatalogProfile(id: "MOBILE_REALTIME", ruleVersion: "mobile-realtime-2026.09.08.1"),
            RemoteCatalogProfile(id: "CASUAL_REALTIME", ruleVersion: "casual-realtime-2026.09.08.1")
        ]
        let region = RemoteCatalogRegion(
            id: "sa-east-1", label: ["pt-BR": "São Paulo", "en": "São Paulo"],
            probe: try! ProbeDestination(host: "gamelift-ping.sa-east-1.api.aws", port: 7770)
        )
        let available: (String, String, String) -> RemoteCatalogGame = { id, name, profileID in
            RemoteCatalogGame(id: id, name: name, contexts: [
                RemoteCatalogGameContext(market: "BR", platforms: [.iphone], profileID: profileID, availability: .available, measurement: RemoteCatalogMeasurement(primaryRegion: "sa-east-1", strategy: .genericRegion, confidence: .medium, precisionKey: "regionalReference"))
            ])
        }
        return RemoteCatalogPayload(
            schemaVersion: 1,
            catalogVersion: "debug-2026.09.08.1",
            profiles: profiles,
            regions: [region],
            games: [
                RemoteCatalogGame(id: "fortnite", name: "Fortnite", contexts: [
                    RemoteCatalogGameContext(
                        market: "BR", platforms: [.iphone], profileID: "BATTLE_ROYALE_COMPETITIVE", availability: .available,
                        measurement: RemoteCatalogMeasurement(primaryRegion: "sa-east-1", strategy: .genericRegion, confidence: .medium, precisionKey: "regionalReference")
                    )
                ]),
                available("call-of-duty-mobile", "Call of Duty: Mobile", "BATTLE_ROYALE_COMPETITIVE"),
                available("free-fire", "Free Fire", "BATTLE_ROYALE_COMPETITIVE"),
                available("pubg-mobile", "PUBG MOBILE", "BATTLE_ROYALE_COMPETITIVE"),
                available("brawl-stars", "Brawl Stars", "MOBILE_REALTIME"),
                available("wild-rift", "League of Legends: Wild Rift", "MOBILE_REALTIME"),
                available("roblox", "Roblox", "CASUAL_REALTIME"),
                available("minecraft", "Minecraft", "CASUAL_REALTIME")
            ]
        )
    }

    func crossplayGame(id: String, name: String, profileID: String, platforms: Set<Platform>) -> RemoteCatalogGame {
        RemoteCatalogGame(id: id, name: name, contexts: [
            RemoteCatalogGameContext(
                market: "BR", platforms: platforms, profileID: profileID, availability: .available,
                measurement: RemoteCatalogMeasurement(primaryRegion: "sa-east-1", strategy: .genericRegion, confidence: .medium, precisionKey: "regionalReference")
            )
        ])
    }

    func schemaTwoPayload() -> RemoteCatalogPayload {
        let legacy = debugPayload()
        let upgradedGames = legacy.games.map { game in
            RemoteCatalogGame(id: game.id, name: game.name, contexts: game.contexts.map { context in
                RemoteCatalogGameContext(
                    market: context.market,
                    platforms: context.platforms,
                    profileID: context.profileID,
                    availability: context.availability,
                    measurement: RemoteCatalogMeasurement(
                        candidateRegionIDs: ["sa-east-1"],
                        candidatePriorities: ["sa-east-1": 10],
                        strategy: .genericRegion,
                        confidence: .medium,
                        precisionKey: "regionalReference"
                    )
                )
            })
        }
        return RemoteCatalogPayload(
            schemaVersion: 2,
            catalogVersion: "debug-2026.09.08.3",
            profiles: legacy.profiles,
            regions: legacy.regions,
            games: upgradedGames
        )
    }

    func publishedDebugEnvelopeData() throws -> Data {
        let sourceDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let repositoryRoot = sourceDirectory.deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf: repositoryRoot.appendingPathComponent("Sources/NolaggyInfrastructure/Resources/DebugCatalogBase.json"))
    }

    func receivedSamples() -> [ProbeSample] {
        (0..<30).map { ProbeSample(sequence: $0, roundTripMilliseconds: 30, outcome: .received) }
    }
}
