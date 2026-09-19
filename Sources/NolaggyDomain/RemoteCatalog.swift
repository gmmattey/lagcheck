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

    /// Endereço base opcional dos assets editoriais. O binário só interpreta
    /// dados assinados; nenhuma imagem altera comportamento de medição.
    public let assetBaseURL: String?

    public init(
        schemaVersion: Int,
        catalogVersion: String,
        profiles: [RemoteCatalogProfile],
        regions: [RemoteCatalogRegion],
        games: [RemoteCatalogGame],
        assetBaseURL: String? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.catalogVersion = catalogVersion
        self.profiles = profiles
        self.regions = regions
        self.games = games
        self.assetBaseURL = assetBaseURL
    }
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
    public let artwork: RemoteCatalogArtwork?
    public let rating: RemoteCatalogRating?

    public init(
        id: String,
        name: String,
        contexts: [RemoteCatalogGameContext],
        artwork: RemoteCatalogArtwork? = nil,
        rating: RemoteCatalogRating? = nil
    ) {
        self.id = id
        self.name = name
        self.contexts = contexts
        self.artwork = artwork
        self.rating = rating
    }
}

/// Arte editorial criada para o LagCheck; nunca uma capa, logo ou asset do
/// publisher. O hash impede que o arquivo servido se afaste do manifesto.
public struct RemoteCatalogArtwork: Codable, Equatable, Hashable, Sendable {
    public let path: String
    public let sha256: String

    public init(path: String, sha256: String) {
        self.path = path
        self.sha256 = sha256
    }
}

/// Snapshot auditável de avaliação: fonte e data acompanham a nota.
public struct RemoteCatalogRating: Codable, Equatable, Sendable {
    public let status: RemoteCatalogRatingStatus
    public let value: Double?
    public let scale: Double?
    public let sourceName: String
    public let sourceURL: String?
    public let updatedAt: String?

    public init(
        status: RemoteCatalogRatingStatus = .verified,
        value: Double? = nil,
        scale: Double? = nil,
        sourceName: String,
        sourceURL: String? = nil,
        updatedAt: String? = nil
    ) {
        self.status = status
        self.value = value
        self.scale = scale
        self.sourceName = sourceName
        self.sourceURL = sourceURL
        self.updatedAt = updatedAt
    }
}

public enum RemoteCatalogRatingStatus: String, Codable, Equatable, Sendable {
    case verified
    case pendingVerification
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
    /// Schema 3: lista ordenada. A rota própria ativa vem primeiro; a AWS
    /// permanece como fallback ativo e não encerra a investigação da primária.
    public let routes: [RemoteCatalogRoute]?

    public init(
        market: String,
        platforms: Set<Platform>,
        profileID: String,
        availability: RemoteCatalogAvailability,
        measurement: RemoteCatalogMeasurement?,
        routes: [RemoteCatalogRoute]? = nil
    ) {
        self.market = market
        self.platforms = platforms
        self.profileID = profileID
        self.availability = availability
        self.measurement = measurement
        self.routes = routes
    }
}

public enum MeasurementRouteKind: String, Codable, Equatable, Sendable {
    case gameOwned
    case awsFallback
}

public enum MeasurementRouteStatus: String, Codable, Equatable, Sendable {
    /// Está publicada, validada e pode ser selecionada agora.
    case active
    /// Existe no backlog, mas não pode receber tráfego até validar host/codec.
    case pending
    case unavailable
}

public struct RemoteCatalogRoute: Codable, Equatable, Sendable {
    public let id: String
    public let kind: MeasurementRouteKind
    public let status: MeasurementRouteStatus
    public let regionID: String
    public let destination: ProbeDestination?
    public let strategy: MeasurementStrategy
    public let confidence: MeasurementConfidence
    public let precisionKey: String
    public let validUntil: String?

    public init(
        id: String,
        kind: MeasurementRouteKind,
        status: MeasurementRouteStatus,
        regionID: String,
        destination: ProbeDestination? = nil,
        strategy: MeasurementStrategy,
        confidence: MeasurementConfidence,
        precisionKey: String,
        validUntil: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.status = status
        self.regionID = regionID
        self.destination = destination
        self.strategy = strategy
        self.confidence = confidence
        self.precisionKey = precisionKey
        self.validUntil = validUntil
    }
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
    case invalidRoute
    case invalidArtwork
    case invalidRating
    case unsupportedDebugCatalog
}

/// Chave pública do catálogo Debug. A chave privada não pertence ao app nem ao
/// Worker; o envelope inicial foi assinado antes de ser incluído no Worker.
public enum DebugCatalogSigningKey {
    public static let publicKeyBase64 = "tCsSOLt9B7WpXalcu6iT6CxMrEx3w787rPRR7KXxGso="
}

public enum RemoteCatalogVerifier {
    /// Schema 1 é o Debug publicado atual: `primaryRegion` é convertido em um
    /// candidato implícito de prioridade zero. Schema 2 adiciona candidatos e
    /// prioridades explícitos, mas não é aceito sem envelope de schema 2.
    public static let legacySchemaVersion = 1
    public static let candidateRegionsSchemaVersion = 2
    public static let routedCatalogSchemaVersion = 3
    public static let supportedSchemaVersions: Set<Int> = [legacySchemaVersion, candidateRegionsSchemaVersion, routedCatalogSchemaVersion]
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
        try resolve(context, in: payload, excludingRouteIDs: [])
    }

    /// Re-resolve apenas entre rotas assinadas após a camada de saúde marcar
    /// uma tentativa como indisponível. Não transforma timeout da rede do
    /// jogador em sucesso: a decisão de saúde pertence à aplicação.
    public static func resolveFallback(
        _ context: GameContext,
        in payload: RemoteCatalogPayload,
        excludingRouteID: String
    ) throws -> RemoteCatalogResolution {
        try resolve(context, in: payload, excludingRouteIDs: [excludingRouteID])
    }

    private static func resolve(
        _ context: GameContext,
        in payload: RemoteCatalogPayload,
        excludingRouteIDs: Set<String>
    ) throws -> RemoteCatalogResolution {
        try context.validateStructure()
        guard let game = payload.games.first(where: { $0.id == context.gameID }),
              let gameContext = game.contexts.first(where: { $0.market == context.market && $0.platforms.contains(context.platform) }) else {
            throw CatalogValidationError.unsupportedGame
        }
        guard gameContext.availability == .available else {
            return .unavailable
        }
        guard let profile = payload.profiles.first(where: { $0.id == gameContext.profileID }),
              let profileID = QualityProfileID(rawValue: gameContext.profileID) else {
            throw RemoteCatalogError.unknownRegion
        }
        if payload.schemaVersion == routedCatalogSchemaVersion {
            guard let route = selectedRoute(
                from: gameContext,
                regions: payload.regions,
                now: Date(),
                excludingIDs: excludingRouteIDs
            ),
                  let destination = resolvedDestination(for: route, regions: payload.regions) else {
                return .unavailable
            }
            return .available(ResolvedMeasurementContext(
                context: context,
                catalogVersion: payload.catalogVersion,
                profileID: profileID,
                profileRuleVersion: profile.ruleVersion,
                regionID: route.regionID,
                destination: destination,
                strategy: route.strategy,
                confidence: route.confidence,
                precisionKey: route.precisionKey,
                routeID: route.id,
                routeKind: route.kind
            ))
        }
        guard let measurement = gameContext.measurement,
              let regionID = candidateIDs(for: measurement, schemaVersion: payload.schemaVersion).first,
              let region = payload.regions.first(where: { $0.id == regionID }) else {
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
              let profile = verifiedPayload.profiles.first(where: { $0.id == gameContext.profileID }),
              let profileID = QualityProfileID(rawValue: gameContext.profileID),
              QualityEvaluator.supports(profile: profileID, ruleVersion: profile.ruleVersion) else {
            throw CatalogValidationError.unsupportedGame
        }
        if verifiedPayload.schemaVersion == routedCatalogSchemaVersion {
            guard let route = selectedRoute(from: gameContext, regions: verifiedPayload.regions, now: Date()),
                  let destination = resolvedDestination(for: route, regions: verifiedPayload.regions) else {
                throw CatalogValidationError.unsupportedGame
            }
            let resolved = ResolvedMeasurementContext(
                context: context,
                catalogVersion: verifiedPayload.catalogVersion,
                profileID: profileID,
                profileRuleVersion: profile.ruleVersion,
                regionID: route.regionID,
                destination: destination,
                strategy: route.strategy,
                confidence: route.confidence,
                precisionKey: route.precisionKey,
                routeID: route.id,
                routeKind: route.kind
            )
            return try RegionalSelectionSnapshot(
                catalogVersion: verifiedPayload.catalogVersion,
                context: context,
                candidates: [try RegionalSelectionCandidate(resolvedContext: resolved, priority: 0)]
            )
        }
        guard let measurement = gameContext.measurement else { throw CatalogValidationError.unsupportedGame }
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

    /// Teto de plataformas por jogo no catálogo Debug. Um contexto publicado pode usar
    /// qualquer subconjunto deste teto — isso permite liberar console num jogo sem exigir
    /// que o envelope já assinado hoje (iPhone-only) seja re-assinado ao mesmo tempo.
    /// O teto reflete só quais jogos existem de fato em PlayStation/Xbox; a estratégia de
    /// medição continua `genericRegion`/`sa-east-1` porque o backend não muda por cliente.
    /// Ver docs/26-decisao-catalogo-console.md.
    public static func allowedPlatforms(for gameID: String) -> Set<Platform> {
        if let editorial = GameEditorialRegistry.editorial(for: gameID) {
            let platforms = Set(editorial.requirements.map(\.platform))
            if !platforms.isEmpty { return platforms }
        }
        return debugAllowedPlatforms[gameID] ?? [.iphone]
    }

    private static let debugAllowedPlatforms: [String: Set<Platform>] = [
        "fortnite": [.iphone, .playstation, .xbox],
        "call-of-duty-mobile": [.iphone],
        "free-fire": [.iphone],
        "pubg-mobile": [.iphone],
        "brawl-stars": [.iphone],
        "wild-rift": [.iphone],
        "roblox": [.iphone, .xbox],
        "minecraft": [.iphone, .playstation, .xbox],
        "apex-legends": [.iphone],
        "blood-strike": [.iphone],
        "cs2": [.iphone],
        "dota2": [.iphone],
        "eafc": [.iphone],
        "league-of-legends": [.iphone],
        "palworld": [.iphone],
        "rainbow-six": [.iphone],
        "rocket-league": [.iphone],
        "rust": [.iphone],
        "valorant": [.iphone],
        "warzone": [.iphone]
    ]

    private static func validateDebugPayload(_ payload: RemoteCatalogPayload) throws {
        if payload.schemaVersion == routedCatalogSchemaVersion {
            try validateRoutedPayload(payload)
            return
        }
        let expectedGames: Set<String> = [
            "fortnite", "call-of-duty-mobile", "free-fire", "pubg-mobile",
            "brawl-stars", "wild-rift", "roblox", "minecraft",
            "apex-legends", "blood-strike", "cs2", "dota2", "eafc",
            "league-of-legends", "palworld", "rainbow-six", "rocket-league",
            "rust", "valorant", "warzone"
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
            guard let allowedPlatforms = debugAllowedPlatforms[game.id] else { return false }
            let context = game.contexts[0]
            let candidateList = candidateIDs(for: context.measurement, schemaVersion: payload.schemaVersion)
            return game.contexts.count == 1 && context.availability == .available && context.market == "BR"
                && context.platforms.isSubset(of: allowedPlatforms)
                && !candidateList.isEmpty
                && Set(candidateList).isSubset(of: GlobalProbeRegistry.allowedRegionIDs)
        }),
              !payload.regions.isEmpty,
              payload.regions.allSatisfy({ region in
                  GlobalProbeRegistry.allowedRegionIDs.contains(region.id)
                      && region.probe.host == "gamelift-ping.\(region.id).api.aws"
                      && region.probe.port == 7770
              }) else {
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

    private static func selectedRoute(
        from context: RemoteCatalogGameContext,
        regions: [RemoteCatalogRegion],
        now: Date,
        excludingIDs: Set<String> = []
    ) -> RemoteCatalogRoute? {
        context.routes?.first { route in
            !excludingIDs.contains(route.id) && route.status == .active &&
                routeIsCurrent(route, now: now) &&
                resolvedDestination(for: route, regions: regions) != nil
        }
    }

    private static func routeIsCurrent(_ route: RemoteCatalogRoute, now: Date) -> Bool {
        guard let validUntil = route.validUntil else { return true }
        guard let date = ISO8601DateFormatter().date(from: validUntil) else { return false }
        return date > now
    }

    private static func resolvedDestination(
        for route: RemoteCatalogRoute,
        regions: [RemoteCatalogRegion]
    ) -> ProbeDestination? {
        route.destination ?? regions.first(where: { $0.id == route.regionID })?.probe
    }

    private static func validateRoutedPayload(_ payload: RemoteCatalogPayload) throws {
        guard !payload.catalogVersion.isEmpty,
              let baseURL = payload.assetBaseURL,
              let parsedBaseURL = URL(string: baseURL),
              parsedBaseURL.scheme == "https" else {
            throw RemoteCatalogError.invalidGame
        }
        _ = parsedBaseURL
        guard Set(payload.profiles.map(\.id)).count == payload.profiles.count else { throw RemoteCatalogError.duplicateProfile }
        guard Set(payload.regions.map(\.id)).count == payload.regions.count else { throw RemoteCatalogError.duplicateRegion }
        guard Set(payload.games.map(\.id)).count == payload.games.count else { throw RemoteCatalogError.duplicateGame }
        let profiles = Dictionary(uniqueKeysWithValues: payload.profiles.map { ($0.id, $0) })
        guard profiles.values.allSatisfy({ profile in
            guard let id = QualityProfileID(rawValue: profile.id) else { return false }
            return QualityEvaluator.supports(profile: id, ruleVersion: profile.ruleVersion)
        }) else { throw RemoteCatalogError.unknownProfile }

        let regions = Dictionary(uniqueKeysWithValues: payload.regions.map { ($0.id, $0) })
        guard regions.values.allSatisfy({ region in
            GlobalProbeRegistry.allowedRegionIDs.contains(region.id) &&
                region.probe.host == "gamelift-ping.\(region.id).api.aws" &&
                region.probe.port == 7770 && region.probe.protocolKind == .gameLiftPing
        }) else { throw RemoteCatalogError.unknownRegion }

        for game in payload.games {
            guard validIdentifier(game.id), !game.name.isEmpty, !game.contexts.isEmpty,
                  let artwork = game.artwork, validArtwork(artwork),
                  let rating = game.rating, validRating(rating) else {
                throw RemoteCatalogError.invalidGame
            }
            var covered = Set<String>()
            for context in game.contexts {
                guard validMarket(context.market), !context.platforms.isEmpty,
                      profiles[context.profileID] != nil else { throw RemoteCatalogError.invalidContext }
                for platform in context.platforms {
                    let key = "\(context.market):\(platform.rawValue)"
                    guard covered.insert(key).inserted else { throw RemoteCatalogError.invalidContext }
                }
                guard context.measurement == nil else { throw RemoteCatalogError.invalidContext }
                guard context.availability == .available, let routes = context.routes, !routes.isEmpty else {
                    throw RemoteCatalogError.invalidAvailability
                }
                guard Set(routes.map(\.id)).count == routes.count,
                      routes.contains(where: { $0.kind == .awsFallback && $0.status == .active }) else {
                    throw RemoteCatalogError.invalidRoute
                }
                for route in routes {
                    try validate(route: route, regions: regions)
                }
            }
        }
    }

    private static func validate(route: RemoteCatalogRoute, regions: [String: RemoteCatalogRegion]) throws {
        guard validIdentifier(route.id), validIdentifier(route.regionID), !route.precisionKey.isEmpty else {
            throw RemoteCatalogError.invalidRoute
        }
        if let validUntil = route.validUntil, ISO8601DateFormatter().date(from: validUntil) == nil {
            throw RemoteCatalogError.invalidRoute
        }
        switch route.kind {
        case .awsFallback:
            guard route.status == .active,
                  route.strategy == .genericRegion,
                  route.confidence == .medium,
                  route.precisionKey == "regionalReference",
                  let region = regions[route.regionID],
                  route.destination == nil || route.destination == region.probe else {
                throw RemoteCatalogError.invalidRoute
            }
        case .gameOwned:
            // Pendências não carregam host improvisado. Quando ficam ativas,
            // precisam trazer um destino e o driver UDP já existente no app.
            if route.status == .active {
                guard route.destination != nil,
                      route.strategy == .dedicatedServer,
                      route.confidence == .high,
                      route.precisionKey == "dedicatedServer" else {
                    throw RemoteCatalogError.invalidRoute
                }
            } else if route.destination != nil {
                throw RemoteCatalogError.invalidRoute
            }
        }
    }

    private static func validIdentifier(_ value: String) -> Bool {
        !value.isEmpty && value == value.lowercased() && value.allSatisfy {
            $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-")
        }
    }

    private static func validMarket(_ value: String) -> Bool {
        value.count == 2 && value == value.uppercased() && value.allSatisfy(\.isLetter)
    }

    private static func validArtwork(_ artwork: RemoteCatalogArtwork) -> Bool {
        artwork.path.hasPrefix("artwork/") && !artwork.path.contains("..") &&
            artwork.sha256.count == 64 && artwork.sha256.allSatisfy { $0.isHexDigit }
    }

    private static func validRating(_ rating: RemoteCatalogRating) -> Bool {
        switch rating.status {
        case .verified:
            guard let value = rating.value, let scale = rating.scale,
                  let sourceURL = rating.sourceURL, let updatedAt = rating.updatedAt else { return false }
            return value >= 0 && scale > 0 && value <= scale &&
                !rating.sourceName.isEmpty && URL(string: sourceURL)?.scheme == "https" &&
                ISO8601DateFormatter().date(from: updatedAt) != nil
        case .pendingVerification:
            return rating.value == nil && rating.scale == nil &&
                rating.sourceURL == nil && rating.updatedAt == nil && !rating.sourceName.isEmpty
        }
    }
}
