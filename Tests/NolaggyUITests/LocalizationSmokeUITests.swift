import XCTest

final class LocalizationSmokeUITests: XCTestCase {
    @MainActor
    func testCatalogSelectionUsesTheSystemLanguageForEverySupportedLocale() {
        let expectations: [(language: String, locale: String, games: String)] = [
            ("pt-BR", "pt_BR", "Jogos"),
            ("en", "en_US", "Games"),
            ("es", "es_ES", "Juegos")
        ]

        for expectation in expectations {
            let app = XCUIApplication()
            // A fixture usa o catálogo assinado empacotado e impede o refresh
            // remoto: a prova de idioma não depende da rede.
            app.launchArguments += [
                "-AppleLanguages", "(\(expectation.language))",
                "-AppleLocale", expectation.locale,
                "-app_selected_language", "system",
                "-ui-fixture-confirmed-region"
            ]
            app.launch()

            XCTAssertTrue(app.buttons[expectation.games].waitForExistence(timeout: 3), expectation.language)
            app.buttons[expectation.games].tap()
            XCTAssertTrue(app.buttons["catalog-game-fortnite"].waitForExistence(timeout: 3), expectation.language)
            app.buttons["catalog-game-fortnite"].tap()
            XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 3), expectation.language)
            app.terminate()
        }
    }

    @MainActor
    func testSelectedLanguageOverridesTheSystemLanguage() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(pt-BR)",
            "-AppleLocale", "pt_BR",
            "-app_selected_language", "es",
            "-ui-fixture-confirmed-region"
        ]
        app.launch()

        XCTAssertTrue(app.buttons["Inicio"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Juegos"].exists)
        XCTAssertFalse(app.buttons["Início"].exists)
    }

    @MainActor
    func testSettingsScreenShowsLocalizedTitleAndNoTechnicalKeysLeaking() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(pt-BR)",
            "-AppleLocale", "pt_BR",
            "-app_selected_language", "pt-BR",
            "-ui-fixture-confirmed-region"
        ]
        app.launch()

        let settingsBtn = app.buttons["navigation-settings-open"]
        XCTAssertTrue(settingsBtn.waitForExistence(timeout: 3))
        settingsBtn.tap()

        // Verify "Ajustes" title exists and "navigation.settings" does not leak
        XCTAssertTrue(app.staticTexts["Ajustes"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["navigation.settings"].exists)

        // Capture screenshot of settings screen for visual verification
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

