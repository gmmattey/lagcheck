import XCTest
@testable import NolaggyDomain

final class NATTopologyTests: XCTestCase {

    func testCGNATRangeDetectionRFC6598() {
        XCTAssertTrue(NATTopologyEvaluator.isRFC6598CGNAT(ip: "100.64.0.1"))
        XCTAssertTrue(NATTopologyEvaluator.isRFC6598CGNAT(ip: "100.100.50.1"))
        XCTAssertTrue(NATTopologyEvaluator.isRFC6598CGNAT(ip: "100.127.255.254"))

        // Fora da faixa
        XCTAssertFalse(NATTopologyEvaluator.isRFC6598CGNAT(ip: "100.63.255.255"))
        XCTAssertFalse(NATTopologyEvaluator.isRFC6598CGNAT(ip: "100.128.0.0"))
        XCTAssertFalse(NATTopologyEvaluator.isRFC6598CGNAT(ip: "177.136.20.10"))
        XCTAssertFalse(NATTopologyEvaluator.isRFC6598CGNAT(ip: "192.168.1.1"))
    }

    func testEvaluateOpenNATWhenLocalEqualsPublic() {
        let snapshot = NATTopologyEvaluator.evaluate(
            localIP: "177.136.20.10",
            publicIP: "177.136.20.10",
            externalPort: 54321
        )

        XCTAssertEqual(snapshot.natType, .type1Open)
        XCTAssertEqual(snapshot.cgnatStatus, .notDetected)
        XCTAssertEqual(snapshot.doubleNATStatus, .notDetected)
        XCTAssertFalse(snapshot.hasAnyMultiplayerIssue)
    }

    func testEvaluateModerateNATUnderStandardRouter() {
        let snapshot = NATTopologyEvaluator.evaluate(
            localIP: "192.168.1.50",
            publicIP: "177.136.20.10",
            externalPort: 54321,
            isPortMappingConsistent: true,
            detectedDoubleHop: false
        )

        XCTAssertEqual(snapshot.natType, .type2Moderate)
        XCTAssertEqual(snapshot.cgnatStatus, .notDetected)
        XCTAssertEqual(snapshot.doubleNATStatus, .notDetected)
        XCTAssertFalse(snapshot.hasAnyMultiplayerIssue)
    }

    func testEvaluateStrictNATWhenCGNATDetected() {
        let snapshot = NATTopologyEvaluator.evaluate(
            localIP: "192.168.1.50",
            publicIP: "100.70.15.22",
            externalPort: 54321
        )

        XCTAssertEqual(snapshot.natType, .type3Strict)
        XCTAssertEqual(snapshot.cgnatStatus, .detected)
        XCTAssertTrue(snapshot.hasAnyMultiplayerIssue)
    }

    func testEvaluateStrictNATWhenDoubleNATDetected() {
        let snapshot = NATTopologyEvaluator.evaluate(
            localIP: "192.168.1.50",
            publicIP: "177.136.20.10",
            externalPort: 54321,
            isPortMappingConsistent: true,
            detectedDoubleHop: true
        )

        XCTAssertEqual(snapshot.natType, .type3Strict)
        XCTAssertEqual(snapshot.doubleNATStatus, .suspectOrDetected)
        XCTAssertTrue(snapshot.hasAnyMultiplayerIssue)
    }

    func testEvaluateInconclusiveWhenNoPublicIP() {
        let snapshot = NATTopologyEvaluator.evaluate(
            localIP: "192.168.1.50",
            publicIP: nil,
            externalPort: nil
        )

        XCTAssertEqual(snapshot.natType, .inconclusive)
        XCTAssertEqual(snapshot.cgnatStatus, .inconclusive)
    }

    func testMaskIPForPrivacy() {
        XCTAssertEqual(NATTopologyEvaluator.maskIP("177.136.25.100"), "177.136.***.***")
        XCTAssertEqual(NATTopologyEvaluator.maskIP("192.168.1.5"), "192.168.***.***")
    }
}
