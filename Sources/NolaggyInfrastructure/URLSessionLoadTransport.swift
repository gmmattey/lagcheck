import Foundation
import NolaggyApplication

/// Configuração de infraestrutura isolada do domínio e da interface para permitir a
/// substituição futura do endpoint sem mudar contratos de medição.
public enum DeepCheckLoadEndpoint {
    public static let pilot = URL(string: "https://nolaggy-deep-check.buildealabs.workers.dev/v1/load")!
}

/// Adaptador do único endpoint de carga autorizado. Não envia identificação nem
/// contexto de medição e encerra por volume ou por tempo, o que ocorrer primeiro.
public struct URLSessionLoadTransport: LoadTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func transfer(_ request: LoadRequest) async -> LoadTransferOutcome {
        await withTaskGroup(of: LoadTransferOutcome.self) { group in
            group.addTask {
                await receive(request)
            }
            group.addTask {
                try? await Task.sleep(for: request.maximumDuration)
                return .unavailable
            }
            let outcome = await group.next() ?? .unavailable
            group.cancelAll()
            return outcome
        }
    }

    private func receive(_ loadRequest: LoadRequest) async -> LoadTransferOutcome {
        var request = URLRequest(url: loadRequest.url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")

        do {
            let (bytes, response) = try await session.bytes(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return .unavailable
            }
            var total = 0
            for try await _ in bytes {
                guard !Task.isCancelled else { return .unavailable }
                total += 1
                if total >= loadRequest.maximumBytes {
                    return .completed(bytesTransferred: total)
                }
            }
            return .completed(bytesTransferred: total)
        } catch {
            return .unavailable
        }
    }
}
