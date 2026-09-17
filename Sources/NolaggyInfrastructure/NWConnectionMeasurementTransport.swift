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
        let sessionID: UUID
        do {
            sessionID = try SecureRandom.uuid()
        } catch {
            return (0..<ProbeAcceptancePolicy.plannedProbeCount).map {
                ProbeSample(sequence: $0, outcome: .transportError)
            }
        }
        let probes: [(sequence: Int, payload: Data)]
        do {
            probes = try (0..<ProbeAcceptancePolicy.plannedProbeCount).map { sequence in
                let payload = PingBeaconPayload(
                    sessionID: sessionID,
                    sequence: UInt32(sequence),
                    nonce: try SecureRandom.uint64()
                )
                return (sequence, PingBeaconPayloadCodec.encode(payload))
            }
        } catch {
            return (0..<ProbeAcceptancePolicy.plannedProbeCount).map {
                ProbeSample(sequence: $0, outcome: .transportError)
            }
        }

        let ledger = ProbeLedger(probes: probes)
        let connection = UDPConnection(
            host: NWEndpoint.Host(plan.endpoint.host),
            port: NWEndpoint.Port(rawValue: plan.endpoint.port)!
        ) { response, receivedAt in
            if let sample = ledger.accept(response: response, receivedAt: receivedAt) {
                Task { await onSample(sample) }
            }
        }

        return await withTaskCancellationHandler(operation: {
            connection.start()

            // `t0` é obtido imediatamente antes do primeiro envio; os payloads já estão prontos.
            let start = DispatchTime.now().uptimeNanoseconds
            for probe in probes {
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

                let sentAt = DispatchTime.now().uptimeNanoseconds
                ledger.register(sequence: probe.sequence, payload: probe.payload, sentAt: sentAt)
                connection.send(probe.payload) {
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

    private func sleep(until deadline: UInt64) async {
        let now = DispatchTime.now().uptimeNanoseconds
        guard deadline > now else { return }
        try? await Task.sleep(nanoseconds: deadline - now)
    }
}

/// Coleta exclusiva da pré-leitura regional: três probes, um por segundo,
/// cada um válido apenas durante dois segundos. O destino vem do snapshot.
public struct NWRegionalPreReadCollector: RegionalPreReadCollecting {
    public init() {}

    public func collect(candidate: RegionalSelectionCandidate) async -> [RegionalPreReadSample] {
        guard let port = NWEndpoint.Port(rawValue: candidate.resolvedContext.destination.port),
              let sessionID = try? SecureRandom.uuid() else { return Array(repeating: RegionalPreReadSample(outcome: .transportError), count: 3) }
        let payloads: [(Int, Data)] = (0..<3).compactMap { sequence in
            guard let nonce = try? SecureRandom.uint64() else { return nil }
            return (sequence, PingBeaconPayloadCodec.encode(PingBeaconPayload(sessionID: sessionID, sequence: UInt32(sequence), nonce: nonce)))
        }
        guard payloads.count == 3 else { return Array(repeating: RegionalPreReadSample(outcome: .transportError), count: 3) }
        let ledger = ProbeLedger(probes: payloads)
        let connection = UDPConnection(host: NWEndpoint.Host(candidate.resolvedContext.destination.host), port: port) { response, receivedAt in
            _ = ledger.accept(response: response, receivedAt: receivedAt)
        }
        connection.start()
        let start = DispatchTime.now().uptimeNanoseconds
        for (sequence, payload) in payloads {
            guard !Task.isCancelled else { connection.cancel(); return [] }
            let deadline = start + UInt64(sequence) * 1_000_000_000
            let now = DispatchTime.now().uptimeNanoseconds
            if deadline > now { try? await Task.sleep(nanoseconds: deadline - now) }
            let sentAt = DispatchTime.now().uptimeNanoseconds
            ledger.register(sequence: sequence, payload: payload, sentAt: sentAt)
            connection.send(payload) { ledger.markTransportError(sequence: sequence) }
        }
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        connection.cancel()
        return ledger.finish(at: DispatchTime.now().uptimeNanoseconds).filter { $0.sequence >= 0 }.map { RegionalPreReadSample(outcome: $0.outcome, roundTripMilliseconds: $0.roundTripMilliseconds) }
    }
}


private enum SecureRandom {
    static func uuid() throws -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else { throw RandomError.unavailable }
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
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

    init(probes: [(sequence: Int, payload: Data)]) {
        self.probes = Dictionary(uniqueKeysWithValues: probes.map { ($0.sequence, PendingProbe(payload: $0.payload, sentAt: nil, result: nil)) })
    }

    func register(sequence: Int, payload: Data, sentAt: UInt64) {
        lock.withLock {
            guard var probe = probes[sequence], probe.payload == payload else { return }
            probe.sentAt = sentAt
            probes[sequence] = probe
        }
    }

    func accept(response: Data, receivedAt: UInt64) -> ProbeSample? {
        lock.withLock {
            guard let match = probes.first(where: { $0.value.payload == response }),
                  var probe = probes[match.key],
                  let sentAt = probe.sentAt,
                  probe.result == nil,
                  receivedAt >= sentAt,
                  receivedAt - sentAt < 2_000_000_000 else {
                invalidResponseCount += 1
                return nil
            }

            let sample = ProbeSample(
                sequence: match.key,
                roundTripMilliseconds: Double(receivedAt - sentAt) / 1_000_000,
                outcome: .received
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
