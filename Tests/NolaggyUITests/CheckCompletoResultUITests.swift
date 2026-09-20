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

        // 2. Hero de resultado: Score presente e veredito canônico
        XCTAssertTrue(app.staticTexts["check-completo-score"].exists)
        XCTAssertTrue(app.staticTexts["check-completo-verdict"].exists)
        let verdictLabel = app.staticTexts["check-completo-verdict"].label
        let validVerdicts = [
            "Conexão boa",
            "Conexão instável",
            "A rede piorou sob carga",
            "Risco de lag"
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

        // 4. O resultado não mostra compatibilidades genéricas sem evidência.
        XCTAssertFalse(app.staticTexts["Streaming"].exists)

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
            "-app_selected_language", "system",
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
            "Good connection",
            "Unstable connection",
            "The network worsened under load",
            "Lag risk"
        ]
        XCTAssertTrue(validEnglishVerdicts.contains(verdictLabel), "Unexpected English verdict: \(verdictLabel)")

        // 3. Consolidated trail nodes in English
        XCTAssertTrue(app.staticTexts["Wi‑Fi"].exists || app.staticTexts["Cellular"].exists)
        XCTAssertTrue(app.staticTexts["Response"].exists)
        XCTAssertTrue(app.staticTexts["Delivery"].exists)
        XCTAssertTrue(app.staticTexts["Load"].exists)

        // 4. The result does not show generic compatibility claims without evidence.
        XCTAssertFalse(app.staticTexts["Streaming"].exists)

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
            "-app_selected_language", "system",
            "-ui-fixture-deep-standalone",
            "-ui-fixture-deep-inconclusive"
        ]
        app.launch()

        // 1. Inconclusive verdict: "Medição inconclusiva"
        XCTAssertTrue(app.staticTexts["check-completo-verdict"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["check-completo-verdict"].label, "Medição inconclusiva")

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
