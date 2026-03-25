import Foundation

enum Language: String {
    case russian = "ru"
    case english = "en"

    var displayName: String {
        switch self {
        case .russian: return "Russian"
        case .english: return "English"
        }
    }

    var code: String {
        rawValue
    }

    var opposite: Language {
        switch self {
        case .russian: return .english
        case .english: return .russian
        }
    }
}
