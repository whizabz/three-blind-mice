import ApplicationServices
import Foundation

extension Shortcut {
    static let defaultToggleRemapping = Shortcut(key: "m", modifiers: [.control, .option])

    var displayLabel: String {
        let modifierLabels = modifiers.map { modifier -> String in
            switch modifier {
            case .command: return "⌘"
            case .shift: return "⇧"
            case .option: return "⌥"
            case .control: return "⌃"
            }
        }
        return modifierLabels.joined() + key.uppercased()
    }

    func cgEventFlags() -> CGEventFlags {
        modifiers.reduce(CGEventFlags()) { partial, modifier in
            partial.union(modifier.cgEventFlag)
        }
    }

    func matches(event: CGEvent, type: CGEventType) -> Bool {
        guard type == .keyDown else { return false }
        guard let expectedKeyCode = KeyCodeTable.keyCode(for: key) else { return false }
        let actualKeyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        guard actualKeyCode == expectedKeyCode else { return false }

        let relevant: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl]
        let required = cgEventFlags().intersection(relevant)
        let actual = event.flags.intersection(relevant)
        if required.isEmpty {
            return actual.isEmpty
        }
        // All required modifiers must be held; extra modifier flags are allowed.
        return required.subtracting(actual).isEmpty
    }
}

extension ModifierKey {
    var cgEventFlag: CGEventFlags {
        switch self {
        case .command: return .maskCommand
        case .shift: return .maskShift
        case .option: return .maskAlternate
        case .control: return .maskControl
        }
    }
}
