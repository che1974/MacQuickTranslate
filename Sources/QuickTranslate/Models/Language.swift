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
    // Slavic
    static let russian    = Language(id: "ru", name: "Russian",     nativeName: "Русский",      isCyrillic: true)
    static let ukrainian  = Language(id: "uk", name: "Ukrainian",   nativeName: "Українська",   isCyrillic: true)
    static let polish     = Language(id: "pl", name: "Polish",      nativeName: "Polski",       isCyrillic: false)
    static let czech      = Language(id: "cs", name: "Czech",       nativeName: "Čeština",      isCyrillic: false)
    static let slovak     = Language(id: "sk", name: "Slovak",      nativeName: "Slovenčina",   isCyrillic: false)
    static let slovenian  = Language(id: "sl", name: "Slovenian",   nativeName: "Slovenščina",  isCyrillic: false)
    static let bulgarian  = Language(id: "bg", name: "Bulgarian",   nativeName: "Български",    isCyrillic: true)
    static let macedonian = Language(id: "mk", name: "Macedonian",  nativeName: "Македонски",   isCyrillic: true)
    static let serbian    = Language(id: "sr", name: "Serbian",     nativeName: "Српски",       isCyrillic: true)
    static let croatian   = Language(id: "hr", name: "Croatian",    nativeName: "Hrvatski",     isCyrillic: false)
    static let bosnian    = Language(id: "bs", name: "Bosnian",     nativeName: "Bosanski",     isCyrillic: false)

    // Germanic
    static let english    = Language(id: "en", name: "English",     nativeName: "English",      isCyrillic: false)
    static let german     = Language(id: "de", name: "German",      nativeName: "Deutsch",      isCyrillic: false)
    static let dutch      = Language(id: "nl", name: "Dutch",       nativeName: "Nederlands",   isCyrillic: false)
    static let swedish    = Language(id: "sv", name: "Swedish",     nativeName: "Svenska",      isCyrillic: false)
    static let norwegian  = Language(id: "no", name: "Norwegian",   nativeName: "Norsk",        isCyrillic: false)
    static let danish     = Language(id: "da", name: "Danish",      nativeName: "Dansk",        isCyrillic: false)
    static let icelandic  = Language(id: "is", name: "Icelandic",   nativeName: "Íslenska",     isCyrillic: false)

    // Romance
    static let french     = Language(id: "fr", name: "French",      nativeName: "Français",     isCyrillic: false)
    static let spanish    = Language(id: "es", name: "Spanish",     nativeName: "Español",      isCyrillic: false)
    static let italian    = Language(id: "it", name: "Italian",     nativeName: "Italiano",     isCyrillic: false)
    static let portuguese = Language(id: "pt", name: "Portuguese",  nativeName: "Português",    isCyrillic: false)
    static let romanian   = Language(id: "ro", name: "Romanian",    nativeName: "Română",       isCyrillic: false)
    static let catalan    = Language(id: "ca", name: "Catalan",     nativeName: "Català",       isCyrillic: false)
    static let galician   = Language(id: "gl", name: "Galician",    nativeName: "Galego",       isCyrillic: false)

    // Baltic
    static let latvian    = Language(id: "lv", name: "Latvian",     nativeName: "Latviešu",     isCyrillic: false)
    static let lithuanian = Language(id: "lt", name: "Lithuanian",  nativeName: "Lietuvių",     isCyrillic: false)

    // Finno-Ugric
    static let finnish    = Language(id: "fi", name: "Finnish",     nativeName: "Suomi",        isCyrillic: false)
    static let estonian   = Language(id: "et", name: "Estonian",    nativeName: "Eesti",        isCyrillic: false)
    static let hungarian  = Language(id: "hu", name: "Hungarian",   nativeName: "Magyar",       isCyrillic: false)

    // Celtic
    static let irish      = Language(id: "ga", name: "Irish",       nativeName: "Gaeilge",      isCyrillic: false)
    static let welsh      = Language(id: "cy", name: "Welsh",       nativeName: "Cymraeg",      isCyrillic: false)

    // Other European
    static let greek      = Language(id: "el", name: "Greek",       nativeName: "Ελληνικά",     isCyrillic: false)
    static let turkish    = Language(id: "tr", name: "Turkish",     nativeName: "Türkçe",       isCyrillic: false)
    static let albanian   = Language(id: "sq", name: "Albanian",    nativeName: "Shqip",        isCyrillic: false)
    static let maltese    = Language(id: "mt", name: "Maltese",     nativeName: "Malti",        isCyrillic: false)
    static let basque     = Language(id: "eu", name: "Basque",      nativeName: "Euskara",      isCyrillic: false)

    static let allLanguages: [Language] = [
        // Top: most common
        .english, .russian, .ukrainian, .german, .french, .spanish,
        // Western Europe
        .italian, .portuguese, .dutch, .catalan, .galician, .basque,
        // Northern Europe
        .swedish, .norwegian, .danish, .finnish, .icelandic, .estonian, .latvian, .lithuanian,
        // Central Europe
        .polish, .czech, .slovak, .hungarian, .slovenian, .croatian, .bosnian, .romanian,
        // Southeast Europe
        .greek, .bulgarian, .serbian, .macedonian, .albanian, .turkish, .maltese,
        // Celtic
        .irish, .welsh,
    ]

    /// Auto-detect source language from text
    static func detect(_ text: String) -> Language {
        let alphaChars = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard !alphaChars.isEmpty else { return .english }

        let cyrillicRange = UnicodeScalar(0x0400)!...UnicodeScalar(0x04FF)!
        let cyrillicCount = alphaChars.filter { cyrillicRange.contains($0) }.count
        let ratio = Double(cyrillicCount) / Double(alphaChars.count)

        if ratio > 0.3 {
            // Ukrainian-specific: і, ї, є, ґ
            let ukChars = text.unicodeScalars.filter { [0x0456, 0x0457, 0x0454, 0x0491].contains($0.value) }
            if ukChars.count > 0 { return .ukrainian }
            // Bulgarian-specific: ъ (very frequent), щ usage patterns differ but hard to detect
            // Default to Russian for Cyrillic
            return .russian
        }

        // Greek
        let greekCount = alphaChars.filter { ($0.value >= 0x0370 && $0.value <= 0x03FF) || ($0.value >= 0x1F00 && $0.value <= 0x1FFF) }.count
        if Double(greekCount) / Double(alphaChars.count) > 0.3 { return .greek }

        return .english
    }
}
