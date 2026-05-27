import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Enable Remapping", isOn: Binding(
                get: { appState.config.isEnabled },
                set: { appState.setEnabled($0) }
            ))

            if !appState.hasAccessibilityPermission {
                Text("Accessibility permission is required.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Button("Grant Permission") {
                    appState.requestAccessibilityPermissionPrompt()
                }
                Button("Open System Settings") {
                    appState.openAccessibilitySystemSettings()
                }
            } else if appState.isEventTapActive {
                Text("Remapping engine: running")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Text("Remapping engine: not running — click Refresh in Settings")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Text("Toggle remapping: \(appState.config.toggleRemappingShortcut.displayLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Text("Profile: \(appState.config.activeProfile.name)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Open Settings") {
                AppActivationController.openSettings(appState: appState)
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Quit Three Blind Mice") {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 260)
    }
}
