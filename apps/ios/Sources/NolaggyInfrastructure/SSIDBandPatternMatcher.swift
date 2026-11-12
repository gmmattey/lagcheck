import Foundation
import NolaggyDomain

/// Identificador de frequência através de análise sintática e heurística de nomes de rede (SSID).
public enum SSIDBandPatternMatcher {
    
    /// Avalia um SSID opcional e retorna o diagnóstico correspondente caso um padrão inequívoco seja detectado.
    public static func evaluate(ssid: String?) -> WiFiBandDiagnostic? {
        guard let ssid = ssid?.trimmingCharacters(in: .whitespacesAndNewlines), !ssid.isEmpty else {
            return nil
        }
        
        if WiFiBandEvaluator.hasExplicit5GHzPattern(ssid) {
            return .confirmed5GHzOrHigher(ssid: ssid)
        }
        
        if WiFiBandEvaluator.hasExplicit24GHzPattern(ssid) {
            return .confirmed24GHz(ssid: ssid)
        }
        
        return nil
    }
}
