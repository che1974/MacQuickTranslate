import Foundation
import MLXLMCommon

enum PromptStrategy {
    /// TranslateGemma structured message format with source/target lang codes
    case translateGemma
    /// General-purpose LLM with text prompt
    case textPrompt
}

struct TranslationModelConfig: Identifiable, Hashable {
    let id: String
    let displayName: String
    let huggingFaceId: String
    let sizeLabel: String
    let promptStrategy: PromptStrategy

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }

    func buildInput(text: String, from source: Language, to target: Language) -> UserInput {
        switch promptStrategy {
        case .translateGemma:
            return buildTranslateGemmaInput(text: text, from: source, to: target)
        case .textPrompt:
            return buildTextPromptInput(text: text, from: source, to: target)
        }
    }

    /// TranslateGemma structured message format
    private func buildTranslateGemmaInput(text: String, from source: Language, to target: Language) -> UserInput {
        let messages: [Message] = [
            [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "source_lang_code": source.bcp47Code,
                        "target_lang_code": target.bcp47Code,
                        "text": text,
                    ] as [String: String]
                ] as [[String: String]]
            ]
        ]
        return UserInput(messages: messages)
    }

    /// General LLM text prompt for translation
    private func buildTextPromptInput(text: String, from source: Language, to target: Language) -> UserInput {
        let prompt = """
        Translate the following \(source.name) text to \(target.name). \
        Output ONLY the translation, nothing else.

        \(text)
        """
        return UserInput(prompt: prompt)
    }
}

extension TranslationModelConfig {
    static let gemma2B = TranslationModelConfig(
        id: "gemma-2-2b",
        displayName: "Gemma 2 2B",
        huggingFaceId: "mlx-community/gemma-2-2b-it-4bit",
        sizeLabel: "~1.5 GB",
        promptStrategy: .textPrompt
    )

    static let translateGemma4B = TranslationModelConfig(
        id: "translategemma-4b",
        displayName: "TranslateGemma 4B",
        huggingFaceId: "mlx-community/translategemma-4b-it-4bit",
        sizeLabel: "~2.2 GB",
        promptStrategy: .translateGemma
    )

    static let translateGemma4B8bit = TranslationModelConfig(
        id: "translategemma-4b-8bit",
        displayName: "TranslateGemma 4B (8-bit)",
        huggingFaceId: "mlx-community/translategemma-4b-it-8bit",
        sizeLabel: "~4.4 GB",
        promptStrategy: .translateGemma
    )

    static let translateGemma12B = TranslationModelConfig(
        id: "translategemma-12b",
        displayName: "TranslateGemma 12B",
        huggingFaceId: "mlx-community/translategemma-12b-it-4bit",
        sizeLabel: "~7 GB",
        promptStrategy: .translateGemma
    )

    static let allModels: [TranslationModelConfig] = [
        .gemma2B,
        .translateGemma4B,
        .translateGemma4B8bit,
        .translateGemma12B,
    ]
}
