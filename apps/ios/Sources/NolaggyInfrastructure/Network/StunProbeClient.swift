import Foundation
import Network
import NolaggyDomain

/// Transporte UDP abstrato usado para trocas STUN, injetável para testes sem rede real.
public protocol StunUDPTransport: Sendable {
    /// Envia `packet` para `host:port` e retorna a resposta bruta recebida, ou lança em caso de erro/timeout.
    func exchange(packet: Data, host: String, port: UInt16, timeoutSeconds: TimeInterval) async throws -> Data
}

/// Um único servidor STUN candidato para a sondagem dupla de consistência de mapeamento de porta.
public struct StunServerEndpoint: Sendable, Equatable {
    public let host: String
    public let port: UInt16

    public init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }
}

/// Cliente de sondagem STUN a custo zero (Decisão 32) baseado em Network.framework.
public final class StunProbeClient: Sendable {
    public let host: String
    public let port: UInt16
    public let timeoutSeconds: TimeInterval
    /// Segundo servidor STUN independente, usado para detectar mapeamento de porta
    /// inconsistente (NAT simétrico) e indícios de NAT duplo, sem exigir nenhuma
    /// infraestrutura própria.
    public let secondaryServer: StunServerEndpoint
    private let transport: StunUDPTransport
    private let localAddressResolver: LocalInterfaceAddressResolving

    public init(
        host: String = "stun.l.google.com",
        port: UInt16 = 19302,
        secondaryServer: StunServerEndpoint = StunServerEndpoint(host: "stun1.l.google.com", port: 19302),
        timeoutSeconds: TimeInterval = 2.0,
        transport: StunUDPTransport = NWConnectionStunUDPTransport(),
        localAddressResolver: LocalInterfaceAddressResolving = BSDLocalInterfaceAddressResolver()
    ) {
        self.host = host
        self.port = port
        self.secondaryServer = secondaryServer
        self.timeoutSeconds = timeoutSeconds
        self.transport = transport
        self.localAddressResolver = localAddressResolver
    }

    /// Executa a sondagem UDP assíncrona e retorna o snapshot da topologia de rede.
    /// Quando `localIP` não é fornecido, resolve o IP local real da interface ativa
    /// (Wi-Fi ou celular) para permitir a detecção de NAT Tipo 1 (Aberto).
    public func probeTopology(localIP: String? = nil) async -> NATTopologySnapshot {
        let resolvedLocalIP = localIP ?? localAddressResolver.resolveLocalIPv4()

        let primaryResult = await performBindingProbe(host: host, port: port)

        guard let primary = primaryResult else {
            return .inconclusive
        }

        let secondaryResult = await performBindingProbe(host: secondaryServer.host, port: secondaryServer.port)

        let (isPortMappingConsistent, detectedDoubleHop) = evaluateDualProbe(primary: primary, secondary: secondaryResult)

        return NATTopologyEvaluator.evaluate(
            localIP: resolvedLocalIP,
            publicIP: primary.publicIP,
            externalPort: primary.externalPort,
            isPortMappingConsistent: isPortMappingConsistent,
            detectedDoubleHop: detectedDoubleHop
        )
    }

    /// Compara os resultados de dois servidores STUN independentes para inferir
    /// se o mapeamento de porta é consistente (mesmo NAT observando de fontes
    /// distintas) e se há indícios de NAT duplo (múltiplas camadas de tradução).
    ///
    /// - Apenas a sondagem primária respondeu: não há dados suficientes para
    ///   afirmar inconsistência; assume-se o caso conservador (mapeamento
    ///   consistente, sem duplo hop detectado) já que nada contradiz o resultado único.
    /// - Ambas respondem com o mesmo IP público e a mesma porta externa:
    ///   mapeamento consistente, sem indício de duplo NAT.
    /// - Ambas respondem com o mesmo IP público mas portas externas diferentes:
    ///   mapeamento de porta inconsistente, típico de NAT simétrico.
    /// - As duas respondem com IPs públicos diferentes: indício forte de duas
    ///   camadas de tradução (NAT duplo / CGNAT em cascata com NAT do roteador).
    private func evaluateDualProbe(
        primary: StunPacketCodec.StunBindingResult,
        secondary: StunPacketCodec.StunBindingResult?
    ) -> (isPortMappingConsistent: Bool, detectedDoubleHop: Bool) {
        guard let secondary else {
            return (true, false)
        }

        if primary.publicIP != secondary.publicIP {
            return (false, true)
        }

        if primary.externalPort != secondary.externalPort {
            return (false, false)
        }

        return (true, false)
    }

    private func performBindingProbe(host: String, port: UInt16) async -> StunPacketCodec.StunBindingResult? {
        let (requestData, txID) = StunPacketCodec.buildBindingRequest()
        do {
            let responseData = try await transport.exchange(packet: requestData, host: host, port: port, timeoutSeconds: timeoutSeconds)
            return StunPacketCodec.parseBindingResponse(data: responseData, expectedTransactionID: txID)
        } catch {
            return nil
        }
    }
}

/// Implementação padrão de `StunUDPTransport` usando `Network.framework` (UDP real).
public final class NWConnectionStunUDPTransport: StunUDPTransport {

    public init() {}

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

    public func exchange(packet: Data, host: String, port: UInt16, timeoutSeconds: TimeInterval) async throws -> Data {
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
