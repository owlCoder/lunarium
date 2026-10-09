import AppKit

enum AnnotationTool: Int, CaseIterable {
    case pen, arrow, line, rectangle, ellipse, text, highlighter, blur, pixelate, redact

    var symbol: String {
        switch self {
        case .pen: return "pencil.tip"
        case .arrow: return "arrow.up.right"
        case .line: return "line.diagonal"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .text: return "textformat"
        case .highlighter: return "highlighter"
        case .blur: return "drop.halffull"
        case .pixelate: return "square.grid.3x3.fill"
        case .redact: return "rectangle.fill"
        }
    }

    var title: String {
        switch self {
        case .pen: return NSLocalizedString("tool.pen", value: "Pen", comment: "")
        case .arrow: return NSLocalizedString("tool.arrow", value: "Arrow", comment: "")
        case .line: return NSLocalizedString("tool.line", value: "Line", comment: "")
        case .rectangle: return NSLocalizedString("tool.rectangle", value: "Rectangle", comment: "")
        case .ellipse: return NSLocalizedString("tool.ellipse", value: "Ellipse", comment: "")
        case .text: return NSLocalizedString("tool.text", value: "Text", comment: "")
        case .highlighter: return NSLocalizedString("tool.highlighter", value: "Highlighter", comment: "")
        case .blur: return NSLocalizedString("tool.blur", value: "Blur", comment: "")
        case .pixelate: return NSLocalizedString("tool.pixelate", value: "Pixelate", comment: "")
        case .redact: return NSLocalizedString("tool.redact", value: "Redact (solid)", comment: "")
        }
    }

    var isImageEffect: Bool { self == .blur || self == .pixelate }
}

struct Annotation {
    var tool: AnnotationTool
    var start: CGPoint
    var end: CGPoint
    var points: [CGPoint] = []
    var text: String = ""
    var color: NSColor = .systemPurple
    /// A snapshot of the pixels covered by this effect (never uploaded).
    var effectImage: CGImage?

    var rect: CGRect {
        CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
               width: abs(end.x - start.x), height: abs(end.y - start.y))
    }

    func draw(offset: CGPoint = .zero) {
        func point(_ p: CGPoint) -> CGPoint {
            CGPoint(x: p.x + offset.x, y: p.y + offset.y)
        }

        let a = point(start)
        let b = point(end)
        let area = CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
                          width: abs(a.x - b.x), height: abs(a.y - b.y))
        let path = NSBezierPath()
        path.lineWidth = 3
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        color.setStroke()

        switch tool {
        case .pen:
            let positions = points.isEmpty ? [a, b] : points.map(point)
            guard let first = positions.first else { return }
            path.move(to: first)
            for next in positions.dropFirst() { path.line(to: next) }
        case .arrow:
            path.move(to: a)
            path.line(to: b)
            let angle = atan2(b.y - a.y, b.x - a.x)
            for delta in [-CGFloat.pi / 6, CGFloat.pi / 6] {
                let p = CGPoint(x: b.x - 14 * cos(angle + delta),
                                y: b.y - 14 * sin(angle + delta))
                path.move(to: b)
                path.line(to: p)
            }
        case .line:
            path.move(to: a)
            path.line(to: b)
        case .rectangle:
            path.appendRect(area)
        case .ellipse:
            path.appendOval(in: area)
        case .highlighter:
            color.withAlphaComponent(0.32).setFill()
            NSBezierPath(roundedRect: area, xRadius: 3, yRadius: 3).fill()
        case .redact:
            // Unlike blur or pixelation, opaque redaction irreversibly hides content
            // in the exported raster image.
            NSColor.black.setFill()
            NSBezierPath(rect: area).fill()
        case .blur, .pixelate:
            if let effectImage {
                NSImage(cgImage: effectImage, size: area.size)
                    .draw(in: area, from: .zero, operation: .copy, fraction: 1)
            } else {
                NSColor.white.withAlphaComponent(0.2).setFill()
                NSBezierPath(rect: area).fill()
                NSColor.white.setStroke()
                let preview = NSBezierPath(rect: area)
                preview.lineWidth = 1
                preview.stroke()
            }
        case .text:
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .left
            (text as NSString).draw(at: a, withAttributes: [
                .font: NSFont.systemFont(ofSize: 19, weight: .semibold),
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ])
        }
        switch tool {
        case .pen, .arrow, .line, .rectangle, .ellipse: path.stroke()
        default: break
        }
    }
}
