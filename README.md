# Translator

基于本地 Ollama 模型的 macOS 原生多语言翻译应用，采用 SwiftUI 构建。提供极简、私密且高效的翻译体验。

## 🌟 功能特点

- **私密可靠**：完全基于本地 Ollama 模型运行，无需将 data 上传至云端，确保隐私安全。
- **流式响应**：实时流式输出翻译结果，响应迅速且体验丝滑。
- **多模型支持**：支持所有 Ollama 可用的模型（如 llama3, mistral, gemma 等），可自由切换。
- **提示词定制**：支持自定义翻译提示词（Prompt），精准控制翻译风格和规范。
- **原生体验**：深度集成 macOS 风格，支持快捷键调整、毛玻璃效果及现代化的图标设计（方案 A：语言之桥）。
- **线程安全**：基于 Swift Actor 模型重构，确保高并发环境下的业务逻辑稳定性。

## 🛠 前置要求

1. **macOS 14.0 (Sonoma) 或更高版本**
2. **Xcode 15.0 或更高版本**
3. **Ollama**：用于运行本地大语言模型。

### 安装与配置 Ollama

```bash
# 使用 Homebrew 安装
brew install ollama

# 下载模型（推荐 Llama 3 或类似模型）
ollama pull llama3
```

## 🚀 构建和运行

### 使用 Xcode (推荐)

```bash
open Translator.xcodeproj
# 点击运行按钮或按 Cmd + R
```

### 使用命令行

```bash
# 如果是基于 XcodeGen 项目，先生成工程
xcodegen generate

# 构建并运行
xcodebuild -project Translator.xcodeproj -scheme Translator -configuration Debug build
```

## 📖 使用指南

### 1. 模型与连接配置

- 启动应用后进入「设置」(`Cmd + ,`)。
- 输入您的 Ollama 服务地址（默认为 `http://localhost:11434`）。
- 点击刷新列表并选择您已下载的模型。

### 2. 翻译参数

- 在设置中可以配置全局翻译 Prompt，例如指定翻译为学术风格或口语风格。

### 3. 主界面操作

- **源文本**：左侧输入原文。
- **语言切换**：点击中间的 ⇄ 按钮可快速互换语言。
- **流式输出**：点击翻译后，右侧会实时呈现翻译内容。

## 📂 项目结构

```text
Translator/
├── Sources/
│   └── Translator/
│       ├── App/
│       │   └── TranslatorApp.swift       # 应用入口
│       ├── Models/
│       │   ├── AppConfiguration.swift    # 状态持久化与应用配置
│       │   ├── Language.swift            # 语言定义与映射
│       │   └── OllamaModels.swift        # API 数据交互结构体
│       ├── Services/
│       │   └── TranslationService.swift  # Actor 驱动的 Ollama 客户端
│       ├── ViewModels/
│       │   └── TranslationViewModel.swift # 业务逻辑与状态管理
│       ├── Views/
│       │   ├── ContentView.swift         # 主翻译工作区
│       │   └── SettingsView.swift        # 深度定制的设置面板
│       └── Resources/
│           └── Assets.xcassets/          # 应用标（现代几何风格）及资源
├── Tests/                                # 单元测试模块
├── project.yml                           # XcodeGen 描述文件
└── .gitignore                            # 精细化的 git 过滤规则
```

## 🏗 技术栈

- **框架**: SwiftUI
- **异步处理**: Swift Concurrency (async/await, Actor, AsyncThrowingStream)
- **网络层**: URLSession (流式数据抓取)
- **构建工具**: XcodeGen
- **本地化**: 支持多语言扩展

## ⚖️ 许可证

[MIT License](LICENSE)
