import XCTest
@testable import NolaggyDomain

final class GlobalProbeRegistryTests: XCTestCase {

    func testAll21GlobalRegionsArePresent() {
        XCTAssertEqual(GlobalProbeRegistry.allRegions.count, 21)
        XCTAssertEqual(GlobalProbeRegistry.allowedRegionIDs.count, 21)
        
        let americas = GlobalProbeRegistry.allRegions.filter { $0.continent == .americas }
        let europe = GlobalProbeRegistry.allRegions.filter { $0.continent == .europe }
        let asiaPacific = GlobalProbeRegistry.allRegions.filter { $0.continent == .asiaPacific }
        let middleEastAfrica = GlobalProbeRegistry.allRegions.filter { $0.continent == .middleEastAfrica }

        XCTAssertEqual(americas.count, 6)
        XCTAssertEqual(europe.count, 6)
        XCTAssertEqual(asiaPacific.count, 7)
        XCTAssertEqual(middleEastAfrica.count, 2)
    }

    func testEveryRegionFollowsAWSGameLiftContract() {
        for region in GlobalProbeRegistry.allRegions {
            XCTAssertEqual(region.port, 7770, "Region \(region.id) must use default GameLift UDP port 7770.")
            XCTAssertEqual(region.host, "gamelift-ping.\(region.id).api.aws", "Region \(region.id) must follow AWS GameLift UDP hostname format.")
            XCTAssertFalse(region.id.isEmpty)
            XCTAssertNoThrow(try ProbeDestination(host: region.host, port: region.port))
        }
    }

    func testFriendlyLabelsNeverContainTechnicalServerCodes() {
        for region in GlobalProbeRegistry.allRegions {
            let pt = region.labelPtBR
            let en = region.labelEN
            let es = region.labelES

            // Proibido exibir códigos técnicos ou hostnames na label principal (Decisão 28 / Decisão 33)
            XCTAssertFalse(pt.contains("gamelift"), "Label PT-BR para \(region.id) não pode conter 'gamelift'")
            XCTAssertFalse(pt.contains("api.aws"), "Label PT-BR para \(region.id) não pode conter 'api.aws'")
            XCTAssertFalse(pt.contains(region.id), "Label PT-BR para \(region.id) não pode conter o código técnico \(region.id)")

            XCTAssertFalse(en.contains("gamelift"), "Label EN para \(region.id) não pode conter 'gamelift'")
            XCTAssertFalse(en.contains("api.aws"), "Label EN para \(region.id) não pode conter 'api.aws'")
            XCTAssertFalse(en.contains(region.id), "Label EN para \(region.id) não pode conter o código técnico \(region.id)")

            XCTAssertFalse(es.contains("gamelift"), "Label ES para \(region.id) não pode conter 'gamelift'")
            XCTAssertFalse(es.contains("api.aws"), "Label ES para \(region.id) não pode conter 'api.aws'")
            XCTAssertFalse(es.contains(region.id), "Label ES para \(region.id) não pode conter o código técnico \(region.id)")
        }

        // Casos de exemplo expressos por Luiz e Decisão 33
        XCTAssertEqual(GlobalProbeRegistry.friendlyLabel(for: "sa-east-1", isPortuguese: true), "São Paulo")
        XCTAssertEqual(GlobalProbeRegistry.friendlyLabel(for: "us-east-1", isPortuguese: true), "Virgínia do Norte")
        XCTAssertEqual(GlobalProbeRegistry.friendlyLabel(for: "us-east-1", isPortuguese: false), "N. Virginia")
        XCTAssertEqual(GlobalProbeRegistry.friendlyLabel(for: "us-east-1", languageCode: "es"), "Virginia del Norte")
        XCTAssertEqual(GlobalProbeRegistry.friendlyLabel(for: "eu-central-1", isPortuguese: true), "Frankfurt")
        XCTAssertEqual(GlobalProbeRegistry.friendlyLabel(for: "eu-central-1", languageCode: "es"), "Fráncfort")
        XCTAssertEqual(GlobalProbeRegistry.friendlyLabel(for: "ap-northeast-1", isPortuguese: true), "Tóquio")
        XCTAssertEqual(GlobalProbeRegistry.friendlyLabel(for: "ap-northeast-1", isPortuguese: false), "Tokyo")
        XCTAssertEqual(GlobalProbeRegistry.friendlyLabel(for: "ap-northeast-1", languageCode: "es"), "Tokio")
    }

    func testContinentLocalizationKeysAreValid() {
        for continent in GlobalProbeRegistry.Continent.allCases {
            XCTAssertTrue(continent.localizationKey.hasPrefix("settings.continent."))
        }
    }
}
