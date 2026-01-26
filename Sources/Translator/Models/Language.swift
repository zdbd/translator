import Foundation

/// 支持的翻译语言
enum Language: String, CaseIterable, Identifiable, Codable {
    case chinese = "中文"
    case english = "英语"
    case japanese = "日语"
    case korean = "韩语"
    case french = "法语"
    case german = "德语"
    case spanish = "西班牙语"
    case russian = "俄语"

    var id: String { rawValue }

    /// 语言的本地化显示名称
    var displayName: String { rawValue }

    /// 语言的英文代码（用于 API 或日志）
    var code: String {
        switch self {
        case .chinese: return "zh"
        case .english: return "en"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .french: return "fr"
        case .german: return "de"
        case .spanish: return "es"
        case .russian: return "ru"
        }
    }
}
