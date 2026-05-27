import ApplicationServices
import Foundation

struct ActionExecutor {
    private static let syntheticMarker: Int64 = 0x54424D31 // "TBM1"

    static func syntheticMarkerValue() -> Int64 {
        syntheticMarker
    }

    static func execute(_ action: NavigationAction) {
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

    private static func post(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = modifiers
        keyUp.flags = modifiers
        keyDown.setIntegerValueField(.eventSourceUserData, value: syntheticMarker)
        keyUp.setIntegerValueField(.eventSourceUserData, value: syntheticMarker)

        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)
    }
}
