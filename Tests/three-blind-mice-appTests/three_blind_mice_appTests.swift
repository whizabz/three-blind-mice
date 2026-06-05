import XCTest
@testable import three_blind_mice_app

final class ThreeBlindMiceAppTests: XCTestCase {
    func testMinimalPresetUsesConservativeDefaults() throws {
        let preset = MappingProfile.minimalPreset
        XCTAssertEqual(preset.action(for: .scrollDown).kind, .tab)
        XCTAssertEqual(preset.action(for: .scrollUp).kind, .shiftTab)
        XCTAssertEqual(preset.action(for: .leftClick).kind, .enter)
        XCTAssertEqual(preset.action(for: .rightClick).kind, .space)
        XCTAssertEqual(preset.action(for: .backButton).kind, .noAction)
    }

    func testAppConfigRoundTripsThroughJSON() throws {
        var profile = MappingProfile.minimalPreset
        profile.setAction(NavigationAction(kind: .escape), for: .middleClick)

        let original = AppConfig(
            isEnabled: false,
            activeProfile: profile,
            toggleRemappingShortcut: .defaultToggleRemapping,
            lockPointerPosition: false,
            scrollNavigationStyle: .arrowNavigation
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppConfig.self, from: encoded)

        XCTAssertEqual(decoded, original)
    }

    func testScrollNavigationStyleAppliesTabMappings() {
        var profile = MappingProfile.minimalPreset
        ScrollNavigationStyle.tabNavigation.applyToProfile(&profile)
        XCTAssertEqual(profile.action(for: .scrollUp).kind, .shiftTab)
        XCTAssertEqual(profile.action(for: .scrollDown).kind, .tab)
    }

    func testScrollNavigationStyleAppliesArrowMappings() {
        var profile = MappingProfile.minimalPreset
        ScrollNavigationStyle.arrowNavigation.applyToProfile(&profile)
        XCTAssertEqual(profile.action(for: .scrollUp).kind, .leftArrow)
        XCTAssertEqual(profile.action(for: .scrollDown).kind, .rightArrow)
    }

    func testScrollNavigationStyleInfersFromProfile() {
        var profile = MappingProfile.minimalPreset
        ScrollNavigationStyle.arrowNavigation.applyToProfile(&profile)
        XCTAssertEqual(ScrollNavigationStyle.infer(from: profile), .arrowNavigation)
    }

    func testForwardButtonHeldUsesTabScroll() {
        var config = AppConfig.default
        ScrollNavigationStyle.arrowNavigation.applyToProfile(&config.activeProfile)
        config.holdForwardForTabScroll = true

        XCTAssertEqual(
            config.scrollAction(for: .scrollDown, forwardButtonHeld: true).kind,
            .tab
        )
        XCTAssertEqual(
            config.scrollAction(for: .scrollUp, forwardButtonHeld: true).kind,
            .shiftTab
        )
        XCTAssertEqual(
            config.scrollAction(for: .scrollDown, forwardButtonHeld: false).kind,
            .rightArrow
        )
    }

    func testForwardButtonHeldIgnoredWhenDisabled() {
        var config = AppConfig.default
        ScrollNavigationStyle.arrowNavigation.applyToProfile(&config.activeProfile)
        config.holdForwardForTabScroll = false

        XCTAssertEqual(
            config.scrollAction(for: .scrollDown, forwardButtonHeld: true).kind,
            .rightArrow
        )
    }

    func testInvertScrollForRemappingSwapsScrollTriggers() {
        var config = AppConfig.default
        config.invertScrollForRemapping = true

        XCTAssertEqual(config.scrollTrigger(forDeltaY: 1), .scrollDown)
        XCTAssertEqual(config.scrollTrigger(forDeltaY: -1), .scrollUp)
        XCTAssertNil(config.scrollTrigger(forDeltaY: 0))
    }

    func testLegacyDualModeScrollConfigMigratesToProfile() throws {
        let json = """
        {
          "isEnabled": true,
          "activeProfile": {
            "name": "Minimal Preset",
            "mappings": {
              "scrollUp": { "kind": "shiftTab" },
              "scrollDown": { "kind": "tab" },
              "leftClick": { "kind": "enter" },
              "rightClick": { "kind": "space" },
              "middleClick": { "kind": "noAction" },
              "backButton": { "kind": "noAction" },
              "forwardButton": { "kind": "noAction" }
            }
          },
          "toggleRemappingShortcut": { "key": "m", "modifiers": ["control", "option"] },
          "lockPointerPosition": true,
          "scrollNavigation": {
            "dualModeEnabled": true,
            "interactiveScrollUp": "leftArrow",
            "interactiveScrollDown": "rightArrow"
          }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AppConfig.self, from: json)
        XCTAssertEqual(decoded.activeProfile.action(for: .scrollUp).kind, .leftArrow)
        XCTAssertEqual(decoded.activeProfile.action(for: .scrollDown).kind, .rightArrow)
    }
}
