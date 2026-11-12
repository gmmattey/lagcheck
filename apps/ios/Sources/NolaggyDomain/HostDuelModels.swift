import Foundation

/// Payload canônico e imutável do Duelo de Host (Decisão 112).
/// Trafega inteiramente codificado na URL sob o domínio https://lagcheck.signallq.com/vs
/// sem necessidade de servidor ou banco de dados externo (Custo Zero).
public struct HostDuelPayload: Codable, Equatable, Sendable {
    public static let standardTTLSeconds: Int64 = 1800 // 30 minutos

    public let gameID: String
    public let regionID: String
    public let p50Ms: Double
    public let packetLossPercent: Double
    public let jitterMs: Double
    public let verdict: GameReadinessVerdict
    public let timestamp: Int64
    public let challengerNick: String
    public let ttlSeconds: Int64

    public init(
        gameID: String,
        regionID: String,
        p50Ms: Double,
        packetLossPercent: Double,
        jitterMs: Double,
        verdict: GameReadinessVerdict,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970),
        challengerNick: String = "",
        ttlSeconds: Int64 = HostDuelPayload.standardTTLSeconds
    ) {
        self.gameID = gameID.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.regionID = regionID.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.p50Ms = max(0, p50Ms)
        self.packetLossPercent = max(0, min(100, packetLossPercent))
        self.jitterMs = max(0, jitterMs)
        self.verdict = verdict
        self.timestamp = timestamp
        self.challengerNick = String(challengerNick.trimmingCharacters(in: .whitespacesAndNewlines).prefix(16))
        self.ttlSeconds = ttlSeconds
    }

    /// Indica se a medição ultrapassou a janela máxima de 30 minutos.
    public func isExpired(now: Date = Date()) -> Bool {
        let currentSeconds = Int64(now.timeIntervalSince1970)
        return (currentSeconds - timestamp) > ttlSeconds
    }

    /// Retorna quantos segundos restam até expirar (ou zero se expirado).
    public func remainingSeconds(now: Date = Date()) -> Int64 {
        let currentSeconds = Int64(now.timeIntervalSince1970)
        let diff = (timestamp + ttlSeconds) - currentSeconds
        return max(0, diff)
    }

    /// Serializa o payload em parâmetros de query compactos para a URL canônica.
    public func toWebURL(baseURL: String = "https://lagcheck.signallq.com/vs") -> URL? {
        guard var components = URLComponents(string: baseURL) else { return nil }
        
        let p50Rounded = String(format: "%.1f", locale: Locale(identifier: "en_US"), p50Ms)
        let lossRounded = String(format: "%.1f", locale: Locale(identifier: "en_US"), packetLossPercent)
        let jitterRounded = String(format: "%.1f", locale: Locale(identifier: "en_US"), jitterMs)

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "g", value: gameID),
            URLQueryItem(name: "r", value: regionID),
            URLQueryItem(name: "p", value: p50Rounded),
            URLQueryItem(name: "l", value: lossRounded),
            URLQueryItem(name: "j", value: jitterRounded),
            URLQueryItem(name: "v", value: verdict.rawValue),
            URLQueryItem(name: "t", value: String(timestamp))
        ]

        if !challengerNick.isEmpty {
            queryItems.append(URLQueryItem(name: "n", value: challengerNick))
        }

        components.queryItems = queryItems
        return components.url
    }

    /// Serializa para o esquema personalizado `lagcheck://vs?...`
    public func toCustomSchemeURL() -> URL? {
        return toWebURL(baseURL: "lagcheck://vs")
    }

    /// Realiza o parsing de qualquer URL do duelo (HTTPS canônico ou scheme nativo).
    public static func parse(url: URL) -> HostDuelPayload? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let scheme = url.scheme?.lowercased()
        guard scheme == "https" || scheme == "lagcheck" else { return nil }

        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()

        let isDuelRoute = (scheme == "https" && host == "lagcheck.signallq.com" && (path == "/vs" || path == "/vs/")) ||
                          (scheme == "lagcheck" && (host == "vs" || path == "/vs" || path == "vs"))
        guard isDuelRoute else { return nil }

        let queryItems = components.queryItems ?? []
        func value(for names: [String]) -> String? {
            for name in names {
                if let item = queryItems.first(where: { $0.name.lowercased() == name.lowercased() }),
                   let val = item.value, !val.isEmpty {
                    return val
                }
            }
            return nil
        }

        guard let game = value(for: ["g", "game", "gameid"]),
              let region = value(for: ["r", "region", "reg"]),
              let p50Str = value(for: ["p", "ping", "p50"]), let p50 = Double(p50Str),
              let lossStr = value(for: ["l", "loss"]), let loss = Double(lossStr),
              let jitterStr = value(for: ["j", "jitter"]), let jitter = Double(jitterStr),
              let verdictStr = value(for: ["v", "verdict"]), let verdict = GameReadinessVerdict(rawValue: verdictStr),
              let timestampStr = value(for: ["t", "ts", "timestamp"]), let timestamp = Int64(timestampStr)
        else {
            return nil
        }

        let nick = value(for: ["n", "nick", "name"]) ?? ""

        return HostDuelPayload(
            gameID: game,
            regionID: region,
            p50Ms: p50,
            packetLossPercent: loss,
            jitterMs: jitter,
            verdict: verdict,
            timestamp: timestamp,
            challengerNick: nick
        )
    }

    /// Gera o texto esportivo pronto para copiar e colar na call do Discord / WhatsApp.
    public func generateDiscordShareText(gameTitle: String? = nil) -> String {
        let displayGame = gameTitle ?? gameID.capitalized
        let name = challengerNick.isEmpty ? "Alguém" : challengerNick
        let pingInt = Int(round(p50Ms))
        let lossInt = Int(round(packetLossPercent))
        let link = toWebURL()?.absoluteString ?? "https://lagcheck.signallq.com/vs"

        return "⚔️ [DUELO DE HOST] \(name) cravou \(pingInt)ms no \(displayGame) (\(lossInt)% perda).\nQuem cria a sala? Aceita o duelo pra ver sua rota:\n\(link)"
    }
}

/// Identifica quem venceu a disputa de host.
public enum HostDuelWinner: String, Codable, Equatable, Sendable {
    case challenger
    case opponent
    case tie
}

/// Resolução calculada do embate entre dois jogadores.
public struct HostDuelResolution: Equatable, Sendable {
    public let winner: HostDuelWinner
    public let deltaMs: Double
    public let headline: String
    public let subheadline: String
    public let challengerLead: Bool

    public init(
        winner: HostDuelWinner,
        deltaMs: Double,
        headline: String,
        subheadline: String,
        challengerLead: Bool
    ) {
        self.winner = winner
        self.deltaMs = deltaMs
        self.headline = headline
        self.subheadline = subheadline
        self.challengerLead = challengerLead
    }
}

/// Algoritmo determinístico de resolução do Duelo de Host (Decisão 112).
/// Regra: Veredito primeiro (estabilidade/perda sob carga) → Menor latência P50 no desempate.
public enum HostDuelResolver {

    private static func rank(for verdict: GameReadinessVerdict) -> Int {
        switch verdict {
        case .ready: return 3
        case .caution: return 2
        case .notReady: return 1
        case .inconclusive: return 0
        }
    }

    public static func resolve(
        challenger: HostDuelPayload,
        opponent: HostDuelPayload,
        challengerDisplayName: String? = nil,
        opponentDisplayName: String? = nil
    ) -> HostDuelResolution {
        let cName = challengerDisplayName ?? (challenger.challengerNick.isEmpty ? "Desafiante" : challenger.challengerNick)
        let oName = opponentDisplayName ?? (opponent.challengerNick.isEmpty ? "Você" : opponent.challengerNick)
        let delta = abs(challenger.p50Ms - opponent.p50Ms)
        let deltaRounded = Int(round(delta))

        let cRank = rank(for: challenger.verdict)
        let oRank = rank(for: opponent.verdict)

        // 1. Desempate por Veredito
        if cRank != oRank {
            if cRank > oRank {
                return HostDuelResolution(
                    winner: .challenger,
                    deltaMs: delta,
                    headline: "\(cName.uppercased()) PUXA A RANKED",
                    subheadline: "\(cName) tem rota mais estável sob carga (\(challenger.verdict.defaultHeadline)).",
                    challengerLead: true
                )
            } else {
                return HostDuelResolution(
                    winner: .opponent,
                    deltaMs: delta,
                    headline: "\(oName.uppercased()) PUXA A RANKED",
                    subheadline: "\(oName) tem rota mais estável sob carga (\(opponent.verdict.defaultHeadline)).",
                    challengerLead: false
                )
            }
        }

        // 2. Ambos têm o mesmo veredito: avaliar perda de pacote (se delta > 0.5%)
        let lossDiff = challenger.packetLossPercent - opponent.packetLossPercent
        if abs(lossDiff) > 0.5 {
            if lossDiff < 0 {
                return HostDuelResolution(
                    winner: .challenger,
                    deltaMs: delta,
                    headline: "\(cName.uppercased()) PUXA A RANKED",
                    subheadline: "\(cName) sofreu menos perda de pacotes (\(Int(round(challenger.packetLossPercent)))% vs \(Int(round(opponent.packetLossPercent)))%).",
                    challengerLead: true
                )
            } else {
                return HostDuelResolution(
                    winner: .opponent,
                    deltaMs: delta,
                    headline: "\(oName.uppercased()) PUXA A RANKED",
                    subheadline: "\(oName) sofreu menos perda de pacotes (\(Int(round(opponent.packetLossPercent)))% vs \(Int(round(challenger.packetLossPercent)))%).",
                    challengerLead: false
                )
            }
        }

        // 3. Mesma estabilidade: Menor latência P50 vence (se delta >= 1.0 ms)
        if delta >= 1.0 {
            if challenger.p50Ms < opponent.p50Ms {
                return HostDuelResolution(
                    winner: .challenger,
                    deltaMs: delta,
                    headline: "\(cName.uppercased()) PUXA A RANKED",
                    subheadline: "Rota \(deltaRounded) ms mais rápida e estável sob carga.",
                    challengerLead: true
                )
            } else {
                return HostDuelResolution(
                    winner: .opponent,
                    deltaMs: delta,
                    headline: "\(oName.uppercased()) PUXA A RANKED",
                    subheadline: "Rota \(deltaRounded) ms mais rápida e estável sob carga.",
                    challengerLead: false
                )
            }
        }

        // 4. Empate técnico
        return HostDuelResolution(
            winner: .tie,
            deltaMs: delta,
            headline: "EMPATE NO LOBBY",
            subheadline: "Ambas as conexões têm a mesma qualidade e latência.",
            challengerLead: false
        )
    }
}
