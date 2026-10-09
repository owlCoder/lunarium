import AppKit
import UniformTypeIdentifiers

enum ExportService {
    static var suggestedName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "Lunarium \(formatter.string(from: Date())).png"
    }

    /// Crop using top-left pixel image coordinates while editor positions use
    /// bottom-left AppKit points. Convert once; rasterize markup at native scale.
    static func pngData(image: CGImage, in selection: CGRect,
                        viewSize: CGSize, annotations: [Annotation]) -> Data? {
        guard selection.width > 0, selection.height > 0,
              viewSize.width > 0, viewSize.height > 0 else { return nil }
        let scaleX = CGFloat(image.width) / viewSize.width
        let scaleY = CGFloat(image.height) / viewSize.height
        let crop = CGRect(x: selection.minX * scaleX,
                          y: (viewSize.height - selection.maxY) * scaleY,
                          width: selection.width * scaleX,
                          height: selection.height * scaleY).integral
        guard let base = image.cropping(to: crop),
              let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                            pixelsWide: base.width, pixelsHigh: base.height,
                                            bitsPerSample: 8, samplesPerPixel: 4,
                                            hasAlpha: true, isPlanar: false,
                                            colorSpaceName: .deviceRGB, bytesPerRow: 0,
                                            bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        let cgContext = context.cgContext
        cgContext.scaleBy(x: CGFloat(base.width) / selection.width,
                          y: CGFloat(base.height) / selection.height)
        NSImage(cgImage: base, size: selection.size).draw(
            in: CGRect(origin: .zero, size: selection.size),
            from: .zero, operation: .copy, fraction: 1)
        // Crop drawing origin is (0,0); existing annotation positions are view-relative.
        for annotation in annotations where annotation.tool != .redact {
            annotation.draw(offset: CGPoint(x: -selection.minX, y: -selection.minY))
        }
        // Always composite solid redaction last. A later-added effect must never
        // put previously captured original pixels over a redacted area.
        for annotation in annotations where annotation.tool == .redact {
            if annotation.tool == .redact {
                // Use Core Graphics, not NSBezierPath, for opaque redaction. This
                // guarantees actual black raster pixels independent of NSImage
                // compositing semantics and cannot be reverse-filtered.
                let rect = annotation.rect.offsetBy(dx: -selection.minX, dy: -selection.minY)
                cgContext.setFillColor(CGColor(gray: 0, alpha: 1))
                cgContext.fill(rect)
            }
        }
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()
        return bitmap.representation(using: .png, properties: [:])
    }

    static func copyToClipboard(_ png: Data) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(png, forType: .png)
    }
}
