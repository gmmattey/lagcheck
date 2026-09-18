import Foundation
import OSLog
import NolaggyApplication
import NolaggyDomain

private let boosterLogger = Logger(subsystem: "com.nolaggy.app", category: "GeminiBooster")

public enum GeminiConnectionBoosterServiceError: LocalizedError, Equatable {
    case notConfigured
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .notConfigured: "Connection tips are not configured for this build."
        case .invalidResponse: "The connection tips service returned an invalid response."
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
            if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist") ?? Bundle.main.url(forResource: "Secrets", withExtension: "plist", subdirectory: "Secrets"),
               let data = try? Data(contentsOf: url),
               let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
               let key = plist["GEMINI_API_KEY"] as? String, !key.isEmpty {
                resolvedKey = key
            }
        }

        if resolvedKey == nil || resolvedKey?.isEmpty == true {
            if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
               let key = dict["GEMINI_API_KEY"] as? String, !key.isEmpty {
                resolvedKey = key
            }
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
    
    private func buildPrompt(for req: ConnectionBoosterRequest) -> String {
        let isPortuguese = req.locale.lowercased().starts(with: "pt")
        let langInstruction = isPortuguese ? "Responda obrigatoriamente em Português do Brasil (pt-BR)." : "Respond strictly in English (en-US)."
        
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

        return """
        Você é o assistente técnico de rede do app LagCheck. Sua missão é fornecer dicas práticas e diretas para o jogador melhorar sua estabilidade de conexão.
        \(langInstruction)

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
        - RTT P50 em repouso: \(String(format: "%.1f", req.p50Milliseconds)) ms
        - Jitter: \(String(format: "%.1f", req.jitterMilliseconds)) ms
        - Perda de pacotes: \(String(format: "%.1f", req.packetLossRate * 100))%
        - Impacto sob carga (Bufferbloat): \(impactDesc)

        FORMATO DE SAÍDA (JSON ESTRITO):
        {
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
    let summary: String
    let items: [GeminiAdviceItem]
}

private struct GeminiAdviceItem: Decodable {
    let category: String
    let title: String
    let detail: String
}
