import ApplicationServices
import Foundation

private func pointerMovementMask() -> CGEventMask {
    1 << CGEventType.mouseMoved.rawValue
}

final class InputRemappingService: NSObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var workerThread: Thread?
    private var currentRunLoop: CFRunLoop?

    private let lock = NSLock()
    private var configProvider: () -> AppConfig
    private var toggleShortcutProvider: () -> Shortcut
    private var onToggleRemapping: (() -> Void)?

    private(set) var isEventTapActive = false
    var onEventTapActiveChanged: ((Bool) -> Void)?

    init(
        configProvider: @escaping () -> AppConfig,
        toggleShortcutProvider: @escaping () -> Shortcut = { .defaultToggleRemapping }
    ) {
        self.configProvider = configProvider
        self.toggleShortcutProvider = toggleShortcutProvider
    }

    func updateConfigProvider(_ configProvider: @escaping () -> AppConfig) {
        lock.lock()
        self.configProvider = configProvider
        lock.unlock()
    }

    func updateToggleShortcutProvider(_ toggleShortcutProvider: @escaping () -> Shortcut) {
        lock.lock()
        self.toggleShortcutProvider = toggleShortcutProvider
        lock.unlock()
    }

    func setToggleRemappingHandler(_ handler: @escaping () -> Void) {
        lock.lock()
        onToggleRemapping = handler
        lock.unlock()
    }

    func restart() {
        stop()
        start()
    }

    func start() {
        lock.lock()
        guard workerThread == nil else {
            lock.unlock()
            return
        }
        let thread = Thread { [weak self] in
            self?.threadMain()
        }
        thread.name = "three-blind-mice.eventtap"
        workerThread = thread
        lock.unlock()
        thread.start()
    }

    func stop() {
        lock.lock()
        guard let thread = workerThread else {
            lock.unlock()
            setEventTapActive(false)
            return
        }
        lock.unlock()

        if Thread.current === thread {
            stopOnThread()
        } else {
            perform(#selector(stopOnThread), on: thread, with: nil, waitUntilDone: true)
        }

        lock.lock()
        workerThread = nil
        lock.unlock()
        setEventTapActive(false)
    }

    deinit {
        stop()
    }

    @objc private func stopOnThread() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource, let runLoop = currentRunLoop {
            CFRunLoopRemoveSource(runLoop, source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        if let runLoop = currentRunLoop {
            CFRunLoopStop(runLoop)
        }
        currentRunLoop = nil
    }

    private func threadMain() {
        defer { clearWorkerThreadIfCurrent() }

        autoreleasepool {
            guard createTap() else {
                setEventTapActive(false)
                return
            }
            currentRunLoop = CFRunLoopGetCurrent()
            if let source = runLoopSource, let runLoop = currentRunLoop {
                CFRunLoopAddSource(runLoop, source, .commonModes)
            }
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            setEventTapActive(true)
            CFRunLoopRun()
            setEventTapActive(false)
        }
    }

    private func clearWorkerThreadIfCurrent() {
        lock.lock()
        if workerThread === Thread.current {
            workerThread = nil
        }
        lock.unlock()
    }

    private func setEventTapActive(_ active: Bool) {
        lock.lock()
        isEventTapActive = active
        let callback = onEventTapActiveChanged
        lock.unlock()
        DispatchQueue.main.async {
            callback?(active)
        }
    }

    private func createTap() -> Bool {
        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.scrollWheel.rawValue) |
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue) |
            (1 << CGEventType.otherMouseDown.rawValue) |
            pointerMovementMask()

        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else { return Unmanaged.passUnretained(event) }
            let service = Unmanaged<InputRemappingService>.fromOpaque(userInfo).takeUnretainedValue()
            return service.handle(event: event, type: type)
        }

        let userInfo = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: userInfo
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        return runLoopSource != nil
    }

    private func handle(event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        if event.getIntegerValueField(.eventSourceUserData) == ActionExecutor.syntheticMarkerValue() {
            return Unmanaged.passUnretained(event)
        }

        lock.lock()
        let config = configProvider()
        let toggleShortcut = toggleShortcutProvider()
        let toggleHandler = onToggleRemapping
        lock.unlock()

        if toggleShortcut.matches(event: event, type: type) {
            if let toggleHandler {
                DispatchQueue.main.async(execute: toggleHandler)
            }
            return nil
        }

        guard config.isEnabled else {
            return Unmanaged.passUnretained(event)
        }

        // Let the settings panel scroll natively when the pointer is over its window.
        if type == .scrollWheel,
           SettingsWindowController.shared.shouldPassThroughScroll(at: event.location) {
            return Unmanaged.passUnretained(event)
        }

        if config.lockPointerPosition, type == .mouseMoved {
            PointerLockManager.shared.warpToLockedPositionIfNeeded()
            return nil
        }

        guard let trigger = triggerFrom(event: event, type: type) else {
            return Unmanaged.passUnretained(event)
        }

        let action = config.activeProfile.action(for: trigger)
        guard action.kind != .noAction else {
            return Unmanaged.passUnretained(event)
        }

        ActionExecutor.execute(action)
        return nil
    }

    private func triggerFrom(event: CGEvent, type: CGEventType) -> InputTrigger? {
        switch type {
        case .scrollWheel:
            let deltaY = scrollDeltaY(from: event)
            if deltaY > 0 {
                return .scrollUp
            }
            if deltaY < 0 {
                return .scrollDown
            }
            return nil
        case .leftMouseDown:
            return .leftClick
        case .rightMouseDown:
            return .rightClick
        case .otherMouseDown:
            let button = event.getIntegerValueField(.mouseEventButtonNumber)
            switch button {
            case 2: return .middleClick
            case 3: return .backButton
            case 4: return .forwardButton
            default: return nil
            }
        default:
            return nil
        }
    }

    private func scrollDeltaY(from event: CGEvent) -> Int64 {
        var delta = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        if delta == 0 {
            let fixed = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
            if fixed != 0 {
                delta = fixed > 0 ? 1 : -1
            }
        }
        if delta == 0 {
            let point = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
            if point != 0 {
                delta = point > 0 ? 1 : -1
            }
        }
        return delta
    }

}
