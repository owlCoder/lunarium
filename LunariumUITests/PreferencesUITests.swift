import XCTest

final class PreferencesUITests: XCTestCase {
    func testSettingsWindowDisplaysShortcutAndPrivacy() {
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Record capture shortcut"].exists)
        XCTAssertTrue(app.staticTexts["Lunarium"].exists)
    }
}
