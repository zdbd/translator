import Foundation

/// Ollama 翻译服务 - 使用 Actor 模型确保线程安全
actor TranslationService {
    static let shared = TranslationService()

    /// 默认 Ollama 服务地址
    static let defaultURL = "http://localhost:11434"

    /// 共享的 URLSession 实例
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    /// 获取 Ollama 服务基础 URL
    private nonisolated func getBaseURL() -> URL {
        let urlString = UserDefaults.standard.string(forKey: "ollamaURL") ?? Self.defaultURL
        guard let url = URL(string: urlString), !urlString.isEmpty else {
            return URL(string: Self.defaultURL)!
        }
        return url
    }

    /// 执行翻译请求，返回流式响应
    /// - Parameters:
    ///   - model: 使用的模型名称
    ///   - prompt: 翻译提示词
    /// - Returns: 异步字符串流
    func translate(model: String, prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        let url = getBaseURL().appending(path: "/api/generate")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let translationRequest = TranslationRequest(
            model: model,
            prompt: prompt,
            stream: true,
            options: ModelOptions(temperature: 0.3, numPredict: 2000)
        )

        request.httpBody = try JSONEncoder().encode(translationRequest)

        let session = self.session
        let finalRequest = request

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await session.bytes(for: finalRequest)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: TranslationError.invalidResponse)
                        return
                    }

                    switch httpResponse.statusCode {
                    case 200:
                        break
                    case 404:
                        continuation.finish(throwing: TranslationError.modelNotFound)
                        return
                    case 500...599:
                        continuation.finish(throwing: TranslationError.serverError(httpResponse.statusCode))
                        return
                    default:
                        continuation.finish(throwing: TranslationError.httpError(httpResponse.statusCode))
                        return
                    }

                    for try await line in bytes.lines {
                        // 检查任务是否被取消
                        try Task.checkCancellation()

                        if let data = line.data(using: .utf8),
                           let translationResponse = try? JSONDecoder().decode(TranslationResponse.self, from: data) {
                            continuation.yield(translationResponse.response)

                            if translationResponse.done {
                                continuation.finish()
                                return
                            }
                        }
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: CancellationError())
                } catch let urlError as URLError {
                    continuation.finish(throwing: TranslationError.from(urlError: urlError))
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    /// 获取可用模型列表
    func getAvailableModels() async throws -> [String] {
        let url = getBaseURL().appending(path: "/api/tags")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranslationError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw TranslationError.httpError(httpResponse.statusCode)
            }

            let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
            return modelsResponse.models.map { $0.name }
        } catch let urlError as URLError {
            throw TranslationError.from(urlError: urlError)
        }
    }
}

// MARK: - 错误类型

enum TranslationError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case serverError(Int)
    case connectionRefused
    case connectionTimeout
    case networkUnavailable
    case modelNotFound

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "无效的服务器响应"
        case .httpError(let code):
            return "HTTP 错误: \(code)"
        case .serverError(let code):
            return "服务器内部错误 (\(code))，请检查 Ollama 日志"
        case .connectionRefused:
            return "连接被拒绝，请确保 Ollama 服务已启动"
        case .connectionTimeout:
            return "连接超时，请检查服务地址是否正确"
        case .networkUnavailable:
            return "网络不可用，请检查网络连接"
        case .modelNotFound:
            return "未找到指定的模型，请先下载模型"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .connectionRefused:
            return "运行 'ollama serve' 启动服务"
        case .modelNotFound:
            return "运行 'ollama pull <模型名>' 下载模型"
        case .connectionTimeout:
            return "检查 Ollama 服务地址设置"
        default:
            return nil
        }
    }

    /// 从 URLError 转换为更友好的错误类型
    static func from(urlError: URLError) -> TranslationError {
        switch urlError.code {
        case .cannotConnectToHost, .cannotFindHost:
            return .connectionRefused
        case .timedOut:
            return .connectionTimeout
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkUnavailable
        default:
            return .httpError(urlError.errorCode)
        }
    }
}
