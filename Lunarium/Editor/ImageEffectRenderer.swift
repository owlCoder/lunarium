import AppKit
import CoreImage
import CoreGraphics

/// Crops before filtering to keep memory usage bounded, including on Retina screens.
/// Rendering uses the same coordinate conversion as ExportService.
enum ImageEffectRenderer {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func makeEffect(tool: AnnotationTool, source: CGImage,
                           screenSize: CGSize, rect: CGRect) -> CGImage? {
        guard tool.isImageEffect, rect.width >= 2, rect.height >= 2,
              screenSize.width > 0, screenSize.height > 0 else { return nil }

        let scaleX = CGFloat(source.width) / screenSize.width
        let scaleY = CGFloat(source.height) / screenSize.height
        let area = CGRect(x: rect.minX * scaleX,
                          y: (screenSize.height - rect.maxY) * scaleY,
                          width: rect.width * scaleX,
                          height: rect.height * scaleY).integral
        guard let region = source.cropping(to: area) else { return nil }

        let input = CIImage(cgImage: region)
        guard let filter = CIFilter(name: tool == .blur ? "CIGaussianBlur" : "CIPixellate") else {
            return nil
        }
        if tool == .blur {
            filter.setValue(input.clampedToExtent(), forKey: kCIInputImageKey)
            filter.setValue(13 * max(scaleX, scaleY), forKey: kCIInputRadiusKey)
        } else {
            filter.setValue(input, forKey: kCIInputImageKey)
            filter.setValue(11 * max(scaleX, scaleY), forKey: kCIInputScaleKey)
        }
        guard let output = filter.outputImage?.cropped(to: input.extent) else { return nil }
        return context.createCGImage(output, from: input.extent)
    }
}
