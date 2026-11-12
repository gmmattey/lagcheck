import Foundation
import Network
import NolaggyApplication

/// Traduz o caminho observado pelo iOS em invalidações de sessão. O primeiro
/// snapshot apenas fixa a referência; ele nunca cancela uma medição recém-iniciada.
public struct NWPathMonitorNetworkPathObserver: NetworkPathObserver {
    public init() {}

    public func pathChanges() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "com.nolaggy.pilot.network-path")
            let detector = NetworkPathChangeDetector()

            monitor.pathUpdateHandler = { path in
                if detector.register(NetworkPathSnapshot(path: path)) {
                    continuation.yield()
                    continuation.finish()
                }
            }
            continuation.onTermination = { @Sendable _ in
                monitor.cancel()
            }
            monitor.start(queue: queue)
        }
    }
}

/// Recorte estável do `NWPath`: somente mudanças que podem alterar a rota ou
/// as condições da medição encerram o Quick Check.
struct NetworkPathSnapshot: Equatable, Sendable {
    enum Status: Sendable { case satisfied, requiresConnection, unsatisfied }

    let status: Status
    let usesWiFi: Bool
    let usesCellular: Bool
    let usesWiredEthernet: Bool
    let usesOther: Bool
    let isExpensive: Bool
    let isConstrained: Bool

    init(status: Status, usesWiFi: Bool, usesCellular: Bool, usesWiredEthernet: Bool, usesOther: Bool, isExpensive: Bool, isConstrained: Bool) {
        self.status = status
        self.usesWiFi = usesWiFi
        self.usesCellular = usesCellular
        self.usesWiredEthernet = usesWiredEthernet
        self.usesOther = usesOther
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
    }

    init(path: NWPath) {
        switch path.status {
        case .satisfied: status = .satisfied
        case .requiresConnection: status = .requiresConnection
        case .unsatisfied: status = .unsatisfied
        @unknown default: status = .unsatisfied
        }
        usesWiFi = path.usesInterfaceType(.wifi)
        usesCellular = path.usesInterfaceType(.cellular)
        usesWiredEthernet = path.usesInterfaceType(.wiredEthernet)
        usesOther = path.usesInterfaceType(.other)
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
    }
}

final class NetworkPathChangeDetector: @unchecked Sendable {
    private let lock = NSLock()
    private var baseline: NetworkPathSnapshot?

    /// Retorna `true` apenas depois de já existir um caminho-base para comparar.
    func register(_ snapshot: NetworkPathSnapshot) -> Bool {
        lock.withLock {
            defer { baseline = snapshot }
            guard let baseline else { return false }
            return baseline != snapshot
        }
    }
}
