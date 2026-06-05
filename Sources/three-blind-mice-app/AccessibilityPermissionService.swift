import AppKit
import ApplicationServices
import Foundation
import Security

enum AccessibilityPermissionService {
    enum CodeSigningKind: Equatable {
        case appleDevelopment(teamID: String)
        case adHoc
        case unknown
    }

    struct Diagnostics: Equatable {
        let isTrusted: Bool
        let bundleIdentifier: String
        let bundlePath: String
        let executablePath: String
        let codeSigningKind: CodeSigningKind
        let codeSigningSummary: String
        /// True when macOS will likely invalidate Accessibility after the next rebuild.
        let permissionResetsOnRebuild: Bool
    }

    static func diagnostics() -> Diagnostics {
        let signingKind = codeSigningKind()
        return Diagnostics(
            isTrusted: AXIsProcessTrusted(),
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "(none — use ThreeBlindMice.xcodeproj)",
            bundlePath: Bundle.main.bundlePath,
            executablePath: Bundle.main.executableURL?.path
                ?? ProcessInfo.processInfo.arguments.first
                ?? "unknown",
            codeSigningKind: signingKind,
            codeSigningSummary: summary(for: signingKind),
            permissionResetsOnRebuild: signingKind == .adHoc
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

    static func codeSigningKind() -> CodeSigningKind {
        guard let url = Bundle.main.bundleURL as CFURL? else { return .unknown }

        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url, [], &staticCode) == errSecSuccess,
              let staticCode else {
            return .unknown
        }

        var signingInfo: CFDictionary?
        guard SecCodeCopySigningInformation(
            staticCode,
            SecCSFlags(rawValue: kSecCSSigningInformation),
            &signingInfo
        ) == errSecSuccess,
              let info = signingInfo as? [String: Any] else {
            return .unknown
        }

        if let teamID = info[kSecCodeInfoTeamIdentifier as String] as? String, !teamID.isEmpty {
            return .appleDevelopment(teamID: teamID)
        }

        return .adHoc
    }

    private static func summary(for kind: CodeSigningKind) -> String {
        switch kind {
        case .appleDevelopment(let teamID):
            return "Apple Development (team \(teamID))"
        case .adHoc:
            return "Ad hoc — permission resets each rebuild"
        case .unknown:
            return "Unknown"
        }
    }
}
