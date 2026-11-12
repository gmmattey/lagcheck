import XCTest
import NolaggyDomain
@testable import NolaggyInfrastructure

final class DirectPlatformHealthClientTests: XCTestCase {
    func testParsePlayStationOperationalPayload() {
        let json = """
        {
            "regionName": "SCEA",
            "status": [],
            "countries": [
                {
                    "countryCode": "BR",
                    "countryName": "Brazil",
                    "status": [],
                    "services": [
                        { "serviceId": "Account_Management", "serviceName": "Account Management", "status": [] },
                        { "serviceId": "Gaming_And_Social", "serviceName": "Gaming And Social", "status": [] }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let health = DirectPlatformHealthClient.parsePlayStationPayload(data: json, market: "BR")
        XCTAssertEqual(health.platform, .playstation)
        XCTAssertEqual(health.status, .operational)
        XCTAssertFalse(health.isIssueReported)
        XCTAssertTrue(health.affectedServices.isEmpty)
    }

    func testParsePlayStationDegradedPayload() {
        let json = """
        {
            "regionName": "SCEA",
            "status": [],
            "countries": [
                {
                    "countryCode": "BR",
                    "countryName": "Brazil",
                    "status": [],
                    "services": [
                        {
                            "serviceId": "Gaming_And_Social",
                            "serviceName": "Jogos e redes sociais",
                            "status": [
                                { "statusType": "degraded", "statusId": "123", "message": { "message": "Lentidão ao buscar partidas" } }
                            ]
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let health = DirectPlatformHealthClient.parsePlayStationPayload(data: json, market: "BR")
        XCTAssertEqual(health.platform, .playstation)
        XCTAssertTrue(health.isIssueReported)
        XCTAssertEqual(health.affectedServices, ["Jogos e redes sociais"])
        if case .degraded(let summary) = health.status {
            XCTAssertTrue(summary.contains("Lentidão") || summary.contains("Instabilidade"))
        } else {
            XCTFail("Esperava status degraded")
        }
    }

    func testParsePlayStationOutagePayload() {
        let json = """
        {
            "regionName": "SCEA",
            "status": [
                { "statusType": "outage", "statusId": "999", "message": { "message": "Queda geral de rede" } }
            ],
            "countries": [
                {
                    "countryCode": "BR",
                    "status": [
                        { "statusType": "outage", "statusId": "999", "message": { "message": "Queda geral no Brasil" } }
                    ],
                    "services": []
                }
            ]
        }
        """.data(using: .utf8)!

        let health = DirectPlatformHealthClient.parsePlayStationPayload(data: json, market: "BR")
        XCTAssertEqual(health.platform, .playstation)
        XCTAssertTrue(health.isIssueReported)
        if case .majorOutage(let summary) = health.status {
            XCTAssertEqual(summary, "Queda geral no Brasil")
        } else {
            XCTFail("Esperava status majorOutage")
        }
    }

    func testParseXboxOperationalPayload() {
        let json = """
        {
            "Status": {
                "Overall": { "State": "None", "Id": 1 }
            },
            "CoreServices": [
                { "Name": "Conta e perfil", "Status": { "Name": "None" } }
            ]
        }
        """.data(using: .utf8)!

        let health = DirectPlatformHealthClient.parseXboxPayload(data: json)
        XCTAssertEqual(health.platform, .xbox)
        XCTAssertEqual(health.status, .operational)
        XCTAssertFalse(health.isIssueReported)
    }

    func testParseXboxDegradedPayload() {
        let json = """
        {
            "Status": {
                "Overall": { "State": "Minor", "Id": 2 }
            },
            "CoreServices": [
                {
                    "Name": "Jogos multijogador",
                    "Status": { "Name": "Minor" },
                    "Scenarios": [
                        {
                            "Name": "Entrar no jogo",
                            "Status": { "Name": "Minor" },
                            "Description": "Alguns usuários podem enfrentar lentidão ao iniciar partidas."
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let health = DirectPlatformHealthClient.parseXboxPayload(data: json)
        XCTAssertEqual(health.platform, .xbox)
        XCTAssertTrue(health.isIssueReported)
        XCTAssertEqual(health.affectedServices, ["Jogos multijogador"])
        if case .degraded(let summary) = health.status {
            XCTAssertTrue(summary.contains("lentidão") || summary.contains("Instabilidade"))
        } else {
            XCTFail("Esperava status degraded")
        }
    }

    func testParseXboxMajorOutagePayload() {
        let json = """
        {
            "Status": {
                "Overall": { "State": "Major", "Id": 3 }
            },
            "CoreServices": [
                {
                    "Name": "Entrar na conta",
                    "Status": { "Name": "Major" },
                    "Scenarios": [
                        {
                            "Name": "Sign In",
                            "Status": { "Name": "Major" },
                            "Description": "Não é possível entrar no Xbox Live."
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let health = DirectPlatformHealthClient.parseXboxPayload(data: json)
        XCTAssertEqual(health.platform, .xbox)
        XCTAssertTrue(health.isIssueReported)
        XCTAssertEqual(health.affectedServices, ["Entrar na conta"])
        if case .majorOutage(let summary) = health.status {
            XCTAssertEqual(summary, "Não é possível entrar no Xbox Live.")
        } else {
            XCTFail("Esperava status majorOutage")
        }
    }

    func testMalformedPayloadReturnsUnknownGracefully() {
        let malformedData = "isto nao e um json".data(using: .utf8)!
        let psnHealth = DirectPlatformHealthClient.parsePlayStationPayload(data: malformedData, market: "BR")
        XCTAssertEqual(psnHealth.status, .unknown)

        let xboxHealth = DirectPlatformHealthClient.parseXboxPayload(data: malformedData)
        XCTAssertEqual(xboxHealth.status, .unknown)
    }

    func testCacheReturnsSameInstanceWithinTTL() async {
        let client = DirectPlatformHealthClient(cacheTTLSeconds: 60)
        let health1 = await client.checkHealth(for: .iphone, market: "BR")
        let health2 = await client.checkHealth(for: .iphone, market: "BR")
        XCTAssertEqual(health1, health2)
    }
}
