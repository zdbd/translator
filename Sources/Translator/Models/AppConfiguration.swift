import SwiftUI

/// 应用配置管理 - 使用 @AppStorage 简化持久化
@MainActor
@Observable
final class AppConfiguration {
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

    // MARK: - 存储键常量

    private enum Keys {
        static let selectedModel = "selectedModel"
        static let customPrompt = "customPrompt"
        static let ollamaURL = "ollamaURL"
    }

    // MARK: - Published Properties

    var selectedModel: String {
        didSet {
            UserDefaults.standard.set(selectedModel, forKey: Keys.selectedModel)
        }
    }

    var customPrompt: String {
        didSet {
            UserDefaults.standard.set(customPrompt, forKey: Keys.customPrompt)
        }
    }

    var ollamaURL: String {
        didSet {
            UserDefaults.standard.set(ollamaURL, forKey: Keys.ollamaURL)
        }
    }

    // MARK: - Init

    private init() {
        self.selectedModel = UserDefaults.standard.string(forKey: Keys.selectedModel) ?? "llama3"
        self.customPrompt = UserDefaults.standard.string(forKey: Keys.customPrompt) ?? Self.defaultPrompt
        self.ollamaURL = UserDefaults.standard.string(forKey: Keys.ollamaURL) ?? TranslationService.defaultURL
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
