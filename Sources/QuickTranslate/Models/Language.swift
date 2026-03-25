import Foundation

struct Language: Identifiable, Hashable {
    let id: String        // BCP-47 code
    let name: String      // English display name
    let nativeName: String // Name in the language itself
    let isCyrillic: Bool

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }

    var displayName: String { name }
    var code: String { id }
    var bcp47Code: String { id }
}

extension Language {
    static let russian   = Language(id: "ru",    name: "Russian",    nativeName: "Русский",     isCyrillic: true)
    static let english   = Language(id: "en",    name: "English",    nativeName: "English",     isCyrillic: false)
    static let german    = Language(id: "de",    name: "German",     nativeName: "Deutsch",     isCyrillic: false)
    static let french    = Language(id: "fr",    name: "French",     nativeName: "Français",    isCyrillic: false)
    static let spanish   = Language(id: "es",    name: "Spanish",    nativeName: "Español",     isCyrillic: false)
    static let italian   = Language(id: "it",    name: "Italian",    nativeName: "Italiano",    isCyrillic: false)
    static let portuguese = Language(id: "pt",   name: "Portuguese", nativeName: "Português",   isCyrillic: false)
    static let chinese   = Language(id: "zh",    name: "Chinese",    nativeName: "中文",         isCyrillic: false)
    static let japanese  = Language(id: "ja",    name: "Japanese",   nativeName: "日本語",       isCyrillic: false)
    static let korean    = Language(id: "ko",    name: "Korean",     nativeName: "한국어",       isCyrillic: false)
    static let turkish   = Language(id: "tr",    name: "Turkish",    nativeName: "Türkçe",      isCyrillic: false)
    static let arabic    = Language(id: "ar",    name: "Arabic",     nativeName: "العربية",      isCyrillic: false)
    static let ukrainian = Language(id: "uk",    name: "Ukrainian",  nativeName: "Українська",  isCyrillic: true)
    static let polish    = Language(id: "pl",    name: "Polish",     nativeName: "Polski",      isCyrillic: false)
    static let dutch     = Language(id: "nl",    name: "Dutch",      nativeName: "Nederlands",  isCyrillic: false)
    static let czech     = Language(id: "cs",    name: "Czech",      nativeName: "Čeština",     isCyrillic: false)
    static let hindi     = Language(id: "hi",    name: "Hindi",      nativeName: "हिन्दी",        isCyrillic: false)

    /// All supported languages, sorted by name
    static let allLanguages: [Language] = [
        .english, .russian, .german, .french, .spanish, .italian, .portuguese,
        .chinese, .japanese, .korean, .turkish, .arabic, .ukrainian,
        .polish, .dutch, .czech, .hindi,
    ]

    /// Auto-detect source language from text
    static func detect(_ text: String) -> Language {
        let alphaChars = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard !alphaChars.isEmpty else { return .english }

        let cyrillicRange = UnicodeScalar(0x0400)!...UnicodeScalar(0x04FF)!
        let cyrillicCount = alphaChars.filter { cyrillicRange.contains($0) }.count
        let ratio = Double(cyrillicCount) / Double(alphaChars.count)

        if ratio > 0.3 {
            // Distinguish Russian from Ukrainian by specific chars
            let ukrainianChars = text.unicodeScalars.filter {
                // і, ї, є, ґ — Ukrainian-specific
                [0x0456, 0x0457, 0x0454, 0x0491].contains($0.value)
            }
            return ukrainianChars.count > 0 ? .ukrainian : .russian
        }

        // CJK detection
        let cjkCount = alphaChars.filter { $0.value >= 0x4E00 && $0.value <= 0x9FFF }.count
        if Double(cjkCount) / Double(alphaChars.count) > 0.3 { return .chinese }

        let hiragana = alphaChars.filter { $0.value >= 0x3040 && $0.value <= 0x309F }.count
        let katakana = alphaChars.filter { $0.value >= 0x30A0 && $0.value <= 0x30FF }.count
        if hiragana + katakana > 0 { return .japanese }

        let hangul = alphaChars.filter { $0.value >= 0xAC00 && $0.value <= 0xD7AF }.count
        if Double(hangul) / Double(alphaChars.count) > 0.3 { return .korean }

        let arabic = alphaChars.filter { $0.value >= 0x0600 && $0.value <= 0x06FF }.count
        if Double(arabic) / Double(alphaChars.count) > 0.3 { return .arabic }

        let devanagari = alphaChars.filter { $0.value >= 0x0900 && $0.value <= 0x097F }.count
        if Double(devanagari) / Double(alphaChars.count) > 0.3 { return .hindi }

        return .english
    }
}
