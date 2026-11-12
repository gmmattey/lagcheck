import Foundation
import NolaggyDomain

/// Orquestrador do Isolador de Causa Raiz ("De Quem é a Culpa?")
/// Executa os 3 probes em tarefas concorrentes não bloqueantes com timeout rigoroso de 800ms.
/// Decisão 75 (Fase 2 / Item 5) — Garante integridade diagnóstica sem atrasar o veredito.
public actor RootCauseCoordinator {
    private let gatewayProber: any GatewayProbing
    private let platformHealthProvider: any PlatformHealthProvider
    private let timeoutNanoseconds: UInt64

    public init(
        gatewayProber: any GatewayProbing,
        platformHealthProvider: any PlatformHealthProvider,
        timeoutMilliseconds: UInt64 = 800
    ) {
        self.gatewayProber = gatewayProber
        self.platformHealthProvider = platformHealthProvider
        self.timeoutNanoseconds = timeoutMilliseconds * 1_000_000
    }

    /// Isola a causa raiz correlacionando os 3 probes com as métricas observadas da medição de rota.
    /// Respeita o orçamento de tempo de 800ms com cancelamento cooperativo e fallback seguro.
    public func isolateRootCause(
        wanMetrics: QualityMetrics,
        platform: Platform = .iphone,
        market: String = "BR"
    ) async -> RootCauseIsolationReport {
        let prober = self.gatewayProber
        let healthProvider = self.platformHealthProvider
        let timeout = self.timeoutNanoseconds

        // Probe 1: Gateway Local protegido por timeout estrito de 800ms
        let gatewayTask = Task<GatewayProbeOutcome, Never> {
            await withTaskGroup(of: GatewayProbeOutcome.self) { group in
                group.addTask {
                    await prober.probeGateway()
                }
                group.addTask {
                    try? await Task.sleep(nanoseconds: timeout)
                    return .unobservable
                }
                let first = await group.next() ?? .unobservable
                group.cancelAll()
                return first
            }
        }

        // Probe 3: Status de Plataforma Oficial protegido por timeout
        let platformTask = Task<(degraded: Bool, name: String?), Never> {
            await withTaskGroup(of: (degraded: Bool, name: String?).self) { group in
                group.addTask {
                    let health = await healthProvider.checkHealth(for: platform, market: market)
                    return (health.isIssueReported, health.serviceName)
                }
                group.addTask {
                    try? await Task.sleep(nanoseconds: timeout)
                    return (false, nil)
                }
                let first = await group.next() ?? (false, nil)
                group.cancelAll()
                return first
            }
        }

        let gatewayOutcome = await gatewayTask.value
        let platformInfo = await platformTask.value

        return RootCauseEvaluator.evaluate(
            gatewayOutcome: gatewayOutcome,
            wanMetrics: wanMetrics,
            platformDegraded: platformInfo.degraded,
            platformServiceName: platformInfo.name
        )
    }
}
