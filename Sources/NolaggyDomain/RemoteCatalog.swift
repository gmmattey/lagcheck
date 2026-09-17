import CryptoKit
import Foundation

/// Contrato verificável do catálogo remoto de Debug. A assinatura incide sobre
/// os bytes decodificados de `payloadBase64`, nunca sobre a serialização do
/// envelope JSON.
public struct SignedCatalogEnvelope: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let catalogVersion: String
    public let issuedAt: String
    public let expiresAt: String
    public let algorithm: String
    public let payloadBase64: String
    public let signatureBase64: String
}

public struct RemoteCatalogPayload: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let catalogVersion: String
    public let profiles: [RemoteCatalogProfile]
    public let regions: [RemoteCatalogRegion]
    public let games: [RemoteCatalogGame]
}

public struct RemoteCatalogProfile: Codable, Equatable, Sendable {
    public let id: String
    public let ruleVersion: String
}

public struct RemoteCatalogRegion: Codable, Equatable, Sendable {
    public let id: String
    public let label: [String: String]
    public let probe: ProbeDestination
}

public struct RemoteCatalogGame: Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let contexts: [RemoteCatalogGameContext]
}

public enum RemoteCatalogAvailability: String, Codable, Equatable, Sendable {
    case available
    case unavailable
}

public struct RemoteCatalogMeasurement: Codable, Equatable, Sendable {
    /// Campo legado do schema 1. No schema 2, a ordem/seleção vem de
    /// `candidateRegionIDs` e `candidatePriorities`.
    public let primaryRegion: String?
    public let candidateRegionIDs: [String]?
    public let candidatePriorities: [String: Int]?
    public let strategy: MeasurementStrategy
    public let confidence: MeasurementConfidence
    public let precisionKey: String

    public init(
        primaryRegion: String? = nil,
        candidateRegionIDs: [String]? = nil,
        candidatePriorities: [String: Int]? = nil,
        strategy: MeasurementStrategy,
        confidence: MeasurementConfidence,
        precisionKey: String
    ) {
        self.primaryRegion = primaryRegion
        self.candidateRegionIDs = candidateRegionIDs
        self.candidatePriorities = candidatePriorities
        self.strategy = strategy
        self.confidence = confidence
        self.precisionKey = precisionKey
    }
}

public struct RemoteCatalogGameContext: Codable, Equatable, Sendable {
    public let market: String
    public let platforms: Set<Platform>
    public let profileID: String
    public let availability: RemoteCatalogAvailability
    public let measurement: RemoteCatalogMeasurement?
}

public enum RemoteCatalogResolution: Equatable, Sendable {
    case available(ResolvedMeasurementContext)
    case unavailable
}

public enum RemoteCatalogError: Error, Equatable, Sendable {
    case malformedEnvelope
    case unsupportedEnvelopeSchema
    case unsupportedAlgorithm
    case invalidDates
    case expired
    case invalidBase64
    case invalidSignature
    case payloadTooLarge
    case malformedPayload
    case versionMismatch
    case duplicateProfile
    case duplicateRegion
    case duplicateGame
    case invalidGame
    case invalidContext
    case unknownProfile
    case unknownRegion
    case invalidAvailability
    case unsupportedDebugCatalog
}

/// Chave pública do catálogo Debug. A chave privada não pertence ao app nem ao
/// Worker; o envelope inicial foi assinado antes de ser incluído no Worker.
public enum DebugCatalogSigningKey {
    public static let publicKeyBase64 = "4YJQhLLBC414Nj2gTjeDSqMxoJqsiw4BQeKTCxX5NuI="
}

public enum RemoteCatalogVerifier {
    /// Schema 1 é o Debug publicado atual: `primaryRegion` é convertido em um
    /// candidato implícito de prioridade zero. Schema 2 adiciona candidatos e
    /// prioridades explícitos, mas não é aceito sem envelope de schema 2.
    public static let legacySchemaVersion = 1
    public static let candidateRegionsSchemaVersion = 2
    public static let supportedSchemaVersions: Set<Int> = [legacySchemaVersion, candidateRegionsSchemaVersion]
    public static let algorithm = "Ed25519"
    public static let maximumPayloadBytes = 64 * 1024

    public static func verifyAndDecode(
        envelopeData: Data,
        publicKeyBase64: String = DebugCatalogSigningKey.publicKeyBase64,
        now: Date = Date()
    ) throws -> RemoteCatalogPayload {
        let envelope: SignedCatalogEnvelope
        do {
            envelope = try JSONDecoder().decode(SignedCatalogEnvelope.self, from: envelopeData)
        } catch {
            throw RemoteCatalogError.malformedEnvelope
        }
        guard supportedSchemaVersions.contains(envelope.schemaVersion) else { throw RemoteCatalogError.unsupportedEnvelopeSchema }
        guard envelope.algorithm == algorithm else { throw RemoteCatalogError.unsupportedAlgorithm }
        guard let issuedAt = ISO8601DateFormatter().date(from: envelope.issuedAt),
              let expiresAt = ISO8601DateFormatter().date(from: envelope.expiresAt),
              expiresAt > issuedAt,
              expiresAt.timeIntervalSince(issuedAt) <= 30 * 24 * 60 * 60 else {
            throw RemoteCatalogError.invalidDates
        }
        guard issuedAt <= now, expiresAt > now else { throw RemoteCatalogError.expired }
        guard let payloadData = Data(base64Encoded: envelope.payloadBase64),
              let signature = Data(base64Encoded: envelope.signatureBase64),
              let publicKeyData = Data(base64Encoded: publicKeyBase64) else {
            throw RemoteCatalogError.invalidBase64
        }
        guard payloadData.count <= maximumPayloadBytes else { throw RemoteCatalogError.payloadTooLarge }
        let publicKey: Curve25519.Signing.PublicKey
        do {
            publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
        } catch {
            throw RemoteCatalogError.invalidSignature
        }
        guard publicKey.isValidSignature(signature, for: payloadData) else { throw RemoteCatalogError.invalidSignature }
        let payload: RemoteCatalogPayload
        do {
            payload = try JSONDecoder().decode(RemoteCatalogPayload.self, from: payloadData)
        } catch {
            throw RemoteCatalogError.malformedPayload
        }
        guard payload.schemaVersion == envelope.schemaVersion,
              payload.catalogVersion == envelope.catalogVersion else { throw RemoteCatalogError.versionMismatch }
        try validateDebugPayload(payload)
        return payload
    }

    public static func resolve(_ context: GameContext, in payload: RemoteCatalogPayload) throws -> RemoteCatalogResolution {
        try context.validateStructure()
        guard let game = payload.games.first(where: { $0.id == context.gameID }),
              let gameContext = game.contexts.first(where: { $0.market == context.market && $0.platforms.contains(context.platform) }) else {
            throw CatalogValidationError.unsupportedGame
        }
        guard gameContext.availability == .available, let measurement = gameContext.measurement else {
            return .unavailable
        }
        guard let profile = payload.profiles.first(where: { $0.id == gameContext.profileID }),
              let regionID = candidateIDs(for: measurement, schemaVersion: payload.schemaVersion).first,
              let region = payload.regions.first(where: { $0.id == regionID }),
              let profileID = QualityProfileID(rawValue: gameContext.profileID) else {
            throw RemoteCatalogError.unknownRegion
        }
        return .available(ResolvedMeasurementContext(
            context: context,
            catalogVersion: payload.catalogVersion,
            profileID: profileID,
            profileRuleVersion: profile.ruleVersion,
            regionID: region.id,
            destination: region.probe,
            strategy: measurement.strategy,
            confidence: measurement.confidence,
            precisionKey: measurement.precisionKey
        ))
    }

    /// Cria o snapshot usado pela regra de seleção somente a partir de um
    /// payload já obtido por `verifyAndDecode`. Não consulta DNS, rede ou UI.
    public static func regionalSelectionSnapshot(
        _ context: GameContext,
        in verifiedPayload: RemoteCatalogPayload
    ) throws -> RegionalSelectionSnapshot {
        try context.validateStructure()
        guard let game = verifiedPayload.games.first(where: { $0.id == context.gameID }),
              let gameContext = game.contexts.first(where: { $0.market == context.market && $0.platforms.contains(context.platform) }),
              gameContext.availability == .available,
              let measurement = gameContext.measurement,
              let profile = verifiedPayload.profiles.first(where: { $0.id == gameContext.profileID }),
              let profileID = QualityProfileID(rawValue: gameContext.profileID),
              QualityEvaluator.supports(profile: profileID, ruleVersion: profile.ruleVersion) else {
            throw CatalogValidationError.unsupportedGame
        }
        let regionIDs = candidateIDs(for: measurement, schemaVersion: verifiedPayload.schemaVersion)
        let priorities = candidatePriorities(for: measurement, schemaVersion: verifiedPayload.schemaVersion)
        let candidates = try regionIDs.map { regionID -> RegionalSelectionCandidate in
            guard let region = verifiedPayload.regions.first(where: { $0.id == regionID }),
                  let priority = priorities[regionID] else {
                throw RemoteCatalogError.unknownRegion
            }
            let resolved = ResolvedMeasurementContext(
                context: context,
                catalogVersion: verifiedPayload.catalogVersion,
                profileID: profileID,
                profileRuleVersion: profile.ruleVersion,
                regionID: region.id,
                destination: region.probe,
                strategy: measurement.strategy,
                confidence: measurement.confidence,
                precisionKey: measurement.precisionKey
            )
            return try RegionalSelectionCandidate(resolvedContext: resolved, priority: priority)
        }
        return try RegionalSelectionSnapshot(
            catalogVersion: verifiedPayload.catalogVersion,
            context: context,
            candidates: candidates
        )
    }

    private static func validateDebugPayload(_ payload: RemoteCatalogPayload) throws {
        let expectedGames: Set<String> = [
            "fortnite", "call-of-duty-mobile", "free-fire", "pubg-mobile",
            "brawl-stars", "wild-rift", "roblox", "minecraft"
        ]
        guard payload.games.count == expectedGames.count,
              Set(payload.games.map(\.id)) == expectedGames else { throw RemoteCatalogError.unsupportedDebugCatalog }
        guard Set(payload.profiles.map(\.id)).count == payload.profiles.count else { throw RemoteCatalogError.duplicateProfile }
        guard Set(payload.regions.map(\.id)).count == payload.regions.count else { throw RemoteCatalogError.duplicateRegion }
        guard Set(payload.games.map(\.id)).count == payload.games.count else { throw RemoteCatalogError.duplicateGame }
        let profileIDs = Set(payload.profiles.map(\.id))
        let regionIDs = Set(payload.regions.map(\.id))
        guard profileIDs == Set(QualityProfileID.allCases.map(\.rawValue)),
              payload.profiles.allSatisfy({ profile in
                  guard let id = QualityProfileID(rawValue: profile.id) else { return false }
                  return QualityEvaluator.supports(profile: id, ruleVersion: profile.ruleVersion)
              }) else {
            throw RemoteCatalogError.unknownProfile
        }
        for game in payload.games {
            guard game.id == game.id.lowercased(), !game.id.isEmpty, !game.name.isEmpty, !game.contexts.isEmpty else {
                throw RemoteCatalogError.invalidGame
            }
            for context in game.contexts {
                guard context.market == "BR", !context.platforms.isEmpty, profileIDs.contains(context.profileID) else {
                    throw RemoteCatalogError.invalidContext
                }
                switch (context.availability, context.measurement) {
                case (.unavailable, nil):
                    continue
                case let (.available, .some(measurement)):
                    let candidates = candidateIDs(for: measurement, schemaVersion: payload.schemaVersion)
                    let priorities = candidatePriorities(for: measurement, schemaVersion: payload.schemaVersion)
                    guard !candidates.isEmpty,
                          legacyFieldsAreCompatible(measurement, schemaVersion: payload.schemaVersion),
                          Set(candidates).count == candidates.count,
                          Set(priorities.keys) == Set(candidates),
                          priorities.values.allSatisfy({ $0 >= 0 }),
                          candidates.allSatisfy(regionIDs.contains),
                          measurement.strategy == .genericRegion,
                          measurement.confidence == .medium,
                          measurement.precisionKey == "regionalReference" else {
                        throw RemoteCatalogError.invalidAvailability
                    }
                default:
                    throw RemoteCatalogError.invalidAvailability
                }
            }
        }
        guard payload.games.allSatisfy({ game in
            game.contexts.count == 1 && game.contexts[0].availability == .available && game.contexts[0].market == "BR" && game.contexts[0].platforms == [.iphone] && candidateIDs(for: game.contexts[0].measurement, schemaVersion: payload.schemaVersion) == ["sa-east-1"]
        }),
              payload.regions.count == 1,
              payload.regions[0].probe.host == "gamelift-ping.sa-east-1.api.aws",
              payload.regions[0].probe.port == 7770 else {
            throw RemoteCatalogError.unsupportedDebugCatalog
        }
    }

    private static func candidateIDs(for measurement: RemoteCatalogMeasurement?, schemaVersion: Int) -> [String] {
        guard let measurement else { return [] }
        switch schemaVersion {
        case legacySchemaVersion:
            return measurement.primaryRegion.map { [$0] } ?? []
        case candidateRegionsSchemaVersion:
            return measurement.candidateRegionIDs ?? []
        default:
            return []
        }
    }

    private static func candidatePriorities(for measurement: RemoteCatalogMeasurement, schemaVersion: Int) -> [String: Int] {
        switch schemaVersion {
        case legacySchemaVersion:
            return measurement.primaryRegion.map { [$0: 0] } ?? [:]
        case candidateRegionsSchemaVersion:
            return measurement.candidatePriorities ?? [:]
        default:
            return [:]
        }
    }

    private static func legacyFieldsAreCompatible(_ measurement: RemoteCatalogMeasurement, schemaVersion: Int) -> Bool {
        switch schemaVersion {
        case legacySchemaVersion:
            return measurement.primaryRegion != nil &&
                measurement.candidateRegionIDs == nil &&
                measurement.candidatePriorities == nil
        case candidateRegionsSchemaVersion:
            return measurement.primaryRegion == nil &&
                measurement.candidateRegionIDs != nil &&
                measurement.candidatePriorities != nil
        default:
            return false
        }
    }
}
