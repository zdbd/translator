import SwiftUI

struct SettingsView: View {
    @ObservedObject private var configuration = AppConfiguration.shared

    @State private var availableModels: [String] = []
    @State private var isLoadingModels = false
    @State private var loadError: String?
    @State private var customPrompt = ""
    @State private var ollamaURL = ""
    @State private var urlError: String?
    @State private var connectionStatus: ConnectionStatus = .unknown

    enum ConnectionStatus {
        case unknown, checking, connected, failed(String)
    }

    enum URLValidationError: LocalizedError {
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "URL 格式无效，请输入例如 http://localhost:11434"
            }
        }
    }

    var body: some View {
        TabView {
            modelSettingsTab
            promptSettingsTab
            aboutTab
        }
        .frame(width: 520, height: 420)
        .onAppear {
            loadSettings()
            loadModels()
        }
    }

    // MARK: - Model Settings Tab

    private var modelSettingsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("模型设置")
                .font(.headline)

            // Ollama 服务地址
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Ollama 服务地址")
                        Spacer()
                        connectionStatusBadge
                    }

                    HStack {
                        TextField(TranslationService.defaultURL, text: $ollamaURL)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                if saveOllamaURL() {
                                    testConnection()
                                }
                            }

                        Button("测试连接") {
                            if saveOllamaURL() {
                                testConnection()
                            }
                        }
                        .disabled(isConnectionChecking)
                    }

                    if let urlError {
                        Text(urlError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            }

            // 模型选择
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("翻译模型")
                        Spacer()
                        Button {
                            loadModels()
                        } label: {
                            Label("刷新", systemImage: "arrow.clockwise")
                        }
                        .disabled(isLoadingModels)
                    }

                    if isLoadingModels {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("加载中...")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    } else if let error = loadError {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .foregroundColor(.secondary)
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    } else if !availableModels.isEmpty {
                        Picker("选择模型", selection: $configuration.selectedModel) {
                            ForEach(availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()

                        Text("共 \(availableModels.count) 个模型可用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("无可用模型")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 4)
            }

            Spacer()

            // 帮助提示
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("确保 Ollama 服务正在运行")
                    Text("使用 `ollama serve` 启动服务，`ollama pull <模型>` 下载模型")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
        }
        .padding()
        .tabItem {
            Label("模型", systemImage: "cube")
        }
    }

    private var connectionStatusBadge: some View {
        Group {
            switch connectionStatus {
            case .unknown:
                EmptyView()
            case .checking:
                ProgressView()
                    .controlSize(.mini)
            case .connected:
                Label("已连接", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            case .failed(let reason):
                Label(reason, systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }

    private var isConnectionChecking: Bool {
        if case .checking = connectionStatus { return true }
        return false
    }

    // MARK: - Prompt Settings Tab

    private var promptSettingsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("提示词模板")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("预设模板:")
                    .font(.caption)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    ForEach(AppConfiguration.promptTemplates) { template in
                        Button(template.name) {
                            customPrompt = template.prompt
                            configuration.selectedPromptTemplate = template.name
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("可用变量:")
                    .font(.caption)
                    .fontWeight(.medium)
                HStack(spacing: 8) {
                    VariableTag(name: "{source_language}", description: "源语言")
                    VariableTag(name: "{target_language}", description: "目标语言")
                    VariableTag(name: "{text}", description: "待翻译文本")
                }
            }

            TextEditor(text: $customPrompt)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .frame(minHeight: 150)

            HStack {
                Button("恢复默认") {
                    resetPrompt()
                }

                Spacer()

                if customPrompt != configuration.customPrompt {
                    Text("有未保存的更改")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                Button("保存") {
                    savePrompt()
                }
                .buttonStyle(.borderedProminent)
                .disabled(customPrompt == configuration.customPrompt)
            }

            Spacer()
        }
        .padding()
        .tabItem {
            Label("提示词", systemImage: "text.bubble")
        }
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading) {
                    Text("Translator")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("基于本地 Ollama 模型的多语言翻译应用")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("功能特点")
                    .font(.headline)

                FeatureRow(icon: "globe", text: "支持多种语言互译")
                FeatureRow(icon: "lock.shield", text: "使用本地模型，保护隐私")
                FeatureRow(icon: "text.bubble", text: "自定义翻译提示词")
                FeatureRow(icon: "bolt", text: "实时流式输出")
                FeatureRow(icon: "keyboard", text: "支持键盘快捷键")
            }

            Spacer()

            HStack {
                Spacer()
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .tabItem {
            Label("关于", systemImage: "info.circle")
        }
    }

    // MARK: - Actions

    private func loadSettings() {
        ollamaURL = configuration.ollamaURL
        customPrompt = configuration.customPrompt
        urlError = nil
    }

    private func saveOllamaURL() -> Bool {
        let trimmedURL = ollamaURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = normalizeOllamaURL(trimmedURL)
        switch normalized {
        case .success(let value):
            ollamaURL = value
            configuration.ollamaURL = value
            urlError = nil
            return true
        case .failure(let error):
            urlError = error.errorDescription
            return false
        }
    }

    private func testConnection() {
        connectionStatus = .checking

        Task {
            do {
                _ = try await TranslationService.shared.getAvailableModels()
                connectionStatus = .connected
            } catch let error as TranslationError {
                connectionStatus = .failed(error.errorDescription ?? "连接失败")
            } catch {
                connectionStatus = .failed("连接失败")
            }
        }
    }

    private func loadModels() {
        isLoadingModels = true
        loadError = nil
        guard saveOllamaURL() else {
            isLoadingModels = false
            connectionStatus = .failed("URL 无效")
            return
        }

        Task {
            do {
                let models = try await TranslationService.shared.getAvailableModels()
                availableModels = models.sorted()

                if models.isEmpty {
                    loadError = "未找到已安装的模型"
                } else {
                    loadError = nil
                    // 如果当前选择的模型不在列表中，选择第一个
                    if !models.contains(configuration.selectedModel) && !models.isEmpty {
                        configuration.selectedModel = models[0]
                    }
                    connectionStatus = .connected
                }
            } catch let error as TranslationError {
                loadError = error.errorDescription
                availableModels = []
                connectionStatus = .failed("连接失败")
            } catch {
                loadError = "加载失败: \(error.localizedDescription)"
                availableModels = []
            }

            isLoadingModels = false
        }
    }

    private func resetPrompt() {
        customPrompt = AppConfiguration.defaultPrompt
        configuration.customPrompt = customPrompt
    }

    private func savePrompt() {
        configuration.customPrompt = customPrompt
    }

    private func normalizeOllamaURL(_ input: String) -> Result<String, URLValidationError> {
        let fallback = TranslationService.defaultURL
        let rawValue = input.isEmpty ? fallback : input

        let withScheme: String
        if rawValue.contains("://") {
            withScheme = rawValue
        } else {
            withScheme = "http://\(rawValue)"
        }

        guard let components = URLComponents(string: withScheme),
              let scheme = components.scheme,
              let host = components.host,
              !scheme.isEmpty,
              !host.isEmpty else {
            return .failure(.invalidFormat)
        }

        return .success(components.string ?? withScheme)
    }
}

// MARK: - Helper Views

struct VariableTag: View {
    let name: String
    let description: String

    var body: some View {
        HStack(spacing: 2) {
            Text(name)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.accentColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(4)
        .help(description)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
        }
    }
}
