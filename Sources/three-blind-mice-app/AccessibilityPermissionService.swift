import AppKit
import ApplicationServices
import Foundation

enum AccessibilityPermissionService {
    struct Diagnostics: Equatable {
        let isTrusted: Bool
        let bundleIdentifier: String
        let bundlePath: String
        let executablePath: String
    }

    static func diagnostics() -> Diagnostics {
        Diagnostics(
            isTrusted: AXIsProcessTrusted(),
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "(none — use ThreeBlindMice.xcodeproj)",
            bundlePath: Bundle.main.bundlePath,
            executablePath: Bundle.main.executableURL?.path
                ?? ProcessInfo.processInfo.arguments.first
                ?? "unknown"
        )
    }

    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    static func promptForTrust() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
