import Foundation
import MLX
import MLXLLM
import MLXLMCommon

enum ModelState: Equatable {
    case notLoaded
    case downloading(progress: Double)
    case loading
    case ready
    case error(String)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.notLoaded, .notLoaded), (.loading, .loading), (.ready, .ready): return true
        case (.downloading(let a), .downloading(let b)): return a == b
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

@MainActor
class TranslationService: ObservableObject {
    @Published var translatedText: String = ""
    @Published var isTranslating: Bool = false
    @Published var error: TranslationError?
    @Published var warning: String?
    @Published var modelState: ModelState = .notLoaded
    @Published var currentModelConfig: TranslationModelConfig

    private var modelContainer: ModelContainer?
    private var currentTask: Task<Void, Never>?

    init(model: TranslationModelConfig = .translateGemma4B) {
        self.currentModelConfig = model
    }

    func loadModel() async {
        guard modelState != .ready && modelState != .loading else { return }

        modelState = .loading

        do {
            let config = ModelConfiguration(id: currentModelConfig.huggingFaceId)

            let container = try await LLMModelFactory.shared.loadContainer(
                configuration: config
            ) { progress in
                Task { @MainActor in
                    self.modelState = .downloading(progress: progress.fractionCompleted)
                }
            }

            self.modelContainer = container
            modelState = .ready
        } catch {
            modelState = .error(error.localizedDescription)
        }
    }

    func switchModel(_ config: TranslationModelConfig) async {
        cancelTranslation()
        modelContainer = nil
        currentModelConfig = config
        modelState = .notLoaded
        await loadModel()
    }

    func unloadModel() {
        cancelTranslation()
        modelContainer = nil
        modelState = .notLoaded
    }

    func translate(_ text: String, from source: Language, to target: Language) async {
        guard let container = modelContainer, modelState == .ready else {
            error = .modelNotLoaded
            return
        }

        currentTask?.cancel()

        isTranslating = true
        translatedText = ""
        error = nil
        warning = nil

        let wordCount = text.split(separator: " ").count
        if wordCount > 1500 {
            warning = "Text is very long (\(wordCount) words). Translation may be truncated."
        }

        let userInput = currentModelConfig.buildInput(text: text, from: source, to: target)

        do {
            try await container.perform { context in
                let input = try await context.processor.prepare(
                    input: userInput
                )
                let params = GenerateParameters(
                    maxTokens: 2048,
                    temperature: 0.0,
                    repetitionPenalty: 1.2
                )

                let stream = try MLXLMCommon.generate(
                    input: input, parameters: params, context: context
                )

                for try await result in stream {
                    if Task.isCancelled { break }
                    if let chunk = result.chunk {
                        // Stop on special tokens
                        if chunk.contains("<end_of_turn>") || chunk.contains("<eos>") { break }

                        await MainActor.run {
                            self.translatedText += chunk
                        }
                    }
                }
            }

            await MainActor.run {
                if self.translatedText.isEmpty && self.error == nil {
                    self.error = .emptyResponse
                }
                // Strip any leaked special tokens and whitespace
                self.translatedText = self.translatedText
                    .replacingOccurrences(of: "<end_of_turn>", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                self.isTranslating = false
            }
        } catch {
            await MainActor.run {
                if !Task.isCancelled {
                    self.error = .unknown(error.localizedDescription)
                }
                self.isTranslating = false
            }
        }
    }

    func cancelTranslation() {
        currentTask?.cancel()
        currentTask = nil
        isTranslating = false
    }

    // MARK: - Model cache management

    /// Get the HuggingFace cache directory for a model
    static func cacheDir(for config: TranslationModelConfig) -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let hfCache = home.appendingPathComponent(".cache/huggingface/hub")
        let modelDir = "models--" + config.huggingFaceId.replacingOccurrences(of: "/", with: "--")
        let path = hfCache.appendingPathComponent(modelDir)
        return FileManager.default.fileExists(atPath: path.path) ? path : nil
    }

    /// Calculate cache size for a model
    static func cacheSize(for config: TranslationModelConfig) -> Int64 {
        guard let dir = cacheDir(for: config) else { return 0 }
        let enumerator = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: [.fileSizeKey])
        var total: Int64 = 0
        while let url = enumerator?.nextObject() as? URL {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    /// Delete cached model files
    func deleteModelCache(for config: TranslationModelConfig) {
        // Unload if it's the current model
        if config == currentModelConfig {
            cancelTranslation()
            modelContainer = nil
            modelState = .notLoaded
        }
        guard let dir = Self.cacheDir(for: config) else { return }
        try? FileManager.default.removeItem(at: dir)
    }

    /// Format bytes to human readable string
    static func formatBytes(_ bytes: Int64) -> String {
        if bytes == 0 { return "Not downloaded" }
        let gb = Double(bytes) / 1_073_741_824
        if gb >= 1.0 { return String(format: "%.1f GB", gb) }
        let mb = Double(bytes) / 1_048_576
        return String(format: "%.0f MB", mb)
    }
}
