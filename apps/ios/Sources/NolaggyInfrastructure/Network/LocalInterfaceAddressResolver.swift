import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// Resolve o endereço IPv4 da própria interface de rede ativa do dispositivo
/// (Wi-Fi ou celular), usado para correlacionar com o IP público observado via STUN
/// e assim detectar NAT Tipo 1 (Aberto) quando local == público.
public protocol LocalInterfaceAddressResolving: Sendable {
    func resolveLocalIPv4() -> String?
}

/// Implementação baseada em `getifaddrs`, priorizando interfaces Wi-Fi (`en0`, `en1`)
/// e, na ausência delas, interfaces celulares (`pdp_ip0`...`pdp_ip3`).
public struct BSDLocalInterfaceAddressResolver: LocalInterfaceAddressResolving {

    /// Ordem de prioridade das interfaces: Wi-Fi primeiro, depois celular.
    public static let interfacePriority: [String] = ["en0", "en1", "pdp_ip0", "pdp_ip1", "pdp_ip2", "pdp_ip3"]

    public init() {}

    public func resolveLocalIPv4() -> String? {
        #if canImport(Darwin)
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }
        defer { freeifaddrs(ifaddr) }

        // Coleta todos os endereços IPv4 válidos por nome de interface, e então
        // seleciona conforme a ordem de prioridade definida.
        var addressesByInterface: [String: String] = [:]

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) == IFF_UP
            let isRunning = (flags & IFF_RUNNING) == IFF_RUNNING
            let isLoopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK

            guard isUp, isRunning, !isLoopback else { continue }
            guard let addr = ptr.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) else { continue }

            let name = String(cString: ptr.pointee.ifa_name)
            guard Self.interfacePriority.contains(name) else { continue }

            let sinAddr = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr }
            var mutableAddr = sinAddr
            var ipBuffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            guard inet_ntop(AF_INET, &mutableAddr, &ipBuffer, socklen_t(INET_ADDRSTRLEN)) != nil else { continue }

            addressesByInterface[name] = String(cString: ipBuffer)
        }

        for name in Self.interfacePriority {
            if let address = addressesByInterface[name] {
                return address
            }
        }
        #endif
        return nil
    }
}
