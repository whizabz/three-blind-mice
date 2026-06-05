import ApplicationServices
import Foundation

struct ActionExecutor {
    private static let syntheticMarker: Int64 = 0x54424D31 // "TBM1"

    // macOS virtual key codes (HIToolbox/Events.h)
    private enum VirtualKey {
        static let capsLock: CGKeyCode = 0x39
        static let control: CGKeyCode = 0x3B
        static let option: CGKeyCode = 0x3A
        static let leftArrow: CGKeyCode = 0x7B
        static let rightArrow: CGKeyCode = 0x7C
    }

    static func execute(_ action: NavigationAction, voiceOverModifier: VoiceOverModifierStyle = .controlOption) {
        switch action.kind {
        case .tab:
            post(keyCode: 48, modifiers: [])
        case .shiftTab:
            post(keyCode: 48, modifiers: [.maskShift])
        case .enter:
            post(keyCode: 36, modifiers: [])
        case .space:
            post(keyCode: 49, modifiers: [])
        case .escape:
            post(keyCode: 53, modifiers: [])
        case .leftArrow:
            post(keyCode: 123, modifiers: [])
        case .rightArrow:
            post(keyCode: 124, modifiers: [])
        case .voiceOverPreviousItem:
            postVoiceOverItemNavigation(previous: true, modifierStyle: voiceOverModifier)
        case .voiceOverNextItem:
            postVoiceOverItemNavigation(previous: false, modifierStyle: voiceOverModifier)
        case .downArrow:
            post(keyCode: 125, modifiers: [])
        case .upArrow:
            post(keyCode: 126, modifiers: [])
        case .nextApp:
            post(keyCode: 48, modifiers: [.maskCommand])
        case .nextWindowInApp:
            post(keyCode: 50, modifiers: [.maskCommand])
        case .customShortcut:
            guard let shortcut = action.shortcut else { return }
            guard let keyCode = KeyCodeTable.keyCode(for: shortcut.key) else { return }
            post(keyCode: keyCode, modifiers: shortcut.cgEventFlags())
        case .noAction:
            return
        }
    }

    static func syntheticMarkerValue() -> Int64 {
        syntheticMarker
    }

    /// VoiceOver item navigation is handled by the screen reader at the HID level.
    /// System-wide shortcuts need explicit modifier key presses, not just flag bits on the arrow key.
    private static func postVoiceOverItemNavigation(previous: Bool, modifierStyle: VoiceOverModifierStyle) {
        let arrow = previous ? VirtualKey.leftArrow : VirtualKey.rightArrow
        switch modifierStyle {
        case .controlOption:
            postSystemWideChord(
                modifierKeyCodes: [VirtualKey.control, VirtualKey.option],
                keyCode: arrow,
                modifierFlags: [.maskControl, .maskAlternate]
            )
        case .capsLock:
            postSystemWideChord(
                modifierKeyCodes: [VirtualKey.capsLock],
                keyCode: arrow,
                modifierFlags: [.maskAlphaShift]
            )
        }
    }

    private static func postSystemWideChord(
        modifierKeyCodes: [CGKeyCode],
        keyCode: CGKeyCode,
        modifierFlags: CGEventFlags
    ) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        for modifier in modifierKeyCodes {
            postRaw(source: source, keyCode: modifier, keyDown: true, flags: [])
        }

        postRaw(source: source, keyCode: keyCode, keyDown: true, flags: modifierFlags)
        postRaw(source: source, keyCode: keyCode, keyDown: false, flags: modifierFlags)

        for modifier in modifierKeyCodes.reversed() {
            postRaw(source: source, keyCode: modifier, keyDown: false, flags: [])
        }
    }

    private static func post(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        postRaw(source: source, keyCode: keyCode, keyDown: true, flags: modifiers, tap: .cgSessionEventTap)
        postRaw(source: source, keyCode: keyCode, keyDown: false, flags: modifiers, tap: .cgSessionEventTap)
    }

    private static func postRaw(
        source: CGEventSource,
        keyCode: CGKeyCode,
        keyDown: Bool,
        flags: CGEventFlags,
        tap: CGEventTapLocation = .cghidEventTap
    ) {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) else {
            return
        }
        event.flags = flags
        event.setIntegerValueField(.eventSourceUserData, value: syntheticMarker)
        event.post(tap: tap)
    }
}
