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
        profile.setAction(
            NavigationAction(
                kind: .customShortcut,
                shortcut: Shortcut(key: "k", modifiers: [.command, .shift])
            ),
            for: .forwardButton
        )

        let original = AppConfig(isEnabled: false, activeProfile: profile)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppConfig.self, from: encoded)

        XCTAssertEqual(decoded, original)
    }
}
