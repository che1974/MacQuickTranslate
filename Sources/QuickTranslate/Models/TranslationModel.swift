import Foundation

/// Represents a translation model that can be loaded and run via MLX.
struct TranslationModelConfig: Identifiable, Hashable {
    let id: String
    let displayName: String
    /// HuggingFace model ID for MLX (e.g. "mlx-community/translategemma-4b-it-4bit")
    let huggingFaceId: String
    /// Disk size estimate for display purposes
    let sizeLabel: String

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }

    // CRITICAL: Two blank lines before source text — TranslateGemma prompt format requirement.
    func buildPrompt(text: String, from source: Language, to target: Language) -> String {
        """
        You are a professional \(source.displayName) (\(source.code)) to \(target.displayName) (\(target.code)) translator. \
        Your goal is to accurately convey the meaning and nuances of the \
        original \(source.displayName) text while adhering to \(target.displayName) grammar, vocabulary, \
        and cultural sensitivities. Produce only the \(target.displayName) translation, \
        without any additional explanations or commentary. \
        Please translate the following \(source.displayName) text into \(target.displayName):


        \(text)
        """
    }
}

extension TranslationModelConfig {
    static let translateGemma4B = TranslationModelConfig(
        id: "translategemma-4b",
        displayName: "TranslateGemma 4B",
        huggingFaceId: "mlx-community/translategemma-4b-it-4bit",
        sizeLabel: "~2.2 GB"
    )

    static let translateGemma4B8bit = TranslationModelConfig(
        id: "translategemma-4b-8bit",
        displayName: "TranslateGemma 4B (8-bit)",
        huggingFaceId: "mlx-community/translategemma-4b-it-8bit",
        sizeLabel: "~4.4 GB"
    )

    static let allModels: [TranslationModelConfig] = [
        .translateGemma4B,
        .translateGemma4B8bit,
    ]
}
