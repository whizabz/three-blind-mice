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

/// How VoiceOver item-navigation shortcuts are synthesized.
enum VoiceOverModifierStyle: String, Codable, CaseIterable, Sendable {
    /// ⌃⌥ + arrow — default when VoiceOver modifier is Control and Option.
    case controlOption
    /// Caps Lock + arrow — when VoiceOver modifier is set to Caps Lock in VoiceOver Utility.
    case capsLock
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
    /// VoiceOver: move to previous item (all elements). Posts Control+Option+Left Arrow.
    case voiceOverPreviousItem
    /// VoiceOver: move to next item (all elements). Posts Control+Option+Right Arrow.
    case voiceOverNextItem
    case nextApp
    case nextWindowInApp
    case customShortcut
    case noAction

    static var presetOptions: [NavigationActionKind] {
        [
            .tab,
            .shiftTab,
            .voiceOverPreviousItem,
            .voiceOverNextItem,
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

    /// Common choices for scroll wheel remapping.
    static var scrollActionOptions: [NavigationActionKind] {
        [.shiftTab, .tab, .leftArrow, .rightArrow, .noAction]
    }
}

enum ScrollNavigationStyle: String, Codable, CaseIterable, Sendable {
    case tabNavigation
    case arrowNavigation
    case custom

    func applyToProfile(_ profile: inout MappingProfile) {
        switch self {
        case .tabNavigation:
            profile.setAction(.shiftTab, for: .scrollUp)
            profile.setAction(.tab, for: .scrollDown)
        case .arrowNavigation:
            profile.setAction(NavigationAction(kind: .leftArrow), for: .scrollUp)
            profile.setAction(NavigationAction(kind: .rightArrow), for: .scrollDown)
        case .custom:
            break
        }
    }

    static func infer(from profile: MappingProfile) -> ScrollNavigationStyle {
        let up = profile.action(for: .scrollUp).kind
        let down = profile.action(for: .scrollDown).kind
        if up == .shiftTab && down == .tab { return .tabNavigation }
        if up == .leftArrow && down == .rightArrow { return .arrowNavigation }
        return .custom
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
    var scrollNavigationStyle: ScrollNavigationStyle
    /// While the forward mouse button is held, scroll uses Tab / Shift+Tab instead of the configured scroll mappings.
    var holdForwardForTabScroll: Bool
    /// Swaps scroll-up and scroll-down remapping only (does not change system scroll elsewhere).
    var invertScrollForRemapping: Bool

    static let `default` = AppConfig(
        isEnabled: false,
        activeProfile: .minimalPreset,
        toggleRemappingShortcut: .defaultToggleRemapping,
        lockPointerPosition: true,
        scrollNavigationStyle: .tabNavigation,
        holdForwardForTabScroll: true,
        invertScrollForRemapping: false
    )

    init(
        isEnabled: Bool,
        activeProfile: MappingProfile,
        toggleRemappingShortcut: Shortcut,
        lockPointerPosition: Bool,
        scrollNavigationStyle: ScrollNavigationStyle = .tabNavigation,
        holdForwardForTabScroll: Bool = true,
        invertScrollForRemapping: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.activeProfile = activeProfile
        self.toggleRemappingShortcut = toggleRemappingShortcut
        self.lockPointerPosition = lockPointerPosition
        self.scrollNavigationStyle = scrollNavigationStyle
        self.holdForwardForTabScroll = holdForwardForTabScroll
        self.invertScrollForRemapping = invertScrollForRemapping
    }

    func scrollTrigger(forDeltaY deltaY: Int64) -> InputTrigger? {
        if deltaY > 0 {
            return invertScrollForRemapping ? .scrollDown : .scrollUp
        }
        if deltaY < 0 {
            return invertScrollForRemapping ? .scrollUp : .scrollDown
        }
        return nil
    }

    func scrollAction(for trigger: InputTrigger, forwardButtonHeld: Bool) -> NavigationAction {
        if holdForwardForTabScroll, forwardButtonHeld {
            switch trigger {
            case .scrollUp: return .shiftTab
            case .scrollDown: return .tab
            default: break
            }
        }
        return activeProfile.action(for: trigger)
    }

    enum CodingKeys: String, CodingKey {
        case isEnabled
        case activeProfile
        case toggleRemappingShortcut
        case lockPointerPosition
        case scrollNavigationStyle
        case holdForwardForTabScroll
        case invertScrollForRemapping
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case scrollNavigation
    }

    private struct LegacyScrollNavigation: Decodable {
        let dualModeEnabled: Bool?
        let interactiveScrollUp: NavigationActionKind?
        let interactiveScrollDown: NavigationActionKind?
        let allElementsScrollUp: NavigationActionKind?
        let allElementsScrollDown: NavigationActionKind?
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        activeProfile = try container.decode(MappingProfile.self, forKey: .activeProfile)
        toggleRemappingShortcut = try container.decodeIfPresent(Shortcut.self, forKey: .toggleRemappingShortcut)
            ?? .defaultToggleRemapping
        lockPointerPosition = try container.decodeIfPresent(Bool.self, forKey: .lockPointerPosition) ?? true
        holdForwardForTabScroll = try container.decodeIfPresent(Bool.self, forKey: .holdForwardForTabScroll) ?? true
        invertScrollForRemapping = try container.decodeIfPresent(Bool.self, forKey: .invertScrollForRemapping) ?? false

        if let style = try container.decodeIfPresent(ScrollNavigationStyle.self, forKey: .scrollNavigationStyle) {
            scrollNavigationStyle = style
        } else if let legacyContainer = try? decoder.container(keyedBy: LegacyCodingKeys.self),
                  let legacy = try legacyContainer.decodeIfPresent(LegacyScrollNavigation.self, forKey: .scrollNavigation) {
            if legacy.dualModeEnabled == true {
                let up = legacy.interactiveScrollUp ?? .shiftTab
                let down = legacy.interactiveScrollDown ?? .tab
                activeProfile.setAction(NavigationAction(kind: up), for: .scrollUp)
                activeProfile.setAction(NavigationAction(kind: down), for: .scrollDown)
            }
            scrollNavigationStyle = ScrollNavigationStyle.infer(from: activeProfile)
        } else {
            scrollNavigationStyle = ScrollNavigationStyle.infer(from: activeProfile)
        }
    }
}
