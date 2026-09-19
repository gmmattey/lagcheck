import XCTest
@testable import NolaggyApplication
@testable import NolaggyDomain
@testable import NolaggyInfrastructure

final class ConnectionBoosterTests: XCTestCase {
    func testGeminiWithoutCredentialDoesNotInventAdvice() async {
        let service = GeminiConnectionBoosterService(apiKey: "")
        let request = ConnectionBoosterRequest(
            gameName: "Fortnite", platform: .iphone, networkKind: .wifi,
            p50Milliseconds: 20, jitterMilliseconds: 2, packetLossRate: 0,
            loadImpactMilliseconds: nil, locale: "en-US"
        )

        do {
            _ = try await service.fetchAdvice(for: request)
            XCTFail("A build without a Gemini credential must not create fallback advice")
        } catch let error as GeminiConnectionBoosterServiceError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSanitizeJSONResponseStripsMarkdownCodeBlocks() {
        let rawWithFences = "```json\n{\"summary\": \"ok\"}\n```"
        let sanitized = GeminiConnectionBoosterService.sanitizeJSONResponse(rawWithFences)
        XCTAssertEqual(sanitized, "{\"summary\": \"ok\"}")
        
        let rawWithPlainFences = "```\n{\"summary\": \"ok\"}\n```"
        let sanitizedPlain = GeminiConnectionBoosterService.sanitizeJSONResponse(rawWithPlainFences)
        XCTAssertEqual(sanitizedPlain, "{\"summary\": \"ok\"}")
    }

    func testRequestMapsSupportedLocalesToTheExpectedAdviceLanguage() {
        XCTAssertEqual(ConnectionBoosterRequest.localeLanguage("pt-BR"), .ptBR)
        XCTAssertEqual(ConnectionBoosterRequest.localeLanguage("en-US"), .en)
        XCTAssertEqual(ConnectionBoosterRequest.localeLanguage("es-MX"), .es)
    }

    func testPromptIsEntirelyTargetedToRequestedLanguage() {
        let service = GeminiConnectionBoosterService(apiKey: "test")

        let portuguese = service.buildPrompt(for: boosterRequest(locale: "pt-BR"))
        XCTAssertTrue(portuguese.contains("Português do Brasil"))
        XCTAssertTrue(portuguese.contains("\"language\": \"pt-BR\""))

        let english = service.buildPrompt(for: boosterRequest(locale: "en-US"))
        XCTAssertTrue(english.contains("Respond exclusively in English"))
        XCTAssertTrue(english.contains("\"language\": \"en\""))
        XCTAssertFalse(english.contains("DADOS DA MEDIÇÃO REAL"))

        let spanish = service.buildPrompt(for: boosterRequest(locale: "es-ES"))
        XCTAssertTrue(spanish.contains("Responde exclusivamente en español"))
        XCTAssertTrue(spanish.contains("\"language\": \"es\""))
        XCTAssertFalse(spanish.contains("DADOS DA MEDIÇÃO REAL"))
    }

    func testLanguageValidationAcceptsPortugueseEnglishAndSpanishAdvice() {
        XCTAssertTrue(GeminiConnectionBoosterService.isAdviceLanguageValid(
            declaredLanguage: "pt-BR",
            summary: "A conexão apresentou pouca variação nesta medição.",
            items: [("Use a rede de 5 GHz", "Aproxime-se do roteador para reduzir interferências e oscilações.")],
            expected: .ptBR
        ))
        XCTAssertTrue(GeminiConnectionBoosterService.isAdviceLanguageValid(
            declaredLanguage: "en",
            summary: "This measurement showed low variation in the connection.",
            items: [("Use the 5 GHz network", "Move closer to the router to reduce interference and instability.")],
            expected: .en
        ))
        XCTAssertTrue(GeminiConnectionBoosterService.isAdviceLanguageValid(
            declaredLanguage: "es",
            summary: "Esta medición mostró poca variación en la conexión.",
            items: [("Usa la red de 5 GHz", "Acércate al router para reducir interferencias e inestabilidad.")],
            expected: .es
        ))
    }

    func testLanguageValidationRejectsAdviceInAnotherLanguageWithoutFallback() {
        XCTAssertFalse(GeminiConnectionBoosterService.isAdviceLanguageValid(
            declaredLanguage: "pt-BR",
            summary: "This measurement showed low variation in the connection.",
            items: [("Use the 5 GHz network", "Move closer to the router to reduce interference and instability.")],
            expected: .ptBR
        ))
        XCTAssertFalse(GeminiConnectionBoosterService.isAdviceLanguageValid(
            declaredLanguage: "en",
            summary: "Esta medición mostró poca variación en la conexión.",
            items: [("Usa la red de 5 GHz", "Acércate al router para reducir interferencias e inestabilidad.")],
            expected: .en
        ))
    }

    func testVocabularyGuardrailSanitizesProhibitedGamerTerms() {
        let text = "Com isso você tem zero lag garantido e amassou no servidor"
        let sanitized = VocabularyGuardrail.sanitize(text)
        
        XCTAssertFalse(sanitized.localizedCaseInsensitiveContains("zero lag"))
        XCTAssertFalse(sanitized.localizedCaseInsensitiveContains("garantido"))
        XCTAssertFalse(sanitized.localizedCaseInsensitiveContains("amassou"))
        XCTAssertTrue(sanitized.contains("conexão mais estável"))
        XCTAssertTrue(sanitized.contains("recomendado"))
        XCTAssertTrue(sanitized.contains("bom desempenho"))
    }
    
    func testVocabularyGuardrailSanitizesActionItems() {
        let items = [
            BoosterActionItem(
                category: .routerEquipment,
                title: "Ativar Modo Turbo",
                detail: "Garante zero-lag nas partidas."
            )
        ]
        let sanitized = VocabularyGuardrail.sanitize(items: items)
        
        XCTAssertEqual(sanitized[0].title, "Ativar ajuste prioritário")
        XCTAssertEqual(sanitized[0].detail, "Garante alta estabilidade nas partidas.")
    }
    
    @MainActor
    func testCoordinatorCachesAdviceForSameRequest() async {
        let mockService = MockBoosterService()
        let coordinator = ConnectionBoosterCoordinator(service: mockService)
        
        let request = ConnectionBoosterRequest(
            gameName: "Fortnite",
            platform: .iphone,
            networkKind: .wifi,
            p50Milliseconds: 25.0,
            jitterMilliseconds: 2.0,
            packetLossRate: 0.0,
            loadImpactMilliseconds: 5.0,
            locale: "pt-BR"
        )
        
        await coordinator.loadAdvice(for: request)
        XCTAssertEqual(mockService.callCount, 1)
        
        // Segunda chamada para a mesma medição deve bater no cache
        await coordinator.loadAdvice(for: request)
        XCTAssertEqual(mockService.callCount, 1)
        
        if case let .loaded(advice) = coordinator.state {
            XCTAssertEqual(advice.gameName, "Fortnite")
            XCTAssertEqual(advice.items.count, 1)
        } else {
            XCTFail("State should be loaded")
        }
        
        await coordinator.retry(for: request)
        XCTAssertEqual(mockService.callCount, 2)
    }
    
    @MainActor
    func testCoordinatorHandlesServiceFailureAndRetries() async {
        let failingService = FailingBoosterService()
        let coordinator = ConnectionBoosterCoordinator(service: failingService)
        
        let request = ConnectionBoosterRequest(
            gameName: "Fortnite",
            platform: .pc,
            networkKind: .wifi,
            p50Milliseconds: 42.0,
            jitterMilliseconds: 8.5,
            packetLossRate: 0.02,
            loadImpactMilliseconds: 28.0,
            locale: "pt-BR"
        )
        
        await coordinator.loadAdvice(for: request)
        if case let .failed(error) = coordinator.state {
            XCTAssertTrue(error.contains("Falha de rede"))
        } else {
            XCTFail("State should be failed")
        }
        
        failingService.shouldSucceed = true
        await coordinator.retry(for: request)
        
        if case let .loaded(advice) = coordinator.state {
            XCTAssertEqual(advice.gameName, "Fortnite")
        } else {
            XCTFail("State should be loaded after retry")
        }
    }
}

private extension ConnectionBoosterRequest {
    static func localeLanguage(_ locale: String) -> ConnectionBoosterLanguage {
        ConnectionBoosterLanguage(localeIdentifier: locale)
    }
}

private func boosterRequest(locale: String) -> ConnectionBoosterRequest {
    ConnectionBoosterRequest(
        gameName: "Fortnite",
        platform: .iphone,
        networkKind: .wifi,
        p50Milliseconds: 25,
        jitterMilliseconds: 2,
        packetLossRate: 0,
        loadImpactMilliseconds: 5,
        locale: locale
    )
}

private final class FailingBoosterService: ConnectionBoosterService, @unchecked Sendable {
    var shouldSucceed = false
    
    func fetchAdvice(for request: ConnectionBoosterRequest) async throws -> ConnectionBoosterAdvice {
        if !shouldSucceed {
            throw NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Falha de rede simulada."])
        }
        return ConnectionBoosterAdvice(
            gameName: request.gameName,
            platform: request.platform,
            summary: "Recuperado.",
            items: []
        )
    }
}

private final class MockBoosterService: ConnectionBoosterService, @unchecked Sendable {
    var callCount = 0
    
    func fetchAdvice(for request: ConnectionBoosterRequest) async throws -> ConnectionBoosterAdvice {
        callCount += 1
        return ConnectionBoosterAdvice(
            gameName: request.gameName,
            platform: request.platform,
            summary: "Conexão avaliada com sucesso.",
            items: [
                BoosterActionItem(
                    category: .routerEquipment,
                    title: "Conectar em 5 GHz",
                    detail: "Reduz oscilações perto do roteador."
                )
            ]
        )
    }
}
