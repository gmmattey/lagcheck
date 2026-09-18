import Foundation
import NolaggyDomain

/// Cliente leve e direto para verificação de integridade das redes de console (PSN, Xbox Live, Nintendo)
/// a custo estritamente zero, consultando os CDNs públicos oficiais das fabricantes sem intermediários.
public actor DirectPlatformHealthClient: PlatformHealthProvider {
    private let urlSession: URLSession
    private let cacheTTLSeconds: TimeInterval
    private var cache: [String: (health: PlatformHealth, expiresAt: Date)] = [:]

    public init(
        urlSession: URLSession? = nil,
        cacheTTLSeconds: TimeInterval = 600.0 // 10 minutos
    ) {
        if let session = urlSession {
            self.urlSession = session
        } else {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 3.0
            config.timeoutIntervalForResource = 3.0
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            config.httpAdditionalHeaders = ["User-Agent": "LagCheck/1.0 (iOS)"]
            self.urlSession = URLSession(configuration: config)
        }
        self.cacheTTLSeconds = cacheTTLSeconds
    }

    public func checkHealth(for platform: Platform, market: String) async -> PlatformHealth {
        let cacheKey = "\(platform.rawValue)_\(market.uppercased())"
        let now = Date()

        if let cached = cache[cacheKey], now < cached.expiresAt {
            return cached.health
        }

        let resolvedHealth: PlatformHealth
        switch platform {
        case .playstation:
            resolvedHealth = await fetchPlayStationHealth(market: market)
        case .xbox:
            resolvedHealth = await fetchXboxHealth(market: market)
        case .nintendo:
            resolvedHealth = await fetchNintendoHealth(market: market)
        case .iphone, .pc:
            resolvedHealth = PlatformHealth.operational(for: platform, serviceName: "Plataforma Local")
        }

        cache[cacheKey] = (health: resolvedHealth, expiresAt: now.addingTimeInterval(cacheTTLSeconds))
        return resolvedHealth
    }

    public func clearCache() {
        cache.removeAll()
    }

    // MARK: - PlayStation Network (Akamai CDN)

    private func fetchPlayStationHealth(market: String) async -> PlatformHealth {
        let serviceName = "PlayStation Network"
        let marketUpper = market.uppercased()

        // SCEA: Américas | SCEE: Europa, Oceania, África
        let isAmericas = ["BR", "US", "CA", "MX", "CL", "AR", "PE", "CO", "PA", "CR", "EC", "GT", "SV", "PY", "HN", "NI", "UY", "BO"].contains(marketUpper)
        let regionEndpoint = isAmericas ? "SCEA" : "SCEE"
        guard let url = URL(string: "https://status.playstation.com/data/statuses/region/\(regionEndpoint).json") else {
            return PlatformHealth.unknown(for: .playstation, serviceName: serviceName)
        }

        do {
            let (data, response) = try await urlSession.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return PlatformHealth.unknown(for: .playstation, serviceName: serviceName)
            }

            return Self.parsePlayStationPayload(data: data, market: marketUpper)
        } catch {
            return PlatformHealth.unknown(for: .playstation, serviceName: serviceName)
        }
    }

    public static func parsePlayStationPayload(data: Data, market: String) -> PlatformHealth {
        let serviceName = "PlayStation Network"
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let countries = json["countries"] as? [[String: Any]] else {
                return PlatformHealth.unknown(for: .playstation, serviceName: serviceName)
            }

            // Busca o país específico do mercado ou fallback para o primeiro país correspondente
            guard let country = countries.first(where: { ($0["countryCode"] as? String)?.uppercased() == market.uppercased() }) ?? countries.first else {
                return PlatformHealth.unknown(for: .playstation, serviceName: serviceName)
            }

            var affectedServices: [String] = []
            var isOutage = false
            var isDegraded = false
            var issueMessages: [String] = []

            // Checa status geral do país
            if let countryStatus = country["status"] as? [[String: Any]], !countryStatus.isEmpty {
                for item in countryStatus {
                    if let statusType = (item["statusType"] as? String)?.lowercased() {
                        if statusType == "outage" { isOutage = true }
                        if statusType == "degraded" || statusType == "maintenance" { isDegraded = true }
                    }
                    if let msg = (item["message"] as? [String: Any])?["message"] as? String, !msg.isEmpty {
                        issueMessages.append(msg)
                    }
                }
            }

            // Checa serviços essenciais (Account_Management, Gaming_And_Social, PlayStation_Store)
            if let services = country["services"] as? [[String: Any]] {
                for svc in services {
                    let svcId = svc["serviceId"] as? String ?? ""
                    let svcName = svc["serviceName"] as? String ?? svcId
                    if let svcStatuses = svc["status"] as? [[String: Any]], !svcStatuses.isEmpty {
                        affectedServices.append(svcName)
                        for item in svcStatuses {
                            let type = (item["statusType"] as? String)?.lowercased() ?? ""
                            if type == "outage" {
                                isOutage = true
                            } else if type == "degraded" || type == "maintenance" {
                                isDegraded = true
                            }
                        }
                    }
                }
            }

            let status: PlatformHealthStatus
            if isOutage {
                let summary = issueMessages.first ?? "Interrupção nos serviços da PlayStation Network"
                status = .majorOutage(summary: summary)
            } else if isDegraded || !affectedServices.isEmpty {
                let summary = issueMessages.first ?? "Instabilidade em serviços da PlayStation Network"
                status = .degraded(summary: summary)
            } else {
                status = .operational
            }

            return PlatformHealth(
                platform: .playstation,
                status: status,
                serviceName: serviceName,
                affectedServices: affectedServices,
                details: issueMessages.joined(separator: " ")
            )
        } catch {
            return PlatformHealth.unknown(for: .playstation, serviceName: serviceName)
        }
    }

    // MARK: - Xbox Network / Xbox Live (Azure Front Door)

    private func fetchXboxHealth(market: String) async -> PlatformHealth {
        let serviceName = "Xbox Network"
        let marketUpper = market.uppercased()
        let locale = (marketUpper == "BR") ? "pt-BR" : "en-US"

        guard let url = URL(string: "https://xnotify.xboxlive.com/servicestatusv6/\(marketUpper)/\(locale)") else {
            return PlatformHealth.unknown(for: .xbox, serviceName: serviceName)
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return PlatformHealth.unknown(for: .xbox, serviceName: serviceName)
            }

            return Self.parseXboxPayload(data: data)
        } catch {
            return PlatformHealth.unknown(for: .xbox, serviceName: serviceName)
        }
    }

    public static func parseXboxPayload(data: Data) -> PlatformHealth {
        let serviceName = "Xbox Network"
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return PlatformHealth.unknown(for: .xbox, serviceName: serviceName)
            }

            let statusObj = json["Status"] as? [String: Any]
            let overall = statusObj?["Overall"] as? [String: Any]
            let state = (overall?["State"] as? String)?.lowercased() ?? "none"

            var affectedServices: [String] = []
            var issueMessages: [String] = []

            if let coreServices = json["CoreServices"] as? [[String: Any]] {
                for svc in coreServices {
                    let svcName = svc["Name"] as? String ?? ""
                    let svcStatus = (svc["Status"] as? [String: Any])?["Name"] as? String ?? "None"
                    if svcStatus.lowercased() != "none" {
                        affectedServices.append(svcName)
                    }
                    if let scenarios = svc["Scenarios"] as? [[String: Any]] {
                        for scn in scenarios {
                            let scnStatus = (scn["Status"] as? [String: Any])?["Name"] as? String ?? "None"
                            if scnStatus.lowercased() != "none" {
                                if let desc = scn["Description"] as? String, !desc.isEmpty {
                                    issueMessages.append(desc)
                                }
                            }
                        }
                    }
                }
            }

            let status: PlatformHealthStatus
            switch state {
            case "major":
                let summary = issueMessages.first ?? "Interrupção geral nos serviços da Xbox Network"
                status = .majorOutage(summary: summary)
            case "minor", "limited":
                let summary = issueMessages.first ?? "Instabilidade temporária na Xbox Network"
                status = .degraded(summary: summary)
            case "none":
                status = .operational
            default:
                if !affectedServices.isEmpty {
                    status = .degraded(summary: "Instabilidade em serviços do Xbox")
                } else {
                    status = .operational
                }
            }

            return PlatformHealth(
                platform: .xbox,
                status: status,
                serviceName: serviceName,
                affectedServices: affectedServices,
                details: issueMessages.joined(separator: " ")
            )
        } catch {
            return PlatformHealth.unknown(for: .xbox, serviceName: serviceName)
        }
    }

    // MARK: - Nintendo Switch Online

    private func fetchNintendoHealth(market: String) async -> PlatformHealth {
        let serviceName = "Nintendo Switch Online"
        guard let url = URL(string: "https://www.nintendo.co.jp/netinfo/en_US/status.json") else {
            return PlatformHealth.unknown(for: .nintendo, serviceName: serviceName)
        }

        do {
            let (data, response) = try await urlSession.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return PlatformHealth.unknown(for: .nintendo, serviceName: serviceName)
            }

            return Self.parseNintendoPayload(data: data)
        } catch {
            return PlatformHealth.unknown(for: .nintendo, serviceName: serviceName)
        }
    }

    public static func parseNintendoPayload(data: Data) -> PlatformHealth {
        let serviceName = "Nintendo Switch Online"
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return PlatformHealth.unknown(for: .nintendo, serviceName: serviceName)
            }

            let operationalStatuses = json["operational_statuses"] as? [[String: Any]] ?? []
            if !operationalStatuses.isEmpty {
                let msgs = operationalStatuses.compactMap { $0["message"] as? String }
                return PlatformHealth(
                    platform: .nintendo,
                    status: .majorOutage(summary: msgs.first ?? "Interrupção no serviço da Nintendo"),
                    serviceName: serviceName,
                    affectedServices: ["Online Services"],
                    details: msgs.joined(separator: " ")
                )
            }

            return PlatformHealth.operational(for: .nintendo, serviceName: serviceName)
        } catch {
            return PlatformHealth.unknown(for: .nintendo, serviceName: serviceName)
        }
    }
}
