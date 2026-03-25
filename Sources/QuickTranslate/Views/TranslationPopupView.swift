import SwiftUI

struct TranslationPopupView: View {
    @ObservedObject var translationService: TranslationService
    let sourceLanguage: Language
    let targetLanguage: Language
    let onDismiss: () -> Void
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top bar: direction + loading
            HStack {
                Text("\(sourceLanguage.displayName) → \(targetLanguage.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if translationService.isTranslating {
                    ProgressView()
                        .controlSize(.small)
                }
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Warning for long text
            if let warning = translationService.warning {
                Text(warning)
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            // Body: translated text or error
            if let error = translationService.error {
                Text(error.errorDescription ?? "Unknown error")
                    .foregroundColor(.red)
                    .font(.body)
            } else if translationService.translatedText.isEmpty && translationService.isTranslating {
                Text("Translating...")
                    .foregroundColor(.secondary)
                    .font(.body)
            } else {
                Text(translationService.translatedText)
                    .font(.body)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 4)

            // Bottom bar: copy button + char count
            HStack {
                Text("\(translationService.translatedText.count) chars")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onCopy) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(translationService.translatedText.isEmpty)
            }
        }
        .padding(12)
        .frame(minWidth: 300, maxWidth: 480, minHeight: 100, maxHeight: 320)
    }
}
