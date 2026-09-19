import Foundation
import Observation

@Observable
@MainActor
public final class ConnectionBoosterCoordinator {
    public enum State: Equatable {
        case idle
        case loading
        case loaded(ConnectionBoosterAdvice)
        case failed(String)
    }
    
    public private(set) var state: State = .idle
    private let service: any ConnectionBoosterService
    
    // Cache em memória para a mesma medição/sessão
    private var cachedAdvice: ConnectionBoosterAdvice?
    private var lastRequestKey: String?
    
    public init(service: any ConnectionBoosterService) {
        self.service = service
    }
    
    public func loadAdvice(for request: ConnectionBoosterRequest) async {
        let requestKey = "\(request.gameName)-\(request.platform.rawValue)-\(request.networkKind.rawValue)-\(request.p50Milliseconds)-\(request.loadImpactMilliseconds ?? 0)-\(request.language.rawValue)"
        
        if let cached = cachedAdvice, lastRequestKey == requestKey {
            state = .loaded(cached)
            return
        }
        
        state = .loading
        do {
            let rawAdvice = try await service.fetchAdvice(for: request)
            let sanitizedItems = VocabularyGuardrail.sanitize(items: rawAdvice.items)
            let sanitizedSummary = VocabularyGuardrail.sanitize(rawAdvice.summary)
            let sanitizedAdvice = ConnectionBoosterAdvice(
                gameName: rawAdvice.gameName,
                platform: rawAdvice.platform,
                summary: sanitizedSummary,
                items: sanitizedItems
            )
            
            self.cachedAdvice = sanitizedAdvice
            self.lastRequestKey = requestKey
            self.state = .loaded(sanitizedAdvice)
        } catch {
            self.state = .failed(error.localizedDescription)
        }
    }
    
    public func retry(for request: ConnectionBoosterRequest) async {
        cachedAdvice = nil
        lastRequestKey = nil
        await loadAdvice(for: request)
    }
}
