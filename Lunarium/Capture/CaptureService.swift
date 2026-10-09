import AppKit
import ScreenCaptureKit
import CoreGraphics

struct ScreenSnapshot {
    let screen: NSScreen
    let image: CGImage
}

enum CaptureError: LocalizedError {
    case noDisplays
    case noMatchingDisplay

    var errorDescription: String? {
        switch self {
        case .noDisplays: return "No displays are available for capture."
        case .noMatchingDisplay: return "Could not match the macOS screen to a capture display."
        }
    }
}

enum CaptureService {
    @MainActor
    static func captureAllScreens() async throws -> [ScreenSnapshot] {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        let screens = NSScreen.screens
        guard !screens.isEmpty else { throw CaptureError.noDisplays }
        var snapshots: [ScreenSnapshot] = []

        for screen in screens {
            guard let displayNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
                  let display = content.displays.first(where: { $0.displayID == CGDirectDisplayID(displayNumber.uint32Value) })
            else { throw CaptureError.noMatchingDisplay }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let configuration = SCStreamConfiguration()
            configuration.width = display.width
            configuration.height = display.height
            configuration.showsCursor = UserDefaults.standard.bool(forKey: "showCursor")
            let image = try await SCScreenshotManager.captureImage(contentFilter: filter,
                                                                    configuration: configuration)
            snapshots.append(ScreenSnapshot(screen: screen, image: image))
        }
        return snapshots
    }
}
