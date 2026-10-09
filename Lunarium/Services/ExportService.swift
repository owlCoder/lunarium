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

        guard let rendered = bitmap.makeImage() else { return nil }
        let redactions = annotations.filter { $0.tool == .redact }
        if redactions.isEmpty {
            return NSBitmapImageRep(cgImage: rendered).representation(using: .png, properties: [:])
        }

        // Redact the raw RGBA bytes AFTER compositing every visual effect.
        // This deliberately bypasses AppKit/CGContext state/CTM: no user content
        // can remain underneath a redacted region in the exported raster.
        let width = rendered.width
        let height = rendered.height
        let format = CGBitmapInfo.byteOrder32Big.rawValue |
                     CGImageAlphaInfo.premultipliedLast.rawValue
        guard let final = CGContext(data: nil, width: width, height: height,
                                    bitsPerComponent: 8, bytesPerRow: width * 4,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: format),
              let pixelData = final.data else { return nil }
        final.draw(rendered, in: CGRect(x: 0, y: 0, width: width, height: height))
        let buffer = pixelData.assumingMemoryBound(to: UInt8.self)
        let stride = final.bytesPerRow
        for annotation in redactions {
            let rect = annotation.rect
            let x0 = max(0, Int(floor((rect.minX - selection.minX) * scaleX)))
            let x1 = min(width, Int(ceil((rect.maxX - selection.minX) * scaleX)))
            let y0 = max(0, Int(floor((rect.minY - selection.minY) * scaleY)))
            let y1 = min(height, Int(ceil((rect.maxY - selection.minY) * scaleY)))
            guard x0 < x1, y0 < y1 else { continue }
            for y in y0..<y1 {
                for x in x0..<x1 {
                    let offset = y * stride + x * 4
                    buffer[offset] = 0
                    buffer[offset + 1] = 0
                    buffer[offset + 2] = 0
                    buffer[offset + 3] = 255
                }
            }
        }
        guard let result = final.makeImage() else { return nil }
        return NSBitmapImageRep(cgImage: result).representation(using: .png, properties: [:])
    }

    static func copyToClipboard(_ png: Data) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(png, forType: .png)
    }
}
