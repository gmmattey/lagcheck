import XCTest
@testable import NolaggyDomain

final class EvidenceRecommendationEngineTests: XCTestCase {

    func testDegradedGatewayYieldsLocalRouterRecommendation() {
        let evidence = DiagnosticEvidence(
            gatewayOutcome: .degraded(rttMilliseconds: 25.0, lossPercentage: 5.0),
            packetLossPercentage: 0.0
        )
        let recommendations = EvidenceRecommendationEngine.generateRecommendations(evidence: evidence)

        XCTAssertFalse(recommendations.isEmpty)
        XCTAssertEqual(recommendations.first?.title, "Aproxime-se do Roteador")
        XCTAssertEqual(recommendations.first?.evidenceBadge, "Wi-Fi Local")
    }

    func testConfirmed24GHzWiFiYields5GHzRecommendation() {
        let evidence = DiagnosticEvidence(
            gatewayOutcome: .stable(rttMilliseconds: 1.5),
            wifiBand: .confirmed24GHz(ssid: "MyNet_2.4G"),
            wifiBandConfidence: .high
        )
        let recommendations = EvidenceRecommendationEngine.generateRecommendations(evidence: evidence)

        XCTAssertFalse(recommendations.isEmpty)
        let rec = recommendations.first { $0.title == "Troque para Wi-Fi 5 GHz" }
        XCTAssertNotNil(rec)
        XCTAssertEqual(rec?.evidenceBadge, "2.4 GHz Detectado")
    }

    func testLowConfidence24GHzDoesNotYield5GHzRecommendation() {
        let evidence = DiagnosticEvidence(
            gatewayOutcome: .stable(rttMilliseconds: 1.5),
            wifiBand: .suspected24GHzContention,
            wifiBandConfidence: .none
        )
        let recommendations = EvidenceRecommendationEngine.generateRecommendations(evidence: evidence)

        let rec = recommendations.first { $0.title == "Troque para Wi-Fi 5 GHz" }
        XCTAssertNil(rec, "Sem confiança alta/média, não pode recomendar troca de banda")
    }

    func testBufferbloatMaterialOrSevereYieldsPauseDownloadsRecommendation() {
        let evidence = DiagnosticEvidence(
            gatewayOutcome: .stable(rttMilliseconds: 1.5),
            loadTier: .material
        )
        let recommendations = EvidenceRecommendationEngine.generateRecommendations(evidence: evidence)

        let rec = recommendations.first { $0.title == "Pause Downloads e Streaming" }
        XCTAssertNotNil(rec)
        XCTAssertEqual(rec?.evidenceBadge, "Saturação sob Carga")
    }

    func testRemotePacketLossYieldsAvoidRankedRecommendation() {
        let evidence = DiagnosticEvidence(
            gatewayOutcome: .stable(rttMilliseconds: 1.5),
            packetLossPercentage: 3.5
        )
        let recommendations = EvidenceRecommendationEngine.generateRecommendations(evidence: evidence)

        let rec = recommendations.first { $0.title == "Evite Partidas Ranqueadas" }
        XCTAssertNotNil(rec)
        XCTAssertEqual(rec?.evidenceBadge, "Rota Externa")
    }

    func testStrictNATOnP2PGameYieldsUPnPRecommendation() {
        let evidence = DiagnosticEvidence(
            gatewayOutcome: .stable(rttMilliseconds: 1.5),
            natType: .type3Strict,
            serverArchitecture: .peerToPeer
        )
        let recommendations = EvidenceRecommendationEngine.generateRecommendations(evidence: evidence)

        let rec = recommendations.first { $0.title == "Habilite UPnP no Roteador" }
        XCTAssertNotNil(rec)
        XCTAssertEqual(rec?.evidenceBadge, "NAT Restrito")
    }

    func testStrictNATOnDedicatedServerGameDoesNotYieldNATRecommendation() {
        let evidence = DiagnosticEvidence(
            gatewayOutcome: .stable(rttMilliseconds: 1.5),
            natType: .type3Strict,
            serverArchitecture: .dedicatedServer
        )
        let recommendations = EvidenceRecommendationEngine.generateRecommendations(evidence: evidence)

        let rec = recommendations.first { $0.title == "Habilite UPnP no Roteador" }
        XCTAssertNil(rec, "Servidores dedicados não devem exibir recomendação de NAT")
    }

    func testRecommendationsAreCappedAtThreeItems() {
        let evidence = DiagnosticEvidence(
            gatewayOutcome: .degraded(rttMilliseconds: 25.0, lossPercentage: 5.0),
            wifiBand: .confirmed24GHz(ssid: "Net2.4"),
            wifiBandConfidence: .high,
            loadTier: .severe,
            packetLossPercentage: 5.0,
            spikePattern: .recurring(count: 4, severeCount: 2),
            natType: .type3Strict,
            serverArchitecture: .peerToPeer
        )
        let recommendations = EvidenceRecommendationEngine.generateRecommendations(evidence: evidence)

        XCTAssertLessThanOrEqual(recommendations.count, 3)
    }

    func testOutOfOrderPacketsYieldsRouteInstabilityRecommendation() {
        let evidence = DiagnosticEvidence(
            gatewayOutcome: .stable(rttMilliseconds: 1.5),
            outOfOrderCount: 3
        )
        let recommendations = EvidenceRecommendationEngine.generateRecommendations(evidence: evidence)

        let rec = recommendations.first { $0.title == "Instabilidade de Rota na Operadora" }
        XCTAssertNotNil(rec)
        XCTAssertEqual(rec?.evidenceBadge, "Rota Desordenada")
    }

    func testGameEditorialRegistryServerArchitecture() {
        XCTAssertEqual(GameEditorialRegistry.serverArchitecture(for: "minecraft"), .hybrid)
        XCTAssertEqual(GameEditorialRegistry.serverArchitecture(for: "roblox"), .hybrid)
        XCTAssertEqual(GameEditorialRegistry.serverArchitecture(for: "ea-sports-fc-mobile"), .hybrid)
        XCTAssertEqual(GameEditorialRegistry.serverArchitecture(for: "fortnite"), .dedicatedServer)
        XCTAssertEqual(GameEditorialRegistry.serverArchitecture(for: "valorant"), .dedicatedServer)
    }
}
