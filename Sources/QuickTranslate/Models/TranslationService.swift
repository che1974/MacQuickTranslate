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

        let prompt = currentModelConfig.buildPrompt(text: text, from: source, to: target)

        do {
            try await container.perform { context in
                let input = try await context.processor.prepare(
                    input: .init(prompt: prompt)
                )
                let params = GenerateParameters(temperature: 0.0)

                let stream = try MLXLMCommon.generate(
                    input: input, parameters: params, context: context
                )

                for try await result in stream {
                    if Task.isCancelled { break }
                    if let chunk = result.chunk {
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
                self.translatedText = self.translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
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
}
