import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            Form {
                generalSection
                toggleShortcutSection
                accessibilitySection
                mappingsSection
            }
            .formStyle(.grouped)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 520, idealWidth: 560)
    }

    // MARK: - Sections

    @ViewBuilder
    private var generalSection: some View {
        Section {
            Toggle("Enable Remapping", isOn: Binding(
                get: { appState.config.isEnabled },
                set: { appState.setEnabled($0) }
            ))
            .accessibilityHint("Turns mouse remapping on or off. You can also use the toggle shortcut.")

            Toggle("Lock pointer position", isOn: Binding(
                get: { appState.config.lockPointerPosition },
                set: { appState.setLockPointerPosition($0) }
            ))
            .accessibilityHint(
                "When enabled, the mouse cursor stays fixed while remapping is on so movement does not hover over other controls."
            )

            if appState.hasAccessibilityPermission {
                Label(
                    appState.isEventTapActive
                        ? "Remapping engine is running."
                        : "Permission granted, but the event tap is not running. Use Refresh below.",
                    systemImage: appState.isEventTapActive ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .foregroundStyle(appState.isEventTapActive ? .green : .orange)
                .accessibilityLabel(
                    appState.isEventTapActive
                        ? "Remapping engine is running"
                        : "Remapping engine is not running"
                )
            }
        } header: {
            Text("General")
        } footer: {
            keyboardNavigationFooter
        }
    }

    @ViewBuilder
    private var keyboardNavigationFooter: some View {
        if KeyboardNavigationHelper.isSystemKeyboardNavigationEnabled {
            Text("Remapping stays active while settings is open unless you turn it off.")
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Enable Keyboard navigation in System Settings for Tab key support in apps (separate from VoiceOver).")
                    .foregroundStyle(.orange)
                Button("Open Keyboard Settings") {
                    KeyboardNavigationHelper.openKeyboardNavigationSettings()
                }
            }
        }
    }

    @ViewBuilder
    private var toggleShortcutSection: some View {
        Section {
            Picker("Toggle key", selection: toggleKeyBinding) {
                ForEach(KeyCodeTable.letterKeys, id: \.self) { key in
                    Text(key.uppercased()).tag(key)
                }
            }

            Toggle("Control modifier", isOn: modifierBinding(.control))
            Toggle("Option modifier", isOn: modifierBinding(.option))
            Toggle("Command modifier", isOn: modifierBinding(.command))
            Toggle("Shift modifier", isOn: modifierBinding(.shift))

            LabeledContent("Current shortcut") {
                Text(appState.config.toggleRemappingShortcut.displayLabel)
            }
        } header: {
            Text("Toggle Remapping Shortcut")
        } footer: {
            Text("Default is Control+Option+M.")
        }
    }

    @ViewBuilder
    private var accessibilitySection: some View {
        let diagnostics = appState.permissionDiagnostics

        Section {
            if diagnostics.isTrusted {
                Label("Permission granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Label("Permission not detected", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }

            LabeledContent("Bundle ID") {
                Text(diagnostics.bundleIdentifier)
                    .textSelection(.enabled)
            }

            LabeledContent("App path") {
                Text(diagnostics.bundlePath)
                    .textSelection(.enabled)
                    .lineLimit(3)
            }

            Button("Grant Permission") {
                appState.requestAccessibilityPermissionPrompt()
            }

            Button("Open System Settings") {
                appState.openAccessibilitySystemSettings()
            }

            Button("Refresh Permission Status") {
                appState.refreshAccessibilityPermission()
            }
        } header: {
            Text("Accessibility")
        }
    }

    @ViewBuilder
    private var mappingsSection: some View {
        Section {
            ForEach(InputTrigger.allCases, id: \.self) { trigger in
                Picker(displayName(for: trigger), selection: Binding(
                    get: { appState.config.activeProfile.action(for: trigger).kind },
                    set: { appState.setAction($0, for: trigger) }
                )) {
                    ForEach(NavigationActionKind.presetOptions, id: \.self) { kind in
                        Text(displayName(for: kind)).tag(kind)
                    }
                }
            }
        } header: {
            Text("Mouse Mappings")
        } footer: {
            Text("Scroll and button mappings apply globally while remapping is enabled.")
        }
    }

    // MARK: - Bindings

    private var toggleKeyBinding: Binding<String> {
        Binding(
            get: { appState.config.toggleRemappingShortcut.key.lowercased() },
            set: { newKey in
                appState.setToggleRemappingShortcut(
                    Shortcut(key: newKey, modifiers: appState.config.toggleRemappingShortcut.modifiers)
                )
            }
        )
    }

    private func modifierBinding(_ modifier: ModifierKey) -> Binding<Bool> {
        Binding(
            get: { appState.config.toggleRemappingShortcut.modifiers.contains(modifier) },
            set: { isOn in
                var modifiers = appState.config.toggleRemappingShortcut.modifiers
                if isOn {
                    if !modifiers.contains(modifier) {
                        modifiers.append(modifier)
                    }
                } else {
                    modifiers.removeAll { $0 == modifier }
                }
                appState.setToggleRemappingShortcut(
                    Shortcut(key: appState.config.toggleRemappingShortcut.key, modifiers: modifiers)
                )
            }
        )
    }

    // MARK: - Labels

    private func displayName(for trigger: InputTrigger) -> String {
        switch trigger {
        case .scrollUp: return "Scroll Up"
        case .scrollDown: return "Scroll Down"
        case .leftClick: return "Left Click"
        case .rightClick: return "Right Click"
        case .middleClick: return "Middle Click"
        case .backButton: return "Back Button"
        case .forwardButton: return "Forward Button"
        }
    }

    private func displayName(for kind: NavigationActionKind) -> String {
        switch kind {
        case .tab: return "Tab"
        case .shiftTab: return "Shift + Tab"
        case .enter: return "Enter / Return"
        case .space: return "Space"
        case .escape: return "Escape"
        case .upArrow: return "Up Arrow"
        case .downArrow: return "Down Arrow"
        case .leftArrow: return "Left Arrow"
        case .rightArrow: return "Right Arrow"
        case .nextApp: return "Command + Tab"
        case .nextWindowInApp: return "Command + `"
        case .customShortcut: return "Custom Shortcut"
        case .noAction: return "No Action"
        }
    }
}
