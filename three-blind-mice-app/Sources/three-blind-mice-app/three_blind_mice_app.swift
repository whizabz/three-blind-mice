import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

private struct MenuBarIcon: View {
    let isEnabled: Bool

    private var enabledSymbolName: String { "sunglasses.fill" }
    private var baseSymbolName: String { "sunglasses" }

    private var hasEnabledVariant: Bool {
        NSImage(systemSymbolName: enabledSymbolName, accessibilityDescription: nil) != nil
    }

    var body: some View {
        if isEnabled, hasEnabledVariant {
            Image(systemName: enabledSymbolName)
        } else if isEnabled {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: baseSymbolName)
                Image(systemName: "circle.fill")
                    .font(.system(size: 6, weight: .bold))
                    .offset(x: 1, y: -1)
            }
        } else {
            Image(systemName: baseSymbolName)
        }
    }
}

@main
struct ThreeBlindMiceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(appState)
        } label: {
            MenuBarIcon(isEnabled: appState.config.isEnabled)
        }
    }
}
