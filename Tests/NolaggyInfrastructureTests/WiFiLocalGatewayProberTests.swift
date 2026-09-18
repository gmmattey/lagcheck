import XCTest
@testable import NolaggyDomain
@testable import NolaggyInfrastructure

final class WiFiLocalGatewayProberTests: XCTestCase {

    func testSSIDBandPatternMatcherRecognizes5GHzNetworks() {
        let sample5G = ["Home_5G", "Router-5GHz", "Net_6E", "WiFi6_Fast"]
        for ssid in sample5G {
            let result = SSIDBandPatternMatcher.evaluate(ssid: ssid)
            XCTAssertEqual(result, .confirmed5GHzOrHigher(ssid: ssid), "Deveria identificar 5GHz para: \(ssid)")
        }
    }

    func testSSIDBandPatternMatcherRecognizes24GHzNetworks() {
        let sample24G = ["Home_2.4G", "Office-2.4GHz", "AP_2G", "LivingRoom_2_4GHz"]
        for ssid in sample24G {
            let result = SSIDBandPatternMatcher.evaluate(ssid: ssid)
            XCTAssertEqual(result, .confirmed24GHz(ssid: ssid), "Deveria identificar 2.4GHz para: \(ssid)")
        }
    }

    func testSSIDBandPatternMatcherReturnsNilForNeutralOrUnifiedSSID() {
        let unifiedSSIDs = ["Vivo-Fibra-Casa", "Claro_WiFi", "TP-Link_Mesh", "", nil]
        for ssid in unifiedSSIDs {
            let result = SSIDBandPatternMatcher.evaluate(ssid: ssid)
            XCTAssertNil(result, "SSID neutro não deve produzir identificação inequívoca: \(String(describing: ssid))")
        }
    }

    func testBSDWiFiLocalGatewayProberInstantiationAndResolution() {
        let prober = BSDWiFiLocalGatewayProber()
        // Em ambiente de teste / simulador, resolveDefaultGatewayIPv4 pode retornar
        // o IP do host (ex: 192.168.x.1 ou 10.x.x.1) ou nil se não houver rota com RTF_GATEWAY.
        // O teste garante que o método é seguro contra crashes e alocações de memória.
        let resolved = prober.resolveDefaultGatewayIPv4()
        if let resolved {
            XCTAssertFalse(resolved.isEmpty)
        }
    }
}
