import Foundation
import NolaggyDomain

/// Adaptador que conecta a sonda BSD de infraestrutura ao protocolo GatewayProbing.
public struct BSDGatewayProbingAdapter: GatewayProbing {
    private let prober: BSDWiFiLocalGatewayProber

    public init(prober: BSDWiFiLocalGatewayProber = BSDWiFiLocalGatewayProber()) {
        self.prober = prober
    }

    public func probeGateway() async -> GatewayProbeOutcome {
        let telemetry = await prober.probeLocalGateway(sampleCount: 3, timeoutPerSampleSeconds: 0.25)
        return telemetry.gatewayOutcome
    }
}
