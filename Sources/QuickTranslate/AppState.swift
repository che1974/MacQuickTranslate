import SwiftUI

enum DirectionOverride: String, CaseIterable {
    case auto = "Auto"
    case ruToEn = "RU → EN"
    case enToRu = "EN → RU"
}

@MainActor
class AppState: ObservableObject {
    @Published var directionOverride: DirectionOverride = .auto
    let history = TranslationHistory()

    private let translationService: TranslationService
    private let hotkeyManager = HotkeyManager()
    private let clipboardManager = ClipboardManager()
    private let popupManager = PopupWindowManager()

    init(translationService: TranslationService) {
        self.translationService = translationService
    }

    func setup() {
        checkAccessibility()
        registerHotkey()
        Task { await translationService.loadModel() }
    }

    private func registerHotkey() {
        hotkeyManager.onHotkey = { [weak self] in
            Task { @MainActor in
                await self?.handleTranslation()
            }
        }
        hotkeyManager.register()
    }

    private func handleTranslation() async {
        if popupManager.isVisible {
            translationService.cancelTranslation()
            popupManager.dismiss()
            return
        }

        guard let text = await clipboardManager.getSelectedText() else {
            translationService.error = .noTextSelected
            popupManager.show(
                translationService: translationService,
                sourceLanguage: .english,
                targetLanguage: .russian
            )
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                popupManager.dismiss()
            }
            return
        }

        let (sourceLanguage, targetLanguage) = resolveDirection(for: text)

        popupManager.show(
            translationService: translationService,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )

        await translationService.translate(text, from: sourceLanguage, to: targetLanguage)

        if translationService.error == nil && !translationService.translatedText.isEmpty {
            history.add(
                source: text,
                translation: translationService.translatedText,
                from: sourceLanguage,
                to: targetLanguage
            )
        }
    }

    private func resolveDirection(for text: String) -> (Language, Language) {
        switch directionOverride {
        case .auto:
            let source = LanguageDetector.detect(text)
            return (source, source.opposite)
        case .ruToEn:
            return (.russian, .english)
        case .enToRu:
            return (.english, .russian)
        }
    }

    private func checkAccessibility() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }
}
