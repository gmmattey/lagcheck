import Foundation
import Network
import NolaggyDomain

/// Cliente de sondagem STUN a custo zero (Decisão 32) baseado em Network.framework.
public final class StunProbeClient: Sendable {
    public let host: String
    public let port: UInt16
    public let timeoutSeconds: TimeInterval

    public init(
        host: String = "stun.l.google.com",
        port: UInt16 = 19302,
        timeoutSeconds: TimeInterval = 2.0
    ) {
        self.host = host
        self.port = port
        self.timeoutSeconds = timeoutSeconds
    }

    /// Executa a sondagem UDP assíncrona e retorna o snapshot da topologia de rede.
    public func probeTopology(localIP: String? = nil) async -> NATTopologySnapshot {
        let (requestData, txID) = StunPacketCodec.buildBindingRequest()
        
        do {
            let responseData = try await performUDPExchange(packet: requestData)
            guard let result = StunPacketCodec.parseBindingResponse(data: responseData, expectedTransactionID: txID) else {
                return .inconclusive
            }

            return NATTopologyEvaluator.evaluate(
                localIP: localIP,
                publicIP: result.publicIP,
                externalPort: result.externalPort,
                isPortMappingConsistent: true,
                detectedDoubleHop: false
            )
        } catch {
            return .inconclusive
        }
    }

    private final class SafeContinuationResumer: @unchecked Sendable {
        private let lock = NSLock()
        private var isCompleted = false
        private var continuation: CheckedContinuation<Data, Error>?

        init(continuation: CheckedContinuation<Data, Error>) {
            self.continuation = continuation
        }

        func resume(returning data: Data) {
            lock.lock()
            defer { lock.unlock() }
            guard !isCompleted, let cont = continuation else { return }
            isCompleted = true
            continuation = nil
            cont.resume(returning: data)
        }

        func resume(throwing error: Error) {
            lock.lock()
            defer { lock.unlock() }
            guard !isCompleted, let cont = continuation else { return }
            isCompleted = true
            continuation = nil
            cont.resume(throwing: error)
        }
    }

    private func performUDPExchange(packet: Data) async throws -> Data {
        let nwEndpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port) ?? 19302
        )
        let parameters = NWParameters.udp
        parameters.serviceClass = .responsiveData

        let connection = NWConnection(to: nwEndpoint, using: parameters)

        return try await withCheckedThrowingContinuation { continuation in
            let queue = DispatchQueue(label: "com.nolaggy.stun.probe")
            let resumer = SafeContinuationResumer(continuation: continuation)

            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + timeoutSeconds)
            timer.setEventHandler {
                connection.cancel()
                resumer.resume(throwing: CancellationError())
            }
            timer.resume()

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.send(content: packet, completion: .contentProcessed { sendError in
                        if let sendError {
                            timer.cancel()
                            connection.cancel()
                            resumer.resume(throwing: sendError)
                            return
                        }

                        connection.receiveMessage { content, _, _, receiveError in
                            timer.cancel()
                            connection.cancel()
                            if let receiveError {
                                resumer.resume(throwing: receiveError)
                            } else if let content {
                                resumer.resume(returning: content)
                            } else {
                                resumer.resume(throwing: CancellationError())
                            }
                        }
                    })
                case .failed(let error):
                    timer.cancel()
                    connection.cancel()
                    resumer.resume(throwing: error)
                case .cancelled:
                    timer.cancel()
                    resumer.resume(throwing: CancellationError())
                default:
                    break
                }
            }

            connection.start(queue: queue)
        }
    }
}
