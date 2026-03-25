import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var translationService: TranslationService

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Model status
            ModelStatusView(state: translationService.modelState)

            Divider()

            // Model picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Model")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Model", selection: Binding(
                    get: { translationService.currentModelConfig },
                    set: { newConfig in
                        Task { await translationService.switchModel(newConfig) }
                    }
                )) {
                    ForEach(TranslationModelConfig.allModels) { model in
                        Text("\(model.displayName) (\(model.sizeLabel))").tag(model)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .disabled(translationService.isTranslating)
            }

            // Target language
            VStack(alignment: .leading, spacing: 4) {
                Text("Translate to")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Target", selection: $appState.targetLanguage) {
                    ForEach(Language.allLanguages) { lang in
                        Text("\(lang.nativeName) (\(lang.name))").tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            // Source language
            HStack {
                Toggle("Auto-detect source", isOn: $appState.autoDetectSource)
                    .font(.caption)
                    .toggleStyle(.checkbox)
            }

            if !appState.autoDetectSource {
                Picker("Source", selection: $appState.sourceLanguageOverride) {
                    ForEach(Language.allLanguages) { lang in
                        Text("\(lang.nativeName)").tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            // Style picker (only for text prompt models)
            if translationService.currentModelConfig.supportsStyles {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Style")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Style", selection: $appState.translationStyle) {
                        ForEach(TranslationStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }

            Text("Hotkey: ⌘⇧T")
                .font(.caption)
                .foregroundColor(.secondary)

            // Translation history
            if !appState.history.records.isEmpty {
                Divider()

                HStack {
                    Text("Recent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Clear") { appState.history.clear() }
                        .font(.caption2)
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(appState.history.records) { record in
                            HistoryRow(record: record)
                        }
                    }
                }
                .frame(maxHeight: 150)
            }

            Divider()

            // Model management
            DisclosureGroup("Model Storage") {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(TranslationModelConfig.allModels) { model in
                        ModelCacheRow(model: model, translationService: translationService)
                    }
                }
            }
            .font(.caption)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 300)
    }
}

struct ModelCacheRow: View {
    let model: TranslationModelConfig
    @ObservedObject var translationService: TranslationService
    @State private var cacheSize: Int64 = 0

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(model.displayName)
                    .font(.caption)
                Text(TranslationService.formatBytes(cacheSize))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if cacheSize > 0 {
                Button("Delete") {
                    translationService.deleteModelCache(for: model)
                    refreshSize()
                }
                .font(.caption2)
                .foregroundColor(.red)
                .buttonStyle(.plain)
            }
        }
        .onAppear { refreshSize() }
    }

    private func refreshSize() {
        cacheSize = TranslationService.cacheSize(for: model)
    }
}

struct ModelStatusView: View {
    let state: ModelState

    var body: some View {
        HStack(spacing: 6) {
            switch state {
            case .notLoaded:
                Circle().fill(Color.gray).frame(width: 8, height: 8)
                Text("Model not loaded")
                    .font(.callout)
            case .downloading(let progress):
                ProgressView(value: progress)
                    .frame(width: 60)
                Text("Downloading \(Int(progress * 100))%")
                    .font(.callout)
            case .loading:
                ProgressView()
                    .controlSize(.small)
                Text("Loading model...")
                    .font(.callout)
            case .ready:
                Circle().fill(Color.green).frame(width: 8, height: 8)
                Text("Model ready")
                    .font(.callout)
            case .error(let msg):
                Circle().fill(Color.red).frame(width: 8, height: 8)
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(2)
            }
        }
    }
}

struct HistoryRow: View {
    let record: TranslationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(record.directionLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(record.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text(record.sourceSnippet)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}
