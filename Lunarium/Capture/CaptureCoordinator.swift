import AppKit
import CoreGraphics

@MainActor
final class CaptureCoordinator {
    private var windows: [SelectionWindow] = []
    private var busy = false

    func start() {
        guard !busy else { return }
        busy = true
        Task { @MainActor in
            do {
                guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
                    presentError("Screen Recording permission is needed. Enable Lunarium in System Settings → Privacy & Security → Screen & System Audio Recording, then relaunch it if macOS asks.")
                    busy = false
                    return
                }
                let shots = try await CaptureService.captureAllScreens()
                windows = shots.map { shot in
                    let window = SelectionWindow(snapshot: shot)
                    window.onFinish = { [weak self] in self?.dismiss() }
                    return window
                }
                windows.forEach { $0.orderFrontRegardless() }
                windows.first?.makeKey()
            } catch {
                presentError(error.localizedDescription)
                busy = false
            }
        }
    }

    private func dismiss() {
        windows.forEach { $0.close() }
        windows.removeAll()
        busy = false
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
