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
    private var unloadTimer: Task<Void, Never>?

    /// Minutes of inactivity before unloading the model
    private let unloadDelayMinutes: UInt64 = 5

    init(translationService: TranslationService) {
        self.translationService = translationService
    }

    func setup() {
        checkAccessibility()
        registerHotkey()
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

        let target = (source == targetLanguage)
            ? (source == .english ? Language.russian : Language.english)
            : targetLanguage

        popupManager.show(
            translationService: translationService,
            sourceLanguage: source,
            targetLanguage: target
        )

        // Load model on demand if not ready
        if translationService.modelState != .ready {
            await translationService.loadModel()
        }

        await translationService.translate(text, from: source, to: target)

        if translationService.error == nil && !translationService.translatedText.isEmpty {
            history.add(
                source: text,
                translation: translationService.translatedText,
                from: source,
                to: target
            )
        }

        // Reset unload timer after each translation
        scheduleUnload()
    }

    private func scheduleUnload() {
        unloadTimer?.cancel()
        unloadTimer = Task {
            try? await Task.sleep(nanoseconds: unloadDelayMinutes * 60 * 1_000_000_000)
            guard !Task.isCancelled else { return }
            translationService.unloadModel()
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
