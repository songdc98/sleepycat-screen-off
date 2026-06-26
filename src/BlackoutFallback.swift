import Cocoa
import Darwin

if CommandLine.arguments.contains("--self-test") {
    print("BlackoutFallback OK")
    exit(0)
}

final class BlackoutWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windows: [NSWindow] = []
    private var eventMonitors: [Any] = []
    private let startedAt = Date()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSCursor.hide()

        for screen in NSScreen.screens {
            let window = BlackoutWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.backgroundColor = .black
            window.isOpaque = true
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.orderFrontRegardless()
            windows.append(window)
        }

        windows.first?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        let mask: NSEvent.EventTypeMask = [
            .keyDown,
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .mouseMoved,
            .scrollWheel
        ]

        if let localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.terminateAfterStartupGrace()
            return event
        }) {
            eventMonitors.append(localMonitor)
        }

        if let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] _ in
            self?.terminateAfterStartupGrace()
        }) {
            eventMonitors.append(globalMonitor)
        }
    }

    private func terminateAfterStartupGrace() {
        if Date().timeIntervalSince(startedAt) > 0.8 {
            NSApp.terminate(nil)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        for monitor in eventMonitors {
            NSEvent.removeMonitor(monitor)
        }
        NSCursor.unhide()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
