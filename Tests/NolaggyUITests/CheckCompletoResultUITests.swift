import XCTest

final class CheckCompletoResultUITests: XCTestCase {

    @MainActor
    func testValidResultScreenInPortuguese() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(pt-BR)",
            "-AppleLocale", "pt_BR",
            "-app_selected_language", "system",
            "-ui-fixture-deep-standalone",
            "-ui-fixture-deep-result"
        ]
        app.launch()

        // 1. Contexto compacto no topo
        XCTAssertTrue(app.staticTexts["check-completo-context"].waitForExistence(timeout: 3))
        let contextLabel = app.staticTexts["check-completo-context"].label
        XCTAssertTrue(contextLabel.contains("Fortnite"))
        XCTAssertTrue(contextLabel.contains("iPhone"))
        XCTAssertTrue(contextLabel.contains("São Paulo"))

        // 2. Hero de resultado: Veredito semântico protagonista (Decisões 50 e 51)
        XCTAssertTrue(app.staticTexts["check-completo-verdict"].exists)
        let verdictLabel = app.staticTexts["check-completo-verdict"].label
        let validVerdicts = [
            "PRONTO PARA RANKED",
            "CONDIÇÕES INSTÁVEIS",
            "EU EVITARIA RANKED AGORA",
            "DADOS INSUFICIENTES"
        ]
        XCTAssertTrue(validVerdicts.contains(verdictLabel), "Veredito inesperado: \(verdictLabel)")

        // 3. Telemetria compacta (Ping, Jitter, Perda)
        XCTAssertTrue(app.staticTexts["PING"].exists)
        XCTAssertTrue(app.staticTexts["JITTER"].exists)
        XCTAssertTrue(app.staticTexts["PERDA"].exists)

        // A prévia Link vem antes da telemetria, como na composição Android.
        let sharePreview = app.buttons["check-completo-share-preview"]
        XCTAssertTrue(sharePreview.waitForExistence(timeout: 3))
        XCTAssertLessThan(sharePreview.frame.minY, app.staticTexts["PING"].frame.minY)

        // 4. O score numérico sai do hero (está na folha técnica secundária)
        XCTAssertFalse(app.staticTexts["check-completo-score"].exists)

        // 5. Ações
        let primaryAction = app.buttons["check-completo-primary-action"]
        XCTAssertTrue(primaryAction.exists)

        XCTAssertTrue(app.buttons["check-completo-details"].exists)
        XCTAssertTrue(app.buttons["check-completo-discord-share"].exists)
        XCTAssertTrue(app.buttons["check-completo-whatsapp-share"].exists)

        // A jornada completa mantém uma única affordance de retorno na barra.
        let back = app.buttons["check-completo-back"]
        let export = app.buttons["check-completo-export-pdf"]
        XCTAssertTrue(back.exists)
        XCTAssertTrue(export.exists)
        XCTAssertEqual(app.buttons.matching(identifier: "check-completo-back").count, 1)
        XCTAssertGreaterThan(export.frame.minY, back.frame.maxY)

        saveScreenshot(named: "check_completo_valid_pt_br")
    }

    @MainActor
    func testValidResultScreenInEnglish() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-app_selected_language", "system",
            "-ui-fixture-deep-standalone",
            "-ui-fixture-deep-result"
        ]
        app.launch()

        // 1. Context header in English
        XCTAssertTrue(app.staticTexts["check-completo-context"].waitForExistence(timeout: 3))

        // 2. Hero: Semantic verdict in English
        XCTAssertTrue(app.staticTexts["check-completo-verdict"].exists)
        let verdictLabel = app.staticTexts["check-completo-verdict"].label
        let validEnglishVerdicts = [
            "READY FOR RANKED",
            "UNSTABLE CONDITIONS",
            "AVOID RANKED FOR NOW",
            "INSUFFICIENT DATA"
        ]
        XCTAssertTrue(validEnglishVerdicts.contains(verdictLabel), "Unexpected English verdict: \(verdictLabel)")

        // 3. Compact telemetry in English
        XCTAssertTrue(app.staticTexts["PING"].exists)
        XCTAssertTrue(app.staticTexts["JITTER"].exists)
        XCTAssertTrue(app.staticTexts["LOSS"].exists)

        // 4. Primary and secondary actions
        let primaryAction = app.buttons["check-completo-primary-action"]
        XCTAssertTrue(primaryAction.exists)
        XCTAssertTrue(app.buttons["check-completo-details"].exists)

        saveScreenshot(named: "check_completo_valid_en")
    }

    @MainActor
    func testInconclusiveResultScreenHasNoScoreAndOnlyRetestAction() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(pt-BR)",
            "-AppleLocale", "pt_BR",
            "-app_selected_language", "system",
            "-ui-fixture-deep-standalone",
            "-ui-fixture-deep-inconclusive"
        ]
        app.launch()

        // 1. Inconclusive semantic verdict
        XCTAssertTrue(app.staticTexts["check-completo-verdict"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["check-completo-verdict"].label, "DADOS INSUFICIENTES")

        // 2. Score must NOT exist
        XCTAssertFalse(app.staticTexts["check-completo-score"].exists)

        // 3. Primary action exists
        let primaryAction = app.buttons["check-completo-primary-action"]
        XCTAssertTrue(primaryAction.exists)

        // 4. Inconclusive state does not offer a details sheet or improvement action.
        XCTAssertFalse(app.buttons["check-completo-details"].exists)
        XCTAssertFalse(app.buttons["check-completo-improve"].exists)

        // Resultado inconclusivo não pode preparar nem oferecer card de compartilhamento.
        XCTAssertFalse(app.buttons["check-completo-discord-share"].exists)
        XCTAssertFalse(app.buttons["check-completo-whatsapp-share"].exists)
        XCTAssertFalse(app.buttons["check-completo-share-preview"].exists)

        saveScreenshot(named: "check_completo_inconclusive_pt_br")
    }

    @MainActor
    private func saveScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
