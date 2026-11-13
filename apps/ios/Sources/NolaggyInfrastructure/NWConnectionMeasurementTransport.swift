import Foundation
import Network
import NolaggyApplication
import NolaggyDomain
import Security

/// Transporte UDP do piloto. Ele só mede o destino configurado e nunca tenta outro protocolo.
/// A composição do app o habilita somente no binário Debug instalado em iPhone.
public struct NWConnectionMeasurementTransport: MeasurementTransport {
    public init() {}

    public func collect(
        session: MeasurementSession,
        plan: QuickCheckPlan,
        onSample: @escaping @Sendable (ProbeSample) async -> Void
    ) async -> [ProbeSample] {
        let protocolKind = plan.endpoint.protocolKind
        let generated: (probes: [(sequence: Int, payload: Data)], validator: @Sendable (Data, Data) -> Bool)
        do {
            generated = try Self.generateProbes(
                count: ProbeAcceptancePolicy.plannedProbeCount,
                protocolKind: protocolKind
            )
        } catch {
            return (0..<ProbeAcceptancePolicy.plannedProbeCount).map {
                ProbeSample(sequence: $0, outcome: .transportError)
            }
        }

        let ledger = ProbeLedger(probes: generated.probes, isCorrelatedResponse: generated.validator)
        let challengeHolder = SteamChallengeHolder()

        let connection = UDPConnection(
            host: NWEndpoint.Host(plan.endpoint.host),
            port: NWEndpoint.Port(rawValue: plan.endpoint.port)!
        ) { response, receivedAt in
            if protocolKind == .steamA2S && SteamQueryA2SPayloadCodec.isChallengeResponse(response) {
                if let token = try? SteamQueryA2SPayloadCodec.decodeChallenge(response) {
                    challengeHolder.setToken(token)
                }
                return
            }
            if let sample = ledger.accept(response: response, receivedAt: receivedAt) {
                Task { await onSample(sample) }
            }
        }

        return await withTaskCancellationHandler(operation: {
            connection.start()

            // Para Steam A2S, realiza sondagem preliminar para obter o challengeToken antes dos probes.
            if protocolKind == .steamA2S {
                connection.send(SteamQueryA2SPayloadCodec.encodeInitialRequest()) {}
                for _ in 0..<6 {
                    if challengeHolder.getToken() != nil { break }
                    await sleep(until: DispatchTime.now().uptimeNanoseconds + 50_000_000)
                }
            }

            // `t0` é obtido imediatamente antes do primeiro envio; os payloads já estão prontos.
            let start = DispatchTime.now().uptimeNanoseconds
            for probe in generated.probes {
                guard !Task.isCancelled else {
                    connection.cancel()
                    return []
                }

                let scheduledAt = start + UInt64(probe.sequence) * 500_000_000
                await sleep(until: scheduledAt)
                guard !Task.isCancelled else {
                    connection.cancel()
                    return []
                }

                let payloadToSend: Data
                if protocolKind == .steamA2S, let token = challengeHolder.getToken() {
                    payloadToSend = SteamQueryA2SPayloadCodec.encodeAuthenticatedRequest(challengeToken: token)
                } else {
                    payloadToSend = probe.payload
                }

                let sentAt = DispatchTime.now().uptimeNanoseconds
                ledger.register(sequence: probe.sequence, payload: payloadToSend, sentAt: sentAt)
                connection.send(payloadToSend) {
                    ledger.markTransportError(sequence: probe.sequence)
                }
            }

            // A drenagem termina exatamente no limite técnico de 17 segundos.
            await sleep(until: start + 17_000_000_000)
            connection.cancel()
            guard !Task.isCancelled else { return [] }
            return ledger.finish(at: DispatchTime.now().uptimeNanoseconds)
        }, onCancel: {
            connection.cancel()
        })
    }

    static func generateProbes(
        count: Int,
        protocolKind: ProbeProtocolKind
    ) throws -> (probes: [(sequence: Int, payload: Data)], validator: @Sendable (Data, Data) -> Bool) {
        switch protocolKind {
        case .gameLiftPing:
            let sessionID = try SecureRandom.uuid()
            let probes = try (0..<count).map { sequence in
                let payload = PingBeaconPayload(
                    sessionID: sessionID,
                    sequence: UInt32(sequence),
                    nonce: try SecureRandom.uint64()
                )
                return (sequence, PingBeaconPayloadCodec.encode(payload))
            }
            return (probes, { req, resp in PingBeaconPayloadCodec.isExactEcho(of: req, response: resp) })

        case .playFabQoS:
            let sessionID = try SecureRandom.uuid()
            let probes = try (0..<count).map { sequence in
                let payload = PlayFabQoSPayload(
                    sessionID: sessionID,
                    sequence: UInt32(sequence),
                    nonce: try SecureRandom.uint64()
                )
                return (sequence, PlayFabQoSPayloadCodec.encode(payload))
            }
            return (probes, { req, resp in PlayFabQoSPayloadCodec.isValidEcho(of: req, response: resp) })

        case .steamA2S:
            let initialPayload = SteamQueryA2SPayloadCodec.encodeInitialRequest()
            let probes = (0..<count).map { sequence in
                (sequence, initialPayload)
            }
            return (probes, { _, resp in SteamQueryA2SPayloadCodec.isValidInfoResponse(resp) })
        }
    }

    private func sleep(until deadline: UInt64) async {
        let now = DispatchTime.now().uptimeNanoseconds
        guard deadline > now else { return }
        try? await Task.sleep(nanoseconds: deadline - now)
    }
}

/// Coleta exclusiva da pré-leitura regional: três probes, um por segundo,
/// cada um válido apenas durante dois segundos. O destino vem do snapshot.
public struct NWRegionalPreReadCollector: RegionalPreReadCollecting {
    private let onEvent: RegionalPreReadEventHandler?

    /// `onEvent` recebe cada envio e cada resposta real, para o mapa de medição.
    public init(onEvent: RegionalPreReadEventHandler? = nil) {
        self.onEvent = onEvent
    }

    public func collect(candidate: RegionalSelectionCandidate) async -> [RegionalPreReadSample] {
        let portRaw = candidate.resolvedContext.destination.port
        let protocolKind = candidate.resolvedContext.probeProtocol
        guard let port = NWEndpoint.Port(rawValue: portRaw) else {
            return Array(repeating: RegionalPreReadSample(outcome: .transportError), count: 3)
        }
        let generated: (probes: [(sequence: Int, payload: Data)], validator: @Sendable (Data, Data) -> Bool)
        do {
            generated = try NWConnectionMeasurementTransport.generateProbes(
                count: 3,
                protocolKind: candidate.resolvedContext.destination.protocolKind
            )
        } catch {
            return Array(repeating: RegionalPreReadSample(outcome: .transportError), count: 3)
        }
        guard generated.probes.count == 3 else {
            return Array(repeating: RegionalPreReadSample(outcome: .transportError), count: 3)
        }
        let ledger = ProbeLedger(probes: generated.probes, isCorrelatedResponse: generated.validator)
        let regionID = candidate.regionID
        let onEvent = onEvent
        let connection = UDPConnection(host: NWEndpoint.Host(candidate.resolvedContext.destination.host), port: port) { response, receivedAt in
            if let sample = ledger.accept(response: response, receivedAt: receivedAt),
               sample.isValidResponse, let rtt = sample.roundTripMilliseconds {
                onEvent?(regionID, .answered(rttMilliseconds: rtt))
            }
        }
        connection.start()
        let start = DispatchTime.now().uptimeNanoseconds
        for (sequence, payload) in generated.probes {
            guard !Task.isCancelled else { connection.cancel(); return [] }
            let deadline = start + UInt64(sequence) * 1_000_000_000
            let now = DispatchTime.now().uptimeNanoseconds
            if deadline > now { try? await Task.sleep(nanoseconds: deadline - now) }
            let sentAt = DispatchTime.now().uptimeNanoseconds
            ledger.register(sequence: sequence, payload: payload, sentAt: sentAt)
            connection.send(payload) { ledger.markTransportError(sequence: sequence) }
            onEvent?(regionID, .sent)
        }
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        connection.cancel()
        let samples = ledger.finish(at: DispatchTime.now().uptimeNanoseconds).filter { $0.sequence >= 0 }
        for sample in samples where !sample.isValidResponse {
            onEvent?(regionID, .unanswered)
        }
        return samples.map { RegionalPreReadSample(outcome: $0.outcome, roundTripMilliseconds: $0.roundTripMilliseconds) }
    }
}

private final class SteamChallengeHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var token: UInt32?

    func setToken(_ t: UInt32) {
        lock.withLock { token = t }
    }

    func getToken() -> UInt32? {
        lock.withLock { token }
    }
}

private enum SecureRandom {
    static func uuid() throws -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else { throw RandomError.unavailable }
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    static func uint64() throws -> UInt64 {
        var value: UInt64 = 0
        let status = withUnsafeMutableBytes(of: &value) { bytes in
            SecRandomCopyBytes(kSecRandomDefault, bytes.count, bytes.baseAddress!)
        }
        guard status == errSecSuccess else { throw RandomError.unavailable }
        return value
    }

    enum RandomError: Error { case unavailable }
}

/// Mantém a correlação e os prazos fora de `NWConnection`, para que possam ser testados sem rede.
final class ProbeLedger: @unchecked Sendable {
    private struct PendingProbe {
        let payload: Data
        var sentAt: UInt64?
        var result: ProbeSample?
    }

    private let lock = NSLock()
    private var probes: [Int: PendingProbe]
    private var invalidResponseCount = 0
    private var receivedCount = 0
    private let isCorrelatedResponse: @Sendable (_ request: Data, _ response: Data) -> Bool

    init(
        probes: [(sequence: Int, payload: Data)],
        isCorrelatedResponse: @escaping @Sendable (_ request: Data, _ response: Data) -> Bool = { $0 == $1 }
    ) {
        self.probes = Dictionary(uniqueKeysWithValues: probes.map { ($0.sequence, PendingProbe(payload: $0.payload, sentAt: nil, result: nil)) })
        self.isCorrelatedResponse = isCorrelatedResponse
    }

    convenience init(probes: [(sequence: Int, payload: Data)], protocolKind: ProbeProtocolKind) {
        let validator: @Sendable (Data, Data) -> Bool
        switch protocolKind {
        case .gameLiftPing:
            validator = { req, resp in PingBeaconPayloadCodec.isExactEcho(of: req, response: resp) }
        case .playFabQoS:
            validator = { req, resp in PlayFabQoSPayloadCodec.isValidEcho(of: req, response: resp) }
        case .steamA2S:
            validator = { _, resp in SteamQueryA2SPayloadCodec.isValidInfoResponse(resp) }
        }
        self.init(probes: probes, isCorrelatedResponse: validator)
    }

    func register(sequence: Int, payload: Data, sentAt: UInt64) {
        lock.withLock {
            guard var probe = probes[sequence] else { return }
            probe.sentAt = sentAt
            probes[sequence] = PendingProbe(payload: payload, sentAt: sentAt, result: probe.result)
        }
    }

    func accept(response: Data, receivedAt: UInt64) -> ProbeSample? {
        lock.withLock {
            guard let match = probes
                .filter({ entry in
                    guard let sentAt = entry.value.sentAt,
                          entry.value.result == nil,
                          receivedAt >= sentAt,
                          receivedAt - sentAt < 2_000_000_000 else {
                        return false
                    }
                    return true
                })
                .sorted(by: {
                    ($0.value.sentAt ?? 0) < ($1.value.sentAt ?? 0)
                })
                .first(where: { isCorrelatedResponse($0.value.payload, response) }),
                var probe = probes[match.key],
                let sentAt = probe.sentAt else {
                invalidResponseCount += 1
                return nil
            }

            let arrival = receivedCount
            receivedCount += 1

            let sample = ProbeSample(
                sequence: match.key,
                roundTripMilliseconds: Double(receivedAt - sentAt) / 1_000_000,
                outcome: .received,
                arrivalIndex: arrival
            )
            probe.result = sample
            probes[match.key] = probe
            return sample
        }
    }

    func markTransportError(sequence: Int) {
        lock.withLock {
            guard var probe = probes[sequence], probe.sentAt != nil, probe.result == nil else { return }
            probe.result = ProbeSample(sequence: sequence, outcome: .transportError)
            probes[sequence] = probe
        }
    }

    func finish(at closureTime: UInt64) -> [ProbeSample] {
        lock.withLock {
            let planned = probes.keys.sorted().map { sequence -> ProbeSample in
                guard let probe = probes[sequence] else { return ProbeSample(sequence: sequence, outcome: .transportError) }
                if let result = probe.result { return result }
                return ProbeSample(sequence: sequence, outcome: .timeout)
            }
            // Uma resposta inválida é diagnóstico separado: ela não substitui o timeout do probe.
            let invalid = (0..<invalidResponseCount).map { _ in
                ProbeSample(sequence: -1, outcome: .invalidResponse)
            }
            return planned + invalid
        }
    }
}

private final class UDPConnection: @unchecked Sendable {
    private let connection: NWConnection
    private let queue = DispatchQueue(label: "com.nolaggy.pilot.udp")
    private let onResponse: @Sendable (Data, UInt64) -> Void

    init(host: NWEndpoint.Host, port: NWEndpoint.Port, onResponse: @escaping @Sendable (Data, UInt64) -> Void) {
        connection = NWConnection(host: host, port: port, using: .udp)
        self.onResponse = onResponse
    }

    func start() {
        connection.start(queue: queue)
        receiveNext()
    }

    func send(_ payload: Data, onError: @escaping @Sendable () -> Void) {
        connection.send(content: payload, completion: .contentProcessed { error in
            if error != nil { onError() }
        })
    }

    func cancel() {
        connection.cancel()
    }

    private func receiveNext() {
        connection.receiveMessage { [weak self] data, _, _, error in
            guard let self else { return }
            if let data {
                self.onResponse(data, DispatchTime.now().uptimeNanoseconds)
            }
            guard error == nil else { return }
            self.receiveNext()
        }
    }
}

/// Pré-validação curta e silenciosa para um candidato A2S já assinado. Não é
/// scanner: abre no máximo uma conexão UDP para o host/porta recebido e só
/// aceita uma resposta cuja identidade seja a esperada.
public final class SteamA2SRoutePreflight: GameRoutePreflighting, @unchecked Sendable {
    private let timeout: Duration
    private let queue: DispatchQueue

    public init(timeout: Duration = .seconds(2), queue: DispatchQueue = DispatchQueue(label: "com.lagcheck.a2s-preflight")) {
        self.timeout = timeout
        self.queue = queue
    }

    public func validates(candidate: ResolvedMeasurementContext, identity: RemoteCatalogRouteIdentity) async -> Bool {
        guard candidate.destination.protocolKind == .steamA2S,
              let port = NWEndpoint.Port(rawValue: candidate.destination.port) else { return false }
        let connection = NWConnection(host: NWEndpoint.Host(candidate.destination.host), port: port, using: .udp)
        return await withCheckedContinuation { continuation in
            let completion = A2SPreflightCompletion(connection: connection, continuation: continuation)
            let machine = A2SPreflightMachineBox(SteamA2SPreflightMachine(identity: identity))
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    Self.send(machine.initialRequest, on: connection, machine: machine, completion: completion)
                case .failed, .cancelled:
                    completion.finish(false)
                default:
                    break
                }
            }
            connection.start(queue: queue)
            Task { [timeout] in
                try? await Task.sleep(for: timeout)
                completion.finish(false)
            }
        }
    }

    private static func send(_ payload: Data, on connection: NWConnection, machine: A2SPreflightMachineBox, completion: A2SPreflightCompletion) {
        connection.send(content: payload, completion: .contentProcessed { error in
            guard error == nil else { completion.finish(false); return }
            connection.receiveMessage { data, _, _, error in
                switch machine.receive(error == nil ? data : nil) {
                case let .send(next): send(next, on: connection, machine: machine, completion: completion)
                case .accept: completion.finish(true)
                case .reject: completion.finish(false)
                }
            }
        })
    }
}

private final class A2SPreflightMachineBox: @unchecked Sendable {
    private let lock = NSLock()
    private var machine: SteamA2SPreflightMachine

    init(_ machine: SteamA2SPreflightMachine) { self.machine = machine }

    var initialRequest: Data { machine.initialRequest }

    func receive(_ datagram: Data?) -> SteamA2SPreflightMachine.Step {
        lock.lock(); defer { lock.unlock() }
        return machine.receive(datagram)
    }
}

private final class A2SPreflightCompletion: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Bool, Never>?
    private let connection: NWConnection

    init(connection: NWConnection, continuation: CheckedContinuation<Bool, Never>) {
        self.connection = connection
        self.continuation = continuation
    }

    func finish(_ value: Bool) {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        guard let continuation else { return }
        connection.cancel()
        continuation.resume(returning: value)
    }
}
