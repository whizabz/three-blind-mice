import AppKit
import Foundation

enum KeyboardNavigationHelper {
    /// macOS setting: System Settings → Keyboard → Keyboard navigation (not VoiceOver).
    static var isSystemKeyboardNavigationEnabled: Bool {
        let mode = UserDefaults.standard.integer(forKey: "AppleKeyboardUIMode")
        return (mode & 0x2) != 0
    }

    static func openKeyboardNavigationSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.Keyboard-Settings.extension?KeyboardNavigation",
            "x-apple.systempreferences:com.apple.preference.keyboard?Keyboard"
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
