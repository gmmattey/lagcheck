import XCTest

final class DeepCheckJourneyUITests: XCTestCase {
    @MainActor
    func testGamesOpenedFromHomeHasReturnButTabSelectionDoesNot() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR"]
        app.launchWithSystemLanguage()

        // A entrada pela Home é uma continuação da decisão inicial; ela deve
        // poder voltar sem transformar Jogos em uma pilha de navegação extra.
        XCTAssertTrue(app.buttons["home-decision-primary-action"].waitForExistence(timeout: 3))
        app.buttons["home-decision-primary-action"].tap()
        XCTAssertTrue(app.buttons["games-return-home"].waitForExistence(timeout: 2))
        app.buttons["games-return-home"].tap()
        XCTAssertTrue(app.buttons["home-decision-primary-action"].waitForExistence(timeout: 2))

        // Pela tab bar, Jogos continua sendo destino principal e não mostra
        // um retorno artificial para a Home.
        app.buttons["Jogos"].tap()
        XCTAssertTrue(app.buttons["catalog-game-fortnite"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["games-return-home"].exists)
    }

    @MainActor
    func testCatalogGameTileSelectsTheHomeMeasurementAction() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["Games"].waitForExistence(timeout: 3))
        app.buttons["Games"].tap()
        XCTAssertTrue(app.buttons["catalog-game-minecraft"].waitForExistence(timeout: 3))
        app.buttons["catalog-game-minecraft"].tap()

        XCTAssertTrue(app.buttons["start-game-deep-check"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testCatalogSelectionOpensTheCurrentGameDetail() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["Games"].waitForExistence(timeout: 3))
        app.buttons["Games"].tap()
        let roblox = app.buttons["catalog-game-roblox"]
        XCTAssertTrue(roblox.waitForExistence(timeout: 3))
        roblox.tap()
        XCTAssertTrue(app.buttons["start-game-deep-check"].waitForExistence(timeout: 2))
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

        XCTAssertTrue(app.buttons["start-game-deep-check"].waitForExistence(timeout: 2))
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
        XCTAssertTrue(app.buttons["catalog-game-fortnite"].waitForExistence(timeout: 3))
        app.buttons["catalog-game-fortnite"].tap()
        XCTAssertTrue(app.staticTexts["Where do you play?"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["start-game-deep-check"].exists)
    }

    @MainActor
    func testGameDetailShowsEveryDeclaredPlatformFromTheSignedCatalog() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["Games"].waitForExistence(timeout: 3))
        app.buttons["Games"].tap()
        XCTAssertTrue(app.buttons["catalog-game-fortnite"].waitForExistence(timeout: 3))
        app.buttons["catalog-game-fortnite"].tap()

        XCTAssertTrue(app.buttons["iPhone"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["PlayStation"].exists)
        XCTAssertTrue(app.buttons["Xbox"].exists)
        XCTAssertTrue(app.buttons["PC"].exists)
        XCTAssertTrue(app.buttons["Switch"].exists)
    }

    @MainActor
    func testPlatformFilterCombinesWithTheExistingCategoryFilter() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchWithSystemLanguage()

        app.buttons["Games"].tap()
        XCTAssertTrue(app.buttons["catalog-platform-pc"].waitForExistence(timeout: 3))
        app.buttons["catalog-platform-pc"].tap()

        XCTAssertTrue(app.buttons["catalog-game-cs2"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["catalog-game-call-of-duty-mobile"].exists)

        app.buttons["Battle Royale"].tap()
        XCTAssertTrue(app.buttons["catalog-game-cs2"].exists)
        XCTAssertFalse(app.buttons["catalog-game-dota2"].exists)
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
    func testSettingsAndHistoryExposeExplicitReturnToHome() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-valid-result"]
        app.launchWithSystemLanguage()

        app.buttons["measurement-back"].tap()
        app.buttons["Configurações"].tap()
        XCTAssertTrue(app.buttons["settings-language"].waitForExistence(timeout: 2))
        app.buttons["settings-history"].tap()
        XCTAssertTrue(app.staticTexts["Histórico"].waitForExistence(timeout: 2))
        app.buttons["Início"].tap()
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

        XCTAssertTrue(app.buttons["start-game-deep-check"].waitForExistence(timeout: 3))
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
        XCTAssertTrue(app.staticTexts["check-completo-score"].exists)
        XCTAssertTrue(app.buttons["check-completo-details"].exists)
    }

    @MainActor
    func testDeepCheckDetailsExposeExplicitReturn() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-confirmed-region", "-ui-fixture-deep-result"]
        app.launchWithSystemLanguage()

        startDeepCheck(app)
        XCTAssertTrue(app.buttons["check-completo-details"].waitForExistence(timeout: 2))
        app.buttons["check-completo-details"].tap()
        XCTAssertTrue(app.buttons["deep-check-details-back"].waitForExistence(timeout: 2))
        app.buttons["deep-check-details-back"].tap()
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

        XCTAssertTrue(app.buttons["start-game-deep-check"].waitForExistence(timeout: 3))
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
        XCTAssertTrue(app.buttons["home-decision-history"].exists)
        captureScreenshot(of: app, named: "home-valid-result-hero")
    }

    @MainActor
    func testHomeDisplaysInconclusiveExplanationWithoutPositiveScore() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-inconclusive-history"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["home-decision-primary-action"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["home-decision-history"].exists)
        captureScreenshot(of: app, named: "home-inconclusive-hero")
    }

    @MainActor
    func testHomeCTAOpensTheSelectedGameDetail() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR"]
        app.launchWithSystemLanguage()

        let startButton = app.buttons["home-decision-primary-action"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 4))
        startButton.tap()
        XCTAssertTrue(app.buttons["catalog-game-fortnite"].waitForExistence(timeout: 3))
        app.buttons["catalog-game-fortnite"].tap()
        XCTAssertTrue(app.buttons["start-game-deep-check"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Onde você joga?"].exists)
        captureScreenshot(of: app, named: "home-game-detail-opened")
    }

    @MainActor
    func testGameDetailDoesNotExposeUnauditedEditorialOrNATClaims() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchWithSystemLanguage()

        XCTAssertTrue(app.buttons["Games"].waitForExistence(timeout: 3))
        app.buttons["Games"].tap()
        XCTAssertTrue(app.buttons["catalog-game-fortnite"].waitForExistence(timeout: 3))
        app.buttons["catalog-game-fortnite"].tap()
        XCTAssertTrue(app.buttons["start-game-deep-check"].waitForExistence(timeout: 3))

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

    /// A Home abre o jogo, onde a pessoa confirma plataforma e inicia o
    /// Deep Check. A pré-leitura regional é automática e não pede outro toque.
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
        } else {
            let chooseGame = app.buttons["home-decision-primary-action"]
            XCTAssertTrue(chooseGame.waitForExistence(timeout: 3))
            chooseGame.tap()
            let fortnite = app.buttons["catalog-game-fortnite"]
            XCTAssertTrue(fortnite.waitForExistence(timeout: 3))
            fortnite.tap()
        }

        let deepCheck = app.buttons["start-game-deep-check"]
        XCTAssertTrue(deepCheck.waitForExistence(timeout: 3))
        XCTAssertTrue(deepCheck.isHittable)
        deepCheck.tap()
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
