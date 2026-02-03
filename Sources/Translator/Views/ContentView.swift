import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TranslationViewModel()
    @FocusState private var focusedField: FocusedField?
    @AppStorage("splitRatio") private var splitRatio: Double = 0.5
    @State private var dragStartRatio: Double?
    @State private var showHistory = false

    private enum FocusedField {
        case source
    }

    private let promptTemplates = AppConfiguration.promptTemplates
    @ObservedObject private var configuration = AppConfiguration.shared

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let clampedRatio = min(max(splitRatio, 0.3), 0.7)
            let leftWidth = max(280, min(totalWidth - 280, totalWidth * clampedRatio))

            HStack(spacing: 0) {
                // 左侧输入区
                VStack(alignment: .leading, spacing: 12) {
                // 源语言选择
                LanguagePicker(selection: $viewModel.sourceLanguage, label: "源语言")

                // 输入文本区（带 Placeholder）
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.sourceText)
                        .font(.body)
                        .focused($focusedField, equals: .source)
                        .scrollContentBackground(.hidden)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)

                    if viewModel.sourceText.isEmpty {
                        Text("输入要翻译的文本...")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }

                // 字符计数
                HStack {
                    Spacer()
                    Text("\(viewModel.characterCount) 字符")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                }
                .padding()
                .frame(width: leftWidth, alignment: .leading)

                // 分割条
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 6)
                    .overlay(
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 1)
                    )
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let startRatio = dragStartRatio ?? splitRatio
                                dragStartRatio = startRatio
                                let deltaRatio = value.translation.width / max(totalWidth, 1)
                                splitRatio = min(max(startRatio + deltaRatio, 0.3), 0.7)
                            }
                            .onEnded { _ in
                                dragStartRatio = nil
                            }
                    )

                // 右侧输出区
                VStack(alignment: .leading, spacing: 12) {
                // 目标语言选择和操作按钮
                HStack {
                    LanguagePicker(selection: $viewModel.targetLanguage, label: "目标语言")

                    Spacer()

                    // 交换语言按钮
                    Button(action: viewModel.swapLanguages) {
                        Image(systemName: "arrow.left.arrow.right")
                    }
                    .disabled(viewModel.isTranslating)
                    .help("交换语言 (⌘⇧S)")
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                    .accessibilityLabel("交换语言")

                    Menu(configuration.selectedPromptTemplate.isEmpty ? "模板" : configuration.selectedPromptTemplate) {
                        ForEach(promptTemplates) { template in
                            Button {
                                viewModel.applyPromptTemplate(template)
                            } label: {
                                if configuration.selectedPromptTemplate == template.name {
                                    Label(template.name, systemImage: "checkmark")
                                } else {
                                    Text(template.name)
                                }
                            }
                        }
                    }
                    .help("快速切换提示词模板")

                    // 翻译/取消按钮
                    if viewModel.isTranslating {
                        Button(action: viewModel.cancelTranslation) {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("取消")
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .accessibilityLabel("取消翻译")
                    } else {
                        Button(action: viewModel.translate) {
                            Text("翻译")
                        }
                        .disabled(!viewModel.canTranslate)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.return, modifiers: .command)
                        .help("翻译 (⌘↩)")
                        .accessibilityLabel("开始翻译")
                    }
                }

                // 语言相同提示
                if viewModel.isSameLanguage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("源语言和目标语言相同")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                // 状态栏（模型与流式状态）
                HStack(spacing: 12) {
                    Label(viewModel.modelName, systemImage: "cube")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if viewModel.isTranslating {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.mini)
                            Text("翻译中…")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }

                // 内联错误提示
                if viewModel.showError, let errorMessage = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.primary)

                        Spacer()

                        Button("重试") {
                            viewModel.translate()
                        }
                        .disabled(!viewModel.canTranslate)

                        Button("关闭") {
                            viewModel.dismissError()
                        }
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(8)
                }

                // 输出文本区（带自动滚动）
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            if viewModel.translatedText.isEmpty && !viewModel.isTranslating {
                                Text("翻译结果将在此显示...")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                            } else {
                                Text(viewModel.translatedText)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                                    .padding(8)
                            }
                            
                            // 底部锚点
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                    }
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .onChange(of: viewModel.translatedText) { _, _ in
                        // 仅在翻译进行时自动滚动
                        if viewModel.isTranslating {
                            withAnimation(.easeOut(duration: 0.1)) {
                                scrollProxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }

                if showHistory {
                    HistoryPanel(records: viewModel.history) { record in
                        viewModel.loadHistory(record)
                    }
                    .frame(maxHeight: 180)
                }

                // 底部状态栏
                HStack {
                    Spacer()

                    // 操作按钮
                    if !viewModel.translatedText.isEmpty && !viewModel.isTranslating {
                        Button("清空") {
                            viewModel.clearAll()
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("清空内容")

                        Button("复制") {
                            viewModel.copyToClipboard()
                        }
                        .buttonStyle(.borderless)
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                        .help("复制翻译结果 (⌘⇧C)")
                        .accessibilityLabel("复制翻译结果")
                    }

                    Button(showHistory ? "隐藏历史" : "历史") {
                        showHistory.toggle()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.secondary)
                }
                }
                .padding()
                .frame(width: totalWidth - leftWidth - 6, alignment: .leading)
            }
        }
        .frame(minWidth: 700, minHeight: 450)
        .overlay(alignment: .topLeading) {
            Button("聚焦输入") {
                focusedField = .source
            }
            .keyboardShortcut("l", modifiers: [.command])
            .opacity(0)
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
        }
        .overlay(alignment: .topLeading) {
            Button("清空内容") {
                viewModel.clearAll()
            }
            .keyboardShortcut("k", modifiers: [.command])
            .opacity(0)
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
        }
    }
}

// MARK: - 可复用组件

/// 语言选择器
struct LanguagePicker: View {
    @Binding var selection: Language
    let label: String

    var body: some View {
        Picker("语言", selection: $selection) {
            ForEach(Language.allCases) { language in
                Text(language.displayName).tag(language)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .accessibilityLabel(label)
    }
}

// MARK: - History Panel

struct HistoryPanel: View {
    let records: [TranslationRecord]
    let onSelect: (TranslationRecord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("历史记录")
                .font(.caption)
                .foregroundColor(.secondary)

            if records.isEmpty {
                Text("暂无历史记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(records) { record in
                            Button {
                                onSelect(record)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(record.sourceLanguage.displayName) → \(record.targetLanguage.displayName) · \(record.model)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(record.sourceText)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(6)
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}
