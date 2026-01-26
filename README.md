# Translator

[中文版 (Chinese Version)](./README_CN.md)

A minimalist, private, and efficient native macOS translation application built with SwiftUI, powered by local Ollama models.

## 🌟 Key Features

- **Private & Secure**: Runs entirely on local Ollama models. No data is sent to the cloud, ensuring total privacy.
- **Streaming Response**: Real-time streaming output for a smooth and responsive translation experience.
- **Multi-Model Support**: Supports all available Ollama models (e.g., llama3, mistral, gemma, etc.) with easy switching.
- **Customizable Prompts**: Define your own translation prompts to control style, tone, and terminology.
- **Native Experience**: Deep integration with macOS aesthetics, featuring glassmorphism effects and a modern icon design (Bridge of Languages).
- **Thread-Safe**: Rebuilt using the Swift Actor model to ensure stability and performance.

## 🛠 Prerequisites

1. **macOS 14.0 (Sonoma) or higher**
2. **Xcode 15.0 or higher**
3. **Ollama**: Required to run local large language models.

### Installation & Setup for Ollama

```bash
# Install via Homebrew
brew install ollama

# Pull a model (Llama 3 is recommended)
ollama pull llama3
```

## 🚀 Build & Run

### Using Xcode (Recommended)

```bash
open Translator.xcodeproj
# Click the Run button or press Cmd + R
```

### Using Command Line

```bash
# Generate project if using XcodeGen
xcodegen generate

# Build and run
xcodebuild -project Translator.xcodeproj -scheme Translator -configuration Debug build
```

## 📖 Usage Guide

### 1. Model & Connection Config

- Open the app and go to **Settings** (`Cmd + ,`).
- Enter your Ollama server URL (default is `http://localhost:11434`).
- Click refresh and select your downloaded model from the list.

### 2. Translation Parameters

- Configure global translation prompts in Settings (e.g., specify academic or colloquial style).

### 3. Main Interface

- **Source Text**: Enter text in the left panel.
- **Language Switch**: Click the ⇄ button to swap source and target languages.
- **Streaming Output**: Witness the translation render in real-time on the right.

## 📂 Project Structure

```text
Translator/
├── Sources/
│   └── Translator/
│       ├── App/
│       │   └── TranslatorApp.swift       # Application Entry
│       ├── Models/
│       │   ├── AppConfiguration.swift    # Persistence & Config
│       │   ├── Language.swift            # Language Definitions
│       │   └── OllamaModels.swift        # API Data Structures
│       ├── Services/
│       │   └── TranslationService.swift  # Actor-driven Ollama Client
│       ├── ViewModels/
│       │   └── TranslationViewModel.swift # Logic & State Management
│       ├── Views/
│       │   ├── ContentView.swift         # Main Translation Workspace
│       │   └── SettingsView.swift        # Detailed Settings Panel
│       └── Resources/
│           └── Assets.xcassets/          # App Icons & Resources
├── Tests/                                # Unit Tests
├── project.yml                           # XcodeGen Specification
└── .gitignore                            # Refined Git Ignore Rules
```

## 🏗 Technology Stack

- **Framework**: SwiftUI
- **Concurrency**: Swift Concurrency (async/await, Actor, AsyncThrowingStream)
- **Networking**: URLSession (Streaming data fetch)
- **Build Tool**: XcodeGen
- **Localization**: Ready for multi-language expansion

## ⚖️ License

[MIT License](LICENSE)
