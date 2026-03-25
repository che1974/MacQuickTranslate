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

            // Direction override
            HStack {
                Text("Direction:")
                    .font(.caption)
                Picker("", selection: $appState.directionOverride) {
                    ForEach(DirectionOverride.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
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
                    Button("Clear") {
                        appState.history.clear()
                    }
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
                .frame(maxHeight: 200)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 280)
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
