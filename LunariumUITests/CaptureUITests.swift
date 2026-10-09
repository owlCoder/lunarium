import XCTest
import AppKit

/// Run only on an unlocked interactive macOS desktop. Never records real pixels.
final class CaptureUITests: XCTestCase {
    func testRegionSelectionCopyAndClose() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-capture"]
        app.launch()
        let capture = app.windows["Lunarium Capture"]
        XCTAssertTrue(capture.waitForExistence(timeout: 10))

        let from = capture.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.25))
        let to = capture.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.70))
        from.press(forDuration: 0.1, thenDragTo: to)

        let copy = app.buttons["Copy PNG"]
        XCTAssertTrue(copy.waitForExistence(timeout: 5))
        copy.click()

        XCTAssertFalse(capture.waitForExistence(timeout: 2))
        XCTAssertNotNil(NSPasteboard.general.data(forType: .png))
    }

    func testEscapeCancelsCapture() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-capture"]
        app.launch()
        let capture = app.windows["Lunarium Capture"]
        XCTAssertTrue(capture.waitForExistence(timeout: 10))
        app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])
        XCTAssertFalse(capture.waitForExistence(timeout: 2))
    }

    func testCopyKeyboardShortcutsDoNotOpenSavePanel() {
        for modifier: XCUIElement.KeyModifierFlags in [.command, .control] {
            let app = XCUIApplication()
            app.launchArguments = ["--uitesting-capture"]
            app.launch()
            let capture = app.windows["Lunarium Capture"]
            XCTAssertTrue(capture.waitForExistence(timeout: 10))
            capture.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.25))
                .press(forDuration: 0.1, thenDragTo:
                    capture.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.70)))
            app.typeKey("c", modifierFlags: modifier)
            let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: capture)
            XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 3), .completed)
            XCTAssertNotNil(NSPasteboard.general.data(forType: .png))
            XCTAssertFalse(app.dialogs["Save"].exists)
            app.terminate()
        }
    }
}
