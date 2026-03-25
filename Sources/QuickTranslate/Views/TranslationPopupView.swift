import SwiftUI

struct TranslationPopupView: View {
    @ObservedObject var translationService: TranslationService
    let sourceLanguage: Language
    let targetLanguage: Language
    let onDismiss: () -> Void
    let onCopy: () -> Void
    let onReplace: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top bar
            HStack(spacing: 10) {
                // Language pill
                HStack(spacing: 6) {
                    Text("\(targetLanguage.displayName)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())

                Spacer()

                if translationService.isTranslating {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Translation text area
            VStack(alignment: .leading, spacing: 0) {
                if let warning = translationService.warning {
                    Text(warning)
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                        .padding(.bottom, 6)
                }

                ScrollView {
                    if let error = translationService.error {
                        Text(error.errorDescription ?? "Unknown error")
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if translationService.translatedText.isEmpty && translationService.isTranslating {
                        Text("Translating...")
                            .foregroundColor(.white.opacity(0.4))
                            .font(.system(size: 16))
                    } else {
                        Text(translationService.translatedText)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 14)

            // Bottom bar with buttons
            HStack(spacing: 8) {
                Button(action: onCopy) {
                    HStack(spacing: 5) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                        Text("Copy")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(translationService.translatedText.isEmpty)

                Spacer()

                Button(action: onReplace) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.turn.down.left")
                            .font(.system(size: 11))
                        Text("Replace")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor)
                    )
                }
                .buttonStyle(.plain)
                .disabled(translationService.translatedText.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 14)
        }
        .frame(minWidth: 360, maxWidth: 480, minHeight: 120, maxHeight: 500)
    }
}
