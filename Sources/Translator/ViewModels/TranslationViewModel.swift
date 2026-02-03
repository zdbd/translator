import SwiftUI

/// 翻译功能的 ViewModel，负责管理翻译状态和业务逻辑
@MainActor
final class TranslationViewModel: ObservableObject {
    // MARK: - Published State

    @Published var sourceText = ""
    @Published var translatedText = ""
    @Published var sourceLanguage: Language = .english {
        didSet {
            configuration.sourceLanguage = sourceLanguage
        }
    }
    @Published var targetLanguage: Language = .chinese {
        didSet {
            configuration.targetLanguage = targetLanguage
        }
    }
    @Published var isTranslating = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var history: [TranslationRecord] = []

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
        self.sourceLanguage = configuration.sourceLanguage
        self.targetLanguage = configuration.targetLanguage
    }

    // MARK: - Actions

    /// 执行翻译
    func translate() {
        guard canTranslate else { return }

        isTranslating = true
        translatedText = ""
        errorMessage = nil

        translationTask = Task {
            var pendingText = ""
            var lastFlushTime = CFAbsoluteTimeGetCurrent()
            let minFlushInterval: CFTimeInterval = 0.05
            var wasCancelled = false
            var didError = false
            let sourceSnapshot = sourceText
            let sourceLanguageSnapshot = sourceLanguage
            let targetLanguageSnapshot = targetLanguage
            let modelSnapshot = configuration.selectedModel

            func flushPending(force: Bool = false) async {
                guard !pendingText.isEmpty else { return }
                let elapsed = CFAbsoluteTimeGetCurrent() - lastFlushTime
                if force || elapsed >= minFlushInterval {
                    let textToAppend = pendingText
                    pendingText = ""
                    lastFlushTime = CFAbsoluteTimeGetCurrent()
                    await MainActor.run {
                        translatedText += textToAppend
                    }
                }
            }

            defer {
                Task { @MainActor in
                    if wasCancelled && translatedText.isEmpty {
                        translatedText = "翻译已取消"
                    }
                    if !didError && !wasCancelled && !translatedText.isEmpty {
                        addHistory(
                            sourceText: sourceSnapshot,
                            translatedText: translatedText,
                            sourceLanguage: sourceLanguageSnapshot,
                            targetLanguage: targetLanguageSnapshot,
                            model: modelSnapshot
                        )
                    }
                    isTranslating = false
                    translationTask = nil
                }
            }

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
                    pendingText += chunk
                    await flushPending()
                }
                await flushPending(force: true)
            } catch is CancellationError {
                wasCancelled = true
                await flushPending(force: true)
            } catch let error as TranslationError {
                didError = true
                await MainActor.run {
                    errorMessage = error.errorDescription
                    if let suggestion = error.recoverySuggestion {
                        errorMessage! += "\n\n建议: \(suggestion)"
                    }
                    showError = true
                }
            } catch {
                didError = true
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
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

    func applyPromptTemplate(_ template: PromptTemplate) {
        configuration.customPrompt = template.prompt
        configuration.selectedPromptTemplate = template.name
    }

    // MARK: - History

    func addHistory(
        sourceText: String,
        translatedText: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        model: String
    ) {
        let record = TranslationRecord(
            sourceText: sourceText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            model: model,
            date: Date()
        )

        history.insert(record, at: 0)
        if history.count > 20 {
            history.removeLast(history.count - 20)
        }
    }

    func loadHistory(_ record: TranslationRecord) {
        sourceText = record.sourceText
        translatedText = record.translatedText
        sourceLanguage = record.sourceLanguage
        targetLanguage = record.targetLanguage
    }
}

// MARK: - History Model

struct TranslationRecord: Identifiable, Hashable {
    let id: UUID
    let sourceText: String
    let translatedText: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let model: String
    let date: Date

    init(
        id: UUID = UUID(),
        sourceText: String,
        translatedText: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        model: String,
        date: Date
    ) {
        self.id = id
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.model = model
        self.date = date
    }
}

struct PromptTemplate: Identifiable, Hashable {
    let id: UUID
    let name: String
    let prompt: String

    init(id: UUID = UUID(), name: String, prompt: String) {
        self.id = id
        self.name = name
        self.prompt = prompt
    }
}
