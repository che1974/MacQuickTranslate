import Foundation

struct TranslationRecord: Identifiable {
    let id = UUID()
    let sourceText: String
    let translatedText: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let timestamp: Date

    var sourceSnippet: String {
        if sourceText.count <= 50 { return sourceText }
        return String(sourceText.prefix(47)) + "..."
    }

    var directionLabel: String {
        "\(sourceLanguage.displayName) → \(targetLanguage.displayName)"
    }
}

class TranslationHistory: ObservableObject {
    @Published private(set) var records: [TranslationRecord] = []
    private let maxRecords = 10

    func add(source: String, translation: String, from: Language, to: Language) {
        let record = TranslationRecord(
            sourceText: source,
            translatedText: translation,
            sourceLanguage: from,
            targetLanguage: to,
            timestamp: Date()
        )
        records.insert(record, at: 0)
        if records.count > maxRecords {
            records.removeLast()
        }
    }

    func clear() {
        records.removeAll()
    }
}
