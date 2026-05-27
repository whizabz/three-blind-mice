import AppKit
import SwiftUI

final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private weak var appState: AppState?
    private var window: NSWindow?
    private var hostingController: NSHostingController<AnyView>?

    private let passthroughLock = NSLock()
    private var passthroughScreenFrame: CGRect = .zero
    private var passthroughEnabled = false
    private var hasAppliedInitialFrame = false

    /// Let native scroll reach the settings window when the pointer is over it (readable from the event-tap thread).
    func shouldPassThroughScroll(at screenLocation: CGPoint) -> Bool {
        passthroughLock.lock()
        defer { passthroughLock.unlock() }
        return passthroughEnabled && passthroughScreenFrame.contains(screenLocation)
    }

    @MainActor
    func show(appState: AppState) {
        self.appState = appState

        if let window {
            present(window: window)
            return
        }

        let rootView = AnyView(
            SettingsView()
                .environmentObject(appState)
        )

        let hostingController = NSHostingController(rootView: rootView)
        self.hostingController = hostingController

        let contentView = hostingController.view
        contentView.autoresizingMask = [.width, .height]

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 460),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Three Blind Mice Settings"
        window.contentView = contentView
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 520, height: 320)
        window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        window.center()

        self.window = window
        present(window: window)
    }

    @MainActor
    func windowWillClose(_ notification: Notification) {
        clearPassthroughFrame()
        NSApp.setActivationPolicy(.accessory)
        appState?.syncPointerLock()
    }

    @MainActor
    func windowDidBecomeKey(_ notification: Notification) {
        refreshPassthroughFrame()
    }

    @MainActor
    func windowDidResignKey(_ notification: Notification) {
        refreshPassthroughFrame()
    }

    @MainActor
    func windowDidMove(_ notification: Notification) {
        refreshPassthroughFrame()
    }

    @MainActor
    func windowDidResize(_ notification: Notification) {
        refreshPassthroughFrame()
    }

    @MainActor
    private func present(window: NSWindow) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if !hasAppliedInitialFrame {
            applyPreferredFrameWithinVisibleScreen(window)
            hasAppliedInitialFrame = true
        } else {
            keepWindowWithinVisibleScreen(window)
        }
        window.makeKeyAndOrderFront(nil)
        // Rebound after ordering front so `window.screen` is stable.
        DispatchQueue.main.async { [weak self, weak window] in
            guard let self, let window else { return }
            self.keepWindowWithinVisibleScreen(window)
            self.refreshPassthroughFrame()
        }
        refreshPassthroughFrame()
    }

    @MainActor
    private func applyPreferredFrameWithinVisibleScreen(_ window: NSWindow) {
        guard let screen = screenForWindowPlacement(window) else { return }
        let visible = screen.visibleFrame
        let marginX: CGFloat = 24
        let marginY: CGFloat = 24
        let maxWidth = max(420, visible.width - marginX * 2)
        let maxHeight = max(300, visible.height - marginY * 2)

        let preferredWidth: CGFloat = 560
        // Always start well below screen height so scrolling is available.
        let preferredHeight: CGFloat = min(460, visible.height * 0.7)
        let width = min(preferredWidth, maxWidth)
        let height = min(preferredHeight, maxHeight)

        let x = visible.midX - width / 2
        let y = visible.midY - height / 2
        var frame = NSRect(x: x, y: y, width: width, height: height)
        frame.origin.x = min(max(frame.origin.x, visible.minX + marginX), visible.maxX - frame.size.width - marginX)
        frame.origin.y = min(max(frame.origin.y, visible.minY + marginY), visible.maxY - frame.size.height - marginY)

        window.setFrame(frame, display: true)
    }

    @MainActor
    private func keepWindowWithinVisibleScreen(_ window: NSWindow) {
        guard let screen = screenForWindowPlacement(window) else { return }
        let visible = screen.visibleFrame
        let marginX: CGFloat = 24
        let marginY: CGFloat = 24

        var frame = window.frame
        let maxWidth = max(420, visible.width - marginX * 2)
        let maxHeight = max(300, visible.height - marginY * 2)
        frame.size.width = min(frame.size.width, maxWidth)
        frame.size.height = min(frame.size.height, maxHeight)

        frame.origin.x = min(max(frame.origin.x, visible.minX + marginX), visible.maxX - frame.size.width - marginX)
        frame.origin.y = min(max(frame.origin.y, visible.minY + marginY), visible.maxY - frame.size.height - marginY)
        window.setFrame(frame, display: true)
    }

    @MainActor
    private func screenForWindowPlacement(_ window: NSWindow) -> NSScreen? {
        if let winScreen = window.screen {
            return winScreen
        }
        let mouse = NSEvent.mouseLocation
        if let underMouse = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) {
            return underMouse
        }
        return NSScreen.main ?? NSScreen.screens.first
    }

    @MainActor
    private func refreshPassthroughFrame() {
        guard let window, window.isVisible else {
            clearPassthroughFrame()
            return
        }
        passthroughLock.lock()
        passthroughEnabled = true
        passthroughScreenFrame = window.frame
        passthroughLock.unlock()
    }

    @MainActor
    private func clearPassthroughFrame() {
        passthroughLock.lock()
        passthroughEnabled = false
        passthroughScreenFrame = .zero
        passthroughLock.unlock()
    }
}
