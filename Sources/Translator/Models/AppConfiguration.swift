import SwiftUI

/// 应用配置管理 - 使用 @AppStorage 简化持久化
@MainActor
final class AppConfiguration: ObservableObject {
    static let shared = AppConfiguration()

    static let defaultPrompt = """
    你是一个专业的翻译助手。请将以下文本从{source_language}翻译成{target_language}。

    要求:
    1. 保持原文的语气和风格
    2. 确保翻译准确、流畅
    3. 专业术语要准确翻译
    4. 只返回翻译结果，不要添加解释

    待翻译文本:
    {text}
    """

    static let promptTemplates: [PromptTemplate] = [
        PromptTemplate(
            name: "简洁",
            prompt: """
            你是一个简洁风格的翻译助手。请将以下文本从{source_language}翻译成{target_language}。
            要求:
            1. 语言简洁，尽量短句
            2. 保持原文意思
            3. 只返回翻译结果

            待翻译文本:
            {text}
            """
        ),
        PromptTemplate(
            name: "正式",
            prompt: """
            你是一个正式风格的翻译助手。请将以下文本从{source_language}翻译成{target_language}。
            要求:
            1. 语气正式、专业
            2. 保持原文语义准确
            3. 只返回翻译结果

            待翻译文本:
            {text}
            """
        ),
        PromptTemplate(
            name: "直译",
            prompt: """
            你是一个偏直译的翻译助手。请将以下文本从{source_language}翻译成{target_language}。
            要求:
            1. 尽量贴近原文结构
            2. 保持词义准确
            3. 只返回翻译结果

            待翻译文本:
            {text}
            """
        )
    ]

    // MARK: - 存储键常量

    private enum Keys {
        static let selectedModel = "selectedModel"
        static let customPrompt = "customPrompt"
        static let ollamaURL = "ollamaURL"
        static let sourceLanguage = "sourceLanguage"
        static let targetLanguage = "targetLanguage"
        static let selectedPromptTemplate = "selectedPromptTemplate"
    }

    // MARK: - Published Properties

    @Published var selectedModel: String {
        didSet {
            userDefaults.set(selectedModel, forKey: Keys.selectedModel)
        }
    }

    @Published var customPrompt: String {
        didSet {
            userDefaults.set(customPrompt, forKey: Keys.customPrompt)
        }
    }

    @Published var ollamaURL: String {
        didSet {
            userDefaults.set(ollamaURL, forKey: Keys.ollamaURL)
        }
    }

    @Published var sourceLanguage: Language {
        didSet {
            userDefaults.set(sourceLanguage.rawValue, forKey: Keys.sourceLanguage)
        }
    }

    @Published var targetLanguage: Language {
        didSet {
            userDefaults.set(targetLanguage.rawValue, forKey: Keys.targetLanguage)
        }
    }

    @Published var selectedPromptTemplate: String {
        didSet {
            userDefaults.set(selectedPromptTemplate, forKey: Keys.selectedPromptTemplate)
        }
    }

    // MARK: - Init

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.selectedModel = userDefaults.string(forKey: Keys.selectedModel) ?? "llama3"
        self.customPrompt = userDefaults.string(forKey: Keys.customPrompt) ?? Self.defaultPrompt
        self.ollamaURL = userDefaults.string(forKey: Keys.ollamaURL) ?? TranslationService.defaultURL

        let storedSource = userDefaults.string(forKey: Keys.sourceLanguage)
        let storedTarget = userDefaults.string(forKey: Keys.targetLanguage)
        self.sourceLanguage = Language(rawValue: storedSource ?? "") ?? .english
        self.targetLanguage = Language(rawValue: storedTarget ?? "") ?? .chinese
        self.selectedPromptTemplate = userDefaults.string(forKey: Keys.selectedPromptTemplate) ?? ""
    }

    // MARK: - Methods

    func buildPrompt(source: String, target: String, text: String) -> String {
        customPrompt
            .replacingOccurrences(of: "{source_language}", with: source)
            .replacingOccurrences(of: "{target_language}", with: target)
            .replacingOccurrences(of: "{text}", with: text)
    }

    /// 重置提示词为默认值
    func resetPrompt() {
        customPrompt = Self.defaultPrompt
    }
}
