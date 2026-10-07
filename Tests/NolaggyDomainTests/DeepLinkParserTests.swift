import XCTest
@testable import NolaggyDomain

final class DeepLinkParserTests: XCTestCase {

    func testParsesCustomSchemeQuickTest() {
        let url = URL(string: "lagcheck://quicktest")!
        let result = DeepLinkParser.parse(url: url)
        XCTAssertEqual(result, .quickCheck(gameID: nil, platform: nil))
    }

    func testParsesCustomSchemeCheckWithGameAndPlatform() {
        let url = URL(string: "lagcheck://check?game=valorant&platform=pc")!
        let result = DeepLinkParser.parse(url: url)
        XCTAssertEqual(result, .quickCheck(gameID: "valorant", platform: .pc))
    }

    func testRejectsInvalidPlatformAndAcceptsEncodedGame() {
        let invalidUrl = URL(string: "lagcheck://check?game=valorant&platform=smartfridge")!
        XCTAssertEqual(DeepLinkParser.parse(url: invalidUrl), .quickCheck(gameID: "valorant", platform: nil))

        let encodedUrl = URL(string: "https://lagcheck.app/check?GAME=call%20of%20duty")!
        XCTAssertEqual(DeepLinkParser.parse(url: encodedUrl), .quickCheck(gameID: "call of duty", platform: nil))
    }

    func testParsesUniversalLinkWithGame() {
        let url = URL(string: "https://lagcheck.app/check?game=fortnite")!
        let result = DeepLinkParser.parse(url: url)
        XCTAssertEqual(result, .quickCheck(gameID: "fortnite", platform: nil))
    }

    func testParsesNetworkCockpit() {
        let url = URL(string: "lagcheck://network")!
        let result = DeepLinkParser.parse(url: url)
        XCTAssertEqual(result, .networkCockpit)

        let wifiUrl = URL(string: "lagcheck://wifi")!
        XCTAssertEqual(DeepLinkParser.parse(url: wifiUrl), .networkCockpit)
    }

    func testParsesGamesCatalog() {
        let url = URL(string: "lagcheck://games")!
        let result = DeepLinkParser.parse(url: url)
        XCTAssertEqual(result, .gamesCatalog)
    }

    func testParsesHome() {
        let url = URL(string: "lagcheck://home")!
        let result = DeepLinkParser.parse(url: url)
        XCTAssertEqual(result, .home)
    }

    func testRejectsUnrecognizedSchemesAndDomains() {
        let badScheme = URL(string: "noping://check")!
        XCTAssertNil(DeepLinkParser.parse(url: badScheme))

        let plainHttp = URL(string: "http://lagcheck.app/check")!
        XCTAssertNil(DeepLinkParser.parse(url: plainHttp))

        let badDomain = URL(string: "https://evil.com/check")!
        XCTAssertNil(DeepLinkParser.parse(url: badDomain))

        let arbitraryHost = URL(string: "lagcheck://arbitraryhost")!
        XCTAssertNil(DeepLinkParser.parse(url: arbitraryHost))
    }
}
