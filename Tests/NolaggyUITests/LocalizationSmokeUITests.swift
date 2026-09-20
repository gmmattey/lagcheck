import XCTest

final class LocalizationSmokeUITests: XCTestCase {
    @MainActor
    func testCatalogDetailUsesTheSystemLanguageForEverySupportedLocale() {
        let expectations: [(language: String, locale: String, games: String, platformTitle: String)] = [
            ("pt-BR", "pt_BR", "Jogos", "Onde você joga?"),
            ("en", "en_US", "Games", "Where do you play?"),
            ("es", "es_ES", "Juegos", "¿Dónde juegas?")
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
            XCTAssertTrue(app.staticTexts[expectation.platformTitle].waitForExistence(timeout: 2), expectation.language)
            XCTAssertTrue(app.buttons["start-game-deep-check"].exists, expectation.language)
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
