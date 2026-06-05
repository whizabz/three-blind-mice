import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            Form {
                generalSection
            }
            .formStyle(.grouped)
            .padding(16)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            Form {
                toggleShortcutSection
            }
            .formStyle(.grouped)
            .padding(16)
            .tabItem {
                Label("Shortcut", systemImage: "command")
            }

            Form {
                accessibilitySection
            }
            .formStyle(.grouped)
            .padding(16)
            .tabItem {
                Label("Accessibility", systemImage: "hand.raised")
            }

            Form {
                mappingsSection
            }
            .formStyle(.grouped)
            .padding(16)
            .tabItem {
                Label("Mappings", systemImage: "computermouse")
            }
        }
        .frame(minWidth: 520, idealWidth: 560, minHeight: 360)
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
                        : "Permission granted, but the event tap is not running. Use the Accessibility tab.",
                    systemImage: appState.isEventTapActive ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .foregroundStyle(appState.isEventTapActive ? .green : .orange)
                .accessibilityLabel(
                    appState.isEventTapActive
                        ? "Remapping engine is running"
                        : "Remapping engine is not running"
                )
            }
        } footer: {
            keyboardNavigationFooter
        }

        Section {
            Picker("Scroll navigation", selection: Binding(
                get: { appState.config.scrollNavigationStyle },
                set: { appState.setScrollNavigationStyle($0) }
            )) {
                Text("Tab / Shift+Tab").tag(ScrollNavigationStyle.tabNavigation)
                Text("Left / Right Arrow").tag(ScrollNavigationStyle.arrowNavigation)
                Text("Custom").tag(ScrollNavigationStyle.custom)
            }
            .accessibilityHint(
                "Choose how scroll up and down are remapped. Use Left / Right Arrow with VoiceOver Quick Nav if enabled."
            )

            if appState.config.scrollNavigationStyle == .custom {
                Picker("Scroll up", selection: scrollActionBinding(.scrollUp)) {
                    ForEach(NavigationActionKind.scrollActionOptions, id: \.self) { kind in
                        Text(displayName(for: kind)).tag(kind)
                    }
                }

                Picker("Scroll down", selection: scrollActionBinding(.scrollDown)) {
                    ForEach(NavigationActionKind.scrollActionOptions, id: \.self) { kind in
                        Text(displayName(for: kind)).tag(kind)
                    }
                }
            }

            Toggle("Hold forward button for Tab navigation", isOn: Binding(
                get: { appState.config.holdForwardForTabScroll },
                set: { appState.setHoldForwardForTabScroll($0) }
            ))
            .accessibilityHint(
                "While the forward mouse button is held, scroll uses Shift+Tab and Tab regardless of the scroll navigation setting above."
            )

            Toggle("Invert scroll for remapping", isOn: Binding(
                get: { appState.config.invertScrollForRemapping },
                set: { appState.setInvertScrollForRemapping($0) }
            ))
            .accessibilityHint(
                "Swaps which scroll direction triggers scroll up versus scroll down actions. Does not change scrolling outside this app."
            )
        } header: {
            Text("Scroll Navigation")
        } footer: {
            Text(
                "Invert scroll for remapping if navigation feels backwards with your mouse scroll settings. "
                + "Hold the forward mouse button while scrolling to temporarily use Tab and Shift+Tab."
            )
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

            LabeledContent("Code signing") {
                Text(diagnostics.codeSigningSummary)
                    .textSelection(.enabled)
                    .foregroundStyle(diagnostics.permissionResetsOnRebuild ? .orange : .primary)
            }

            if diagnostics.permissionResetsOnRebuild {
                Text(
                    "This build is ad hoc signed, so macOS treats each rebuild as a new app and Accessibility permission will not stick. "
                    + "Copy App/DevelopmentTeam.xcconfig.example to App/DevelopmentTeam.xcconfig, set your Team ID, then rebuild."
                )
                .foregroundStyle(.orange)
                .font(.callout)
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
                    ForEach(actionOptions(for: trigger), id: \.self) { kind in
                        Text(displayName(for: kind)).tag(kind)
                    }
                }
            }
        } footer: {
            Text("Scroll and button mappings apply globally while remapping is enabled.")
        }
    }

    private func scrollActionBinding(_ trigger: InputTrigger) -> Binding<NavigationActionKind> {
        Binding(
            get: { appState.config.activeProfile.action(for: trigger).kind },
            set: { appState.setAction($0, for: trigger) }
        )
    }

    private func actionOptions(for trigger: InputTrigger) -> [NavigationActionKind] {
        switch trigger {
        case .scrollUp, .scrollDown:
            return NavigationActionKind.scrollActionOptions
        default:
            return NavigationActionKind.presetOptions
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
        case .voiceOverPreviousItem: return "VoiceOver Previous Item (⌃⌥←)"
        case .voiceOverNextItem: return "VoiceOver Next Item (⌃⌥→)"
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
