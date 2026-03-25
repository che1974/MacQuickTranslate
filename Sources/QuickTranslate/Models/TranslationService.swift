import Foundation

@MainActor
class TranslationService: ObservableObject {
    @Published var translatedText: String = ""
    @Published var isTranslating: Bool = false
    @Published var error: TranslationError?
    @Published var warning: String?
    @Published var currentModel: any TranslationModel

    static let availableModels: [any TranslationModel] = [
        TranslateGemmaModel(),
        OpusMTModel(),
    ]

    private let baseURL = URL(string: "http://localhost:11434")!
    private var currentTask: Task<Void, Never>?

    init(model: (any TranslationModel)? = nil) {
        self.currentModel = model ?? Self.availableModels[0]
    }

    func switchModel(_ model: any TranslationModel) {
        cancelTranslation()
        currentModel = model
    }

    func translate(_ text: String, from source: Language, to target: Language) async {
        currentTask?.cancel()

        isTranslating = true
        translatedText = ""
        error = nil
        warning = nil

        let wordCount = text.split(separator: " ").count
        if wordCount > 1500 {
            warning = "Text is very long (\(wordCount) words). Translation may be truncated."
        }

        let body = currentModel.buildRequestBody(text: text, from: source, to: target)

        var request = URLRequest(url: baseURL.appendingPathComponent("api/chat"))
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                error = .unknown("Invalid response")
                isTranslating = false
                return
            }

            if httpResponse.statusCode == 404 {
                error = .modelNotFound(currentModel.ollamaModel)
                isTranslating = false
                return
            }

            for try await line in bytes.lines {
                if Task.isCancelled { break }

                guard let data = line.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let parsed = currentModel.parseStreamChunk(json)
                else { continue }

                translatedText += parsed.content
                if parsed.done { break }
            }

            if translatedText.isEmpty && error == nil {
                error = .emptyResponse
            }

            translatedText = translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch let urlError as URLError {
            switch urlError.code {
            case .cannotConnectToHost, .networkConnectionLost:
                error = .connectionRefused
            case .timedOut:
                error = .timeout
            default:
                error = .unknown(urlError.localizedDescription)
            }
        } catch {
            if !Task.isCancelled {
                self.error = .unknown(error.localizedDescription)
            }
        }

        isTranslating = false
    }

    func cancelTranslation() {
        currentTask?.cancel()
        currentTask = nil
        isTranslating = false
    }

    func checkConnection() async -> Bool {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/tags"))
        request.timeoutInterval = 5
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    /// Check if a specific model is available in Ollama
    func checkModelAvailable(_ modelTag: String) async -> Bool {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/tags"))
        request.timeoutInterval = 5
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let models = json["models"] as? [[String: Any]] else {
                return false
            }
            return models.contains { ($0["name"] as? String)?.hasPrefix(modelTag) == true }
        } catch {
            return false
        }
    }
}
