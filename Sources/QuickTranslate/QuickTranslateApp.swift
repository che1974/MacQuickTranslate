import SwiftUI

@main
struct QuickTranslateApp: App {
    @StateObject private var translationService: TranslationService
    @StateObject private var appState: AppState

    init() {
        let service = TranslationService()
        _translationService = StateObject(wrappedValue: service)
        _appState = StateObject(wrappedValue: AppState(translationService: service))
    }

    var body: some Scene {
        MenuBarExtra("QuickTranslate", systemImage: "character.book.closed") {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(translationService)
                .onAppear { appState.setup() }
        }
        .menuBarExtraStyle(.window)
    }
}
