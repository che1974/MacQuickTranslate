import Foundation

struct TranslateGemmaModel: TranslationModel {
    let id = "translategemma-4b"
    let displayName = "TranslateGemma 4B"
    let ollamaModel = "translategemma:4b"

    let supportedDirections = [
        TranslationDirection(source: .russian, target: .english),
        TranslationDirection(source: .english, target: .russian),
    ]

    // CRITICAL: Two blank lines before source text — TranslateGemma prompt format requirement.
    func buildRequestBody(text: String, from source: Language, to target: Language) -> [String: Any] {
        let prompt = """
        You are a professional \(source.displayName) (\(source.code)) to \(target.displayName) (\(target.code)) translator. \
        Your goal is to accurately convey the meaning and nuances of the \
        original \(source.displayName) text while adhering to \(target.displayName) grammar, vocabulary, \
        and cultural sensitivities. Produce only the \(target.displayName) translation, \
        without any additional explanations or commentary. \
        Please translate the following \(source.displayName) text into \(target.displayName):


        \(text)
        """

        return [
            "model": ollamaModel,
            "stream": true,
            "messages": [["role": "user", "content": prompt]]
        ]
    }
}
