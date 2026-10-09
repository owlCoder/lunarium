import XCTest
import AppKit
@testable import Lunarium

final class ExportTests: XCTestCase {
    private func sampleImage(size: Int = 200) -> CGImage {
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size,
                                       pixelsHigh: size, bitsPerSample: 8,
                                       samplesPerPixel: 4, hasAlpha: true,
                                       isPlanar: false, colorSpaceName: .deviceRGB,
                                       bytesPerRow: 0, bitsPerPixel: 0)!
        let ctx = NSGraphicsContext(bitmapImageRep: bitmap)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: size, height: size).fill()
        ctx.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()
        return bitmap.cgImage!
    }

    func testCropUsesRetinaPixelDimensions() throws {
        let png = try XCTUnwrap(ExportService.pngData(
            image: sampleImage(), in: CGRect(x: 25, y: 25, width: 50, height: 50),
            viewSize: CGSize(width: 100, height: 100), annotations: []))
        let decoded = try XCTUnwrap(NSBitmapImageRep(data: png))
        XCTAssertEqual(decoded.pixelsWide, 100)
        XCTAssertEqual(decoded.pixelsHigh, 100)
    }

    func testSolidRedactionOverwritesPixels() throws {
        let redact = Annotation(tool: .redact, start: CGPoint(x: 10, y: 10),
                                end: CGPoint(x: 40, y: 40))
        let png = try XCTUnwrap(ExportService.pngData(
            image: sampleImage(), in: CGRect(x: 0, y: 0, width: 100, height: 100),
            viewSize: CGSize(width: 100, height: 100), annotations: [redact]))
        let decoded = try XCTUnwrap(NSBitmapImageRep(data: png))
        let pixel = try XCTUnwrap(decoded.colorAt(x: 50, y: 50)?.usingColorSpace(.deviceRGB))
        XCTAssertLessThan(pixel.redComponent, 0.10)
        XCTAssertLessThan(pixel.greenComponent, 0.10)
        XCTAssertLessThan(pixel.blueComponent, 0.10)
    }

    func testRedactionStaysOpaqueWithLaterImageEffect() throws {
        let background = sampleImage()
        let blurImage = ImageEffectRenderer.makeEffect(
            tool: .blur, source: background,
            screenSize: CGSize(width: 100, height: 100),
            rect: CGRect(x: 10, y: 10, width: 30, height: 30))
        let redact = Annotation(tool: .redact, start: CGPoint(x: 10, y: 10),
                                end: CGPoint(x: 40, y: 40))
        let blur = Annotation(tool: .blur, start: CGPoint(x: 10, y: 10),
                              end: CGPoint(x: 40, y: 40), effectImage: blurImage)
        let bytes = try XCTUnwrap(ExportService.pngData(
            image: background, in: CGRect(x: 0, y: 0, width: 100, height: 100),
            viewSize: CGSize(width: 100, height: 100), annotations: [redact, blur]))
        let output = try XCTUnwrap(NSBitmapImageRep(data: bytes))
        let pixel = try XCTUnwrap(output.colorAt(x: 50, y: 50)?.usingColorSpace(.deviceRGB))
        XCTAssertLessThan(pixel.redComponent, 0.10)
    }

    func testBlurAndPixelateProduceRasterOfExpectedSize() {
        for tool in [AnnotationTool.blur, .pixelate] {
            let image = ImageEffectRenderer.makeEffect(
                tool: tool, source: sampleImage(), screenSize: CGSize(width: 100, height: 100),
                rect: CGRect(x: 10, y: 10, width: 20, height: 20))
            XCTAssertNotNil(image, "Failed for \(tool)")
            XCTAssertEqual(image?.width, 40)
            XCTAssertEqual(image?.height, 40)
        }
    }

    func testAnnotationRectNormalizesDragDirection() {
        let item = Annotation(tool: .rectangle, start: CGPoint(x: 80, y: 70),
                              end: CGPoint(x: 20, y: 30))
        XCTAssertEqual(item.rect, CGRect(x: 20, y: 30, width: 60, height: 40))
    }
}
