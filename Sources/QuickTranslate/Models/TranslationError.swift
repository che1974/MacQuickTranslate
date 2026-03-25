import Foundation

enum TranslationError: LocalizedError {
    case modelNotLoaded
    case emptyResponse
    case noTextSelected
    case timeout
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Model is not loaded yet. Please wait for download to complete."
        case .emptyResponse:
            return "No translation received. Try again."
        case .noTextSelected:
            return "No text selected"
        case .timeout:
            return "Translation timed out. Text may be too long."
        case .unknown(let message):
            return message
        }
    }
}
