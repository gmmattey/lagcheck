import Foundation
import NaturalLanguage
import OSLog
import NolaggyApplication
import NolaggyDomain

private let boosterLogger = Logger(subsystem: "com.nolaggy.app", category: "GeminiBooster")

public enum GeminiConnectionBoosterServiceError: LocalizedError, Equatable {
    case notConfigured
    case invalidResponse
    case unexpectedLanguage

    public var errorDescription: String? {
        switch self {
        case .notConfigured: "Connection tips are not configured for this build."
        case .invalidResponse: "The connection tips service returned an invalid response."
        case .unexpectedLanguage: "The connection tips service responded in an unexpected language."
        }
    }
}

public struct GeminiConnectionBoosterService: ConnectionBoosterService {
    private let apiKey: String
    private let session: URLSession
    private let endpoint: URL
    
    public init(
        apiKey: String? = nil,
        session: URLSession? = nil
    ) {
        // Chave client-side transitória conforme docs/23 aprovado pelo dono do produto (Luiz)
        // Busca chave: parâmetro explícito -> variável de ambiente -> Secrets.plist local -> Info.plist
        var resolvedKey = apiKey ?? ProcessInfo.processInfo.environment["GEMINI_API_KEY"]

        if resolvedKey == nil || resolvedKey?.isEmpty == true {
            resolvedKey = Self.readSecretsPlistKey()
        }

        if resolvedKey == nil || resolvedKey?.isEmpty == true {
            resolvedKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String
        }

        self.apiKey = resolvedKey ?? ""
        if let customSession = session {
            self.session = customSession
        } else {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 20.0
            config.timeoutIntervalForResource = 25.0
            self.session = URLSession(configuration: config)
        }
        self.endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent")!
    }
    
    /// Lê `GEMINI_API_KEY` de `Secrets.plist` em um único caminho de resolução,
    /// tentando as localizações plausíveis do bundle sem duplicar a leitura em disco.
    private static func readSecretsPlistKey() -> String? {
        let candidateURLs = [
            Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            Bundle.main.url(forResource: "Secrets", withExtension: "plist", subdirectory: "Secrets")
        ].compactMap { $0 }

        for url in candidateURLs {
            guard let data = try? Data(contentsOf: url),
                  let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
                  let key = plist["GEMINI_API_KEY"] as? String, !key.isEmpty else { continue }
            return key
        }
        return nil
    }

    /// Sanitiza o texto bruto recebido do LLM, removendo possíveis code blocks markdown (` ```json ` ou ` ``` `)
    public static func sanitizeJSONResponse(_ rawText: String) -> String {
        var text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```json") {
            text = String(text.dropFirst(7))
        } else if text.hasPrefix("```") {
            text = String(text.dropFirst(3))
        }
        if text.hasSuffix("```") {
            text = String(text.dropLast(3))
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func fetchAdvice(for request: ConnectionBoosterRequest) async throws -> ConnectionBoosterAdvice {
        guard !apiKey.isEmpty else {
            boosterLogger.error("Chave do Gemini não configurada neste build.")
            throw GeminiConnectionBoosterServiceError.notConfigured
        }
        
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-goog-api-key")
        urlRequest.timeoutInterval = 20.0
        
        let prompt = buildPrompt(for: request)
        let requestBody = GeminiRequestBody(
            contents: [
                GeminiContent(parts: [GeminiPart(text: prompt)])
            ],
            generationConfig: GeminiGenerationConfig(
                responseMimeType: "application/json",
                temperature: 0.2
            )
        )
        
        urlRequest.httpBody = try JSONEncoder().encode(requestBody)
        
        boosterLogger.info("Enviando requisição de dicas de conexão para \(request.gameName, privacy: .public) no \(request.platform.rawValue, privacy: .public).")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let data: Data
        let httpResponse: URLResponse
        do {
            (data, httpResponse) = try await session.data(for: urlRequest)
        } catch {
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            boosterLogger.error("Erro de rede na chamada do Gemini após \(String(format: "%.2f", elapsed), privacy: .public)s: \(error.localizedDescription, privacy: .public)")
            throw error
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        guard let http = httpResponse as? HTTPURLResponse else {
            boosterLogger.error("Resposta nula ou não-HTTP recebida do Gemini após \(String(format: "%.2f", elapsed), privacy: .public)s.")
            throw NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Falha na resposta do serviço de dicas."])
        }
        
        guard (200...299).contains(http.statusCode) else {
            boosterLogger.error("Gemini retornou status HTTP \(http.statusCode, privacy: .public) após \(String(format: "%.2f", elapsed), privacy: .public)s.")
            throw NSError(domain: "GeminiService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Falha na resposta do serviço de dicas (HTTP \(http.statusCode))."])
        }
        
        let geminiResponse: GeminiResponse
        do {
            geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        } catch {
            boosterLogger.error("Falha ao decodificar envelope GeminiResponse: \(error.localizedDescription, privacy: .public)")
            throw GeminiConnectionBoosterServiceError.invalidResponse
        }
        
        guard let rawText = geminiResponse.candidates.first?.content.parts.first(where: { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })?.text else {
            boosterLogger.error("Candidato do Gemini vazio ou sem partes de texto válidas.")
            throw NSError(domain: "GeminiService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Resposta vazia do modelo."])
        }
        
        let sanitizedJSON = Self.sanitizeJSONResponse(rawText)
        guard let jsonData = sanitizedJSON.data(using: .utf8) else {
            boosterLogger.error("Falha ao converter texto sanitizado para UTF-8.")
            throw GeminiConnectionBoosterServiceError.invalidResponse
        }
        
        let decodedPayload: GeminiAdvicePayload
        do {
            decodedPayload = try JSONDecoder().decode(GeminiAdvicePayload.self, from: jsonData)
        } catch {
            boosterLogger.error("Falha ao decodificar payload GeminiAdvicePayload: \(error.localizedDescription, privacy: .public). JSON bruto: \(sanitizedJSON, privacy: .public)")
            throw GeminiConnectionBoosterServiceError.invalidResponse
        }
        
        guard !decodedPayload.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              (3...5).contains(decodedPayload.items.count),
              decodedPayload.items.allSatisfy({
                  !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      && !$0.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              }) else {
            boosterLogger.error("Payload fora dos critérios de negócio: summary vazio ou contagem inválida (\(decodedPayload.items.count) itens).")
            throw GeminiConnectionBoosterServiceError.invalidResponse
        }

        guard Self.isAdviceLanguageValid(
            declaredLanguage: decodedPayload.language,
            summary: decodedPayload.summary,
            items: decodedPayload.items.map { ($0.title, $0.detail) },
            expected: request.language
        ) else {
            boosterLogger.error("Gemini returned advice outside the requested language \(request.language.rawValue, privacy: .public).")
            throw GeminiConnectionBoosterServiceError.unexpectedLanguage
        }
        
        let items = decodedPayload.items.map { item in
            let category: BoosterActionCategory
            switch item.category.lowercased() {
            case "router_equipment", "router":
                category = .routerEquipment
            case "platform_system", "platform":
                category = .platformSystem
            default:
                category = .ispConnection
            }
            return BoosterActionItem(
                category: category,
                title: item.title,
                detail: item.detail
            )
        }
        
        boosterLogger.info("Dicas de conexão obtidas com sucesso em \(String(format: "%.2f", elapsed), privacy: .public)s (\(items.count, privacy: .public) ações).")
        
        return ConnectionBoosterAdvice(
            gameName: request.gameName,
            platform: request.platform,
            summary: decodedPayload.summary,
            items: items
        )
    }
    
    func buildPrompt(for req: ConnectionBoosterRequest) -> String {
        switch req.language {
        case .ptBR:
            return portuguesePrompt(for: req)
        case .en:
            return englishPrompt(for: req)
        case .es:
            return spanishPrompt(for: req)
        }
    }

    /// The model must declare its output language and the returned prose is
    /// checked independently. A mismatched response is discarded; no fallback
    /// recommendation is created from partial or translated content.
    static func isAdviceLanguageValid(
        declaredLanguage: String,
        summary: String,
        items: [(String, String)],
        expected: ConnectionBoosterLanguage
    ) -> Bool {
        guard declaredLanguage.caseInsensitiveCompare(expected.rawValue) == .orderedSame else {
            return false
        }

        let prose = ([summary] + items.flatMap { [$0.0, $0.1] })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prose.isEmpty else { return false }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(prose)
        let detected = recognizer.dominantLanguage?.rawValue.lowercased()
        let expectedCode: String
        switch expected {
        case .ptBR: expectedCode = "pt"
        case .en: expectedCode = "en"
        case .es: expectedCode = "es"
        }
        return detected == expectedCode
    }

    private func portuguesePrompt(for req: ConnectionBoosterRequest) -> String {
        
        let impactDesc: String
        if let impact = req.loadImpactMilliseconds {
            impactDesc = "\(String(format: "%.1f", impact)) ms de atraso sob uso intenso"
        } else {
            impactDesc = "não avaliado"
        }
        
        let wifiDiagnosticDesc: String
        if let band = req.wifiBandEstimate {
            switch band {
            case .confirmed24GHz:
                wifiDiagnosticDesc = "Conectado em rede 2.4 GHz confirmada. Priorize fortemente sugerir migrar para rede 5 GHz ou usar cabo."
            case .suspected24GHzContention:
                wifiDiagnosticDesc = "Oscilações e contenção severa típicas de 2.4 GHz ou sinal instável observadas. Recomende testar frequência de 5 GHz ou aproximar-se do roteador."
            case .confirmed5GHzOrHigher, .stableWiFi:
                wifiDiagnosticDesc = "Rede Wi-Fi em 5 GHz/estável com baixo jitter local."
            case .inconclusive:
                wifiDiagnosticDesc = "Sem leitura conclusiva do rádio local."
            }
        } else {
            wifiDiagnosticDesc = "não avaliado"
        }

        let natDiagnosticDesc: String
        if let nat = req.natTopology {
            if nat.cgnatStatus.isImpacted {
                natDiagnosticDesc = "CGNAT detectado (RFC 6598). Provedor não aloca IP público dedicado. Sugira solicitar suporte a IPv6 ou IP público dinâmico para jogos ao provedor."
            } else if nat.doubleNATStatus.isImpacted {
                natDiagnosticDesc = "Duplo NAT detectado (dois roteadores encadeados). Sugira fortemente configurar o roteador secundário em modo Ponto de Acesso (Bridge)."
            } else if nat.natType.isMultiplayerRestricted {
                natDiagnosticDesc = "NAT Estrito (Tipo 3) detectado. Recomende ativar UPnP no roteador para liberar portas de matchmaking."
            } else {
                natDiagnosticDesc = "NAT \(nat.natType.shortLabel) (sem restrições críticas de topologia)."
            }
        } else {
            natDiagnosticDesc = "não avaliado"
        }

        return """
        Você é o assistente técnico de rede do app LagCheck. Sua missão é fornecer dicas práticas e diretas para o jogador melhorar sua estabilidade de conexão.
        Responda exclusivamente em Português do Brasil (pt-BR). Todas as frases, inclusive os campos JSON, devem estar nesse idioma.

        DIRETRIZES DE TOM DE VOZ (INVIOLÁVEIS):
        - Tom calmo, direto, preciso, usando termos naturais da plataforma/jogo.
        - NUNCA use termos como 'zero lag', 'rede perfeita', 'garantido', 'amassou', 'modo turbo' ou 'GG'.
        - NUNCA prometa milagres ou desempenho futuro infalível.
        - Não escreva parágrafos longos nem introduções.
        - Retorne uma lista de 3 a 5 ações concretas e executáveis.

        DADOS DA MEDIÇÃO REAL (DEEP CHECK):
        - Jogo: \(req.gameName)
        - Plataforma do jogador: \(req.platform.rawValue)
        - Tipo de conexão no iPhone: \(req.networkKind.rawValue)
        - Frequência / Estabilidade Wi-Fi: \(wifiDiagnosticDesc)
        - Topologia de NAT / Rede: \(natDiagnosticDesc)
        - RTT P50 em repouso: \(String(format: "%.1f", req.p50Milliseconds)) ms
        - Jitter: \(String(format: "%.1f", req.jitterMilliseconds)) ms
        - Perda de pacotes: \(String(format: "%.1f", req.packetLossRate * 100))%
        - Impacto sob carga (Bufferbloat): \(impactDesc)

        FORMATO DE SAÍDA (JSON ESTRITO):
        {
          "language": "pt-BR",
          "summary": "Uma frase curta resumindo o diagnóstico da conexão nesta medição.",
          "items": [
            {
              "category": "router_equipment" | "platform_system" | "isp_connection",
              "title": "Ação clara em poucas palavras",
              "detail": "Explicação objetiva de 1 ou 2 frases sobre como e por que fazer isso."
            }
          ]
        }
        """
    }

    private func englishPrompt(for req: ConnectionBoosterRequest) -> String {
        let loadImpact = req.loadImpactMilliseconds.map { String(format: "%.1f ms of added delay under heavy use", $0) } ?? "not measured"
        let wifi = englishWiFiDescription(req.wifiBandEstimate)
        let nat = englishNATDescription(req.natTopology)
        return """
        You are LagCheck's network assistant. Give the player practical, direct advice to improve connection stability.
        Respond exclusively in English (en). Every sentence, including JSON field values, must be in English.

        VOICE RULES (NON-NEGOTIABLE):
        - Be calm, direct, and precise, using natural game and platform terms.
        - Never use terms such as 'zero lag', 'perfect network', 'guaranteed', 'turbo mode', or 'GG'.
        - Never promise miracles or infallible future performance.
        - Do not write long paragraphs or introductions.
        - Return 3 to 5 concrete, actionable steps.

        REAL MEASUREMENT DATA (DEEP CHECK):
        - Game: \(req.gameName)
        - Player platform: \(req.platform.rawValue)
        - iPhone connection type: \(req.networkKind.rawValue)
        - Wi-Fi frequency / stability: \(wifi)
        - NAT / network topology: \(nat)
        - Idle RTT P50: \(String(format: "%.1f", req.p50Milliseconds)) ms
        - Jitter: \(String(format: "%.1f", req.jitterMilliseconds)) ms
        - Packet loss: \(String(format: "%.1f", req.packetLossRate * 100))%
        - Load impact (bufferbloat): \(loadImpact)

        STRICT JSON OUTPUT:
        {
          "language": "en",
          "summary": "One short sentence summarizing this connection measurement.",
          "items": [{
            "category": "router_equipment" | "platform_system" | "isp_connection",
            "title": "Clear action in a few words",
            "detail": "One or two objective sentences explaining how and why to do it."
          }]
        }
        """
    }

    private func spanishPrompt(for req: ConnectionBoosterRequest) -> String {
        let loadImpact = req.loadImpactMilliseconds.map { String(format: "%.1f ms de retraso adicional bajo uso intenso", $0) } ?? "no medido"
        let wifi = spanishWiFiDescription(req.wifiBandEstimate)
        let nat = spanishNATDescription(req.natTopology)
        return """
        Eres el asistente de red de LagCheck. Ofrece al jugador consejos prácticos y directos para mejorar la estabilidad de su conexión.
        Responde exclusivamente en español (es). Todas las frases, incluidos los valores de los campos JSON, deben estar en español.

        REGLAS DE VOZ (OBLIGATORIAS):
        - Mantén un tono tranquilo, directo y preciso, con términos naturales del juego y la plataforma.
        - Nunca uses expresiones como 'lag cero', 'red perfecta', 'garantizado', 'modo turbo' o 'GG'.
        - Nunca prometas milagros ni rendimiento futuro infalible.
        - No escribas párrafos largos ni introducciones.
        - Devuelve de 3 a 5 acciones concretas y realizables.

        DATOS REALES DE LA MEDICIÓN (DEEP CHECK):
        - Juego: \(req.gameName)
        - Plataforma del jugador: \(req.platform.rawValue)
        - Tipo de conexión en el iPhone: \(req.networkKind.rawValue)
        - Frecuencia / estabilidad Wi-Fi: \(wifi)
        - Topología de NAT / red: \(nat)
        - RTT P50 en reposo: \(String(format: "%.1f", req.p50Milliseconds)) ms
        - Jitter: \(String(format: "%.1f", req.jitterMilliseconds)) ms
        - Pérdida de paquetes: \(String(format: "%.1f", req.packetLossRate * 100))%
        - Impacto bajo carga (bufferbloat): \(loadImpact)

        SALIDA JSON ESTRICTA:
        {
          "language": "es",
          "summary": "Una frase corta que resuma esta medición de conexión.",
          "items": [{
            "category": "router_equipment" | "platform_system" | "isp_connection",
            "title": "Acción clara en pocas palabras",
            "detail": "Una o dos frases objetivas que expliquen cómo y por qué hacerlo."
          }]
        }
        """
    }

    private func englishWiFiDescription(_ diagnostic: WiFiBandDiagnostic?) -> String {
        switch diagnostic {
        case .confirmed24GHz?: "Confirmed 2.4 GHz Wi-Fi. Prioritize moving to 5 GHz or using Ethernet."
        case .suspected24GHzContention?: "Severe variation or contention typical of 2.4 GHz or unstable signal was observed. Suggest testing 5 GHz or moving closer to the router."
        case .confirmed5GHzOrHigher?, .stableWiFi?: "5 GHz or stable Wi-Fi with low local jitter."
        case .inconclusive?, nil: "not measured or inconclusive"
        }
    }

    private func spanishWiFiDescription(_ diagnostic: WiFiBandDiagnostic?) -> String {
        switch diagnostic {
        case .confirmed24GHz?: "Wi-Fi de 2,4 GHz confirmado. Prioriza cambiar a 5 GHz o usar cable Ethernet."
        case .suspected24GHzContention?: "Se observaron variaciones o congestión intensa típicas de 2,4 GHz o de señal inestable. Sugiere probar 5 GHz o acercarse al router."
        case .confirmed5GHzOrHigher?, .stableWiFi?: "Wi-Fi de 5 GHz o estable, con poco jitter local."
        case .inconclusive?, nil: "sin medición o sin resultado concluyente"
        }
    }

    private func englishNATDescription(_ topology: NATTopologySnapshot?) -> String {
        guard let topology else { return "not measured" }
        if topology.cgnatStatus.isImpacted { return "CGNAT detected (RFC 6598). Suggest asking the ISP about IPv6 or a public dynamic IP for gaming." }
        if topology.doubleNATStatus.isImpacted { return "Double NAT detected (two chained routers). Strongly suggest setting the secondary router to Access Point or Bridge mode." }
        if topology.natType.isMultiplayerRestricted { return "Strict NAT (Type 3) detected. Recommend enabling UPnP on the router for matchmaking." }
        return "NAT \(topology.natType.shortLabel), with no critical topology restrictions."
    }

    private func spanishNATDescription(_ topology: NATTopologySnapshot?) -> String {
        guard let topology else { return "sin medición" }
        if topology.cgnatStatus.isImpacted { return "Se detectó CGNAT (RFC 6598). Sugiere consultar al proveedor por IPv6 o una IP pública dinámica para jugar." }
        if topology.doubleNATStatus.isImpacted { return "Se detectó doble NAT (dos routers en cadena). Recomienda configurar el router secundario en modo Punto de Acceso o Bridge." }
        if topology.natType.isMultiplayerRestricted { return "Se detectó NAT estricta (Tipo 3). Recomienda activar UPnP en el router para el emparejamiento." }
        return "NAT \(topology.natType.shortLabel), sin restricciones críticas de topología."
    }
    
}

// MARK: - Gemini Models

private struct GeminiRequestBody: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

private struct GeminiContent: Encodable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Encodable {
    let text: String
}

private struct GeminiGenerationConfig: Encodable {
    let responseMimeType: String
    let temperature: Double
}

private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Decodable {
    let content: GeminiCandidateContent
}

private struct GeminiCandidateContent: Decodable {
    let parts: [GeminiPartResponse]
}

private struct GeminiPartResponse: Decodable {
    let text: String
}

private struct GeminiAdvicePayload: Decodable {
    let language: String
    let summary: String
    let items: [GeminiAdviceItem]
}

private struct GeminiAdviceItem: Decodable {
    let category: String
    let title: String
    let detail: String
}
