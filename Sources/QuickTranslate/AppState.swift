import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var targetLanguage: Language = .english
    @Published var autoDetectSource: Bool = true
    @Published var sourceLanguageOverride: Language = .russian
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
                targetLanguage: targetLanguage
            )
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                popupManager.dismiss()
            }
            return
        }

        let source: Language
        if autoDetectSource {
            source = Language.detect(text)
        } else {
            source = sourceLanguageOverride
        }

        // If source == target, flip to a sensible default
        let target = (source == targetLanguage)
            ? (source == .english ? Language.russian : Language.english)
            : targetLanguage

        popupManager.show(
            translationService: translationService,
            sourceLanguage: source,
            targetLanguage: target
        )

        await translationService.translate(text, from: source, to: target)

        if translationService.error == nil && !translationService.translatedText.isEmpty {
            history.add(
                source: text,
                translation: translationService.translatedText,
                from: source,
                to: target
            )
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
