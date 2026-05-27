import AppKit
import CoreGraphics

/// Keeps the cursor at a fixed screen position while remapping is active so movement
/// does not trigger hover or hit-testing under the pointer.
final class PointerLockManager {
    static let shared = PointerLockManager()

    private let lock = NSLock()
    private var lockedPosition: CGPoint?
    private var isCursorHidden = false
    private var isSuspended = false

    private init() {}

    func setSuspended(_ suspended: Bool) {
        lock.lock()
        isSuspended = suspended
        lock.unlock()
        if suspended {
            restoreCursor()
        }
    }

    func activateLock(at position: CGPoint) {
        lock.lock()
        lockedPosition = position
        lock.unlock()
        DispatchQueue.main.async {
            self.hideCursor()
            CGWarpMouseCursorPosition(position)
        }
    }

    func deactivateLock() {
        lock.lock()
        lockedPosition = nil
        lock.unlock()
        DispatchQueue.main.async {
            self.restoreCursor()
        }
    }

    func warpToLockedPositionIfNeeded() {
        lock.lock()
        let suspended = isSuspended
        let position = lockedPosition
        lock.unlock()
        guard !suspended, let position else { return }
        CGWarpMouseCursorPosition(position)
    }

    private func hideCursor() {
        guard !isCursorHidden else { return }
        NSCursor.hide()
        isCursorHidden = true
    }

    private func restoreCursor() {
        guard isCursorHidden else { return }
        NSCursor.unhide()
        isCursorHidden = false
    }
}
