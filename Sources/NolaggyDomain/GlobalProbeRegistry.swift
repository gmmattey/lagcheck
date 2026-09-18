import Foundation

/// Registro canônico das 21 localidades globais de teste com UDP Ping Beacons
/// da AWS GameLift (porta 7770, eco monotônico sem custo operacional).
/// Conforme Decisão 28 (Luiz / Marco / Iury / Renan / Rian).
public enum GlobalProbeRegistry {

    public enum Continent: String, CaseIterable, Sendable, Hashable {
        case americas
        case europe
        case asiaPacific
        case middleEastAfrica

        public var localizationKey: String {
            switch self {
            case .americas: return "settings.continent.americas"
            case .europe: return "settings.continent.europe"
            case .asiaPacific: return "settings.continent.asia_pacific"
            case .middleEastAfrica: return "settings.continent.middle_east_africa"
            }
        }
    }

    public struct RegionDefinition: Sendable, Hashable, Identifiable {
        public let id: String
        public let host: String
        public let port: UInt16
        public let labelPtBR: String
        public let labelEN: String
        public let continent: Continent

        public init(
            id: String,
            host: String,
            port: UInt16 = 7770,
            labelPtBR: String,
            labelEN: String,
            continent: Continent
        ) {
            self.id = id
            self.host = host
            self.port = port
            self.labelPtBR = labelPtBR
            self.labelEN = labelEN
            self.continent = continent
        }

        public func localizedLabel(isPortuguese: Bool) -> String {
            isPortuguese ? labelPtBR : labelEN
        }

        public func localizedLabel(for languageCode: String) -> String {
            languageCode.lowercased().hasPrefix("pt") ? labelPtBR : labelEN
        }

        public var probeDestination: ProbeDestination {
            try! ProbeDestination(host: host, port: port)
        }
    }

    public static let allRegions: [RegionDefinition] = [
        // Américas (6)
        RegionDefinition(id: "sa-east-1", host: "gamelift-ping.sa-east-1.api.aws", port: 7770, labelPtBR: "São Paulo", labelEN: "São Paulo", continent: .americas),
        RegionDefinition(id: "us-east-1", host: "gamelift-ping.us-east-1.api.aws", port: 7770, labelPtBR: "Virgínia do Norte", labelEN: "N. Virginia", continent: .americas),
        RegionDefinition(id: "us-east-2", host: "gamelift-ping.us-east-2.api.aws", port: 7770, labelPtBR: "Ohio", labelEN: "Ohio", continent: .americas),
        RegionDefinition(id: "us-west-1", host: "gamelift-ping.us-west-1.api.aws", port: 7770, labelPtBR: "Norte da Califórnia", labelEN: "N. California", continent: .americas),
        RegionDefinition(id: "us-west-2", host: "gamelift-ping.us-west-2.api.aws", port: 7770, labelPtBR: "Oregon", labelEN: "Oregon", continent: .americas),
        RegionDefinition(id: "ca-central-1", host: "gamelift-ping.ca-central-1.api.aws", port: 7770, labelPtBR: "Canadá Central", labelEN: "Central Canada", continent: .americas),

        // Europa (6)
        RegionDefinition(id: "eu-central-1", host: "gamelift-ping.eu-central-1.api.aws", port: 7770, labelPtBR: "Frankfurt", labelEN: "Frankfurt", continent: .europe),
        RegionDefinition(id: "eu-west-1", host: "gamelift-ping.eu-west-1.api.aws", port: 7770, labelPtBR: "Irlanda", labelEN: "Ireland", continent: .europe),
        RegionDefinition(id: "eu-west-2", host: "gamelift-ping.eu-west-2.api.aws", port: 7770, labelPtBR: "Londres", labelEN: "London", continent: .europe),
        RegionDefinition(id: "eu-west-3", host: "gamelift-ping.eu-west-3.api.aws", port: 7770, labelPtBR: "Paris", labelEN: "Paris", continent: .europe),
        RegionDefinition(id: "eu-north-1", host: "gamelift-ping.eu-north-1.api.aws", port: 7770, labelPtBR: "Estocolmo", labelEN: "Stockholm", continent: .europe),
        RegionDefinition(id: "eu-south-1", host: "gamelift-ping.eu-south-1.api.aws", port: 7770, labelPtBR: "Milão", labelEN: "Milan", continent: .europe),

        // Ásia & Pacífico (7)
        RegionDefinition(id: "ap-northeast-1", host: "gamelift-ping.ap-northeast-1.api.aws", port: 7770, labelPtBR: "Tóquio", labelEN: "Tokyo", continent: .asiaPacific),
        RegionDefinition(id: "ap-northeast-2", host: "gamelift-ping.ap-northeast-2.api.aws", port: 7770, labelPtBR: "Seul", labelEN: "Seoul", continent: .asiaPacific),
        RegionDefinition(id: "ap-northeast-3", host: "gamelift-ping.ap-northeast-3.api.aws", port: 7770, labelPtBR: "Osaka", labelEN: "Osaka", continent: .asiaPacific),
        RegionDefinition(id: "ap-southeast-1", host: "gamelift-ping.ap-southeast-1.api.aws", port: 7770, labelPtBR: "Cingapura", labelEN: "Singapore", continent: .asiaPacific),
        RegionDefinition(id: "ap-southeast-2", host: "gamelift-ping.ap-southeast-2.api.aws", port: 7770, labelPtBR: "Sydney", labelEN: "Sydney", continent: .asiaPacific),
        RegionDefinition(id: "ap-south-1", host: "gamelift-ping.ap-south-1.api.aws", port: 7770, labelPtBR: "Mumbai", labelEN: "Mumbai", continent: .asiaPacific),
        RegionDefinition(id: "ap-east-1", host: "gamelift-ping.ap-east-1.api.aws", port: 7770, labelPtBR: "Hong Kong", labelEN: "Hong Kong", continent: .asiaPacific),

        // Oriente Médio & África (2)
        RegionDefinition(id: "me-south-1", host: "gamelift-ping.me-south-1.api.aws", port: 7770, labelPtBR: "Bahrein", labelEN: "Bahrain", continent: .middleEastAfrica),
        RegionDefinition(id: "af-south-1", host: "gamelift-ping.af-south-1.api.aws", port: 7770, labelPtBR: "Cidade do Cabo", labelEN: "Cape Town", continent: .middleEastAfrica)
    ]

    public static let regionMap: [String: RegionDefinition] = Dictionary(
        uniqueKeysWithValues: allRegions.map { ($0.id, $0) }
    )

    public static let allowedRegionIDs: Set<String> = Set(allRegions.map(\.id))

    public static func definition(for regionID: String) -> RegionDefinition? {
        regionMap[regionID]
    }

    public static func friendlyLabel(for regionID: String, isPortuguese: Bool) -> String {
        regionMap[regionID]?.localizedLabel(isPortuguese: isPortuguese) ?? regionID
    }

    public static func friendlyLabel(for regionID: String, languageCode: String) -> String {
        regionMap[regionID]?.localizedLabel(for: languageCode) ?? regionID
    }
}
