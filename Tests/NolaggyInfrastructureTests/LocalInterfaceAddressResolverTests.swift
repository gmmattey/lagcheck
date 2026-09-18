import XCTest
@testable import NolaggyInfrastructure

final class LocalInterfaceAddressResolverTests: XCTestCase {

    func testBSDResolverIsSafeAndReturnsValidIPv4WhenAvailable() {
        let resolver = BSDLocalInterfaceAddressResolver()
        // No ambiente de simulador/CI, pode não haver en0/pdp_ip* ativos —
        // o teste garante apenas que a chamada é segura (sem crash) e que,
        // quando um endereço é retornado, ele tem a forma de um IPv4 válido.
        let resolved = resolver.resolveLocalIPv4()
        if let resolved {
            let parts = resolved.split(separator: ".")
            XCTAssertEqual(parts.count, 4, "Endereço resolvido deve ter 4 octetos: \(resolved)")
            for part in parts {
                XCTAssertNotNil(UInt8(part), "Cada octeto deve ser um UInt8 válido: \(resolved)")
            }
        }
    }

    func testInterfacePriorityOrdersWiFiBeforeCellular() {
        let priority = BSDLocalInterfaceAddressResolver.interfacePriority
        let wifiIndex = priority.firstIndex(of: "en0")
        let cellularIndex = priority.firstIndex(of: "pdp_ip0")
        XCTAssertNotNil(wifiIndex)
        XCTAssertNotNil(cellularIndex)
        if let wifiIndex, let cellularIndex {
            XCTAssertLessThan(wifiIndex, cellularIndex, "Wi-Fi (en0) deve ter prioridade sobre celular (pdp_ip0).")
        }
    }
}
