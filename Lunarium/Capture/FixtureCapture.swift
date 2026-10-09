#if DEBUG
import AppKit
import CoreGraphics

/// Deterministic, non-sensitive image used *only* by local UI automation.
/// Enabled exclusively by --uitesting-capture in Debug builds.
enum FixtureCapture {
    @MainActor
    static func make() -> [ScreenSnapshot] {
        guard let screen = NSScreen.main else { return [] }
        let scale = screen.backingScaleFactor
        let width = max(1, Int(screen.frame.width * scale))
        let height = max(1, Int(screen.frame.height * scale))
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }
        context.setFillColor(CGColor(red: 0.12, green: 0.15, blue: 0.3, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(red: 0.38, green: 0.22, blue: 0.77, alpha: 1))
        context.fill(CGRect(x: width / 4, y: height / 4,
                            width: width / 2, height: height / 2))
        context.setFillColor(CGColor(red: 0.80, green: 0.88, blue: 0.98, alpha: 1))
        context.fill(CGRect(x: width / 3, y: height / 3,
                            width: width / 4, height: height / 4))
        guard let image = context.makeImage() else { return [] }
        return [ScreenSnapshot(screen: screen, image: image)]
    }
}
#endif
