import AppKit
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var config: AppConfig {
        didSet {
            saveConfig()
            remappingService.updateConfigProvider { [weak self] in
                self?.config ?? .default
            }
            remappingService.updateToggleShortcutProvider { [weak self] in
                self?.config.toggleRemappingShortcut ?? .defaultToggleRemapping
            }
            syncPointerLock()
        }
    }

    @Published private(set) var hasAccessibilityPermission: Bool
    @Published private(set) var isEventTapActive = false

    var permissionDiagnostics: AccessibilityPermissionService.Diagnostics {
        AccessibilityPermissionService.diagnostics()
    }

    private let store: ConfigStore
    private let remappingService: InputRemappingService
    private var activationObserver: NSObjectProtocol?
    private var permissionPollTimer: Timer?

    init(store: ConfigStore = ConfigStore()) {
        self.store = store
        self.hasAccessibilityPermission = AccessibilityPermissionService.isTrusted()
        do {
            self.config = try store.loadOrCreateDefault()
        } catch {
            self.config = .default
        }

        self.remappingService = InputRemappingService(
            configProvider: { .default },
            toggleShortcutProvider: { .defaultToggleRemapping }
        )

        self.remappingService.updateConfigProvider { [weak self] in
            self?.config ?? .default
        }
        self.remappingService.updateToggleShortcutProvider { [weak self] in
            self?.config.toggleRemappingShortcut ?? .defaultToggleRemapping
        }
        self.remappingService.setToggleRemappingHandler { [weak self] in
            Task { @MainActor in
                self?.toggleRemappingEnabled()
            }
        }

        self.remappingService.onEventTapActiveChanged = { [weak self] active in
            Task { @MainActor in
                self?.isEventTapActive = active
                if active {
                    self?.hasAccessibilityPermission = true
                }
            }
        }

        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAccessibilityPermission()
            }
        }

        startPermissionPolling()
        startServicesIfNeeded()
        syncPointerLock()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            refreshAccessibilityPermission()
        }
    }

    deinit {
        permissionPollTimer?.invalidate()
        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
        }
    }

    func setEnabled(_ enabled: Bool) {
        guard config.isEnabled != enabled else { return }
        config.isEnabled = enabled
        RemappingSoundService.shared.playRemappingEnabled(enabled)
        syncPointerLock()
    }

    func toggleRemappingEnabled() {
        let newValue = !config.isEnabled
        config.isEnabled = newValue
        RemappingSoundService.shared.playRemappingEnabled(newValue)
        syncPointerLock()
    }

    func setLockPointerPosition(_ enabled: Bool) {
        config.lockPointerPosition = enabled
    }

    func syncPointerLock() {
        guard config.isEnabled, config.lockPointerPosition else {
            PointerLockManager.shared.deactivateLock()
            return
        }
        PointerLockManager.shared.activateLock(at: NSEvent.mouseLocation)
    }

    func setToggleRemappingShortcut(_ shortcut: Shortcut) {
        config.toggleRemappingShortcut = shortcut
    }

    func setAction(_ actionKind: NavigationActionKind, for trigger: InputTrigger) {
        var profile = config.activeProfile
        let action: NavigationAction
        if actionKind == .customShortcut {
            action = NavigationAction(
                kind: .customShortcut,
                shortcut: Shortcut(key: "k", modifiers: [.command])
            )
        } else {
            action = NavigationAction(kind: actionKind)
        }
        profile.setAction(action, for: trigger)
        config.activeProfile = profile
    }

    private func saveConfig() {
        do {
            try store.save(config)
        } catch {
            // Silent fail for now; later we can expose this in diagnostics UI.
        }
    }

    func refreshAccessibilityPermission() {
        let trusted = AccessibilityPermissionService.isTrusted()
        if trusted != hasAccessibilityPermission {
            hasAccessibilityPermission = trusted
            startServicesIfNeeded()
        } else if trusted {
            // Re-start if permission is on but tap died (e.g. after sleep).
            if !isEventTapActive {
                remappingService.restart()
            }
        }
    }

    func requestAccessibilityPermissionPrompt() {
        _ = AccessibilityPermissionService.promptForTrust()
        refreshAccessibilityPermission()
    }

    func openAccessibilitySystemSettings() {
        AccessibilityPermissionService.openSystemSettings()
    }

    private func startPermissionPolling() {
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAccessibilityPermission()
            }
        }
    }

    private func startServicesIfNeeded() {
        if hasAccessibilityPermission {
            remappingService.restart()
        } else {
            remappingService.stop()
            isEventTapActive = false
        }
    }
}
