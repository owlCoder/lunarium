import AppKit
import SwiftUI
import Carbon.HIToolbox

struct ShortcutRecorder: NSViewRepresentable {
    let shortcut: CaptureShortcut
    let onChange: (CaptureShortcut) -> Void
    let onInvalid: () -> Void

    func makeNSView(context: Context) -> RecorderButton {
        let view = RecorderButton(frame: .zero)
        view.update(shortcut: shortcut, onChange: onChange, onInvalid: onInvalid)
        return view
    }
    func updateNSView(_ nsView: RecorderButton, context: Context) {
        nsView.update(shortcut: shortcut, onChange: onChange, onInvalid: onInvalid)
    }
}

final class RecorderButton: NSButton {
    private var recording = false
    private var changed: ((CaptureShortcut) -> Void)?
    private var invalid: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    func update(shortcut: CaptureShortcut,
                onChange: @escaping (CaptureShortcut) -> Void,
                onInvalid: @escaping () -> Void) {
        changed = onChange
        invalid = onInvalid
        bezelStyle = .rounded
        setButtonType(.momentaryPushIn)
        focusRingType = .exterior
        target = self
        action = #selector(beginRecording)
        if !recording { title = shortcut.displayName }
        toolTip = NSLocalizedString("shortcut.record.hint", value: "Click, then press keys. Escape cancels.", comment: "")
        setAccessibilityLabel(NSLocalizedString("shortcut.record", value: "Record shortcut", comment: ""))
    }

    @objc private func beginRecording() {
        recording = true
        title = NSLocalizedString("shortcut.recording", value: "Press keys…", comment: "")
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard recording else { return super.keyDown(with: event) }
        if event.keyCode == UInt16(kVK_Escape) {
            recording = false
            title = CaptureShortcut.load().displayName
            return
        }
        guard let shortcut = CaptureShortcut.from(event: event) else {
            NSSound.beep()
            invalid?()
            return
        }
        recording = false
        title = shortcut.displayName
        changed?(shortcut)
    }

    override func resignFirstResponder() -> Bool {
        if recording {
            recording = false
            title = CaptureShortcut.load().displayName
        }
        return super.resignFirstResponder()
    }
}
