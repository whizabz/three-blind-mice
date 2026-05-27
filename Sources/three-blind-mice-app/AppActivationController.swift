import AppKit

/// Opens the AppKit-hosted settings window (keyboard-focusable).
@MainActor
enum AppActivationController {
    static func openSettings(appState: AppState) {
        SettingsWindowController.shared.show(appState: appState)
    }
}
