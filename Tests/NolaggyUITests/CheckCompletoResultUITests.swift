import XCTest

final class CheckCompletoResultUITests: XCTestCase {

    @MainActor
    func testValidResultScreenInPortuguese() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(pt-BR)",
            "-AppleLocale", "pt_BR",
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

        // 2. Hero de resultado: Score presente e veredito canônico
        XCTAssertTrue(app.staticTexts["check-completo-score"].exists)
        XCTAssertTrue(app.staticTexts["check-completo-verdict"].exists)
        let verdictLabel = app.staticTexts["check-completo-verdict"].label
        let validVerdicts = [
            "A rota segurou",
            "A rota oscilou",
            "A carga pesou",
            "A entrega falhou"
        ]
        XCTAssertTrue(validVerdicts.contains(verdictLabel), "Veredito inesperado: \(verdictLabel)")

        // Verificação estrita de ausência de termos proibidos
        let forbiddenTerms = [
            "Pronto para jogar",
            "Sua rota ficou estável",
            "A rede piorou",
            "Conexão perfeita",
            "Zero lag",
            "Garantido",
            "Booster",
            "Otimizar"
        ]
        for term in forbiddenTerms {
            XCTAssertFalse(app.staticTexts[term].exists, "Termo proibido encontrado na tela: \(term)")
        }

        // 3. Trilha Consolidada (5 passos)
        XCTAssertTrue(app.staticTexts["Wi‑Fi"].exists || app.staticTexts["Rede móvel"].exists)
        XCTAssertTrue(app.staticTexts["Resposta"].exists)
        XCTAssertTrue(app.staticTexts["Entrega"].exists)
        XCTAssertTrue(app.staticTexts["Carga"].exists)
        XCTAssertTrue(app.staticTexts["São Paulo"].exists)

        // 4. Faixa de compatibilidade da sessão
        XCTAssertTrue(app.staticTexts["Multiplayer"].exists)
        XCTAssertTrue(app.staticTexts["Calls"].exists)
        XCTAssertTrue(app.staticTexts["Streaming"].exists)

        // 5. Ações
        let primaryAction = app.buttons["check-completo-primary-action"]
        XCTAssertTrue(primaryAction.exists)
        XCTAssertEqual(primaryAction.label, "Testar de novo")

        XCTAssertTrue(app.buttons["check-completo-details"].exists)
        XCTAssertEqual(app.buttons["check-completo-details"].label, "Ver detalhes")

        XCTAssertTrue(app.buttons["check-completo-improve"].exists)
        XCTAssertEqual(app.buttons["check-completo-improve"].label, "Como melhorar")

        saveScreenshot(named: "check_completo_valid_pt_br")
    }

    @MainActor
    func testValidResultScreenInEnglish() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-ui-fixture-deep-standalone",
            "-ui-fixture-deep-result"
        ]
        app.launch()

        // 1. Context header in English
        XCTAssertTrue(app.staticTexts["check-completo-context"].waitForExistence(timeout: 3))

        // 2. Hero: Score exists and verdict is in English
        XCTAssertTrue(app.staticTexts["check-completo-score"].exists)
        XCTAssertTrue(app.staticTexts["check-completo-verdict"].exists)
        let verdictLabel = app.staticTexts["check-completo-verdict"].label
        let validEnglishVerdicts = [
            "The route held",
            "The route fluctuated",
            "The load weighed down",
            "Delivery failed"
        ]
        XCTAssertTrue(validEnglishVerdicts.contains(verdictLabel), "Unexpected English verdict: \(verdictLabel)")

        // 3. Consolidated trail nodes in English
        XCTAssertTrue(app.staticTexts["Wi‑Fi"].exists || app.staticTexts["Cellular"].exists)
        XCTAssertTrue(app.staticTexts["Response"].exists)
        XCTAssertTrue(app.staticTexts["Delivery"].exists)
        XCTAssertTrue(app.staticTexts["Load"].exists)

        // 4. Compatibility strip in English
        XCTAssertTrue(app.staticTexts["Multiplayer"].exists)
        XCTAssertTrue(app.staticTexts["Calls"].exists)
        XCTAssertTrue(app.staticTexts["Streaming"].exists)

        // 5. Actions in English
        let primaryAction = app.buttons["check-completo-primary-action"]
        XCTAssertTrue(primaryAction.exists)
        XCTAssertEqual(primaryAction.label, "Test again")

        XCTAssertTrue(app.buttons["check-completo-details"].exists)
        XCTAssertEqual(app.buttons["check-completo-details"].label, "View details")

        XCTAssertTrue(app.buttons["check-completo-improve"].exists)
        XCTAssertEqual(app.buttons["check-completo-improve"].label, "How to improve")

        saveScreenshot(named: "check_completo_valid_en")
    }

    @MainActor
    func testInconclusiveResultScreenHasNoScoreAndOnlyRetestAction() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(pt-BR)",
            "-AppleLocale", "pt_BR",
            "-ui-fixture-deep-standalone",
            "-ui-fixture-deep-inconclusive"
        ]
        app.launch()

        // 1. Inconclusive verdict: "Medição incompleta"
        XCTAssertTrue(app.staticTexts["check-completo-verdict"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["check-completo-verdict"].label, "Medição incompleta")

        // 2. Score must NOT exist
        XCTAssertFalse(app.staticTexts["check-completo-score"].exists)

        // 3. Primary action is "Tentar de novo"
        let primaryAction = app.buttons["check-completo-primary-action"]
        XCTAssertTrue(primaryAction.exists)
        XCTAssertEqual(primaryAction.label, "Tentar de novo")

        // 4. Secondary actions must NOT exist
        XCTAssertFalse(app.buttons["check-completo-details"].exists)
        XCTAssertFalse(app.buttons["check-completo-improve"].exists)

        saveScreenshot(named: "check_completo_inconclusive_pt_br")
    }

    @MainActor
    private func saveScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let artifactDir = URL(fileURLWithPath: "/Users/giammattey/.gemini/antigravity/brain/da941c85-3368-47ab-8a12-712ab3d2664b")
        let destinationURL = artifactDir.appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: destinationURL)
    }
}
