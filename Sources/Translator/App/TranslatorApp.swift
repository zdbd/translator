import SwiftUI

@main
struct TranslatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 600)

        Settings {
            SettingsView()
        }
    }
}
