import Foundation

/// Helsinki-NLP Opus-MT models via Ollama.
/// Opus-MT is a dedicated neural machine translation model — no chat prompt needed,
/// just pass the source text directly. The model outputs the translation.
struct OpusMTModel: TranslationModel {
    let id = "opus-mt"
    let displayName = "Opus-MT"
    /// Ollama model tag — user needs to pull the appropriate model.
    /// Opus-MT uses separate models per direction:
    ///   ollama pull opus-mt-ru-en
    ///   ollama pull opus-mt-en-ru
    /// We select the right one based on direction.
    var ollamaModel: String { "opus-mt" }

    let supportedDirections = [
        TranslationDirection(source: .russian, target: .english),
        TranslationDirection(source: .english, target: .russian),
    ]

    func buildRequestBody(text: String, from source: Language, to target: Language) -> [String: Any] {
        // Opus-MT uses direction-specific model tags
        let modelTag = "opus-mt-\(source.code)-\(target.code)"

        return [
            "model": modelTag,
            "stream": true,
            "messages": [["role": "user", "content": text]]
        ]
    }
}
