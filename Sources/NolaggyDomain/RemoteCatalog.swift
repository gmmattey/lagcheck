import CryptoKit
import Foundation

/// Contrato verificável do catálogo local de Debug. A assinatura incide sobre
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
    /// Evidência pública revisada para um destino que não é um beacon GameLift
    /// previamente homologado. O catálogo assinado nunca deve introduzir um
    /// host de PlayFab ou A2S sem esta ficha.
    public let evidence: RemoteCatalogDestinationEvidence?

    public init(
        id: String,
        label: [String: String],
        probe: ProbeDestination,
        evidence: RemoteCatalogDestinationEvidence? = nil
    ) {
        self.id = id
        self.label = label
        self.probe = probe
        self.evidence = evidence
    }
}

/// Registro mínimo auditável de por que um host pode receber sondas UDP do
/// LagCheck. A assinatura ainda é obrigatória; a evidência evita que um campo
/// de host isolado seja tratado como rota do jogo.
public struct RemoteCatalogDestinationEvidence: Codable, Equatable, Sendable {
    public let id: String
    public let sourceURL: String
    public let reviewedAt: String

    public init(id: String, sourceURL: String, reviewedAt: String) {
        self.id = id
        self.sourceURL = sourceURL
        self.reviewedAt = reviewedAt
    }
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
    /// Candidatos já autorizados e assinados para uma rota própria. O iPhone
    /// jamais descobre hosts, resolve listas públicas ou aceita IP digitado
    /// como parte desta política automática.
    public let selection: RemoteCatalogRouteSelection?

    public var candidates: [RemoteCatalogRouteCandidate]? { selection?.candidates }

    public init(
        id: String,
        kind: MeasurementRouteKind,
        status: MeasurementRouteStatus,
        regionID: String,
        destination: ProbeDestination? = nil,
        strategy: MeasurementStrategy,
        confidence: MeasurementConfidence,
        precisionKey: String,
        validUntil: String? = nil,
        selection: RemoteCatalogRouteSelection? = nil
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
        self.selection = selection
    }
}

/// Identidade que uma resposta de protocolo precisa confirmar antes de um
/// candidato próprio receber tráfego de medição. O catálogo descreve dados;
/// o codec que sabe interpretá-los continua no binário iOS.
public struct RemoteCatalogRouteIdentity: Codable, Equatable, Sendable {
    public let expectedAppID: UInt16
    public let expectedGameDirectory: String
    public let expectedServerNamePrefix: String?

    public init(expectedAppID: UInt16, expectedGameDirectory: String, expectedServerNamePrefix: String? = nil) {
        self.expectedAppID = expectedAppID
        self.expectedGameDirectory = expectedGameDirectory
        self.expectedServerNamePrefix = expectedServerNamePrefix
    }

    private enum CodingKeys: String, CodingKey {
        case expectedAppID = "appID"
        case expectedGameDirectory = "gameDirectory"
        case expectedServerNamePrefix = "namePrefix"
    }
}

/// Um candidato de servidor dedicado publicado no catálogo assinado. A
/// prioridade menor é testada primeiro; igualdade é desempatada pelo ID,
/// nunca por RTT ou um host descoberto fora do catálogo.
public struct RemoteCatalogRouteCandidate: Codable, Equatable, Sendable {
    public let id: String
    public let priority: Int
    public let destination: ProbeDestination
    public let regionID: String
    public let identity: RemoteCatalogRouteIdentity
    public let operatorEvidenceURL: String

    public init(
        id: String,
        priority: Int,
        destination: ProbeDestination,
        regionID: String,
        identity: RemoteCatalogRouteIdentity,
        operatorEvidenceURL: String
    ) {
        self.id = id
        self.priority = priority
        self.destination = destination
        self.regionID = regionID
        self.identity = identity
        self.operatorEvidenceURL = operatorEvidenceURL
    }

    private enum CodingKeys: String, CodingKey {
        case id, priority
        case host
        case queryPort
        case region = "region"
        case identity = "expectedIdentity"
        case operatorEvidenceURL
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        priority = try values.decode(Int.self, forKey: .priority)
        regionID = try values.decode(String.self, forKey: .region)
        identity = try values.decode(RemoteCatalogRouteIdentity.self, forKey: .identity)
        operatorEvidenceURL = try values.decode(String.self, forKey: .operatorEvidenceURL)
        destination = try ProbeDestination(
            host: values.decode(String.self, forKey: .host),
            port: values.decode(UInt16.self, forKey: .queryPort),
            protocolKind: .steamA2S
        )
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(priority, forKey: .priority)
        try values.encode(destination.host, forKey: .host)
        try values.encode(destination.port, forKey: .queryPort)
        try values.encode(regionID, forKey: .region)
        try values.encode(identity, forKey: .identity)
        try values.encode(operatorEvidenceURL, forKey: .operatorEvidenceURL)
    }
}

public enum RemoteCatalogRouteSelectionMode: String, Codable, Equatable, Sendable {
    case automaticValidatedCandidates
}

public struct RemoteCatalogRouteSelection: Codable, Equatable, Sendable {
    public let mode: RemoteCatalogRouteSelectionMode
    public let maxCandidates: Int
    public let candidates: [RemoteCatalogRouteCandidate]

    public init(
        mode: RemoteCatalogRouteSelectionMode = .automaticValidatedCandidates,
        maxCandidates: Int = 3,
        candidates: [RemoteCatalogRouteCandidate]
    ) {
        self.mode = mode
        self.maxCandidates = maxCandidates
        self.candidates = candidates
    }
}

/// Plano determinístico entregue à aplicação depois da assinatura/schema do
/// catálogo já terem sido aceitos. A aplicação pode apenas pré-validar os
/// candidatos desta lista e, se todos falharem, usar o fallback assinado.
public struct RemoteCatalogRoutePlan: Equatable, Sendable {
    public let ownedCandidates: [ResolvedRemoteCatalogRouteCandidate]
    public let fallback: ResolvedMeasurementContext

    public init(ownedCandidates: [ResolvedRemoteCatalogRouteCandidate], fallback: ResolvedMeasurementContext) {
        self.ownedCandidates = ownedCandidates
        self.fallback = fallback
    }
}

public struct ResolvedRemoteCatalogRouteCandidate: Equatable, Sendable {
    public let context: ResolvedMeasurementContext
    public let identity: RemoteCatalogRouteIdentity
    public let priority: Int

    public init(context: ResolvedMeasurementContext, identity: RemoteCatalogRouteIdentity, priority: Int) {
        self.context = context
        self.identity = identity
        self.priority = priority
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
    case invalidDestination
    case invalidDestinationEvidence
    case unsupportedDebugCatalog
}

/// Chave pública do catálogo Debug. A chave privada não pertence ao app nem ao
/// Worker; o envelope inicial foi assinado antes de ser incluído no Worker.
public enum DebugCatalogSigningKey {
    public static let publicKeyBase64 = "tCsSOLt9B7WpXalcu6iT6CxMrEx3w787rPRR7KXxGso="
    public static let v3PublicKeyBase64 = "oe/5VSQfhWcma+W6DdUzAESJpjgTrLtkXAcT0nEbDwo="
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
    // Decisão 89: o catálogo Schema 3 com 48 jogos ocupa ~73 KiB assinados.
    // Mantemos uma barreira explícita e igual ao Android, sem aceitar payloads ilimitados.
    public static let maximumPayloadBytes = 128 * 1024

    /// Decisão 106: o catálogo acompanha o build (assinado pela Apple/Google) e
    /// não passa por rede nem cache. Por isso não há assinatura nem validade a
    /// verificar: só tamanho, schema e regras de negócio. Aceita o payload puro
    /// (formato atual) ou um envelope antigo, do qual só lê `payloadBase64`.
    public static func decodeBundled(_ data: Data) throws -> RemoteCatalogPayload {
        var payloadData = data
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           object["payloadBase64"] != nil {
            guard let envelope = try? JSONDecoder().decode(SignedCatalogEnvelope.self, from: data),
                  let decoded = Data(base64Encoded: envelope.payloadBase64) else {
                throw RemoteCatalogError.malformedEnvelope
            }
            payloadData = decoded
        }
        guard payloadData.count <= maximumPayloadBytes else { throw RemoteCatalogError.payloadTooLarge }
        let payload: RemoteCatalogPayload
        do {
            payload = try JSONDecoder().decode(RemoteCatalogPayload.self, from: payloadData)
        } catch {
            throw RemoteCatalogError.malformedPayload
        }
        guard supportedSchemaVersions.contains(payload.schemaVersion) else { throw RemoteCatalogError.unsupportedEnvelopeSchema }
        try validateDebugPayload(payload)
        return payload
    }

    /// Legado: verifica envelope assinado com validade. Não é usado pelo app
    /// desde a Decisão 106; permanece só para os vetores históricos de teste.
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
        let resolvedPublicKeyBase64 = envelope.schemaVersion == routedCatalogSchemaVersion && publicKeyBase64 == DebugCatalogSigningKey.publicKeyBase64
            ? DebugCatalogSigningKey.v3PublicKeyBase64
            : publicKeyBase64
        guard let payloadData = Data(base64Encoded: envelope.payloadBase64),
              let signature = Data(base64Encoded: envelope.signatureBase64),
              let publicKeyData = Data(base64Encoded: resolvedPublicKeyBase64) else {
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

    /// Entrega a política automática de uma rota v3 sem abrir socket. Só
    /// candidatos previamente assinados entram aqui; a aplicação é obrigada a
    /// pré-validá-los com um driver conhecido antes de usar um deles.
    public static func automaticRoutePlan(
        _ context: GameContext,
        in payload: RemoteCatalogPayload,
        now: Date = Date()
    ) throws -> RemoteCatalogRoutePlan? {
        guard payload.schemaVersion == routedCatalogSchemaVersion else { return nil }
        try context.validateStructure()
        guard let game = payload.games.first(where: { $0.id == context.gameID }),
              let gameContext = game.contexts.first(where: { $0.market == context.market && $0.platforms.contains(context.platform) }),
              gameContext.availability == .available,
              let profile = payload.profiles.first(where: { $0.id == gameContext.profileID }),
              let profileID = QualityProfileID(rawValue: gameContext.profileID),
              let routes = gameContext.routes,
              let fallbackRoute = routes.first(where: { $0.kind == .awsFallback && $0.status == .active && routeIsCurrent($0, now: now) }),
              let fallbackDestination = resolvedDestination(for: fallbackRoute, regions: payload.regions) else {
            return nil
        }

        let fallback = resolvedContext(
            context,
            catalogVersion: payload.catalogVersion,
            profileID: profileID,
            profileRuleVersion: profile.ruleVersion,
            route: fallbackRoute,
            destination: fallbackDestination
        )
        var ownedCandidates: [ResolvedRemoteCatalogRouteCandidate] = []
        for route in routes where route.kind == .gameOwned && route.status == .active && routeIsCurrent(route, now: now) {
            for candidate in route.candidates ?? [] {
                let candidateRouteID = route.id + "-" + candidate.id
                let candidateContext = resolvedContext(
                    context,
                    catalogVersion: payload.catalogVersion,
                    profileID: profileID,
                    profileRuleVersion: profile.ruleVersion,
                    route: route,
                    destination: candidate.destination,
                    routeID: candidateRouteID,
                    candidateID: candidate.id
                )
                ownedCandidates.append(ResolvedRemoteCatalogRouteCandidate(
                    context: candidateContext,
                    identity: candidate.identity,
                    priority: candidate.priority
                ))
            }
        }
        ownedCandidates.sort { lhs, rhs in
                lhs.priority == rhs.priority
                    ? (lhs.context.routeID ?? "") < (rhs.context.routeID ?? "")
                    : lhs.priority < rhs.priority
        }
        return RemoteCatalogRoutePlan(ownedCandidates: ownedCandidates, fallback: fallback)
    }

    private static func resolve(
        _ context: GameContext,
        in payload: RemoteCatalogPayload,
        excludingRouteIDs: Set<String>
    ) throws -> RemoteCatalogResolution {
        try context.validateStructure()
        if context.isGenericGaming {
            return try resolveGenericGaming(context, in: payload)
        }
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
            return .available(resolvedContext(
                context,
                catalogVersion: payload.catalogVersion,
                profileID: profileID,
                profileRuleVersion: profile.ruleVersion,
                route: route,
                destination: destination
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

    private static func resolveGenericGaming(
        _ context: GameContext,
        in payload: RemoteCatalogPayload
    ) throws -> RemoteCatalogResolution {
        let profileID = QualityProfileID.battleRoyaleCompetitive
        let ruleVersion = payload.profiles.first(where: { $0.id == profileID.rawValue })?.ruleVersion
            ?? QualityEvaluator.ruleVersion(for: profileID)

        let preferredRegionID: String
        switch context.market {
        case "BR":
            preferredRegionID = "sa-east-1"
        case "US":
            preferredRegionID = "us-east-1"
        default:
            preferredRegionID = "sa-east-1"
        }

        guard let region = payload.regions.first(where: { $0.id == preferredRegionID }) ?? payload.regions.first else {
            throw RemoteCatalogError.unknownRegion
        }

        return .available(ResolvedMeasurementContext(
            context: context,
            catalogVersion: payload.catalogVersion,
            profileID: profileID,
            profileRuleVersion: ruleVersion,
            regionID: region.id,
            destination: region.probe,
            strategy: .genericRegion,
            confidence: .medium,
            precisionKey: "regionalReference"
        ))
    }

    /// Cria o snapshot usado pela regra de seleção somente a partir de um
    /// payload já obtido por `verifyAndDecode`. Não consulta DNS, rede ou UI.
    public static func regionalSelectionSnapshot(
        _ context: GameContext,
        in verifiedPayload: RemoteCatalogPayload
    ) throws -> RegionalSelectionSnapshot {
        try context.validateStructure()
        if context.isGenericGaming {
            return try regionalSelectionSnapshotForGenericGaming(context, in: verifiedPayload)
        }
        guard let game = verifiedPayload.games.first(where: { $0.id == context.gameID }),
              let gameContext = game.contexts.first(where: { $0.market == context.market && $0.platforms.contains(context.platform) }),
              gameContext.availability == .available,
              let profile = verifiedPayload.profiles.first(where: { $0.id == gameContext.profileID }),
              let profileID = QualityProfileID(rawValue: gameContext.profileID),
              QualityEvaluator.supports(profile: profileID, ruleVersion: profile.ruleVersion) else {
            throw CatalogValidationError.unsupportedGame
        }
        if verifiedPayload.schemaVersion == routedCatalogSchemaVersion {
            // Decisão 90: a AWS é uma referência regional, não um servidor de
            // jogo. A rota assinada autoriza a classe da medição; todas as
            // regiões assinadas são pré-lidas e a regra escolhe pelo RTT real.
            guard let route = gameContext.routes?.first(where: {
                $0.kind == .awsFallback && $0.status == .active && routeIsCurrent($0, now: Date())
            }) else {
                throw CatalogValidationError.unsupportedGame
            }
            let candidates = try verifiedPayload.regions.map { region in
                let resolved = ResolvedMeasurementContext(
                    context: context,
                    catalogVersion: verifiedPayload.catalogVersion,
                    profileID: profileID,
                    profileRuleVersion: profile.ruleVersion,
                    regionID: region.id,
                    destination: region.probe,
                    strategy: route.strategy,
                    confidence: route.confidence,
                    precisionKey: route.precisionKey,
                    routeID: route.id,
                    routeKind: route.kind
                )
                // A ordem do catálogo não é sinal de proximidade. Empates
                // reais caem no desempate estável da regra regional.
                return try RegionalSelectionCandidate(resolvedContext: resolved, priority: 0)
            }
            return try RegionalSelectionSnapshot(
                catalogVersion: verifiedPayload.catalogVersion,
                context: context,
                candidates: candidates
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

    private static func regionalSelectionSnapshotForGenericGaming(
        _ context: GameContext,
        in verifiedPayload: RemoteCatalogPayload
    ) throws -> RegionalSelectionSnapshot {
        let profileID = QualityProfileID.battleRoyaleCompetitive
        let ruleVersion = verifiedPayload.profiles.first(where: { $0.id == profileID.rawValue })?.ruleVersion
            ?? QualityEvaluator.ruleVersion(for: profileID)

        guard QualityEvaluator.supports(profile: profileID, ruleVersion: ruleVersion) else {
            throw RemoteCatalogError.unknownProfile
        }

        guard !verifiedPayload.regions.isEmpty else {
            throw RemoteCatalogError.unknownRegion
        }

        let candidates = try verifiedPayload.regions.map { region -> RegionalSelectionCandidate in
            let resolved = ResolvedMeasurementContext(
                context: context,
                catalogVersion: verifiedPayload.catalogVersion,
                profileID: profileID,
                profileRuleVersion: ruleVersion,
                regionID: region.id,
                destination: region.probe,
                strategy: .genericRegion,
                confidence: .medium,
                precisionKey: "regionalReference"
            )
            return try RegionalSelectionCandidate(resolvedContext: resolved, priority: 0)
        }

        return try RegionalSelectionSnapshot(
            catalogVersion: verifiedPayload.catalogVersion,
            context: context,
            candidates: candidates
        )
    }

    /// Teto de plataformas do candidato schema 2. A UI só oferece a plataforma
    /// quando o contexto assinado a declara, mas este teto impede que um
    /// envelope Debug publique uma combinação que não pertence ao produto.
    public static func allowedPlatforms(for gameID: String) -> Set<Platform> {
        if gameID == GameContext.genericGamingID {
            return Set(Platform.allCases)
        }
        return schemaTwoAllowedPlatforms[gameID] ?? legacyAllowedPlatforms[gameID] ?? []
    }

    /// O envelope schema 1 já publicado é aceito exatamente como foi assinado.
    /// Ele não ganha plataformas novas por interpretação retrospectiva.
    private static let legacyAllowedPlatforms: [String: Set<Platform>] = [
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

    private static let schemaTwoAllowedPlatforms: [String: Set<Platform>] = [
        "fortnite": [.iphone, .playstation, .xbox, .nintendo, .pc],
        "call-of-duty-mobile": [.iphone],
        "free-fire": [.iphone],
        "pubg-mobile": [.iphone],
        "brawl-stars": [.iphone],
        "wild-rift": [.iphone],
        "roblox": [.iphone, .playstation, .xbox, .pc],
        "minecraft": [.iphone, .playstation, .xbox, .nintendo, .pc],
        "apex-legends": [.playstation, .xbox, .nintendo, .pc],
        "blood-strike": [.iphone, .pc],
        "cs2": [.pc],
        "dota2": [.pc],
        "eafc": [.iphone, .playstation, .xbox, .pc],
        "league-of-legends": [.pc],
        "palworld": [.playstation, .xbox, .pc],
        "rainbow-six": [.playstation, .xbox, .pc],
        "rainbow-six-mobile": [.iphone],
        "rocket-league": [.playstation, .xbox, .nintendo, .pc],
        "rocket-league-sideswipe": [.iphone],
        "rust": [.playstation, .xbox, .pc],
        "valorant": [.playstation, .xbox, .pc],
        "warzone": [.playstation, .xbox, .pc],
        "dead-by-daylight": [.playstation, .xbox, .pc, .nintendo],
        "for-honor": [.playstation, .xbox, .pc],
        "borderlands-3": [.playstation, .xbox, .pc, .nintendo],
        "new-world": [.playstation, .xbox, .pc],
        "squid-game-unleashed": [.iphone, .playstation, .xbox, .pc],
        "warhammer-darktide": [.playstation, .xbox, .pc],
        "marvel-snap": [.iphone, .pc],
        "the-outlast-trials": [.playstation, .xbox, .pc],
        "tribes-of-midgard": [.playstation, .xbox, .pc, .nintendo],
        "crossfar": [.pc],
        "lost-rift": [.pc],
        "star-wars-hunters": [.iphone, .nintendo],
        "rematch": [.playstation, .xbox, .pc],
        "predecessor": [.playstation, .xbox, .pc],
        "super-mega-baseball-4": [.playstation, .xbox, .pc, .nintendo],
        "marauders": [.pc],
        "legacy-steel-and-sorcery": [.pc],
        "ninjala": [.nintendo],
        "roller-champions": [.playstation, .xbox, .pc, .nintendo],
        "ghost-recon-breakpoint": [.playstation, .xbox, .pc],
        "dark-alliance": [.playstation, .xbox, .pc],
        "wolcen-lords-of-mayhem": [.playstation, .xbox, .pc],
        "streamline": [.pc],
        "tacticool": [.iphone, .pc],
        "ghost-war": [.iphone],
        "overwatch-2": [.playstation, .xbox, .pc, .nintendo]
    ]

    private static func validateDebugPayload(_ payload: RemoteCatalogPayload) throws {
        if payload.schemaVersion == routedCatalogSchemaVersion {
            try validateRoutedPayload(payload)
            return
        }
        let legacyGameIDs: Set<String> = [
            "fortnite", "call-of-duty-mobile", "free-fire", "pubg-mobile",
            "brawl-stars", "wild-rift", "roblox", "minecraft",
            "apex-legends", "blood-strike", "cs2", "dota2", "eafc",
            "league-of-legends", "palworld", "rainbow-six", "rocket-league",
            "rust", "valorant", "warzone"
        ]
        let expectedGames: Set<String>
        let allowedPlatforms: [String: Set<Platform>]
        switch payload.schemaVersion {
        case legacySchemaVersion:
            expectedGames = legacyGameIDs
            allowedPlatforms = legacyAllowedPlatforms
        case candidateRegionsSchemaVersion:
            expectedGames = Set(schemaTwoAllowedPlatforms.keys)
            allowedPlatforms = schemaTwoAllowedPlatforms
        default:
            throw RemoteCatalogError.unsupportedDebugCatalog
        }
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
                          candidates.compactMap({ regionID in payload.regions.first(where: { $0.id == regionID }) }).allSatisfy({
                              isCompatible(measurement: measurement, destination: $0)
                          }) else {
                        throw RemoteCatalogError.invalidAvailability
                    }
                default:
                    throw RemoteCatalogError.invalidAvailability
                }
            }
        }
        let referencedRegionIDs = Set(payload.games.flatMap { game in
            game.contexts.flatMap { candidateIDs(for: $0.measurement, schemaVersion: payload.schemaVersion) }
        })
        guard payload.games.allSatisfy({ game in
            guard let allowedPlatforms = allowedPlatforms[game.id] else { return false }
            var claimedPlatforms = Set<Platform>()
            return game.contexts.allSatisfy { context in
                let candidateList = candidateIDs(for: context.measurement, schemaVersion: payload.schemaVersion)
                guard context.market == "BR",
                      context.platforms.isSubset(of: allowedPlatforms),
                      claimedPlatforms.isDisjoint(with: context.platforms) else {
                    return false
                }
                claimedPlatforms.formUnion(context.platforms)
                return context.availability == .available && !candidateList.isEmpty
            }
        }),
              !payload.regions.isEmpty,
              referencedRegionIDs == regionIDs,
              payload.regions.allSatisfy({ region in
                  isValidDestination(region)
              }) else {
            throw RemoteCatalogError.unsupportedDebugCatalog
        }
    }

    private static func isCompatible(
        measurement: RemoteCatalogMeasurement,
        destination: RemoteCatalogRegion
    ) -> Bool {
        switch destination.probe.protocolKind {
        case .gameLiftPing, .playFabQoS:
            return measurement.strategy == .genericRegion
                && measurement.confidence == .medium
                && measurement.precisionKey == "regionalReference"
        case .steamA2S:
            return measurement.strategy == .dedicatedServer
                && measurement.confidence == .high
                && measurement.precisionKey == "dedicatedServer"
        }
    }

    private static func isValidDestination(_ region: RemoteCatalogRegion) -> Bool {
        switch region.probe.protocolKind {
        case .gameLiftPing:
            return GlobalProbeRegistry.allowedRegionIDs.contains(region.id)
                && region.probe.host == "gamelift-ping.\(region.id).api.aws"
                && region.probe.port == 7770
                && region.evidence == nil
        case .playFabQoS:
            return region.probe.port == 3075 && isValidEvidence(region.evidence)
        case .steamA2S:
            return region.probe.port > 0 && isValidEvidence(region.evidence)
        }
    }

    private static func isValidEvidence(_ evidence: RemoteCatalogDestinationEvidence?) -> Bool {
        guard let evidence,
              !evidence.id.isEmpty,
              evidence.id == evidence.id.lowercased(),
              evidence.id.allSatisfy({ $0.isASCII && ($0.isLowercase || $0.isNumber || $0 == "-") }),
              let sourceURL = URL(string: evidence.sourceURL),
              sourceURL.scheme == "https",
              sourceURL.host != nil,
              ISO8601DateFormatter().date(from: evidence.reviewedAt) != nil else {
            return false
        }
        return true
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
                // Candidatos automáticos precisam passar pelo resolvedor da
                // aplicação; `resolve` nunca pode iniciar uma sessão A2S sem
                // a confirmação de identidade.
                !(route.kind == .gameOwned && route.candidates != nil) &&
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
        route.destination ?? route.candidates?
            .sorted { $0.priority == $1.priority ? $0.id < $1.id : $0.priority < $1.priority }
            .first?.destination ?? regions.first(where: { $0.id == route.regionID })?.probe
    }

    private static func resolvedContext(
        _ context: GameContext,
        catalogVersion: String,
        profileID: QualityProfileID,
        profileRuleVersion: String,
        route: RemoteCatalogRoute,
        destination: ProbeDestination,
        routeID: String? = nil,
        candidateID: String? = nil
    ) -> ResolvedMeasurementContext {
        ResolvedMeasurementContext(
            context: context,
            catalogVersion: catalogVersion,
            profileID: profileID,
            profileRuleVersion: profileRuleVersion,
            regionID: route.regionID,
            destination: destination,
            strategy: route.strategy,
            confidence: route.confidence,
            precisionKey: route.precisionKey,
            routeID: routeID ?? route.id,
            routeKind: route.kind,
            candidateID: candidateID
        )
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
            // Pendências não carregam host improvisado. Uma rota automática
            // ativa só pode publicar candidatos A2S que o binário sabe
            // pré-validar; outros protocolos ficam em pendência e caem na AWS.
            if route.status == .active {
                guard route.destination == nil,
                      let selection = route.selection,
                      selection.mode == .automaticValidatedCandidates,
                      selection.maxCandidates == 3,
                      let candidates = route.candidates,
                      !candidates.isEmpty,
                      candidates.count <= selection.maxCandidates,
                      Set(candidates.map(\.id)).count == candidates.count,
                      Set(candidates.map { "\($0.destination.host):\($0.destination.port)" }).count == candidates.count,
                      route.strategy == .dedicatedServer,
                      route.confidence == .high,
                      route.precisionKey == "dedicatedServer" else {
                    throw RemoteCatalogError.invalidRoute
                }
                guard candidates.allSatisfy(valid) else { throw RemoteCatalogError.invalidRoute }
            } else if route.destination != nil || route.selection != nil {
                throw RemoteCatalogError.invalidRoute
            }
        }
    }

    private static func valid(_ candidate: RemoteCatalogRouteCandidate) -> Bool {
        guard validIdentifier(candidate.id), candidate.priority >= 0,
              candidate.destination.protocolKind == .steamA2S,
              validIdentifier(candidate.regionID),
              candidate.identity.expectedAppID > 0,
              !candidate.identity.expectedGameDirectory.isEmpty,
              candidate.identity.expectedGameDirectory.count <= 80,
              candidate.identity.expectedGameDirectory == candidate.identity.expectedGameDirectory.lowercased(),
              !candidate.identity.expectedGameDirectory.contains("\0"),
              URL(string: candidate.operatorEvidenceURL)?.scheme == "https" else {
            return false
        }
        guard let prefix = candidate.identity.expectedServerNamePrefix else { return true }
        return !prefix.isEmpty && prefix.count <= 80 &&
            prefix.unicodeScalars.allSatisfy { scalar in
                !(0...31).contains(scalar.value) && !(127...159).contains(scalar.value)
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
