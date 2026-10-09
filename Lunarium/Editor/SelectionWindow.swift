import AppKit

final class SelectionWindow: NSWindow {
    var onFinish: (() -> Void)?
    private let overlay: SelectionView

    init(snapshot: ScreenSnapshot) {
        overlay = SelectionView(snapshot: snapshot)
        // The screen-taking convenience initializer calls back into the
        // subclass's unimplemented designated initializer and traps in Swift.
        // Borderless content coordinates already identify the target screen.
        super.init(contentRect: snapshot.screen.frame,
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false)
        title = "Lunarium Capture"
        level = .screenSaver
        backgroundColor = .black
        isOpaque = true
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        acceptsMouseMovedEvents = true
        isReleasedWhenClosed = false
        contentView = overlay
        makeFirstResponder(overlay)
        overlay.onFinish = { [weak self] in self?.onFinish?() }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if overlay.performCaptureShortcut(with: event) { return true }
        return super.performKeyEquivalent(with: event)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
