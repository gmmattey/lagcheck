import XCTest

final class LocalizationSmokeUITests: XCTestCase {
    @MainActor
    func testCatalogDetailUsesTheSystemLanguageForEverySupportedLocale() {
        let expectations: [(language: String, locale: String, games: String, platform: String, estimate: String)] = [
            ("pt-BR", "pt_BR", "Jogos", "Plataforma", "Estimativa de conexão para São Paulo, não o ping oficial do jogo."),
            ("en", "en_US", "Games", "Platform", "Connection estimate for São Paulo, not the game's official ping."),
            ("es", "es_ES", "Juegos", "Plataforma", "Estimación de conexión para São Paulo, no el ping oficial del juego.")
        ]

        for expectation in expectations {
            let app = XCUIApplication()
            // A fixture usa o catálogo assinado empacotado e impede o refresh
            // remoto: a prova de idioma não depende da rede.
            app.launchArguments += [
                "-AppleLanguages", "(\(expectation.language))",
                "-AppleLocale", expectation.locale,
                "-ui-fixture-confirmed-region"
            ]
            app.launch()

            XCTAssertTrue(app.buttons[expectation.games].waitForExistence(timeout: 3), expectation.language)
            app.buttons[expectation.games].tap()
            XCTAssertTrue(app.buttons["catalog-game-fortnite"].waitForExistence(timeout: 3), expectation.language)
            app.buttons["catalog-game-fortnite"].tap()
            XCTAssertTrue(app.staticTexts[expectation.platform].waitForExistence(timeout: 2), expectation.language)
            XCTAssertTrue(app.staticTexts[expectation.estimate].waitForExistence(timeout: 2), expectation.language)
            XCTAssertTrue(app.buttons["quick-check-start"].exists, expectation.language)
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
}
