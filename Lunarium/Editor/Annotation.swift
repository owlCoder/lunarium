import AppKit

enum AnnotationTool: Int {
    case pen, arrow, rectangle, ellipse, text

    var symbol: String {
        switch self {
        case .pen: return "pencil.tip"
        case .arrow: return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .text: return "textformat"
        }
    }

    var title: String {
        switch self {
        case .pen: return "Pen"
        case .arrow: return "Arrow"
        case .rectangle: return "Rectangle"
        case .ellipse: return "Ellipse"
        case .text: return "Text"
        }
    }
}

struct Annotation {
    var tool: AnnotationTool
    var start: CGPoint
    var end: CGPoint
    var points: [CGPoint] = []
    var text: String = ""
    var color: NSColor = .systemPurple

    func draw(offset: CGPoint = .zero) {
        func point(_ p: CGPoint) -> CGPoint {
            CGPoint(x: p.x + offset.x, y: p.y + offset.y)
        }

        let a = point(start)
        let b = point(end)
        color.setStroke()
        let path = NSBezierPath()
        path.lineWidth = 3
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

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
        case .rectangle:
            path.appendRect(CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
                                   width: abs(b.x - a.x), height: abs(b.y - a.y)))
        case .ellipse:
            path.appendOval(in: CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
                                       width: abs(b.x - a.x), height: abs(b.y - a.y)))
        case .text:
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .left
            (text as NSString).draw(at: a, withAttributes: [
                .font: NSFont.systemFont(ofSize: 19, weight: .semibold),
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ])
        }
        if tool != .text { path.stroke() }
    }
}
