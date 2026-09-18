import Foundation
import Network
import NolaggyDomain
import os
#if canImport(Darwin)
import Darwin
#endif

public protocol WiFiLocalGatewayProbing: Sendable {
    func probeLocalGateway(sampleCount: Int, timeoutPerSampleSeconds: TimeInterval) async -> WiFiLocalTelemetry
}

/// Sonda o primeiro salto (roteador Wi-Fi) para diagnosticar se a oscilação é local (RF) ou externa (WAN).
public struct BSDWiFiLocalGatewayProber: WiFiLocalGatewayProbing {
    
    public init() {}

    public func probeLocalGateway(
        sampleCount: Int = 5,
        timeoutPerSampleSeconds: TimeInterval = 0.5
    ) async -> WiFiLocalTelemetry {
        // 1. Verifica se a interface primária atual é Wi-Fi
        let isWiFi = await checkIsWiFi()
        guard isWiFi else {
            return WiFiLocalTelemetry(
                validSampleCount: 0,
                plannedSampleCount: 0,
                isWiFi: false
            )
        }

        // 2. Tenta resolver o IPv4 provável do gateway da interface en0
        guard let gatewayAddress = resolveDefaultGatewayIPv4() else {
            return WiFiLocalTelemetry(
                validSampleCount: 0,
                plannedSampleCount: sampleCount,
                isWiFi: true
            )
        }

        // 3. Executa a amostragem UDP local com timeout estrito
        var rtts: [Double] = []
        for _ in 0..<sampleCount {
            if let rtt = await probeHost(address: gatewayAddress, timeout: timeoutPerSampleSeconds) {
                rtts.append(rtt)
            }
        }

        guard !rtts.isEmpty else {
            return WiFiLocalTelemetry(
                validSampleCount: 0,
                plannedSampleCount: sampleCount,
                isWiFi: true
            )
        }

        // 4. Calcula mediana, jitter adjacente e cauda
        let sortedRTTs = rtts.sorted()
        let median: Double
        if sortedRTTs.count % 2 == 1 {
            median = sortedRTTs[sortedRTTs.count / 2]
        } else {
            let mid = sortedRTTs.count / 2
            median = (sortedRTTs[mid - 1] + sortedRTTs[mid]) / 2.0
        }

        var jitter: Double = 0.0
        if rtts.count > 1 {
            var diffSum: Double = 0.0
            for i in 0..<(rtts.count - 1) {
                diffSum += abs(rtts[i + 1] - rtts[i])
            }
            jitter = diffSum / Double(rtts.count - 1)
        }

        let p95Index = Int(ceil(Double(sortedRTTs.count) * 0.95)) - 1
        let safeP95Index = max(0, min(p95Index, sortedRTTs.count - 1))
        let p95 = sortedRTTs[safeP95Index]
        let tailRatio = median > 0 ? (p95 / median) : 1.0

        return WiFiLocalTelemetry(
            gatewayRTTMedianMs: median,
            gatewayJitterMs: jitter,
            tailRatioP95P50: tailRatio,
            validSampleCount: rtts.count,
            plannedSampleCount: sampleCount,
            isWiFi: true
        )
    }

    private func checkIsWiFi() async -> Bool {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "com.nolaggy.gateway-wifi-check")
        return await withCheckedContinuation { continuation in
            monitor.pathUpdateHandler = { path in
                continuation.resume(returning: path.usesInterfaceType(.wifi))
                monitor.cancel()
            }
            monitor.start(queue: queue)
        }
    }

    /// Resolve o endereço IPv4 do gateway da rede sem fio local através de getifaddrs.
    public func resolveDefaultGatewayIPv4() -> String? {
        #if canImport(Darwin)
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) == IFF_UP
            let isRunning = (flags & IFF_RUNNING) == IFF_RUNNING
            let isLoopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK

            guard isUp, isRunning, !isLoopback else { continue }

            let name = String(cString: ptr.pointee.ifa_name)
            guard name == "en0" else { continue }

            guard let addr = ptr.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) else { continue }
            guard let netmask = ptr.pointee.ifa_netmask else { continue }

            let sinAddr = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr.s_addr }
            let sinMask = netmask.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr.s_addr }

            let hostAddr = UInt32(bigEndian: sinAddr)
            let hostMask = UInt32(bigEndian: sinMask)

            let network = hostAddr & hostMask
            let gatewayHost = network | 1 // Subnet router padrão RFC 1918 (.1)
            let gatewayNetworkOrder = gatewayHost.bigEndian

            var inAddr = in_addr(s_addr: gatewayNetworkOrder)
            var ipBuffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            if inet_ntop(AF_INET, &inAddr, &ipBuffer, socklen_t(INET_ADDRSTRLEN)) != nil {
                return String(cString: ipBuffer)
            }
        }
        #endif
        return nil
    }

    /// Envia datagrama UDP local com tempo de resposta medido monotonicamente e concorrência estrita Swift 6.
    private func probeHost(address: String, timeout: TimeInterval) async -> Double? {
        await withCheckedContinuation { continuation in
            let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(address), port: 53)
            let connection = NWConnection(to: endpoint, using: .udp)
            let queue = DispatchQueue(label: "com.nolaggy.gateway-probe")

            let start = ContinuousClock.now
            let isResumed = OSAllocatedUnfairLock(initialState: false)

            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + timeout)
            timer.setEventHandler {
                let shouldResume = isResumed.withLock { resumed -> Bool in
                    if !resumed {
                        resumed = true
                        return true
                    }
                    return false
                }
                if shouldResume {
                    connection.cancel()
                    continuation.resume(returning: nil)
                }
            }
            timer.resume()

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let dummyData = Data([0x00, 0x01, 0x01, 0x00])
                    connection.send(content: dummyData, completion: .contentProcessed { error in
                        guard error == nil else { return }
                        let shouldResume = isResumed.withLock { resumed -> Bool in
                            if !resumed {
                                resumed = true
                                return true
                            }
                            return false
                        }
                        if shouldResume {
                            let elapsed = ContinuousClock.now - start
                            let elapsedMs = Double(elapsed.components.seconds) * 1000.0 + Double(elapsed.components.attoseconds) / 1_000_000_000_000_000.0
                            timer.cancel()
                            connection.cancel()
                            continuation.resume(returning: elapsedMs)
                        }
                    })
                case .failed:
                    let shouldResume = isResumed.withLock { resumed -> Bool in
                        if !resumed {
                            resumed = true
                            return true
                        }
                        return false
                    }
                    if shouldResume {
                        timer.cancel()
                        connection.cancel()
                        continuation.resume(returning: nil)
                    }
                default:
                    break
                }
            }

            connection.start(queue: queue)
        }
    }
}
