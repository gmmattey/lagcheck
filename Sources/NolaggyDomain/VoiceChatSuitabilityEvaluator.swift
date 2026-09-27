import Foundation

/// Leitura local mínima para chamadas de voz. Não avalia a rota até um serviço
/// de voz; só classifica o primeiro salto quando houve RTT observável.
public enum VoiceChatSuitabilityEvaluator {
    public enum Assessment: Equatable, Sendable {
        case favorable(localGatewayRTTMilliseconds: Int)
        case attention(localGatewayRTTMilliseconds: Int)
        case notAssessed
    }

    public static func assess(localGatewayRTTMilliseconds: Double?) -> Assessment {
        guard let localGatewayRTTMilliseconds,
              localGatewayRTTMilliseconds.isFinite,
              localGatewayRTTMilliseconds >= 0 else {
            return .notAssessed
        }

        let roundedRTT = Int(localGatewayRTTMilliseconds.rounded())
        if localGatewayRTTMilliseconds <= 15 {
            return .favorable(localGatewayRTTMilliseconds: roundedRTT)
        }
        return .attention(localGatewayRTTMilliseconds: roundedRTT)
    }
}
