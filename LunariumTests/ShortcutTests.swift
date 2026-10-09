import XCTest
import Carbon.HIToolbox
@testable import Lunarium

final class ShortcutTests: XCTestCase {
    func testF13DefaultAndFallback() {
        XCTAssertEqual(CaptureShortcut.defaultShortcut.keyCode, UInt32(kVK_F13))
        XCTAssertEqual(CaptureShortcut.defaultShortcut.modifiers, 0)
        XCTAssertEqual(CaptureShortcut.fallback.displayName, "⇧⌘2")
    }

    func testCustomShortcutDisplay() {
        let shortcut = CaptureShortcut(keyCode: UInt32(kVK_ANSI_K), modifiers: UInt32(cmdKey | optionKey),
                                       label: "K")
        XCTAssertEqual(shortcut.displayName, "⌥⌘K")
    }
}
