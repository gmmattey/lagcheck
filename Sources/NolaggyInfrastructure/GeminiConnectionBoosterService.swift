import Foundation
import NolaggyApplication
import NolaggyDomain

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
        session: URLSession = .shared
    ) {
        // Chave client-side transitória conforme docs/23 aprovado pelo dono do produto (Luiz)
        // Busca chave: parâmetro explícito -> variável de ambiente -> Secrets.plist local -> Info.plist
        var resolvedKey = apiKey ?? ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
        
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
        self.session = session
        self.endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent")!
    }
    
    public func fetchAdvice(for request: ConnectionBoosterRequest) async throws -> ConnectionBoosterAdvice {
        guard !apiKey.isEmpty else {
            // Sem credencial não há uma resposta baseada em medição. A UI já
            // tem um estado explícito para indisponibilidade e tentativa nova.
            throw GeminiConnectionBoosterServiceError.notConfigured
        }
        
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-goog-api-key")
        urlRequest.timeoutInterval = 12.0
        
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
        
        let (data, httpResponse) = try await session.data(for: urlRequest)
        guard let http = httpResponse as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "GeminiService", code: (httpResponse as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Falha na resposta do serviço de dicas."])
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.candidates.first?.content.parts.first?.text,
              let jsonData = text.data(using: .utf8) else {
            throw NSError(domain: "GeminiService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Resposta vazia do modelo."])
        }
        
        let decodedPayload = try JSONDecoder().decode(GeminiAdvicePayload.self, from: jsonData)
        guard !decodedPayload.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              (3...5).contains(decodedPayload.items.count),
              decodedPayload.items.allSatisfy({
                  !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      && !$0.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              }) else {
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
