import Network
import NolaggyApplication

/// Consulta pontual usada antes de cada fase do Deep Check. O observador contínuo
/// continua sendo responsável por cancelar uma sessão quando o caminho muda.
public struct NWPathWiFiAvailability: WiFiAvailability {
    public init() {}

    public func isWiFiAvailable() async -> Bool {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "com.nolaggy.pilot.wifi-availability")
        return await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { continuation in
                monitor.pathUpdateHandler = { path in
                    continuation.resume(returning: path.status == .satisfied && path.usesInterfaceType(.wifi))
                    monitor.cancel()
                }
                monitor.start(queue: queue)
            }
        }, onCancel: {
            monitor.cancel()
        })
    }
}
