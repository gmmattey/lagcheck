import XCTest
@testable import NolaggyDomain

final class HostDuelModelsTests: XCTestCase {

    func testPayloadSerializationAndParsingRoundtrip() {
        let original = HostDuelPayload(
            gameID: "valorant",
            regionID: "sa-east-1",
            p50Ms: 18.4,
            packetLossPercent: 0.0,
            jitterMs: 1.2,
            verdict: .ready,
            timestamp: 1730848800,
            challengerNick: "Luiz"
        )

        guard let webURL = original.toWebURL() else {
            XCTFail("Failed to generate web URL")
            return
        }

        XCTAssertTrue(webURL.absoluteString.contains("https://lagcheck.signallq.com/vs"))
        XCTAssertTrue(webURL.absoluteString.contains("g=valorant"))
        XCTAssertTrue(webURL.absoluteString.contains("n=Luiz"))

        guard let parsed = HostDuelPayload.parse(url: webURL) else {
            XCTFail("Failed to parse web URL")
            return
        }

        XCTAssertEqual(parsed.gameID, "valorant")
        XCTAssertEqual(parsed.regionID, "sa-east-1")
        XCTAssertEqual(parsed.p50Ms, 18.4, accuracy: 0.1)
        XCTAssertEqual(parsed.packetLossPercent, 0.0, accuracy: 0.1)
        XCTAssertEqual(parsed.jitterMs, 1.2, accuracy: 0.1)
        XCTAssertEqual(parsed.verdict, .ready)
        XCTAssertEqual(parsed.timestamp, 1730848800)
        XCTAssertEqual(parsed.challengerNick, "Luiz")
    }

    func testParsesCustomSchemeDuelURL() {
        let customURL = URL(string: "lagcheck://vs?g=cs2&r=sao_paulo&p=24.5&l=1.0&j=3.0&v=caution&t=1730848800&n=FalleN")!
        let parsed = HostDuelPayload.parse(url: customURL)

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.gameID, "cs2")
        XCTAssertEqual(parsed?.challengerNick, "FalleN")
        XCTAssertEqual(parsed?.verdict, .caution)
    }

    func testDeepLinkParserRecognizesHostDuel() {
        let url = URL(string: "https://lagcheck.signallq.com/vs?g=valorant&r=sa-east-1&p=18.0&l=0.0&j=1.0&v=ready&t=1730848800&n=Luiz")!
        let deepLink = DeepLinkParser.parse(url: url)

        guard case let .hostDuel(payload) = deepLink else {
            XCTFail("DeepLinkParser did not produce .hostDuel")
            return
        }

        XCTAssertEqual(payload.challengerNick, "Luiz")
        XCTAssertEqual(payload.p50Ms, 18.0)
    }

    func testTTLAndExpirationLogic() {
        let fixedDate = Date(timeIntervalSince1970: 1730848800)
        let payload = HostDuelPayload(
            gameID: "valorant",
            regionID: "sa-east-1",
            p50Ms: 18.0,
            packetLossPercent: 0.0,
            jitterMs: 1.0,
            verdict: .ready,
            timestamp: 1730848800
        )

        // Exatamente no momento da criação: não expirado, 1800s restantes
        XCTAssertFalse(payload.isExpired(now: fixedDate))
        XCTAssertEqual(payload.remainingSeconds(now: fixedDate), 1800)

        // 15 minutos depois: não expirado, 900s restantes
        let midDate = Date(timeIntervalSince1970: 1730848800 + 900)
        XCTAssertFalse(payload.isExpired(now: midDate))
        XCTAssertEqual(payload.remainingSeconds(now: midDate), 900)

        // 31 minutos depois: expirado, 0s restantes
        let expiredDate = Date(timeIntervalSince1970: 1730848800 + 1860)
        XCTAssertTrue(payload.isExpired(now: expiredDate))
        XCTAssertEqual(payload.remainingSeconds(now: expiredDate), 0)
    }

    func testResolutionReadyVsCautionFavorsReadyRegardlessOfPing() {
        let challengerReady = HostDuelPayload(
            gameID: "valorant",
            regionID: "sa-east-1",
            p50Ms: 35.0, // Maior ping
            packetLossPercent: 0.0,
            jitterMs: 1.0,
            verdict: .ready,
            challengerNick: "Luiz"
        )

        let opponentCaution = HostDuelPayload(
            gameID: "valorant",
            regionID: "sa-east-1",
            p50Ms: 20.0, // Menor ping bruto, mas oscilando
            packetLossPercent: 2.0,
            jitterMs: 15.0,
            verdict: .caution,
            challengerNick: "Pedro"
        )

        let resolution = HostDuelResolver.resolve(challenger: challengerReady, opponent: opponentCaution)
        XCTAssertEqual(resolution.winner, .challenger)
        XCTAssertTrue(resolution.challengerLead)
        XCTAssertTrue(resolution.headline.contains("LUIZ PUXA A RANKED"))
    }

    func testResolutionTiebreakByP50WhenBothReady() {
        let luiz = HostDuelPayload(
            gameID: "valorant",
            regionID: "sa-east-1",
            p50Ms: 18.0,
            packetLossPercent: 0.0,
            jitterMs: 1.0,
            verdict: .ready,
            challengerNick: "Luiz"
        )

        let pedro = HostDuelPayload(
            gameID: "valorant",
            regionID: "sa-east-1",
            p50Ms: 46.0,
            packetLossPercent: 0.0,
            jitterMs: 1.5,
            verdict: .ready,
            challengerNick: "Pedro"
        )

        let resolution = HostDuelResolver.resolve(challenger: luiz, opponent: pedro)
        XCTAssertEqual(resolution.winner, .challenger)
        XCTAssertEqual(resolution.deltaMs, 28.0, accuracy: 0.1)
        XCTAssertTrue(resolution.headline.contains("LUIZ PUXA A RANKED"))
    }

    func testDiscordShareTextFormat() {
        let payload = HostDuelPayload(
            gameID: "valorant",
            regionID: "sa-east-1",
            p50Ms: 18.2,
            packetLossPercent: 0.0,
            jitterMs: 1.0,
            verdict: .ready,
            challengerNick: "Luiz"
        )

        let text = payload.generateDiscordShareText()
        XCTAssertTrue(text.contains("⚔️ [DUELO DE HOST] Luiz cravou 18ms no Valorant (0% perda)."))
        XCTAssertTrue(text.contains("https://lagcheck.signallq.com/vs?"))
    }
}
