import AppKit
import CoreGraphics
import UniformTypeIdentifiers

enum ExportService {
    static var suggestedName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "Lunarium \(formatter.string(from: Date())).png"
    }

    /// Crop in top-left CGImage pixel coordinates. Composite markup in AppKit
    /// point coordinates, then irreversibly overwrite redacted pixels in the
    /// final bitmap (after ALL other tools) using Core Graphics.
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
              let bitmap = CGContext(
                data: nil, width: base.width, height: base.height,
                bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: bitmap, flipped: false)
        bitmap.saveGState()
        bitmap.scaleBy(x: CGFloat(base.width) / selection.width,
                       y: CGFloat(base.height) / selection.height)
        NSImage(cgImage: base, size: selection.size).draw(
            in: CGRect(origin: .zero, size: selection.size),
            from: .zero, operation: .copy, fraction: 1
        )
        for annotation in annotations where annotation.tool != .redact {
            annotation.draw(offset: CGPoint(x: -selection.minX, y: -selection.minY))
        }
        bitmap.restoreGState()
        NSGraphicsContext.restoreGraphicsState()

        // Last-pass opaque redaction is performed in raw pixel coordinates
        // with no NSGraphicsContext transforms. This prevents later-added
        // blur/image effects from restoring hidden original pixels.
        bitmap.setAllowsAntialiasing(false)
        bitmap.setFillColor(CGColor(gray: 0, alpha: 1))
        let extent = CGRect(x: 0, y: 0, width: base.width, height: base.height)
        for annotation in annotations where annotation.tool == .redact {
            let rect = annotation.rect
            let pixels = CGRect(x: (rect.minX - selection.minX) * scaleX,
                                y: (rect.minY - selection.minY) * scaleY,
                                width: rect.width * scaleX,
                                height: rect.height * scaleY).integral.intersection(extent)
            if !pixels.isNull && !pixels.isEmpty { bitmap.fill(pixels) }
        }

        guard let image = bitmap.makeImage() else { return nil }
        return NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    }

    static func copyToClipboard(_ png: Data) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(png, forType: .png)
    }
}
