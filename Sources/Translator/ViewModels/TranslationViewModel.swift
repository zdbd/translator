import SwiftUI

/// 翻译功能的 ViewModel，负责管理翻译状态和业务逻辑
@MainActor
@Observable
final class TranslationViewModel {
    // MARK: - Published State

    var sourceText = ""
    var translatedText = ""
    var sourceLanguage: Language = .english
    var targetLanguage: Language = .chinese
    var isTranslating = false
    var errorMessage: String?
    var showError = false

    // MARK: - Private

    private var translationTask: Task<Void, Never>?
    private let configuration: AppConfiguration

    // MARK: - Computed Properties

    /// 是否可以执行翻译
    var canTranslate: Bool {
        !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && sourceLanguage != targetLanguage
            && !isTranslating
    }

    /// 源语言和目标语言是否相同
    var isSameLanguage: Bool {
        sourceLanguage == targetLanguage
    }

    /// 源文本字符数
    var characterCount: Int {
        sourceText.count
    }

    /// 当前使用的模型名称
    var modelName: String {
        configuration.selectedModel
    }

    // MARK: - Init

    init(configuration: AppConfiguration = .shared) {
        self.configuration = configuration
    }

    // MARK: - Actions

    /// 执行翻译
    func translate() {
        guard canTranslate else { return }

        isTranslating = true
        translatedText = ""
        errorMessage = nil

        translationTask = Task {
            do {
                let prompt = configuration.buildPrompt(
                    source: sourceLanguage.displayName,
                    target: targetLanguage.displayName,
                    text: sourceText
                )

                for try await chunk in try await TranslationService.shared.translate(
                    model: configuration.selectedModel,
                    prompt: prompt
                ) {
                    if Task.isCancelled { break }
                    translatedText += chunk
                }
            } catch is CancellationError {
                if translatedText.isEmpty {
                    translatedText = "翻译已取消"
                }
            } catch let error as TranslationError {
                errorMessage = error.errorDescription
                if let suggestion = error.recoverySuggestion {
                    errorMessage! += "\n\n建议: \(suggestion)"
                }
                showError = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }

            isTranslating = false
            translationTask = nil
        }
    }

    /// 取消翻译
    func cancelTranslation() {
        translationTask?.cancel()
        translationTask = nil
        isTranslating = false
    }

    /// 交换源语言和目标语言
    func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp

        if !translatedText.isEmpty {
            sourceText = translatedText
            translatedText = ""
        }
    }

    /// 清空所有内容
    func clearAll() {
        sourceText = ""
        translatedText = ""
        errorMessage = nil
    }

    /// 复制翻译结果到剪贴板
    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(translatedText, forType: .string)
    }

    /// 重置错误弹窗状态
    func dismissError() {
        showError = false
    }
}
