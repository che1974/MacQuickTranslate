import Foundation

enum TranslationError: LocalizedError {
    case connectionRefused
    case modelNotFound(String)
    case timeout
    case emptyResponse
    case noTextSelected
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .connectionRefused:
            return "Ollama is not running. Start it with: ollama serve"
        case .modelNotFound(let model):
            return "Model not installed. Run: ollama pull \(model)"
        case .timeout:
            return "Translation timed out. Text may be too long."
        case .emptyResponse:
            return "No translation received. Try again."
        case .noTextSelected:
            return "No text selected"
        case .unknown(let message):
            return message
        }
    }
}
