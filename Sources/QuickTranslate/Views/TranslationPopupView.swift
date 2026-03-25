import SwiftUI

struct TranslationPopupView: View {
    @ObservedObject var translationService: TranslationService
    let sourceLanguage: Language
    let targetLanguage: Language
    let onDismiss: () -> Void
    let onCopy: () -> Void
    let onReplace: () -> Void

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
            ScrollView {
                if let error = translationService.error {
                    Text(error.errorDescription ?? "Unknown error")
                        .foregroundColor(.red)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if translationService.translatedText.isEmpty && translationService.isTranslating {
                    Text("Translating...")
                        .foregroundColor(.secondary)
                        .font(.body)
                } else {
                    Text(translationService.translatedText)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Bottom bar
            HStack {
                Text("\(translationService.translatedText.count) chars")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onReplace) {
                    Label("Replace", systemImage: "arrow.turn.down.left")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(translationService.translatedText.isEmpty)
                .help("Paste translation into the source app")

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
        .frame(minWidth: 300, maxWidth: 480, minHeight: 100, maxHeight: 500)
    }
}
