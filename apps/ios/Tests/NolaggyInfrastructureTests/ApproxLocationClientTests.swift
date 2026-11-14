import XCTest
@testable import NolaggyInfrastructure

/// Mesmas regras de `parseApproxLocation` do site e de `ApproxLocationClient.decode` do Android.
final class ApproxLocationClientTests: XCTestCase {
    private func decode(_ json: String) -> ApproxLocation? {
        ApproxLocationClient.decode(Data(json.utf8))
    }

    func testDecodesSiteResponse() {
        XCTAssertEqual(
            decode(#"{"city":"Rio de Janeiro","country":"BR","lat":-23,"lon":-43.5}"#),
            ApproxLocation(city: "Rio de Janeiro", country: "BR", lat: -23, lon: -43.5)
        )
    }

    func testDecodesUnicodeAndMissingCity() {
        XCTAssertEqual(decode(#"{"city":"São Paulo","country":null,"lat":-23.5,"lon":-46.5}"#)?.city, "São Paulo")
        XCTAssertNil(decode(#"{"city":null,"lat":-15.5,"lon":-48}"#)?.city)
        XCTAssertNil(decode(#"{"city":"  ","lat":1,"lon":2}"#)?.city)
    }

    func testRejectsMissingOrOutOfRangeCoordinates() {
        XCTAssertNil(decode(#"{"city":"X","lat":"10","lon":20}"#))
        XCTAssertNil(decode(#"{"lat":91,"lon":0}"#))
        XCTAssertNil(decode(#"{"lat":0,"lon":-181}"#))
        XCTAssertNil(decode("not json"))
    }
}
