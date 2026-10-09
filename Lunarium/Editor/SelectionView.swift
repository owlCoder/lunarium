import AppKit

/// A zero-dependency, AppKit-only selection and annotation canvas.
/// Screen coordinates are in points; export rasterizes at capture pixel scale.
final class SelectionView: NSView, NSTextFieldDelegate {
    var onFinish: (() -> Void)?
    private let snapshot: ScreenSnapshot
    private var dragOrigin: CGPoint?
    private var selection: CGRect?
    private var isEditing = false
    private var activeTool: AnnotationTool = .pen
    private var annotations: [Annotation] = []
    private var preview: Annotation?
    private var toolbar: NSVisualEffectView?
    private var toolButtons: [NSButton] = []
    private var textField: NSTextField?
    private var textOrigin: CGPoint?
    private var inkColor: NSColor = .systemPurple

    init(snapshot: ScreenSnapshot) {
        self.snapshot = snapshot
        super.init(frame: CGRect(origin: .zero, size: snapshot.screen.frame.size))
        wantsLayer = true
    }

    required init?(coder: NSCoder) { nil }

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    private func clamped(_ p: CGPoint) -> CGPoint {
        CGPoint(x: max(bounds.minX, min(bounds.maxX, p.x)),
                y: max(bounds.minY, min(bounds.maxY, p.y)))
    }

    private func dragRect(_ a: CGPoint, _ b: CGPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
               width: abs(a.x - b.x), height: abs(a.y - b.y))
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let image = NSImage(cgImage: snapshot.image, size: bounds.size)
        image.draw(in: bounds, from: .zero, operation: .copy, fraction: 1)

        let shade = NSBezierPath(rect: bounds)
        if let selection {
            shade.appendRect(selection)
            shade.windingRule = .evenOdd
        }
        NSColor.black.withAlphaComponent(0.40).setFill()
        shade.fill()

        guard let selection, selection.width > 0, selection.height > 0 else {
            drawHint()
            return
        }

        NSColor.systemPurple.setStroke()
        let outline = NSBezierPath(rect: selection)
        outline.lineWidth = 1.8
        outline.stroke()

        if isEditing {
            NSGraphicsContext.saveGraphicsState()
            NSBezierPath(rect: selection).addClip()
            for annotation in annotations where annotation.tool != .redact { annotation.draw() }
            if preview?.tool != .redact { preview?.draw() }
            for annotation in annotations where annotation.tool == .redact { annotation.draw() }
            if preview?.tool == .redact { preview?.draw() }
            NSGraphicsContext.restoreGraphicsState()
        }
        drawDimensions(for: selection)
    }

    private func drawHint() {
        let title = NSLocalizedString("editor.hint", value: "Drag to capture  ·  Esc to cancel", comment: "") as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = title.size(withAttributes: attributes)
        let frame = CGRect(x: (bounds.width - size.width) / 2 - 18,
                           y: bounds.midY - 26, width: size.width + 36, height: 52)
        NSColor.black.withAlphaComponent(0.45).setFill()
        NSBezierPath(roundedRect: frame, xRadius: 12, yRadius: 12).fill()
        title.draw(at: CGPoint(x: frame.minX + 18, y: frame.minY + 17), withAttributes: attributes)
    }

    private func drawDimensions(for rect: CGRect) {
        let caption = "\(Int(rect.width)) × \(Int(rect.height))" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let width = caption.size(withAttributes: attributes).width + 18
        let x = max(8, min(rect.minX, bounds.maxX - width - 8))
        let y = rect.maxY + 7 + 22 < bounds.maxY ? rect.maxY + 7 : rect.maxY - 27
        let frame = CGRect(x: x, y: y, width: width, height: 22)
        NSColor.black.withAlphaComponent(0.75).setFill()
        NSBezierPath(roundedRect: frame, xRadius: 6, yRadius: 6).fill()
        caption.draw(at: CGPoint(x: frame.minX + 9, y: frame.minY + 4), withAttributes: attributes)
    }

    override func mouseDown(with event: NSEvent) {
        let p = clamped(convert(event.locationInWindow, from: nil))
        guard isEditing else {
            selection = nil
            dragOrigin = p
            needsDisplay = true
            return
        }
        guard let selection, selection.contains(p) else { return }
        if activeTool == .text {
            beginText(at: p)
        } else {
            preview = Annotation(tool: activeTool, start: p, end: p, points: [p], color: inkColor)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let p = clamped(convert(event.locationInWindow, from: nil))
        if !isEditing, let origin = dragOrigin {
            selection = dragRect(origin, p)
        } else if var annotation = preview, let selection {
            annotation.end = CGPoint(x: max(selection.minX, min(selection.maxX, p.x)),
                                     y: max(selection.minY, min(selection.maxY, p.y)))
            if annotation.tool == .pen { annotation.points.append(annotation.end) }
            preview = annotation
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let p = clamped(convert(event.locationInWindow, from: nil))
        if !isEditing {
            guard let origin = dragOrigin else { return }
            dragOrigin = nil
            let rect = dragRect(origin, p)
            guard rect.width >= 10, rect.height >= 10 else {
                selection = nil
                needsDisplay = true
                return
            }
            selection = rect
            isEditing = true
            showToolbar()
        } else if var annotation = preview {
            if annotation.tool.isImageEffect {
                annotation.effectImage = ImageEffectRenderer.makeEffect(tool: annotation.tool,
                    source: snapshot.image, screenSize: bounds.size, rect: annotation.rect)
            }
            annotations.append(annotation)
            preview = nil
        }
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onFinish?()
        } else if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "z" {
            if !annotations.isEmpty { annotations.removeLast() }
            needsDisplay = true
        } else {
            super.keyDown(with: event)
        }
    }

    private func showToolbar() {
        guard let selection else { return }
        toolbar?.removeFromSuperview()
        toolButtons.removeAll()

        let panel = NSVisualEffectView(frame: CGRect(x: 0, y: 0, width: 548, height: 48))
        panel.material = .hudWindow
        panel.blendingMode = .withinWindow
        panel.state = .active
        panel.wantsLayer = true
        panel.layer?.cornerRadius = 13
        panel.layer?.masksToBounds = true
        panel.layer?.borderColor = NSColor.white.withAlphaComponent(0.16).cgColor
        panel.layer?.borderWidth = 1

        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 3
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 7, bottom: 6, right: 7)
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            stack.topAnchor.constraint(equalTo: panel.topAnchor),
            stack.bottomAnchor.constraint(equalTo: panel.bottomAnchor)
        ])

        for tool in AnnotationTool.allCases {
            let button = makeButton(symbol: tool.symbol, title: tool.title,
                                    action: #selector(selectTool(_:)))
            button.tag = tool.rawValue
            toolButtons.append(button)
            stack.addArrangedSubview(button)
        }
        let colorWell = NSColorWell(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        colorWell.color = inkColor
        colorWell.target = self
        colorWell.action = #selector(changeColor(_:))
        colorWell.toolTip = NSLocalizedString("tool.color", value: "Annotation color", comment: "")
        colorWell.widthAnchor.constraint(equalToConstant: 30).isActive = true
        stack.addArrangedSubview(colorWell)
        let separator = NSBox()
        separator.boxType = .separator
        separator.setFrameSize(NSSize(width: 1, height: 24))
        stack.addArrangedSubview(separator)
        stack.addArrangedSubview(makeButton(symbol: "arrow.uturn.backward", title: NSLocalizedString("tool.undo", value: "Undo", comment: "") + " (⌘Z)",
                                            action: #selector(undoAnnotation)))
        stack.addArrangedSubview(makeButton(symbol: "doc.on.doc", title: NSLocalizedString("tool.copy", value: "Copy PNG", comment: ""),
                                            action: #selector(copyImage)))
        stack.addArrangedSubview(makeButton(symbol: "square.and.arrow.down", title: NSLocalizedString("tool.save", value: "Save PNG", comment: ""),
                                            action: #selector(saveImage)))
        stack.addArrangedSubview(makeButton(symbol: "xmark", title: NSLocalizedString("tool.close", value: "Close", comment: "") + " (Esc)",
                                            action: #selector(closeCapture)))

        let x = max(8, min(selection.minX, bounds.width - panel.frame.width - 8))
        let y = selection.minY - 60 >= 8 ? selection.minY - 60 :
                 min(selection.maxY + 12, bounds.height - panel.frame.height - 8)
        panel.setFrameOrigin(NSPoint(x: x, y: max(8, y)))
        addSubview(panel)
        toolbar = panel
        updateToolButtons()
    }

    private func makeButton(symbol: String, title: String, action: Selector) -> NSButton {
        let button = NSButton()
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        button.imagePosition = .imageOnly
        button.isBordered = false
        button.toolTip = title
        button.bezelStyle = .regularSquare
        button.target = self
        button.action = action
        button.widthAnchor.constraint(equalToConstant: 34).isActive = true
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        button.wantsLayer = true
        button.layer?.cornerRadius = 8
        return button
    }

    private func updateToolButtons() {
        for button in toolButtons {
            let active = button.tag == activeTool.rawValue
            button.contentTintColor = active ? .systemPurple : .labelColor
            button.layer?.backgroundColor = active ? NSColor.systemPurple.withAlphaComponent(0.17).cgColor : nil
        }
    }

    @objc private func changeColor(_ sender: NSColorWell) {
        inkColor = sender.color
    }

    @objc private func selectTool(_ sender: NSButton) {
        if let tool = AnnotationTool(rawValue: sender.tag) {
            activeTool = tool
            updateToolButtons()
        }
    }

    @objc private func undoAnnotation() {
        if !annotations.isEmpty { annotations.removeLast() }
        needsDisplay = true
    }

    @objc private func closeCapture() { onFinish?() }

    @objc private func copyImage() {
        commitTextIfNeeded()
        guard let data = ExportService.pngData(image: snapshot.image,
                                               in: selection ?? .zero,
                                               viewSize: bounds.size,
                                               annotations: annotations) else { return }
        ExportService.copyToClipboard(data)
        onFinish?()
    }

    @objc private func saveImage() {
        commitTextIfNeeded()
        guard let data = ExportService.pngData(image: snapshot.image,
                                               in: selection ?? .zero,
                                               viewSize: bounds.size,
                                               annotations: annotations) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = ExportService.suggestedName
        // The screen-saver-level overlay would otherwise cover the save panel.
        window?.orderOut(nil)
        panel.begin { [weak self] result in
            guard let self else { return }
            if result == .OK, let url = panel.url {
                do {
                    try data.write(to: url, options: .atomic)
                    self.onFinish?()
                } catch {
                    self.window?.orderFrontRegardless()
                    self.showError(error.localizedDescription)
                }
            } else {
                self.window?.orderFrontRegardless()
                self.window?.makeKey()
            }
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("editor.saveError", value: "Could not save screenshot", comment: "")
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func beginText(at position: CGPoint) {
        commitTextIfNeeded()
        guard let selection else { return }
        let field = NSTextField(frame: CGRect(x: position.x, y: position.y,
                                              width: min(220, selection.maxX - position.x),
                                              height: 30))
        field.stringValue = ""
        field.font = .systemFont(ofSize: 19, weight: .semibold)
        field.textColor = inkColor
        field.drawsBackground = true
        field.backgroundColor = .windowBackgroundColor
        field.isBezeled = true
        field.delegate = self
        addSubview(field)
        textField = field
        textOrigin = position
        window?.makeFirstResponder(field)
    }

    func controlTextDidEndEditing(_ obj: Notification) { commitTextIfNeeded() }

    private func commitTextIfNeeded() {
        guard let field = textField, let point = textOrigin else { return }
        let value = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        textField = nil
        textOrigin = nil
        field.removeFromSuperview()
        if !value.isEmpty {
            annotations.append(Annotation(tool: .text, start: point, end: point, text: value, color: inkColor))
            needsDisplay = true
        }
        window?.makeFirstResponder(self)
    }
}
