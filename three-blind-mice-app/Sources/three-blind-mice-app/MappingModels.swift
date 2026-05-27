import Foundation

enum InputTrigger: String, Codable, CaseIterable, Sendable {
    case scrollUp
    case scrollDown
    case leftClick
    case rightClick
    case middleClick
    case backButton
    case forwardButton
}

enum ModifierKey: String, Codable, CaseIterable, Sendable {
    case command
    case shift
    case option
    case control
}

struct Shortcut: Codable, Equatable, Sendable {
    let key: String
    let modifiers: [ModifierKey]
}

enum NavigationActionKind: String, Codable, CaseIterable, Sendable {
    case tab
    case shiftTab
    case enter
    case space
    case escape
    case upArrow
    case downArrow
    case leftArrow
    case rightArrow
    case nextApp
    case nextWindowInApp
    case customShortcut
    case noAction

    static var presetOptions: [NavigationActionKind] {
        [
            .tab,
            .shiftTab,
            .enter,
            .space,
            .escape,
            .upArrow,
            .downArrow,
            .leftArrow,
            .rightArrow,
            .nextApp,
            .nextWindowInApp,
            .customShortcut,
            .noAction
        ]
    }
}

struct NavigationAction: Codable, Equatable, Sendable {
    let kind: NavigationActionKind
    let shortcut: Shortcut?

    init(kind: NavigationActionKind, shortcut: Shortcut? = nil) {
        self.kind = kind
        self.shortcut = shortcut
    }

    static let tab = NavigationAction(kind: .tab)
    static let shiftTab = NavigationAction(kind: .shiftTab)
    static let enter = NavigationAction(kind: .enter)
    static let space = NavigationAction(kind: .space)
    static let escape = NavigationAction(kind: .escape)
    static let noAction = NavigationAction(kind: .noAction)
}

struct MappingProfile: Codable, Equatable, Sendable {
    let name: String
    private(set) var mappings: [InputTrigger: NavigationAction]

    init(name: String, mappings: [InputTrigger: NavigationAction]) {
        self.name = name
        self.mappings = mappings
    }

    func action(for trigger: InputTrigger) -> NavigationAction {
        mappings[trigger] ?? .noAction
    }

    mutating func setAction(_ action: NavigationAction, for trigger: InputTrigger) {
        mappings[trigger] = action
    }

    static let minimalPreset = MappingProfile(
        name: "Minimal Preset",
        mappings: [
            .scrollUp: .shiftTab,
            .scrollDown: .tab,
            .leftClick: .enter,
            .rightClick: .space,
            .middleClick: .noAction,
            .backButton: .noAction,
            .forwardButton: .noAction
        ]
    )
}

struct AppConfig: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var activeProfile: MappingProfile
    var toggleRemappingShortcut: Shortcut
    /// When true, the pointer stays fixed (no hover from accidental movement).
    var lockPointerPosition: Bool

    static let `default` = AppConfig(
        isEnabled: true,
        activeProfile: .minimalPreset,
        toggleRemappingShortcut: .defaultToggleRemapping,
        lockPointerPosition: true
    )

    init(
        isEnabled: Bool,
        activeProfile: MappingProfile,
        toggleRemappingShortcut: Shortcut,
        lockPointerPosition: Bool
    ) {
        self.isEnabled = isEnabled
        self.activeProfile = activeProfile
        self.toggleRemappingShortcut = toggleRemappingShortcut
        self.lockPointerPosition = lockPointerPosition
    }

    enum CodingKeys: String, CodingKey {
        case isEnabled
        case activeProfile
        case toggleRemappingShortcut
        case lockPointerPosition
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        activeProfile = try container.decode(MappingProfile.self, forKey: .activeProfile)
        toggleRemappingShortcut = try container.decodeIfPresent(Shortcut.self, forKey: .toggleRemappingShortcut)
            ?? .defaultToggleRemapping
        lockPointerPosition = try container.decodeIfPresent(Bool.self, forKey: .lockPointerPosition) ?? true
    }
}
