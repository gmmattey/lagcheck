import XCTest

final class DeepCheckJourneyUITests: XCTestCase {
    @MainActor
    func testGameSelectionFromHomeStartsMeasurementWithoutConsoleSelection() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR"]
        app.launchWithSystemLanguage()

        // Trocar jogo é uma troca de contexto, não uma etapa extra: escolher o
        // título inicia a medição sem voltar à Home ou abrir seletor de console.
        XCTAssertTrue(app.buttons["home-shortcut-change-game"].waitForExistence(timeout: 3))
        app.buttons["home-shortcut-change-game"].tap()
        selectCatalogGame("fortnite", matching: "Fortnite", in: app)
        XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Onde você joga?"].exists)
        XCTAssertFalse(app.buttons["home-decision-primary-action"].exists)
    }

    @MainActor
    func testCatalogGameTileSelectsTheHomeMeasurementAction() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["Games"].waitForExistence(timeout: 3))
        app.buttons["Games"].tap()
        selectCatalogGame("minecraft", matching: "Minecraft", in: app)

        XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testCatalogShowsPCOnlyGameAndStartsItsResolvedCheck() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["Games"].waitForExistence(timeout: 3))
        app.buttons["Games"].tap()
        let search = app.textFields["catalog-search-input"]
        XCTAssertTrue(search.waitForExistence(timeout: 3))
        search.tap()
        search.typeText("Counter-Strike")

        let cs2 = app.buttons["catalog-game-cs2"]
        XCTAssertTrue(cs2.waitForExistence(timeout: 3))
        cs2.tap()

        XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["platform-choice-pc"].exists)
    }

    @MainActor
    func testCatalogSelectionOpensTheCurrentGameDetail() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["Games"].waitForExistence(timeout: 3))
        app.buttons["Games"].tap()
        selectCatalogGame("roblox", matching: "Roblox", in: app)
        XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testStartThenBackShowsCancelledWithoutScore() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-confirmed-region"]
        app.launchWithSystemLanguage()

        startDeepCheck(app)

        XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 2))
        captureScreenshot(of: app, named: "deep-check-measuring")
        app.buttons["deep-check-back"].tap()

        XCTAssertTrue(app.buttons["home-decision-primary-action"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Excelente"].exists)
        XCTAssertFalse(app.staticTexts["Risco de lag"].exists)
    }

    @MainActor
    func testEnglishContextUsesLocalizedCopy() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["Games"].waitForExistence(timeout: 3))
        app.buttons["Games"].tap()
        selectCatalogGame("fortnite", matching: "Fortnite", in: app)
        XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Where do you play?"].exists)
    }

    @MainActor
    func testGameSelectionDoesNotExposeAPlatformPicker() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["Games"].waitForExistence(timeout: 3))
        app.buttons["Games"].tap()
        selectCatalogGame("fortnite", matching: "Fortnite", in: app)

        XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["platform-choice-iphone"].exists)
    }

    @MainActor
    func testPlatformFilterCombinesWithTheExistingCategoryFilter() throws {
        throw XCTSkip("Substituído pelo catálogo Dark Competitive de 1 toque (Mockup 02) com favoritos e busca.")
    }

    @MainActor
    func testLanguageChangeRefreshesTheCurrentScreenImmediately() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR"]
        app.launchWithSystemLanguage()

        app.buttons["Configurações"].tap()
        XCTAssertTrue(app.buttons["settings-language"].waitForExistence(timeout: 3))
        app.buttons["settings-language"].tap()
        XCTAssertTrue(app.buttons["English"].waitForExistence(timeout: 2))
        app.buttons["English"].tap()

        app.buttons["Home"].tap()
        XCTAssertTrue(app.buttons["Home"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testFixtureOpensLocalizedDetailsWithOnlyCompletedMetrics() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-valid-result"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["measurement-details"].waitForExistence(timeout: 2))
        app.buttons["measurement-details"].tap()
        XCTAssertTrue(app.staticTexts["Detalhes"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["P50"].exists)
        XCTAssertTrue(app.staticTexts["P99"].exists)
        XCTAssertTrue(app.staticTexts["Pior spike"].exists)
        XCTAssertTrue(app.staticTexts["Alvo medido"].exists)
        XCTAssertTrue(app.staticTexts["Rota regional de referência"].exists)
        XCTAssertTrue(app.staticTexts["Média"].exists)
        captureScreenshot(of: app, named: "details-valid-result")
        app.buttons["measurement-details-back"].tap()
        XCTAssertTrue(app.buttons["measurement-details"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testFixtureDetailsAccommodateAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "-UIPreferredContentSizeCategory", "UICTContentSizeCategoryAccessibilityXXXL",
            "-ui-fixture-valid-result"
        ]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["measurement-details"].waitForExistence(timeout: 2))
        app.buttons["measurement-details"].tap()
        XCTAssertTrue(app.staticTexts["Details"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Worst spike"].exists)
        captureScreenshot(of: app, named: "details-accessibility-en")
    }

    @MainActor
    func testFixtureShowsARealHistoryEntryAndRetestAction() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-valid-result"]
        app.launchWithSystemLanguage()

        app.buttons["measurement-back"].tap()
        XCTAssertTrue(app.buttons["Histórico"].waitForExistence(timeout: 2))
        app.buttons["Histórico"].tap()
        XCTAssertTrue(app.staticTexts["Histórico"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Fortnite"].exists)
        captureScreenshot(of: app, named: "history-valid-entry")
    }

    @MainActor
    func testNativeTabBarExposesHomeGamesHistoryAndSettings() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-valid-result"]
        app.launchWithSystemLanguage()

        app.buttons["measurement-back"].tap()
        XCTAssertTrue(app.tabBars.buttons["Início"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.tabBars.buttons["Jogos"].exists)
        XCTAssertTrue(app.tabBars.buttons["Histórico"].exists)
        XCTAssertTrue(app.tabBars.buttons["Ajustes"].exists)

        app.tabBars.buttons["Ajustes"].tap()
        XCTAssertTrue(app.buttons["settings-language"].waitForExistence(timeout: 2))

        // Histórico é raiz da sua própria aba; não depende mais de uma linha
        // de Ajustes nem exibe volta artificial ao abrir pela tab bar.
        app.tabBars.buttons["Histórico"].tap()
        XCTAssertTrue(app.staticTexts["Histórico"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["history-back"].exists)

        app.tabBars.buttons["Início"].tap()
        XCTAssertTrue(app.buttons["home-decision-primary-action"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testDeepCheckStartsFromAValidGameAndPlatformSelection() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-confirmed-region", "-ui-fixture-deep-result"]
        app.launchWithSystemLanguage()

        startDeepCheck(app)
        XCTAssertTrue(app.staticTexts["check-completo-verdict"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["check-completo-back"].exists)
    }

    @MainActor
    func testCellularConsentRefusalReturnsToTheGameWithoutAResult() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR",
            "-ui-fixture-confirmed-region", "-ui-fixture-cellular-consent"
        ]
        app.launchWithSystemLanguage()

        startDeepCheck(app)
        XCTAssertTrue(app.staticTexts["Uso de dados móveis"].waitForExistence(timeout: 3))
        app.buttons["cellular-consent-cancel"].tap()

        XCTAssertTrue(app.buttons["home-decision-primary-action"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["check-completo-back"].exists)
        XCTAssertFalse(app.buttons["measurement-retry"].exists)
    }

    @MainActor
    func testDeepCheckFixtureShowsRestScoreAndSeparateLoadImpact() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-ui-fixture-confirmed-region", "-ui-fixture-deep-result"]
        app.launchWithSystemLanguage()

        startDeepCheck(app)
        XCTAssertTrue(app.staticTexts["check-completo-verdict"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["check-completo-details"].exists)
        app.buttons["check-completo-details"].tap()
        XCTAssertTrue(app.staticTexts["check-completo-score"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testDeepCheckDetailsExposeExplicitReturn() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-confirmed-region", "-ui-fixture-deep-result"]
        app.launchWithSystemLanguage()

        startDeepCheck(app)
        XCTAssertTrue(app.buttons["check-completo-details"].waitForExistence(timeout: 2))
        app.buttons["check-completo-details"].tap()
        let closeDetails = app.buttons["technical-details-close"].exists ? app.buttons["technical-details-close"] : app.buttons["deep-check-details-back"]
        XCTAssertTrue(closeDetails.waitForExistence(timeout: 2))
        closeDetails.tap()
        XCTAssertTrue(app.buttons["check-completo-back"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testDeepCheckComparisonAccommodatesAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "-UIPreferredContentSizeCategory", "UICTContentSizeCategoryAccessibilityXXXL",
            "-ui-fixture-confirmed-region", "-ui-fixture-deep-result"
        ]
        app.launchWithSystemLanguage()

        startDeepCheck(app)
        XCTAssertTrue(app.staticTexts["check-completo-verdict"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["check-completo-primary-action"].exists)
        captureScreenshot(of: app, named: "deep-check-accessibility-en")
    }

    @MainActor
    func testEnglishMeasurementUsesLocalizedWaitingCopy() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-ui-fixture-confirmed-region"]
        app.launchWithSystemLanguage()

        startDeepCheck(app)
        XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testAccessibilitySizeKeepsMeasurementActionable() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(pt-BR)",
            "-AppleLocale", "pt_BR",
            "-ui-fixture-confirmed-region",
            "-UIPreferredContentSizeCategory", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launchWithSystemLanguage()

        startDeepCheck(app)
        XCTAssertTrue(app.buttons["deep-check-back"].exists)
        captureScreenshot(of: app, named: "deep-check-accessibility-measuring")
    }

    @MainActor
    func testHomeStartGoesStraightToMeasuringWithoutAConfirmationScreen() {
        // A seleção regional é automática: depois de tocar "Iniciar" não deve
        // existir nenhum segundo toque de confirmação antes de medir.
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-confirmed-region"]
        app.launchWithSystemLanguage()

        startDeepCheck(app)
        XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["regional-selection-start"].exists)
    }

    @MainActor
    func testSettingsRegionPreferenceCanBeSetAndClearedToAutomatic() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-valid-result"]
        app.launchWithSystemLanguage()

        app.buttons["measurement-back"].tap()
        app.buttons["Configurações"].tap()
        let regionRow = app.buttons["settings-region"]
        XCTAssertTrue(regionRow.waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Automática"].exists)
        captureScreenshot(of: app, named: "settings-region-automatic")

        for _ in 0..<4 where !regionRow.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(regionRow.isHittable)
        regionRow.tap()
        XCTAssertTrue(app.buttons["Américas"].waitForExistence(timeout: 2))
        app.buttons["Américas"].tap()
        let saoPaulo = app.buttons["São Paulo"]
        XCTAssertTrue(saoPaulo.waitForExistence(timeout: 2))
        saoPaulo.tap()

        XCTAssertTrue(app.staticTexts["São Paulo"].waitForExistence(timeout: 2))

        regionRow.tap()
        let automatic = app.buttons["Automática"]
        XCTAssertTrue(automatic.waitForExistence(timeout: 2))
        automatic.tap()
        XCTAssertTrue(app.staticTexts["Automática"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testRegionalNoViableCandidateOffersRetryAndReturnHomeWithoutScore() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-ui-fixture-regional-no-viable"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.staticTexts["We couldn’t start the check"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["regional-selection-start"].exists)
        XCTAssertTrue(app.buttons["regional-selection-retry"].isHittable)
        XCTAssertTrue(app.buttons["regional-selection-back-home"].isHittable)
        captureScreenshot(of: app, named: "regional-selection-no-viable-en")

        app.buttons["regional-selection-retry"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["regional-selection-confirming"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testRegionalNoViableCandidateCanReturnToHome() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-fixture-regional-no-viable"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["regional-selection-back-home"].waitForExistence(timeout: 2))
        app.buttons["regional-selection-back-home"].tap()
        XCTAssertTrue(app.buttons["home-decision-primary-action"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testRegionalConfirmingAndManualStateAccommodateAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "-UIPreferredContentSizeCategory", "UICTContentSizeCategoryAccessibilityXXXL",
            "-ui-fixture-regional-confirming"
        ]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.descendants(matching: .any)["regional-selection-confirming"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Confirming a reference region…"].exists)
        captureScreenshot(of: app, named: "regional-selection-confirming-accessibility-en")
    }

    @MainActor
    func testBackgroundDiscardsPhysicalMeasurement() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-confirmed-region"]
        app.launchWithSystemLanguage()

        startDeepCheck(app)
        XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 2))

        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()

        XCTAssertTrue(app.buttons["home-decision-primary-action"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["check-completo-score"].exists)
    }

    @MainActor
    func testNewUserHomePresentsReadyStateAndExploreAction() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR"]
        app.launchWithSystemLanguage()

        let exploreButton = app.buttons["home-decision-primary-action"]
        XCTAssertTrue(exploreButton.waitForExistence(timeout: 4))
        captureScreenshot(of: app, named: "home-new-user-ready")

        exploreButton.tap()
        let search = app.textFields["catalog-search-input"]
        XCTAssertTrue(search.waitForExistence(timeout: 3))
        search.tap()
        search.typeText("Fortnite")
        XCTAssertTrue(app.buttons["catalog-game-fortnite"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testHomeDisplaysValidEvaluatedScoreHero() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-valid-result"]
        app.launchWithSystemLanguage()

        if app.buttons["measurement-back"].waitForExistence(timeout: 2) {
            app.buttons["measurement-back"].tap()
        }

        XCTAssertTrue(app.buttons["home-decision-primary-action"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["home-shortcut-change-game"].exists)
        XCTAssertFalse(app.buttons["home-decision-history"].exists)
        captureScreenshot(of: app, named: "home-valid-result-hero")
    }

    @MainActor
    func testHomeDisplaysInconclusiveExplanationWithoutPositiveScore() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-inconclusive-history"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["home-decision-primary-action"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["home-shortcut-change-game"].exists)
        XCTAssertFalse(app.buttons["home-decision-history"].exists)
        captureScreenshot(of: app, named: "home-inconclusive-hero")
    }

    @MainActor
    func testHomeCTASelectsGameAndStartsMeasurement() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR"]
        app.launchWithSystemLanguage()

        let startButton = app.buttons["home-decision-primary-action"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 4))
        startButton.tap()
        selectCatalogGame("fortnite", matching: "Fortnite", in: app)
        XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Onde você joga?"].exists)
        captureScreenshot(of: app, named: "home-game-measuring")
    }

    @MainActor
    func testGameDetailDoesNotExposeUnauditedEditorialOrNATClaims() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["Games"].waitForExistence(timeout: 3))
        app.buttons["Games"].tap()
        selectCatalogGame("fortnite", matching: "Fortnite", in: app)
        XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 3))

        XCTAssertFalse(app.staticTexts["Metacritic"].exists)
        XCTAssertFalse(app.staticTexts["System requirements"].exists)
        XCTAssertFalse(app.staticTexts["NAT"].exists)
        XCTAssertFalse(app.staticTexts["CGNAT"].exists)
    }

    @MainActor
    func testPhysicalNetworkSmokeThreeRuns() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Esse smoke depende de uma rede física.")
        #endif

        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR"]
        app.launchWithSystemLanguage()

        for run in 1...3 {
            // O smoke físico resolve a referência assinada automaticamente; só
            // então a medição Deep Check pode começar.
            startDeepCheck(app)
            XCTAssertTrue(app.staticTexts["Verificando"].waitForExistence(timeout: 2))
            XCTAssertTrue(app.staticTexts["Verificando"].waitForNonExistence(timeout: 20))
            captureScreenshot(of: app, named: "deep-check-physical-run-\(run)")

            XCTAssertTrue(app.buttons["measurement-retry"].waitForExistence(timeout: 2))
            app.buttons["measurement-retry"].tap()
        }
    }

    @MainActor
    private func captureScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Selecionar ou trocar um jogo inicia o Deep Check direto. A pré-leitura
    /// regional é automática e não pede console, plataforma ou outro toque.
    @MainActor
    private func startDeepCheck(_ app: XCUIApplication) {
        let start = app.buttons["home-cta-start-lagcheck"]
        if start.waitForExistence(timeout: 2) {
            XCTAssertTrue(start.isEnabled)
            for _ in 0..<4 where !start.isHittable {
                app.swipeUp()
            }
            XCTAssertTrue(start.isHittable)
            start.tap()
            return
        } else {
            let chooseGame = app.buttons["home-decision-primary-action"]
            XCTAssertTrue(chooseGame.waitForExistence(timeout: 3))
            chooseGame.tap()
            selectCatalogGame("fortnite", matching: "Fortnite", in: app)
        }

        XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 3))
    }

    @MainActor
    private func selectCatalogGame(_ id: String, matching query: String, in app: XCUIApplication) {
        let game = app.buttons["catalog-game-\(id)"]
        if !game.exists {
            let search = app.textFields["catalog-search-input"]
            XCTAssertTrue(search.waitForExistence(timeout: 3))
            search.tap()
            search.typeText(query)
        }
        XCTAssertTrue(game.waitForExistence(timeout: 3))
        game.tap()
    }
}

private extension XCUIApplication {
    /// A seleção de idioma é persistida pela tela de Configurações. Cada prova
    /// precisa sobrepor esse valor para que a ordem de execução não altere a UI
    /// observada pelo teste seguinte.
    func launchWithSystemLanguage() {
        if !launchArguments.contains("-app_selected_language"),
           !launchArguments.contains("-ui-fixture-reset-language") {
            launchArguments += ["-ui-fixture-reset-language"]
        }
        launch()
    }
}
