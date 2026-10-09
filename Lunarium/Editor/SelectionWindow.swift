import AppKit

final class SelectionWindow: NSWindow {
    var onFinish: (() -> Void)?
    private let overlay: SelectionView

    init(snapshot: ScreenSnapshot) {
        overlay = SelectionView(snapshot: snapshot)
        super.init(contentRect: snapshot.screen.frame,
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false,
                   screen: snapshot.screen)
        level = .screenSaver
        backgroundColor = .black
        isOpaque = true
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        acceptsMouseMovedEvents = true
        isReleasedWhenClosed = false
        contentView = overlay
        overlay.onFinish = { [weak self] in self?.onFinish?() }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
