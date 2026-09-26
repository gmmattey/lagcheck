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
/// Segue a Integridade Diagnóstica (Decisões 50 e 51):
/// - Descobre o gateway padrão real a partir da tabela de rotas do sistema.
/// - Mede RTT REAL de ida e volta por consulta DNS (porta 53) com validação de Transaction ID.
/// - NUNCA trata conclusão de envio UDP (contentProcessed) como RTT sem resposta confirmada.
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

        // 2. Resolve o IPv4 real do default gateway
        guard let gatewayAddress = resolveDefaultGatewayIPv4() else {
            return WiFiLocalTelemetry(
                validSampleCount: 0,
                plannedSampleCount: sampleCount,
                isWiFi: true
            )
        }

        // 3. Executa a amostragem com medição de RTT real de resposta (ida e volta)
        var rtts: [Double] = []
        for _ in 0..<sampleCount {
            if let rtt = await probeHostDNSQuery(address: gatewayAddress, timeout: timeoutPerSampleSeconds) {
                rtts.append(rtt)
            }
        }

        guard !rtts.isEmpty else {
            // Roteador não respondeu na porta 53: nenhuma amostra inventada!
            return WiFiLocalTelemetry(
                validSampleCount: 0,
                plannedSampleCount: sampleCount,
                isWiFi: true
            )
        }

        // 4. Calcula mediana, jitter e cauda de RTT real
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

    /// Resolve o endereço IPv4 do gateway padrão utilizando a tabela de rotas do kernel BSD/Darwin.
    /// Caso não esteja disponível no sandbox, busca a interface Wi-Fi (en0).
    public func resolveDefaultGatewayIPv4() -> String? {
        #if canImport(Darwin)
        // Tentativa 1: sysctl NET_RT_FLAGS com RTF_GATEWAY
        if let routingGateway = resolveGatewayFromRoutingTable() {
            return routingGateway
        }

        // Tentativa 2: Consulta getifaddrs para en0 com verificação cautelosa
        return resolveGatewayFromInterfaceFallback()
        #else
        return nil
        #endif
    }

    #if canImport(Darwin)
    private static let rtfGatewayFlag: Int32 = 0x2
    private static let rtaDstFlag: Int32 = 0x1
    private static let rtaGatewayFlag: Int32 = 0x2
    private static let rtaNetmaskFlag: Int32 = 0x4
    private static let rtaGenmaskFlag: Int32 = 0x8
    private static let rtaIfpFlag: Int32 = 0x10
    private static let rtaIfaFlag: Int32 = 0x20
    private static let rtaAuthorFlag: Int32 = 0x40
    private static let rtaBrdFlag: Int32 = 0x80

    private struct DarwinRtMetrics {
        var rmx_locks: UInt32 = 0
        var rmx_mtu: UInt32 = 0
        var rmx_hopcount: UInt32 = 0
        var rmx_expire: Int32 = 0
        var rmx_recvpipe: UInt32 = 0
        var rmx_sendpipe: UInt32 = 0
        var rmx_ssthresh: UInt32 = 0
        var rmx_rtt: UInt32 = 0
        var rmx_rttvar: UInt32 = 0
        var rmx_pksent: UInt32 = 0
        var rmx_filler0: UInt32 = 0
        var rmx_filler1: UInt32 = 0
        var rmx_filler2: UInt32 = 0
        var rmx_filler3: UInt32 = 0
    }

    private struct DarwinRtMsgHdr {
        var rtm_msglen: UInt16
        var rtm_version: UInt8
        var rtm_type: UInt8
        var rtm_index: UInt16
        var rtm_flags: Int32
        var rtm_addrs: Int32
        var rtm_pid: pid_t
        var rtm_seq: Int32
        var rtm_errno: Int32
        var rtm_use: Int32
        var rtm_inits: UInt32
        var rtm_rmx: DarwinRtMetrics
    }

    private func resolveGatewayFromRoutingTable() -> String? {
        let wifiIndex = if_nametoindex("en0")
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, Self.rtfGatewayFlag]
        var len: size_t = 0
        guard sysctl(&mib, UInt32(mib.count), nil, &len, nil, 0) == 0, len > 0 else {
            return nil
        }

        var buffer = [UInt8](repeating: 0, count: len)
        guard sysctl(&mib, UInt32(mib.count), &buffer, &len, nil, 0) == 0 else {
            return nil
        }

        var offset = 0
        while offset < len {
            let msgPtr = buffer.withUnsafeBytes { rawBytes -> UnsafePointer<DarwinRtMsgHdr>? in
                guard offset + MemoryLayout<DarwinRtMsgHdr>.size <= len else { return nil }
                return rawBytes.baseAddress?.advanced(by: offset).assumingMemoryBound(to: DarwinRtMsgHdr.self)
            }
            guard let rtm = msgPtr?.pointee, rtm.rtm_msglen > 0 else { break }

            let msgLen = Int(rtm.rtm_msglen)
            let addrs = Int(rtm.rtm_addrs)

            // Se o índice de en0 for conhecido, ignora rotas associadas a túneis VPN
            if wifiIndex > 0 && rtm.rtm_index != 0 && rtm.rtm_index != wifiIndex {
                offset += msgLen
                continue
            }

            if (addrs & Int(Self.rtaGatewayFlag)) != 0 {
                var sockOffset = offset + MemoryLayout<DarwinRtMsgHdr>.size
                let rtaBits = [
                    Self.rtaDstFlag, Self.rtaGatewayFlag, Self.rtaNetmaskFlag,
                    Self.rtaGenmaskFlag, Self.rtaIfpFlag, Self.rtaIfaFlag,
                    Self.rtaAuthorFlag, Self.rtaBrdFlag
                ]

                for bit in rtaBits {
                    guard (addrs & Int(bit)) != 0 else { continue }
                    guard sockOffset + MemoryLayout<sockaddr>.size <= offset + msgLen else { break }

                    let saPtr = buffer.withUnsafeBytes { rawBytes -> UnsafePointer<sockaddr>? in
                        rawBytes.baseAddress?.advanced(by: sockOffset).assumingMemoryBound(to: sockaddr.self)
                    }

                    if let sa = saPtr?.pointee {
                        let saLen = sa.sa_len > 0 ? Int(sa.sa_len) : MemoryLayout<sockaddr>.size
                        let alignedLen = (saLen + 3) & ~3

                        if bit == Self.rtaGatewayFlag && sa.sa_family == UInt8(AF_INET) {
                            if let sinPtr = saPtr?.withMemoryRebound(to: sockaddr_in.self, capacity: 1, { $0 }) {
                                var sinAddr = sinPtr.pointee.sin_addr
                                var ipBuffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                                if inet_ntop(AF_INET, &sinAddr, &ipBuffer, socklen_t(INET_ADDRSTRLEN)) != nil {
                                    let gatewayStr = String(cString: ipBuffer)
                                    if !gatewayStr.isEmpty && gatewayStr != "0.0.0.0" {
                                        return gatewayStr
                                    }
                                }
                            }
                        }
                        sockOffset += alignedLen
                    } else {
                        break
                    }
                }
            }
            offset += msgLen
        }
        return nil
    }

    private func resolveGatewayFromInterfaceFallback() -> String? {
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
            let gatewayHost = network | 1 // Heurística padrão caso a routing table esteja inacessível
            let gatewayNetworkOrder = gatewayHost.bigEndian

            var inAddr = in_addr(s_addr: gatewayNetworkOrder)
            var ipBuffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            if inet_ntop(AF_INET, &inAddr, &ipBuffer, socklen_t(INET_ADDRSTRLEN)) != nil {
                return String(cString: ipBuffer)
            }
        }
        return nil
    }
    #endif

    /// Envia query DNS real (porta 53) para o roteador local e aguarda resposta UDP válida (RTT real de ida e volta).
    /// Se o roteador não responder ou der timeout, retorna `nil` honestamente.
    private func probeHostDNSQuery(address: String, timeout: TimeInterval) async -> Double? {
        await withCheckedContinuation { continuation in
            let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(address), port: 53)
            let connection = NWConnection(to: endpoint, using: .udp)
            let queue = DispatchQueue(label: "com.nolaggy.gateway-dns-probe")

            let start = ContinuousClock.now
            let isResumed = OSAllocatedUnfairLock(initialState: false)

            // Gera Transaction ID de 16 bits para correlacionar a resposta
            let txId = UInt16.random(in: 1...0xFFFE)
            let queryPacket = makeDNSQuery(transactionID: txId)

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
                    // Envia query DNS
                    connection.send(content: queryPacket, completion: .contentProcessed { sendError in
                        guard sendError == nil else {
                            let shouldResume = isResumed.withLock { resumed -> Bool in
                                if !resumed { resumed = true; return true }
                                return false
                            }
                            if shouldResume {
                                timer.cancel()
                                connection.cancel()
                                continuation.resume(returning: nil)
                            }
                            return
                        }

                        // Aguarda resposta UDP real do roteador com correlation ID
                        connection.receiveMessage { data, _, _, recvError in
                            let shouldResume = isResumed.withLock { resumed -> Bool in
                                if !resumed { resumed = true; return true }
                                return false
                            }
                            guard shouldResume else { return }

                            timer.cancel()
                            connection.cancel()

                            guard recvError == nil, let data, data.count >= 2 else {
                                continuation.resume(returning: nil)
                                return
                            }

                            // Valida se o Transaction ID da resposta bate com o enviado
                            let respTxId = (UInt16(data[0]) << 8) | UInt16(data[1])
                            guard respTxId == txId else {
                                continuation.resume(returning: nil)
                                return
                            }

                            let elapsed = ContinuousClock.now - start
                            let elapsedMs = Double(elapsed.components.seconds) * 1000.0 + Double(elapsed.components.attoseconds) / 1_000_000_000_000_000.0
                            continuation.resume(returning: elapsedMs)
                        }
                    })

                case .failed:
                    let shouldResume = isResumed.withLock { resumed -> Bool in
                        if !resumed { resumed = true; return true }
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

    /// Constrói uma query DNS básica RFC 1035 para "local" ou "a.root-servers.net"
    private func makeDNSQuery(transactionID: UInt16) -> Data {
        var data = Data()
        // Transaction ID (2 bytes)
        data.append(UInt8(transactionID >> 8))
        data.append(UInt8(transactionID & 0xFF))
        // Flags: 0x0100 (Standard query, RD = 1)
        data.append(contentsOf: [0x01, 0x00])
        // QDCOUNT: 1 question
        data.append(contentsOf: [0x00, 0x01])
        // ANCOUNT, NSCOUNT, ARCOUNT: 0
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        // QNAME: "local" (5 'l' 'o' 'c' 'a' 'l' 0)
        data.append(0x05)
        data.append(contentsOf: "local".utf8)
        data.append(0x00)
        // QTYPE: A (0x0001)
        data.append(contentsOf: [0x00, 0x01])
        // QCLASS: IN (0x0001)
        data.append(contentsOf: [0x00, 0x01])
        return data
    }
}
