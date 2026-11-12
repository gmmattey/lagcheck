import Network
import NolaggyApplication

/// Consulta pontual usada antes de cada fase do Deep Check para identificar a interface de rede ativa.
/// O observador contínuo continua sendo responsável por cancelar uma sessão quando o caminho muda.
public struct NWPathWiFiAvailability: WiFiAvailability {
    public init() {}

    public func currentInterface() async -> NetworkInterfaceType {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "com.nolaggy.pilot.interface-availability")
        return await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { continuation in
                monitor.pathUpdateHandler = { path in
                    let result: NetworkInterfaceType
                    if path.status == .satisfied {
                        if path.usesInterfaceType(.wifi) {
                            result = .wifi
                        } else if path.usesInterfaceType(.cellular) {
                            result = .cellular
                        } else {
                            result = .other
                        }
                    } else {
                        result = .none
                    }
                    continuation.resume(returning: result)
                    monitor.cancel()
                }
                monitor.start(queue: queue)
            }
        }, onCancel: {
            monitor.cancel()
        })
    }

    public func isWiFiAvailable() async -> Bool {
        await currentInterface() == .wifi
    }

    public func isCellularAvailable() async -> Bool {
        await currentInterface() == .cellular
    }
}
