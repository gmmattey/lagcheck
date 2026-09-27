import XCTest
@testable import NolaggyDomain

final class VoiceChatSuitabilityEvaluatorTests: XCTestCase {
    func testEveryObservedGatewayRTTIsAssessed() {
        let favorable: [Double] = [0, 8, 9, 15]
        for rtt in favorable {
            XCTAssertEqual(
                VoiceChatSuitabilityEvaluator.assess(localGatewayRTTMilliseconds: rtt),
                .favorable(localGatewayRTTMilliseconds: Int(rtt))
            )
        }

        let attention: [Double] = [16, 20, 21]
        for rtt in attention {
            XCTAssertEqual(
                VoiceChatSuitabilityEvaluator.assess(localGatewayRTTMilliseconds: rtt),
                .attention(localGatewayRTTMilliseconds: Int(rtt))
            )
        }
    }

    func testMissingGatewayRTTRemainsNotAssessed() {
        XCTAssertEqual(
            VoiceChatSuitabilityEvaluator.assess(localGatewayRTTMilliseconds: nil),
            .notAssessed
        )
    }
}
