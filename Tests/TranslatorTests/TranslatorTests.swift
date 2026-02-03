import XCTest
@testable import Translator

final class TranslatorTests: XCTestCase {
    @MainActor
    private func makeTestConfig() -> AppConfiguration {
        let userDefaults = UserDefaults(suiteName: "TranslatorTests")!
        userDefaults.removePersistentDomain(forName: "TranslatorTests")
        return AppConfiguration(userDefaults: userDefaults)
    }

    // MARK: - Language Enum Tests

    func testLanguageAllCases() {
        XCTAssertEqual(Language.allCases.count, 8)
        XCTAssertTrue(Language.allCases.contains(.chinese))
        XCTAssertTrue(Language.allCases.contains(.english))
    }

    func testLanguageDisplayName() {
        XCTAssertEqual(Language.chinese.displayName, "中文")
        XCTAssertEqual(Language.english.displayName, "英语")
        XCTAssertEqual(Language.japanese.displayName, "日语")
    }

    func testLanguageCode() {
        XCTAssertEqual(Language.chinese.code, "zh")
        XCTAssertEqual(Language.english.code, "en")
        XCTAssertEqual(Language.japanese.code, "ja")
    }

    func testLanguageRawValue() {
        XCTAssertEqual(Language.chinese.rawValue, "中文")
        XCTAssertEqual(Language(rawValue: "英语"), .english)
    }

    // MARK: - AppConfiguration Tests

    @MainActor
    func testPromptBuilding() async {
        let config = makeTestConfig()
        let prompt = config.buildPrompt(source: "英语", target: "中文", text: "Hello")

        XCTAssertTrue(prompt.contains("英语"))
        XCTAssertTrue(prompt.contains("中文"))
        XCTAssertTrue(prompt.contains("Hello"))
    }

    @MainActor
    func testDefaultPromptContainsPlaceholders() {
        let prompt = AppConfiguration.defaultPrompt
        XCTAssertTrue(prompt.contains("{source_language}"))
        XCTAssertTrue(prompt.contains("{target_language}"))
        XCTAssertTrue(prompt.contains("{text}"))
    }

    // MARK: - ViewModel Tests

    @MainActor
    func testViewModelInitialState() {
        let vm = TranslationViewModel(configuration: makeTestConfig())

        XCTAssertEqual(vm.sourceText, "")
        XCTAssertEqual(vm.translatedText, "")
        XCTAssertEqual(vm.sourceLanguage, .english)
        XCTAssertEqual(vm.targetLanguage, .chinese)
        XCTAssertFalse(vm.isTranslating)
    }

    @MainActor
    func testViewModelCanTranslate() {
        let vm = TranslationViewModel(configuration: makeTestConfig())

        // Empty text - cannot translate
        XCTAssertFalse(vm.canTranslate)

        // With text - can translate
        vm.sourceText = "Hello"
        XCTAssertTrue(vm.canTranslate)

        // Same language - cannot translate
        vm.targetLanguage = .english
        XCTAssertFalse(vm.canTranslate)
    }

    @MainActor
    func testViewModelSwapLanguages() {
        let vm = TranslationViewModel(configuration: makeTestConfig())
        vm.sourceLanguage = .english
        vm.targetLanguage = .chinese
        vm.translatedText = "你好"

        vm.swapLanguages()

        XCTAssertEqual(vm.sourceLanguage, .chinese)
        XCTAssertEqual(vm.targetLanguage, .english)
        XCTAssertEqual(vm.sourceText, "你好")
        XCTAssertEqual(vm.translatedText, "")
    }

    @MainActor
    func testViewModelClearAll() {
        let vm = TranslationViewModel(configuration: makeTestConfig())
        vm.sourceText = "Hello"
        vm.translatedText = "你好"
        vm.errorMessage = "Some error"

        vm.clearAll()

        XCTAssertEqual(vm.sourceText, "")
        XCTAssertEqual(vm.translatedText, "")
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - Ollama Models Tests

    func testTranslationRequestEncoding() throws {
        let request = TranslationRequest(
            model: "llama3",
            prompt: "Translate hello",
            stream: true,
            options: ModelOptions(temperature: 0.3, numPredict: 2000)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let jsonString = String(data: data, encoding: .utf8) ?? ""

        XCTAssertTrue(jsonString.contains("\"llama3\""))
        XCTAssertTrue(jsonString.contains("\"stream\":true"))
    }

    func testTranslationResponseDecoding() throws {
        let json = """
        {
            "model": "llama3",
            "created_at": "2024-01-01T00:00:00Z",
            "response": "你好",
            "done": false
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(TranslationResponse.self, from: data)

        XCTAssertEqual(response.model, "llama3")
        XCTAssertEqual(response.response, "你好")
        XCTAssertEqual(response.done, false)
    }

    func testOllamaErrorResponseDecoding() throws {
        let json = """
        { "error": "model not found" }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(OllamaErrorResponse.self, from: data)

        XCTAssertEqual(response.error, "model not found")
    }

    // MARK: - Error Handling Tests

    func testTranslationErrorDescriptions() {
        XCTAssertNotNil(TranslationError.connectionRefused.errorDescription)
        XCTAssertNotNil(TranslationError.connectionTimeout.errorDescription)
        XCTAssertNotNil(TranslationError.networkUnavailable.errorDescription)
        XCTAssertNotNil(TranslationError.modelNotFound.errorDescription)
        XCTAssertNotNil(TranslationError.invalidResponse.errorDescription)
        XCTAssertNotNil(TranslationError.httpError(500).errorDescription)
        XCTAssertNotNil(TranslationError.serverError(503).errorDescription)
        XCTAssertNotNil(TranslationError.ollamaError("bad request").errorDescription)
    }

    func testTranslationErrorRecoverySuggestions() {
        XCTAssertNotNil(TranslationError.connectionRefused.recoverySuggestion)
        XCTAssertNotNil(TranslationError.modelNotFound.recoverySuggestion)
        XCTAssertNotNil(TranslationError.connectionTimeout.recoverySuggestion)
        XCTAssertNotNil(TranslationError.ollamaError("bad request").recoverySuggestion)

        // These errors don't have recovery suggestions
        XCTAssertNil(TranslationError.invalidResponse.recoverySuggestion)
        XCTAssertNil(TranslationError.httpError(400).recoverySuggestion)
    }

    func testTranslationErrorFromURLError() {
        switch TranslationError.from(urlError: URLError(.cannotConnectToHost)) {
        case .connectionRefused: break
        default: XCTFail("Expected connectionRefused")
        }

        switch TranslationError.from(urlError: URLError(.cannotFindHost)) {
        case .connectionRefused: break
        default: XCTFail("Expected connectionRefused")
        }

        switch TranslationError.from(urlError: URLError(.timedOut)) {
        case .connectionTimeout: break
        default: XCTFail("Expected connectionTimeout")
        }

        switch TranslationError.from(urlError: URLError(.notConnectedToInternet)) {
        case .networkUnavailable: break
        default: XCTFail("Expected networkUnavailable")
        }
    }

    func testDefaultOllamaURL() {
        XCTAssertEqual(TranslationService.defaultURL, "http://localhost:11434")
    }
}
