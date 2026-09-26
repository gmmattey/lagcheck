import Foundation
import os
import NolaggyApplication

/// Cliente assíncrono e anônimo para envio de telemetria mínima ao Cloudflare Worker (/v1/telemetry).
/// Decisões 50 e 51:
/// - UUID anônimo de instalação (zero PII, sem identificadores de hardware ou contas).
/// - Funil restrito: app_open, check_started, verdict_viewed, retest_started.
/// - Fire-and-forget em segundo plano com timeout estrito de 3 segundos.
public struct CloudflareWorkerAnalyticsTracker: AnalyticsTracker {
    public static let defaultEndpointURL = URL(string: "https://nolaggy-deep-check.giammattey.workers.dev/v1/telemetry")!
    private static let installationIdDefaultsKey = "lagcheck.analytics.installation_id"

    private let endpointURL: URL
    private let urlSession: URLSession
    private let fallbackTracker: AnalyticsTracker
    private let logger = Logger(subsystem: "com.lagcheck.app", category: "Telemetry")

    public init(
        endpointURL: URL = CloudflareWorkerAnalyticsTracker.defaultEndpointURL,
        urlSession: URLSession = .shared,
        fallbackTracker: AnalyticsTracker = OSLogAnalyticsTracker()
    ) {
        self.endpointURL = endpointURL
        self.urlSession = urlSession
        self.fallbackTracker = fallbackTracker
    }

    public func track(_ event: AnalyticsEvent) {
        // 1. Sempre loga localmente no console de desenvolvimento
        fallbackTracker.track(event)

        // 2. Extrai e converte evento para o contrato de produto da Decisão 50
        guard let payload = makePayload(for: event) else { return }

        // 3. Disparo assíncrono desacoplado (fire-and-forget)
        Task.detached(priority: .utility) {
            await self.sendTelemetry(payload: payload)
        }
    }

    // MARK: - Resolução de Installation ID Anônimo

    public static func getOrCreateInstallationID(userDefaults: UserDefaults = .standard) -> String {
        if let existing = userDefaults.string(forKey: installationIdDefaultsKey),
           UUID(uuidString: existing) != nil {
            return existing
        }
        let newID = UUID().uuidString.lowercased()
        userDefaults.set(newID, forKey: installationIdDefaultsKey)
        return newID
    }

    // MARK: - Construção de Payload Anônimo

    private func makePayload(for event: AnalyticsEvent) -> TelemetryPayload? {
        let installationID = Self.getOrCreateInstallationID()

        switch event {
        case .appOpen:
            return TelemetryPayload(
                installationId: installationID,
                event: "app_open",
                gameId: nil,
                platform: nil,
                verdict: nil
            )

        case let .lagcheckStarted(gameID, platform, _, _):
            return TelemetryPayload(
                installationId: installationID,
                event: "check_started",
                gameId: gameID.lowercased(),
                platform: normalizePlatform(platform),
                verdict: nil
            )

        case let .resultViewed(gameID, platform, resultClass):
            return TelemetryPayload(
                installationId: installationID,
                event: "verdict_viewed",
                gameId: gameID.lowercased(),
                platform: normalizePlatform(platform),
                verdict: mapResultClassToVerdict(resultClass)
            )

        case let .retestStarted(gameID, platform):
            return TelemetryPayload(
                installationId: installationID,
                event: "retest_started",
                gameId: gameID.lowercased(),
                platform: normalizePlatform(platform),
                verdict: nil
            )

        default:
            // Eventos auxiliares locais não compõem o funil mínimo remoto
            return nil
        }
    }

    private func normalizePlatform(_ platform: String) -> String {
        let lower = platform.lowercased()
        if lower.contains("playstation") || lower.contains("ps") { return "playstation" }
        if lower.contains("xbox") { return "xbox" }
        if lower.contains("pc") || lower.contains("windows") { return "pc" }
        return "iphone"
    }

    private func mapResultClassToVerdict(_ resultClass: String) -> String {
        switch resultClass.lowercased() {
        case "excellent", "great", "ready": return "ready"
        case "unstable", "caution": return "caution"
        case "lagrisk", "notready", "not_ready": return "not_ready"
        default: return "inconclusive"
        }
    }

    // MARK: - Envio HTTP Seguro

    private func sendTelemetry(payload: TelemetryPayload) async {
        do {
            var request = URLRequest(url: endpointURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 3.0

            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(payload)

            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                logger.debug("Telemetria anônima enviada: \(payload.event, privacy: .public)")
            }
        } catch {
            // Falha silenciosa de telemetria nunca prejudica a experiência do jogador
            logger.debug("Erro ao enviar telemetria: \(error.localizedDescription, privacy: .public)")
        }
    }

    private struct TelemetryPayload: Codable, Sendable {
        let installationId: String
        let event: String
        let gameId: String?
        let platform: String?
        let verdict: String?
    }
}
