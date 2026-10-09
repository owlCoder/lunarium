import SwiftUI
import AppKit

@main
struct LunariumApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Settings {
            PreferencesView()
                .frame(width: 480, height: 345)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var hotkeys: HotkeyManager?
    private let coordinator = CaptureCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "moon.stars.fill", accessibilityDescription: "Lunarium")
        item.button?.toolTip = "Lunarium — Screenshot"
        let menu = NSMenu()
        let capture = NSMenuItem(title: "Capture Area", action: #selector(captureArea), keyEquivalent: "")
        capture.target = self
        menu.addItem(capture)
        menu.addItem(NSMenuItem.separator())

        let preferences = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        preferences.keyEquivalentModifierMask = [.command]
        preferences.target = self
        menu.addItem(preferences)

        let quit = NSMenuItem(title: "Quit Lunarium", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        item.menu = menu
        statusItem = item

        hotkeys = HotkeyManager { [weak self] in
            self?.coordinator.start()
        }
        hotkeys?.register()
    }

    @objc private func captureArea() {
        coordinator.start()
    }

    @objc private func showSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
