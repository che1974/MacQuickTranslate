import Foundation
import MLXLMCommon

enum PromptStrategy {
    case translateGemma
    case textPrompt
}

enum TranslationStyle: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case casual = "Casual"
    case formal = "Formal"
    case technical = "Technical"
    case creative = "Creative"

    var id: String { rawValue }

    var promptInstruction: String {
        switch self {
        case .standard:
            return "Output ONLY the translation, nothing else."
        case .casual:
            return "Use casual, conversational tone. Output ONLY the translation, nothing else."
        case .formal:
            return "Use formal, professional tone suitable for business correspondence. Output ONLY the translation, nothing else."
        case .technical:
            return "Preserve all technical terms, abbreviations, and domain-specific vocabulary. Output ONLY the translation, nothing else."
        case .creative:
            return "Use expressive, literary language while preserving the original meaning. Output ONLY the translation, nothing else."
        }
    }
}

struct TranslationModelConfig: Identifiable, Hashable {
    let id: String
    let displayName: String
    let huggingFaceId: String
    let sizeLabel: String
    let promptStrategy: PromptStrategy

    /// Whether this model supports translation styles
    var supportsStyles: Bool { promptStrategy == .textPrompt }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }

    func buildInput(text: String, from source: Language, to target: Language, style: TranslationStyle = .standard) -> UserInput {
        switch promptStrategy {
        case .translateGemma:
            return buildTranslateGemmaInput(text: text, from: source, to: target)
        case .textPrompt:
            return buildTextPromptInput(text: text, from: source, to: target, style: style)
        }
    }

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

    private func buildTextPromptInput(text: String, from source: Language, to target: Language, style: TranslationStyle) -> UserInput {
        let prompt = """
        Translate the following \(source.name) text to \(target.name). \
        \(style.promptInstruction)

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
