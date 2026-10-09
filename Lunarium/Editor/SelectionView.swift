import AppKit
import Carbon.HIToolbox

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
    private var toolButtons: [CaptureToolbarButton] = []
    private var textField: NSTextField?
    private var textOrigin: CGPoint?
    private var inkColor: NSColor = .systemPurple

    init(snapshot: ScreenSnapshot) {
        self.snapshot = snapshot
        super.init(frame: CGRect(origin: .zero, size: snapshot.screen.frame.size))
        wantsLayer = true
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel(NSLocalizedString("editor.canvas", value: "Screenshot editor", comment: ""))
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
        NSColor.black.withAlphaComponent(0.34).setFill()
        shade.fill()

        guard let selection, selection.width > 0, selection.height > 0 else {
            drawHint()
            return
        }

        let outline = NSBezierPath(rect: selection)
        NSColor.black.withAlphaComponent(0.45).setStroke()
        outline.lineWidth = 3
        outline.stroke()
        NSColor.white.withAlphaComponent(0.95).setStroke()
        outline.lineWidth = 1
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
        if !isEditing { drawDimensions(for: selection) }
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
        if performCaptureShortcut(with: event) {
            return
        } else if event.keyCode == 53 { // Escape
            onFinish?()
        } else if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "z" {
            if !annotations.isEmpty { annotations.removeLast() }
            needsDisplay = true
        } else {
            super.keyDown(with: event)
        }
    }

    /// Handle capture actions even when a toolbar control has keyboard focus.
    @discardableResult
    func performCaptureShortcut(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
        guard isEditing, event.keyCode == UInt16(kVK_ANSI_C),
              modifiers == .command || modifiers == .control else { return false }
        copyImage()
        return true
    }

    private func showToolbar() {
        guard let selection else { return }
        toolbar?.removeFromSuperview()
        toolButtons.removeAll()

        let panel = NSVisualEffectView(frame: CGRect(x: 0, y: 0, width: 452, height: 104))
        panel.material = .hudWindow
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.blendingMode = .withinWindow
        panel.state = .active
        panel.wantsLayer = true
        panel.layer?.cornerRadius = 14
        panel.layer?.masksToBounds = true
        panel.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.72).cgColor
        panel.layer?.borderColor = NSColor.white.withAlphaComponent(0.14).cgColor
        panel.layer?.borderWidth = 1
        panel.setAccessibilityElement(true)
        panel.setAccessibilityRole(.group)
        panel.setAccessibilityLabel(NSLocalizedString("editor.toolbar", value: "Capture tools", comment: ""))

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            stack.topAnchor.constraint(equalTo: panel.topAnchor),
            stack.bottomAnchor.constraint(equalTo: panel.bottomAnchor)
        ])

        let tools = NSStackView()
        tools.orientation = .horizontal
        tools.alignment = .centerY
        tools.spacing = 4
        tools.heightAnchor.constraint(equalToConstant: 32).isActive = true
        stack.addArrangedSubview(tools)
        for tool in AnnotationTool.allCases {
            if tool == .blur { tools.addArrangedSubview(makeSeparator()) }
            let button = makeButton(symbol: tool.symbol, title: tool.title,
                                    action: #selector(selectTool(_:)))
            button.tag = tool.rawValue
            toolButtons.append(button)
            tools.addArrangedSubview(button)
        }
        tools.addArrangedSubview(makeSeparator())
        let colorWell = NSColorWell(style: .minimal)
        colorWell.color = inkColor
        colorWell.target = self
        colorWell.action = #selector(changeColor(_:))
        colorWell.toolTip = NSLocalizedString("tool.color", value: "Annotation color", comment: "")
        colorWell.setAccessibilityLabel(colorWell.toolTip)
        colorWell.widthAnchor.constraint(equalToConstant: 32).isActive = true
        colorWell.heightAnchor.constraint(equalToConstant: 32).isActive = true
        tools.addArrangedSubview(colorWell)

        let actions = NSView()
        actions.widthAnchor.constraint(equalToConstant: panel.frame.width - 28).isActive = true
        actions.heightAnchor.constraint(equalToConstant: 32).isActive = true
        stack.addArrangedSubview(actions)

        let leading = NSStackView()
        leading.orientation = .horizontal
        leading.alignment = .centerY
        leading.spacing = 6
        leading.addArrangedSubview(makeButton(symbol: "arrow.uturn.backward", title: NSLocalizedString("tool.undo", value: "Undo", comment: "") + " (⌘Z)",
                                              action: #selector(undoAnnotation)))
        let dimensions = NSTextField(labelWithString: "\(Int(selection.width)) × \(Int(selection.height))")
        dimensions.font = .monospacedDigitSystemFont(ofSize: 10.5, weight: .medium)
        dimensions.textColor = NSColor.white.withAlphaComponent(0.68)
        dimensions.alignment = .center
        dimensions.setContentHuggingPriority(.defaultLow, for: .horizontal)
        leading.addArrangedSubview(dimensions)

        let trailing = NSStackView()
        trailing.orientation = .horizontal
        trailing.alignment = .centerY
        trailing.spacing = 6
        let hint = NSTextField(labelWithString: "⌘C / Ctrl+C")
        hint.font = .systemFont(ofSize: 10, weight: .medium)
        hint.textColor = NSColor.white.withAlphaComponent(0.5)
        hint.alignment = .center
        hint.setContentHuggingPriority(.defaultLow, for: .horizontal)
        trailing.addArrangedSubview(hint)
        trailing.addArrangedSubview(makeButton(symbol: "xmark", title: NSLocalizedString("tool.close", value: "Close", comment: "") + " (Esc)",
                                               action: #selector(closeCapture)))

        let exports = NSStackView()
        exports.orientation = .horizontal
        exports.alignment = .centerY
        exports.spacing = 8
        let copy = makeButton(symbol: "doc.on.doc", title: NSLocalizedString("tool.copy", value: "Copy PNG", comment: ""),
                              action: #selector(copyImage),
                              visibleTitle: NSLocalizedString("tool.copyAction", value: "Copy", comment: ""))
        copy.isProminent = true
        copy.toolTip = NSLocalizedString("tool.copyHint", value: "Copy PNG to clipboard (⌘C / Ctrl+C). No file is saved.", comment: "")
        exports.addArrangedSubview(copy)
        exports.addArrangedSubview(makeButton(symbol: "square.and.arrow.down", title: NSLocalizedString("tool.save", value: "Save PNG", comment: ""),
                                              action: #selector(saveImage),
                                              visibleTitle: NSLocalizedString("tool.saveAction", value: "Save", comment: "")))

        for group in [leading, exports, trailing] {
            group.translatesAutoresizingMaskIntoConstraints = false
            actions.addSubview(group)
            group.centerYAnchor.constraint(equalTo: actions.centerYAnchor).isActive = true
        }
        NSLayoutConstraint.activate([
            leading.leadingAnchor.constraint(equalTo: actions.leadingAnchor),
            leading.widthAnchor.constraint(equalToConstant: 104),
            exports.centerXAnchor.constraint(equalTo: actions.centerXAnchor),
            trailing.trailingAnchor.constraint(equalTo: actions.trailingAnchor),
            trailing.widthAnchor.constraint(equalTo: leading.widthAnchor)
        ])

        let x = max(8, min(selection.midX - panel.frame.width / 2, bounds.width - panel.frame.width - 8))
        let y = selection.minY - panel.frame.height - 12 >= 8 ? selection.minY - panel.frame.height - 12 :
                 min(selection.maxY + 12, bounds.height - panel.frame.height - 8)
        panel.setFrameOrigin(NSPoint(x: x, y: max(8, y)))
        addSubview(panel)
        toolbar = panel
        updateToolButtons()
    }

    private func makeSeparator() -> NSBox {
        let separator = NSBox()
        separator.boxType = .separator
        separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return separator
    }

    private func makeButton(symbol: String, title: String, action: Selector, visibleTitle: String? = nil) -> CaptureToolbarButton {
        let button = CaptureToolbarButton(symbol: symbol, label: title, visibleTitle: visibleTitle)
        button.target = self
        button.action = action
        button.widthAnchor.constraint(equalToConstant: visibleTitle == nil ? 32 : 92).isActive = true
        return button
    }

    private func updateToolButtons() {
        for button in toolButtons {
            button.isSelectedTool = button.tag == activeTool.rawValue
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
