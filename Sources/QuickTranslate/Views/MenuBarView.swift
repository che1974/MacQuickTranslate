import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var translationService: TranslationService

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Connection status
            HStack(spacing: 6) {
                Circle()
                    .fill(appState.isOllamaConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(appState.isOllamaConnected ? "Ollama connected" : "Ollama not running")
                    .font(.callout)
            }

            Divider()

            // Model picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Model")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Model", selection: Binding(
                    get: { translationService.currentModel.id },
                    set: { newId in
                        if let model = TranslationService.availableModels.first(where: { $0.id == newId }) {
                            translationService.switchModel(model)
                        }
                    }
                )) {
                    ForEach(TranslationService.availableModels, id: \.id) { model in
                        Text(model.displayName).tag(model.id)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
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
        .frame(width: 260)
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
