import Foundation

/// Estratégia que qualifica a proximidade entre o alvo de probe e o jogo.
/// `genericRegion` não autoriza tratar o RTT como ping oficial do jogo.
public enum MeasurementStrategy: String, Codable, CaseIterable, Hashable, Sendable {
    case genericRegion
    case dedicatedServer
}

public enum MeasurementConfidence: String, Codable, CaseIterable, Hashable, Sendable {
    case medium
    case high
}

/// Protocolo declarado pelo catálogo para a rota que será efetivamente medida.
///
/// A porta não identifica o protocolo: destinos futuros podem usar portas não
/// canônicas e uma porta conhecida não transforma um host desconhecido em um
/// beacon válido. A sessão deve receber este valor do contexto assinado.
public enum ProbeProtocolKind: String, Codable, CaseIterable, Hashable, Sendable {
    case gameLiftPing
    case playFabQoS
    case steamA2S
}

public enum QualityProfileID: String, Codable, CaseIterable, Hashable, Sendable {
    case battleRoyaleCompetitive = "BATTLE_ROYALE_COMPETITIVE"
    case mobileRealtime = "MOBILE_REALTIME"
    case casualRealtime = "CASUAL_REALTIME"
}

public struct ProbeDestination: Codable, Hashable, Sendable {
    public let host: String
    public let port: UInt16
    public let protocolKind: ProbeProtocolKind

    public init(
        host: String,
        port: UInt16,
        protocolKind: ProbeProtocolKind = .gameLiftPing
    ) throws {
        guard Self.isValidHost(host) else {
            throw CatalogValidationError.invalidProbeHost
        }
        guard port > 0 else {
            throw CatalogValidationError.invalidProbePort
        }
        self.host = host
        self.port = port
        self.protocolKind = protocolKind
    }

    private enum CodingKeys: String, CodingKey {
        case host
        case port
        case protocolKind
    }

    /// Catálogos já assinados antes do campo existir representam somente os
    /// beacons GameLift homologados. A compatibilidade se limita a esses
    /// envelopes; novos destinos precisam declarar o protocolo explicitamente.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            host: container.decode(String.self, forKey: .host),
            port: container.decode(UInt16.self, forKey: .port),
            protocolKind: try container.decodeIfPresent(ProbeProtocolKind.self, forKey: .protocolKind) ?? .gameLiftPing
        )
    }

    private static func isValidHost(_ host: String) -> Bool {
        guard !host.isEmpty, host.count <= 253, host == host.lowercased() else { return false }
        return host.split(separator: ".", omittingEmptySubsequences: false).allSatisfy { label in
            guard !label.isEmpty, label.count <= 63,
                  label.first != "-", label.last != "-" else { return false }
            return label.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
        }
    }
}

public struct CatalogRegion: Codable, Hashable, Sendable {
    public let id: String
    public let destination: ProbeDestination

    public init(id: String, destination: ProbeDestination) throws {
        guard Self.isValidIdentifier(id) else {
            throw CatalogValidationError.invalidRegionID
        }
        self.id = id
        self.destination = destination
    }

    private static func isValidIdentifier(_ identifier: String) -> Bool {
        guard !identifier.isEmpty else { return false }
        return identifier.allSatisfy { $0.isASCII && ($0.isLowercase || $0.isNumber || $0 == "-") }
    }
}

public struct PilotCatalog: Sendable, Equatable {
    public let version: String
    public let regions: [CatalogRegion]
    public let games: [CatalogGame]

    public init(version: String, regions: [CatalogRegion], games: [CatalogGame]) throws {
        guard !version.isEmpty else { throw CatalogValidationError.invalidCatalogVersion }
        guard !regions.isEmpty else { throw CatalogValidationError.missingRegion }
        guard Set(regions.map(\.id)).count == regions.count else { throw CatalogValidationError.duplicateRegionID }
        guard Set(games.map(\.id)).count == games.count else { throw CatalogValidationError.duplicateGameID }
        guard games.allSatisfy({ game in regions.contains(where: { $0.id == game.primaryRegionID }) }) else {
            throw CatalogValidationError.unknownPrimaryRegion
        }
        self.version = version
        self.regions = regions
        self.games = games
    }

    /// O único catálogo liberado para o piloto. O endpoint é uma referência regional AWS,
    /// não um servidor oficial do Fortnite.
    public static let pilotBase: PilotCatalog = {
        let destination = try! ProbeDestination(host: "gamelift-ping.sa-east-1.api.aws", port: 7770)
        let region = try! CatalogRegion(id: "sa-east-1", destination: destination)
        let game = try! CatalogGame(
            id: "fortnite",
            market: "BR",
            supportedPlatforms: [.iphone],
            profileID: .battleRoyaleCompetitive,
            primaryRegionID: region.id,
            strategy: .genericRegion,
            confidence: .medium
        )
        return try! PilotCatalog(version: "pilot-2026.09.08.1", regions: [region], games: [game])
    }()

    public func resolve(_ context: GameContext) throws -> ResolvedMeasurementContext {
        try context.validateStructure()
        guard let game = games.first(where: { $0.id == context.gameID }) else {
            throw CatalogValidationError.unsupportedGame
        }
        guard game.market == context.market else {
            throw CatalogValidationError.unsupportedMarket
        }
        guard game.supportedPlatforms.contains(context.platform) else {
            throw CatalogValidationError.unsupportedPlatform
        }
        guard let region = regions.first(where: { $0.id == game.primaryRegionID }) else {
            throw CatalogValidationError.unknownPrimaryRegion
        }

        return ResolvedMeasurementContext(
            context: context,
            catalogVersion: version,
            profileID: game.profileID,
            regionID: region.id,
            destination: region.destination,
            strategy: game.strategy,
            confidence: game.confidence
        )
    }
}

public struct CatalogGame: Codable, Hashable, Sendable {
    public let id: String
    public let market: String
    public let supportedPlatforms: Set<Platform>
    public let profileID: QualityProfileID
    public let primaryRegionID: String
    public let strategy: MeasurementStrategy
    public let confidence: MeasurementConfidence

    public init(
        id: String,
        market: String,
        supportedPlatforms: Set<Platform>,
        profileID: QualityProfileID,
        primaryRegionID: String,
        strategy: MeasurementStrategy,
        confidence: MeasurementConfidence
    ) throws {
        guard !id.isEmpty, id == id.lowercased() else { throw CatalogValidationError.invalidGameID }
        guard market.count == 2, market == market.uppercased(), market.allSatisfy(\.isLetter) else {
            throw CatalogValidationError.invalidMarket
        }
        guard !supportedPlatforms.isEmpty else { throw CatalogValidationError.missingSupportedPlatform }
        self.id = id
        self.market = market
        self.supportedPlatforms = supportedPlatforms
        self.profileID = profileID
        self.primaryRegionID = primaryRegionID
        self.strategy = strategy
        self.confidence = confidence
    }
}

public struct ResolvedMeasurementContext: Codable, Hashable, Sendable {
    public let context: GameContext
    public let catalogVersion: String
    public let profileID: QualityProfileID
    public let profileRuleVersion: String
    public let regionID: String
    public let destination: ProbeDestination
    public let strategy: MeasurementStrategy
    public let confidence: MeasurementConfidence
    public let precisionKey: String

    /// Protocolo que a sessão deve usar. Ele é carregado do destino assinado e
    /// nunca deduzido a partir da porta.
    public var probeProtocol: ProbeProtocolKind { destination.protocolKind }

    public init(
        context: GameContext,
        catalogVersion: String,
        profileID: QualityProfileID,
        profileRuleVersion: String? = nil,
        regionID: String,
        destination: ProbeDestination,
        strategy: MeasurementStrategy,
        confidence: MeasurementConfidence,
        precisionKey: String = "regionalReference"
    ) {
        self.context = context
        self.catalogVersion = catalogVersion
        self.profileID = profileID
        self.profileRuleVersion = profileRuleVersion ?? catalogVersion
        self.regionID = regionID
        self.destination = destination
        self.strategy = strategy
        self.confidence = confidence
        self.precisionKey = precisionKey
    }

    public func withEquipmentConnection(_ connection: NetworkKind?) -> ResolvedMeasurementContext {
        let updatedContext = GameContext(
            gameID: context.gameID,
            market: context.market,
            platform: context.platform,
            equipmentConnection: connection
        )
        return ResolvedMeasurementContext(
            context: updatedContext,
            catalogVersion: catalogVersion,
            profileID: profileID,
            profileRuleVersion: profileRuleVersion,
            regionID: regionID,
            destination: destination,
            strategy: strategy,
            confidence: confidence,
            precisionKey: precisionKey
        )
    }
}

public enum CatalogValidationError: Error, Equatable, Sendable {
    case invalidCatalogVersion
    case invalidGameID
    case invalidMarket
    case invalidRegionID
    case invalidProbeHost
    case invalidProbePort
    case missingRegion
    case missingSupportedPlatform
    case duplicateRegionID
    case duplicateGameID
    case unknownPrimaryRegion
    case equipmentConnectionNotApplicable
    case unsupportedGame
    case unsupportedMarket
    case unsupportedPlatform
}
