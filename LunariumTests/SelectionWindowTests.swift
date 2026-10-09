import XCTest
import AppKit
import Carbon.HIToolbox
@testable import Lunarium

final class SelectionWindowTests: XCTestCase {
    @MainActor
    func testCaptureWindowCanBeCreatedAndClosed() throws {
        _ = NSApplication.shared
        let screen = try XCTUnwrap(NSScreen.main)
        let context = try XCTUnwrap(CGContext(
            data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        let image = try XCTUnwrap(context.makeImage())
        let window = SelectionWindow(snapshot: ScreenSnapshot(screen: screen, image: image))

        XCTAssertEqual(window.frame, screen.frame)
        XCTAssertTrue(window.contentView is SelectionView)
        XCTAssertTrue(window.canBecomeKey)
        window.close()
    }

    @MainActor
    func testCommandAndControlCopyPNGWithoutSavePanel() throws {
        _ = NSApplication.shared
        let screen = try XCTUnwrap(NSScreen.main)
        let context = try XCTUnwrap(CGContext(
            data: nil, width: 200, height: 200, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        let image = try XCTUnwrap(context.makeImage())
        let pasteboard = NSPasteboard.general
        let original = (pasteboard.pasteboardItems ?? []).map { item in
            item.types.compactMap { type -> (NSPasteboard.PasteboardType, Data)? in
                item.data(forType: type).map { (type, $0) }
            }
        }
        defer {
            pasteboard.clearContents()
            pasteboard.writeObjects(original.map { contents in
                let item = NSPasteboardItem()
                for (type, data) in contents { item.setData(data, forType: type) }
                return item
            })
        }

        for modifiers: NSEvent.ModifierFlags in [.command, .control] {
            let window = SelectionWindow(snapshot: ScreenSnapshot(screen: screen, image: image))
            defer { window.close() }
            let view = try XCTUnwrap(window.contentView as? SelectionView)
            for (type, point) in [(NSEvent.EventType.leftMouseDown, NSPoint(x: 20, y: 20)),
                                  (.leftMouseDragged, NSPoint(x: 120, y: 100)),
                                  (.leftMouseUp, NSPoint(x: 120, y: 100))] {
                let event = try XCTUnwrap(NSEvent.mouseEvent(
                    with: type, location: point, modifierFlags: [], timestamp: 0,
                    windowNumber: window.windowNumber, context: nil, eventNumber: 0,
                    clickCount: 1, pressure: 1))
                switch type {
                case .leftMouseDown: view.mouseDown(with: event)
                case .leftMouseDragged: view.mouseDragged(with: event)
                default: view.mouseUp(with: event)
                }
            }
            var finished = false
            window.onFinish = { finished = true }
            pasteboard.clearContents()
            let key = try XCTUnwrap(NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: 0,
                windowNumber: window.windowNumber, context: nil,
                characters: modifiers == .control ? "\u{3}" : "c",
                charactersIgnoringModifiers: "c", isARepeat: false, keyCode: UInt16(kVK_ANSI_C)))

            XCTAssertTrue(window.performKeyEquivalent(with: key))
            XCTAssertTrue(finished)
            let data = try XCTUnwrap(pasteboard.data(forType: .png))
            XCTAssertNotNil(NSBitmapImageRep(data: data))
            XCTAssertFalse(NSApp.windows.contains { $0 is NSSavePanel && $0.isVisible })
        }
    }
}
