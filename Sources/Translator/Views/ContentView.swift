import SwiftUI

struct ContentView: View {
    @State private var viewModel = TranslationViewModel()

    var body: some View {
        HSplitView {
            // 左侧输入区
            VStack(alignment: .leading, spacing: 12) {
                // 源语言选择
                LanguagePicker(selection: $viewModel.sourceLanguage)

                // 输入文本区（带 Placeholder）
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.sourceText)
                        .font(.body)
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

            // 右侧输出区
            VStack(alignment: .leading, spacing: 12) {
                // 目标语言选择和操作按钮
                HStack {
                    LanguagePicker(selection: $viewModel.targetLanguage)

                    Spacer()

                    // 交换语言按钮
                    Button(action: viewModel.swapLanguages) {
                        Image(systemName: "arrow.left.arrow.right")
                    }
                    .disabled(viewModel.isTranslating)
                    .help("交换语言 (⌘⇧S)")
                    .keyboardShortcut("s", modifiers: [.command, .shift])

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
                    } else {
                        Button(action: viewModel.translate) {
                            Text("翻译")
                        }
                        .disabled(!viewModel.canTranslate)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.return, modifiers: .command)
                        .help("翻译 (⌘↩)")
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

                // 输出文本区（带自动滚动）
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(viewModel.translatedText)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .padding(8)
                            
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

                // 底部状态栏
                HStack {
                    // 模型名称
                    Label(viewModel.modelName, systemImage: "cube")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // 操作按钮
                    if !viewModel.translatedText.isEmpty && !viewModel.isTranslating {
                        Button("清空") {
                            viewModel.clearAll()
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.secondary)

                        Button("复制") {
                            viewModel.copyToClipboard()
                        }
                        .buttonStyle(.borderless)
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                        .help("复制翻译结果 (⌘⇧C)")
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 450)
        .alert("翻译错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) {
                viewModel.dismissError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - 可复用组件

/// 语言选择器
struct LanguagePicker: View {
    @Binding var selection: Language

    var body: some View {
        Picker("语言", selection: $selection) {
            ForEach(Language.allCases) { language in
                Text(language.displayName).tag(language)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }
}
