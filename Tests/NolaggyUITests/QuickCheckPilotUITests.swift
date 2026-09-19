import XCTest

final class QuickCheckPilotUITests: XCTestCase {
    @MainActor
    func testCatalogSearchFiltersTheSignedGameDiscovery() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.buttons["catalog-game-minecraft"].waitForExistence(timeout: 3))
        app.buttons["catalog-search-open"].tap()
        XCTAssertTrue(app.textFields["Search games"].waitForExistence(timeout: 2))
        captureScreenshot(of: app, named: "catalog-expanded-search")
        app.textFields["Search games"].tap()
        app.textFields["Search games"].typeText("Mine")

        XCTAssertTrue(app.buttons["catalog-game-minecraft"].exists)
        XCTAssertFalse(app.buttons["catalog-game-fortnite"].exists)
    }

    @MainActor
    func testCatalogGameTileSelectsTheHomeMeasurementAction() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.buttons["catalog-game-minecraft"].waitForExistence(timeout: 3))
        app.buttons["catalog-game-minecraft"].tap()

        XCTAssertTrue(app.staticTexts["home-selected-game-title"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["home-selected-game-title"].label, "Minecraft")
        XCTAssertTrue(app.buttons["quick-check-start"].exists)
    }

    @MainActor
    func testCallOfDutySelectionUpdatesTheHomeMeasurementAction() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let callOfDuty = app.buttons["catalog-game-call-of-duty-mobile"]
        XCTAssertTrue(callOfDuty.waitForExistence(timeout: 3))
        callOfDuty.tap()
        XCTAssertTrue(app.staticTexts["home-selected-game-title"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["home-selected-game-title"].label, "Call of Duty: Mobile")
    }

    @MainActor
    func testStartThenBackShowsCancelledWithoutScore() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-confirmed-region"]
        app.launch()

        startQuick(app)

        XCTAssertTrue(app.staticTexts["Verificando"].waitForExistence(timeout: 2))
        captureScreenshot(of: app, named: "quick-check-measuring")
        app.buttons["quick-check-back"].tap()

        XCTAssertTrue(app.staticTexts["A medição foi cancelada. Descartamos a leitura parcial. Reinicie o teste para termos um resultado confiável."].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Excelente"].exists)
        XCTAssertFalse(app.staticTexts["Risco de lag"].exists)
    }

    @MainActor
    func testEnglishContextUsesLocalizedCopy() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.buttons["catalog-game-fortnite"].waitForExistence(timeout: 3))
        app.buttons["catalog-game-fortnite"].tap()
        XCTAssertTrue(app.staticTexts["Platform"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Connection estimate for São Paulo, not the game's official ping."].exists)
        XCTAssertTrue(app.buttons["quick-check-start"].exists)
    }

    @MainActor
    func testFixtureOpensLocalizedDetailsWithOnlyCompletedMetrics() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-valid-result"]
        app.launch()

        XCTAssertTrue(app.buttons["quick-check-details"].waitForExistence(timeout: 2))
        app.buttons["quick-check-details"].tap()
        XCTAssertTrue(app.staticTexts["Detalhes"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["P50"].exists)
        XCTAssertTrue(app.staticTexts["P99"].exists)
        XCTAssertTrue(app.staticTexts["Pior spike"].exists)
        XCTAssertTrue(app.staticTexts["Alvo medido"].exists)
        XCTAssertTrue(app.staticTexts["Rota regional de referência"].exists)
        XCTAssertTrue(app.staticTexts["Média"].exists)
        captureScreenshot(of: app, named: "details-valid-result")
        app.buttons["measurement-details-back"].tap()
        XCTAssertTrue(app.buttons["quick-check-details"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testFixtureDetailsAccommodateAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "-UIPreferredContentSizeCategory", "UICTContentSizeCategoryAccessibilityXXXL",
            "-ui-fixture-valid-result"
        ]
        app.launch()

        XCTAssertTrue(app.buttons["quick-check-details"].waitForExistence(timeout: 2))
        app.buttons["quick-check-details"].tap()
        XCTAssertTrue(app.staticTexts["Details"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Worst spike"].exists)
        captureScreenshot(of: app, named: "details-accessibility-en")
    }

    @MainActor
    func testFixtureShowsARealHistoryEntryAndRetestAction() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-valid-result"]
        app.launch()

        app.buttons["quick-check-back"].tap()
        XCTAssertTrue(app.buttons["navigation-settings-open"].waitForExistence(timeout: 2))
        app.buttons["navigation-settings-open"].tap()
        XCTAssertTrue(app.buttons["settings-history"].waitForExistence(timeout: 2))
        captureScreenshot(of: app, named: "settings-native-menu")
        app.buttons["settings-history"].tap()
        XCTAssertTrue(app.staticTexts["Histórico"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Testar Fortnite de novo"].exists)
        captureScreenshot(of: app, named: "history-valid-entry")
    }

    @MainActor
    func testSettingsAndHistoryExposeExplicitReturnToHome() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-valid-result"]
        app.launch()

        app.buttons["quick-check-back"].tap()
        app.buttons["navigation-settings-open"].tap()
        XCTAssertTrue(app.buttons["settings-back"].waitForExistence(timeout: 2))
        app.buttons["settings-back"].tap()
        XCTAssertTrue(app.staticTexts["Jogos disponíveis"].waitForExistence(timeout: 2))

        app.buttons["navigation-settings-open"].tap()
        app.buttons["settings-history"].tap()
        XCTAssertTrue(app.buttons["history-back"].waitForExistence(timeout: 2))
        app.buttons["history-back"].tap()
        XCTAssertTrue(app.staticTexts["Jogos disponíveis"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testDeepCheckIntroIsReachableFromAValidQuickCheck() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-valid-result"]
        app.launch()

        app.buttons["deep-check-open"].tap()
        XCTAssertTrue(app.staticTexts["Investigar mais a fundo?"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Iniciar Deep Check"].exists)
        XCTAssertTrue(app.staticTexts["Disponível apenas em Wi-Fi nesta versão."].exists)
    }

    @MainActor
    func testDeepCheckFixtureShowsRestScoreAndSeparateLoadImpact() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-ui-fixture-valid-result", "-ui-fixture-deep-result"]
        app.launch()

        app.buttons["deep-check-open"].tap()
        XCTAssertTrue(app.staticTexts["Material impact under load"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Excellent at rest"].exists)
        XCTAssertTrue(app.staticTexts["At rest"].exists)
        XCTAssertTrue(app.staticTexts["Under load"].exists)
    }

    @MainActor
    func testDeepCheckDetailsExposeExplicitReturn() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-valid-result", "-ui-fixture-deep-result"]
        app.launch()

        app.buttons["deep-check-open"].tap()
        XCTAssertTrue(app.buttons["Ver detalhes completos"].waitForExistence(timeout: 2))
        app.buttons["Ver detalhes completos"].tap()
        XCTAssertTrue(app.buttons["deep-check-details-back"].waitForExistence(timeout: 2))
        app.buttons["deep-check-details-back"].tap()
        XCTAssertTrue(app.buttons["deep-check-back"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testDeepCheckComparisonAccommodatesAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "-UIPreferredContentSizeCategory", "UICTContentSizeCategoryAccessibilityXXXL",
            "-ui-fixture-valid-result", "-ui-fixture-deep-result"
        ]
        app.launch()

        app.buttons["deep-check-open"].tap()
        XCTAssertTrue(app.staticTexts["Material impact under load"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["At rest"].exists)
        XCTAssertTrue(app.staticTexts["Under load"].exists)
        captureScreenshot(of: app, named: "deep-check-accessibility-en")
    }

    @MainActor
    func testEnglishMeasurementUsesLocalizedWaitingCopy() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-ui-fixture-measuring"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Measuring"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Medindo"].exists)
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
        app.launch()

        startQuick(app)
        XCTAssertTrue(app.staticTexts["Verificando"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["quick-check-back"].exists)
        captureScreenshot(of: app, named: "quick-check-accessibility-measuring")
    }

    @MainActor
    func testHomeStartGoesStraightToMeasuringWithoutAConfirmationScreen() {
        // A seleção regional é automática: depois de tocar "Iniciar" não deve
        // existir nenhum segundo toque de confirmação antes de medir.
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-confirmed-region"]
        app.launch()

        startQuick(app)
        XCTAssertTrue(app.staticTexts["Verificando"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["regional-selection-start"].exists)
    }

    @MainActor
    func testSettingsRegionPreferenceCanBeSetAndClearedToAutomatic() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-valid-result"]
        app.launch()

        app.buttons["quick-check-back"].tap()
        app.buttons["navigation-settings-open"].tap()
        let regionRow = app.buttons["settings-region"]
        XCTAssertTrue(regionRow.waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Automática"].exists)
        captureScreenshot(of: app, named: "settings-region-automatic")

        for _ in 0..<4 where !regionRow.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(regionRow.isHittable)
        regionRow.tap()
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
        app.launch()

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
        app.launch()

        XCTAssertTrue(app.buttons["regional-selection-back-home"].waitForExistence(timeout: 2))
        app.buttons["regional-selection-back-home"].tap()
        XCTAssertTrue(app.staticTexts["Jogos disponíveis"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testRegionalConfirmingAndManualStateAccommodateAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "-UIPreferredContentSizeCategory", "UICTContentSizeCategoryAccessibilityXXXL",
            "-ui-fixture-regional-confirming"
        ]
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["regional-selection-confirming"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Confirming a reference region…"].exists)
        captureScreenshot(of: app, named: "regional-selection-confirming-accessibility-en")
    }

    @MainActor
    func testBackgroundDiscardsPhysicalQuickCheck() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-confirmed-region"]
        app.launch()

        startQuick(app)
        XCTAssertTrue(app.staticTexts["Verificando"].waitForExistence(timeout: 2))

        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()

        let backgroundMessage = app.staticTexts.matching(
            NSPredicate(
                format: "label == %@",
                "A medição foi interrompida porque o app foi para segundo plano. Descartamos a leitura parcial. Reinicie o teste para termos um resultado confiável."
            )
        ).firstMatch
        XCTAssertTrue(backgroundMessage.waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Excelente"].exists)
        XCTAssertFalse(app.staticTexts["Risco de lag"].exists)
    }

    @MainActor
    func testNewUserHomePresentsReadyStateAndExploreAction() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Início"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.otherElements["home-state-hero"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Pronto para verificar sua rota"].exists)
        XCTAssertTrue(app.buttons["home-cta-start-lagcheck"].exists)

        let exploreButton = app.buttons.matching(NSPredicate(format: "label == 'Explorar Jogos' OR identifier == 'home-empty-explore-button'")).firstMatch
        XCTAssertTrue(exploreButton.waitForExistence(timeout: 3))
        captureScreenshot(of: app, named: "home-new-user-ready")

        exploreButton.tap()
        XCTAssertTrue(app.staticTexts["Jogos"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testHomeDisplaysValidEvaluatedScoreHero() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-valid-result"]
        app.launch()

        if app.buttons["quick-check-back"].waitForExistence(timeout: 2) {
            app.buttons["quick-check-back"].tap()
        }

        XCTAssertTrue(app.staticTexts["Início"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.otherElements["home-state-hero"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["home-hero-score-value"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Conexão excelente"].exists)
        captureScreenshot(of: app, named: "home-valid-result-hero")
    }

    @MainActor
    func testHomeDisplaysInconclusiveExplanationWithoutPositiveScore() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "-ui-fixture-inconclusive-history"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Início"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.otherElements["home-state-hero"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Medição inconclusiva"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Respostas UDP insuficientes para avaliar a rota com precisão."].exists)
        XCTAssertFalse(app.staticTexts["home-hero-score-value"].exists)
        XCTAssertFalse(app.staticTexts["Conexão excelente"].exists)
        captureScreenshot(of: app, named: "home-inconclusive-hero")
    }

    @MainActor
    func testHomeCTAOpensPlatformSelectionSheet() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR"]
        app.launch()

        let startButton = app.buttons["home-cta-start-lagcheck"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 4))
        startButton.tap()

        XCTAssertTrue(app.buttons["confirm-platform-and-start"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["iPhone"].exists)
        XCTAssertFalse(app.staticTexts["PlayStation"].exists)
        XCTAssertFalse(app.staticTexts["Xbox"].exists)
        captureScreenshot(of: app, named: "home-platform-picker-opened")
    }

    @MainActor
    func testPhysicalNetworkSmokeThreeRuns() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Esse smoke depende de uma rede física.")
        #endif

        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR"]
        app.launch()

        for run in 1...3 {
            // O smoke físico resolve a referência assinada automaticamente; só
            // então a janela de 30 probes do Quick Check pode começar.
            startQuick(app)
            XCTAssertTrue(app.staticTexts["Verificando"].waitForExistence(timeout: 2))
            XCTAssertTrue(app.staticTexts["Verificando"].waitForNonExistence(timeout: 20))
            captureScreenshot(of: app, named: "quick-check-physical-run-\(run)")

            XCTAssertTrue(app.buttons["quick-check-retry"].waitForExistence(timeout: 2))
            app.buttons["quick-check-retry"].tap()
        }
    }

    @MainActor
    private func captureScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// A seleção regional é automática: um único toque em "Iniciar" já
    /// dispara a pré-leitura e, ao resolver, a medição em si — sem tela ou
    /// toque de confirmação no meio do caminho.
    @MainActor
    private func startQuick(_ app: XCUIApplication) {
        if app.buttons["catalog-game-fortnite"].exists {
            app.buttons["catalog-game-fortnite"].tap()
        }
        let quickStart = app.buttons["quick-check-start"]
        XCTAssertTrue(quickStart.waitForExistence(timeout: 3))
        XCTAssertTrue(quickStart.isEnabled)
        for _ in 0..<4 where !quickStart.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(quickStart.isHittable)
        sleep(1)
        quickStart.tap()
    }
}
