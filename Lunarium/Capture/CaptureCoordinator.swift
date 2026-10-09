import AppKit
import CoreGraphics

@MainActor
final class CaptureCoordinator {
    private var windows: [SelectionWindow] = []
    private var busy = false
    private var previousApplication: NSRunningApplication?

    func start() {
        guard !busy else { return }
        busy = true
        let frontmost = NSWorkspace.shared.frontmostApplication
        previousApplication = frontmost?.processIdentifier == ProcessInfo.processInfo.processIdentifier ? nil : frontmost
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting-capture") {
            present(FixtureCapture.make())
            return
        }
        #endif
        Task { @MainActor in
            do {
                guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
                    presentError("Screen Recording permission is needed. Enable Lunarium in System Settings → Privacy & Security → Screen & System Audio Recording, then relaunch it if macOS asks.")
                    busy = false
                    return
                }
                let shots = try await CaptureService.captureAllScreens()
                present(shots)
            } catch {
                presentError(error.localizedDescription)
                busy = false
            }
        }
    }

    private func present(_ shots: [ScreenSnapshot]) {
        guard !shots.isEmpty else {
            busy = false
            return
        }
        windows = shots.map { shot in
            let window = SelectionWindow(snapshot: shot)
            window.onFinish = { [weak self] in self?.dismiss() }
            return window
        }
        NSApp.activate(ignoringOtherApps: true)
        windows.forEach { $0.orderFrontRegardless() }
        windows.first?.makeKeyAndOrderFront(nil)
    }

    private func dismiss() {
        windows.forEach { $0.close() }
        windows.removeAll()
        busy = false
        previousApplication?.activate(options: [])
        previousApplication = nil
    }

    private func presentError(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Lunarium couldn't capture your screen"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
