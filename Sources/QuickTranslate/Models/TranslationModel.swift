import Foundation

/// Abstraction for different translation models running via Ollama.
/// Each model has its own prompt format and may parse responses differently.
protocol TranslationModel {
    var id: String { get }
    var displayName: String { get }
    /// Ollama model tag (e.g. "translategemma:4b", "opus-mt-en-ru")
    var ollamaModel: String { get }
    var supportedDirections: [TranslationDirection] { get }

    /// Build the prompt/messages payload for the Ollama API request body.
    func buildRequestBody(text: String, from source: Language, to target: Language) -> [String: Any]

    /// Extract translated text from a single streamed JSON line.
    /// Return nil if the line doesn't contain translation content.
    func parseStreamChunk(_ json: [String: Any]) -> (content: String, done: Bool)?
}

struct TranslationDirection: Equatable {
    let source: Language
    let target: Language

    var label: String { "\(source.displayName) → \(target.displayName)" }
}

// Default implementation for standard Ollama chat API response parsing
extension TranslationModel {
    func parseStreamChunk(_ json: [String: Any]) -> (content: String, done: Bool)? {
        let done = json["done"] as? Bool ?? false
        guard let message = json["message"] as? [String: Any],
              let content = message["content"] as? String else {
            return done ? ("", true) : nil
        }
        return (content, done)
    }
}
