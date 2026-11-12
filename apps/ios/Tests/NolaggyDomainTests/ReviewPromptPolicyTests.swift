import XCTest
@testable import NolaggyDomain

final class ReviewPromptPolicyTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let baseDate = Date(timeIntervalSince1970: 1700000000)

    func testNonReadyVerdictNeverPrompts() {
        let nonReadyVerdicts: [GameReadinessVerdict] = [.caution, .notReady, .inconclusive]
        let readyState = ReviewPromptState(
            successfulReadyChecksCount: 5,
            lastPromptedDate: nil,
            lastPromptedVersion: nil
        )

        for verdict in nonReadyVerdicts {
            let shouldPrompt = ReviewPromptPolicy.shouldPrompt(
                verdict: verdict,
                state: readyState,
                currentAppVersion: "1.0.0",
                currentDate: baseDate
            )
            XCTAssertFalse(shouldPrompt, "Veredito \(verdict) nunca deve disparar review prompt")
        }
    }

    func testRequiresAtLeastThreeSuccessfulReadyChecks() {
        for count in 0..<3 {
            let state = ReviewPromptState(
                successfulReadyChecksCount: count,
                lastPromptedDate: nil,
                lastPromptedVersion: nil
            )
            let shouldPrompt = ReviewPromptPolicy.shouldPrompt(
                verdict: .ready,
                state: state,
                currentAppVersion: "1.0.0",
                currentDate: baseDate
            )
            XCTAssertFalse(shouldPrompt, "Não deve disparar com menos de 3 checks concluídos (count: \(count))")
        }

        let eligibleState = ReviewPromptState(
            successfulReadyChecksCount: 3,
            lastPromptedDate: nil,
            lastPromptedVersion: nil
        )
        let shouldPrompt = ReviewPromptPolicy.shouldPrompt(
            verdict: .ready,
            state: eligibleState,
            currentAppVersion: "1.0.0",
            currentDate: baseDate
        )
        XCTAssertTrue(shouldPrompt, "Deve autorizar no 3º check concluído com veredito .ready")
    }

    func testBlocksSameVersionIfAlreadyPrompted() {
        let state = ReviewPromptState(
            successfulReadyChecksCount: 10,
            lastPromptedDate: baseDate.addingTimeInterval(-100 * 86400), // Mais de 90 dias atrás
            lastPromptedVersion: "1.0.0"
        )

        let shouldPromptSameVersion = ReviewPromptPolicy.shouldPrompt(
            verdict: .ready,
            state: state,
            currentAppVersion: "1.0.0",
            currentDate: baseDate
        )
        XCTAssertFalse(shouldPromptSameVersion, "Não pode disparar na mesma versão onde já houve prompt")

        let shouldPromptNewVersion = ReviewPromptPolicy.shouldPrompt(
            verdict: .ready,
            state: state,
            currentAppVersion: "1.1.0",
            currentDate: baseDate
        )
        XCTAssertTrue(shouldPromptNewVersion, "Deve permitir na nova versão após expirar o cooldown de 90 dias")
    }

    func testRespectsNinetyDaysCooldownBetweenPrompts() {
        let lastPrompt = baseDate.addingTimeInterval(-30 * 86400) // 30 dias atrás
        let state = ReviewPromptState(
            successfulReadyChecksCount: 10,
            lastPromptedDate: lastPrompt,
            lastPromptedVersion: "0.9.0"
        )

        let shouldPromptBeforeCooldown = ReviewPromptPolicy.shouldPrompt(
            verdict: .ready,
            state: state,
            currentAppVersion: "1.0.0",
            currentDate: baseDate
        )
        XCTAssertFalse(shouldPromptBeforeCooldown, "Não pode disparar antes de completar 90 dias de cooldown")

        let ninetyOneDaysLater = lastPrompt.addingTimeInterval(91 * 86400)
        let shouldPromptAfterCooldown = ReviewPromptPolicy.shouldPrompt(
            verdict: .ready,
            state: state,
            currentAppVersion: "1.0.0",
            currentDate: ninetyOneDaysLater
        )
        XCTAssertTrue(shouldPromptAfterCooldown, "Deve autorizar após 90 dias de cooldown em versão diferente")
    }
}
