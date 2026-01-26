import Foundation

struct TranslationRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool
    let options: ModelOptions?

    init(model: String, prompt: String, stream: Bool = true, options: ModelOptions? = nil) {
        self.model = model
        self.prompt = prompt
        self.stream = stream
        self.options = options
    }
}

struct ModelOptions: Codable {
    let temperature: Double
    let numPredict: Int?

    enum CodingKeys: String, CodingKey {
        case temperature
        case numPredict = "num_predict"
    }
}

struct TranslationResponse: Codable {
    let model: String
    let createdAt: String
    let response: String
    let done: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case response
        case done
    }
}

struct ModelsResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable {
    let name: String
    let modifiedAt: String

    enum CodingKeys: String, CodingKey {
        case name
        case modifiedAt = "modified_at"
    }
}
