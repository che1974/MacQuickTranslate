import Foundation

struct LanguageDetector {
    /// Detects language based on Cyrillic character ratio.
    /// If > 30% of alpha chars are Cyrillic, treat as Russian.
    static func detect(_ text: String) -> Language {
        let alphaChars = text.unicodeScalars.filter {
            CharacterSet.letters.contains($0)
        }
        guard !alphaChars.isEmpty else { return .english }

        let cyrillicRange = UnicodeScalar(0x0400)!...UnicodeScalar(0x04FF)!
        let cyrillicCount = alphaChars.filter { cyrillicRange.contains($0) }.count
        let ratio = Double(cyrillicCount) / Double(alphaChars.count)
        return ratio > 0.3 ? .russian : .english
    }
}
