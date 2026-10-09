import AppKit

/// Neutral controls keep the toolbar readable over any captured background.
final class CaptureToolbarButton: NSButton {
    var isSelectedTool = false { didSet { updateAppearance() } }
    var isProminent = false { didSet { updateAppearance() } }
    private var isHovered = false
    private var hoverArea: NSTrackingArea?

    init(symbol: String, label: String, visibleTitle: String? = nil) {
        super.init(frame: .zero)
        cell = CaptureToolbarButtonCell(textCell: visibleTitle ?? "")
        title = visibleTitle ?? ""
        image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        imagePosition = visibleTitle == nil ? .imageOnly : .imageLeading
        imageScaling = .scaleProportionallyDown
        font = .systemFont(ofSize: 12, weight: .semibold)
        isBordered = false
        bezelStyle = .regularSquare
        toolTip = label
        setAccessibilityLabel(label)
        wantsLayer = true
        layer?.cornerRadius = 7
        heightAnchor.constraint(equalToConstant: 32).isActive = true
        updateAppearance()
    }

    required init?(coder: NSCoder) { nil }

    override func updateTrackingAreas() {
        if let hoverArea { removeTrackingArea(hoverArea) }
        let area = NSTrackingArea(rect: .zero,
                                 options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                 owner: self, userInfo: nil)
        addTrackingArea(area)
        hoverArea = area
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        updateAppearance()
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        updateAppearance()
    }

    private func updateAppearance() {
        let foreground: NSColor
        let background: NSColor
        if isProminent {
            foreground = .black
            background = NSColor.white.withAlphaComponent(isHovered ? 0.85 : 1)
        } else {
            foreground = NSColor.white.withAlphaComponent(isSelectedTool || isHovered ? 1 : 0.78)
            background = NSColor.white.withAlphaComponent(isSelectedTool ? 0.18 : (isHovered ? 0.10 : 0))
        }
        contentTintColor = foreground
        attributedTitle = NSAttributedString(string: title, attributes: [
            .font: font ?? NSFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: foreground
        ])
        layer?.backgroundColor = background.cgColor
    }
}

/// Center the icon and title as one group, with the same gap on both actions.
private final class CaptureToolbarButtonCell: NSButtonCell {
    private let iconSize: CGFloat = 16
    private let titleGap: CGFloat = 7

    override func imageRect(forBounds rect: NSRect) -> NSRect {
        let contentWidth = title.isEmpty ? iconSize : iconSize + titleGap + attributedTitle.size().width
        return NSRect(x: rect.midX - contentWidth / 2, y: rect.midY - iconSize / 2,
                      width: iconSize, height: iconSize)
    }

    override func titleRect(forBounds rect: NSRect) -> NSRect {
        guard !title.isEmpty else { return .zero }
        let size = attributedTitle.size()
        let contentWidth = iconSize + titleGap + size.width
        return NSRect(x: rect.midX - contentWidth / 2 + iconSize + titleGap,
                      y: rect.midY - size.height / 2, width: size.width, height: size.height)
    }
}
