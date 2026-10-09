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
    private let updater = UpdateCoordinator()
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "moon.stars.fill", accessibilityDescription: "Lunarium")
        item.button?.toolTip = "Lunarium — Screenshot"
        let menu = NSMenu()
        let capture = NSMenuItem(title: NSLocalizedString("menu.capture", value: "Capture Area", comment: ""), action: #selector(captureArea), keyEquivalent: "")
        capture.target = self
        menu.addItem(capture)
        menu.addItem(NSMenuItem.separator())

        let preferences = NSMenuItem(title: NSLocalizedString("menu.settings", value: "Settings…", comment: ""), action: #selector(showSettings), keyEquivalent: ",")
        preferences.keyEquivalentModifierMask = [.command]
        preferences.target = self
        menu.addItem(preferences)

        let check = NSMenuItem(
            title: NSLocalizedString("menu.update", value: "Check for Updates…", comment: ""),
            action: #selector(checkForUpdates), keyEquivalent: "")
        check.target = self
        menu.addItem(check)
        menu.addItem(NSMenuItem.separator())

        let quit = NSMenuItem(title: NSLocalizedString("menu.quit", value: "Quit Lunarium", comment: ""), action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        item.menu = menu
        statusItem = item

        hotkeys = HotkeyManager { [weak self] in
            self?.coordinator.start()
        }
        hotkeys?.register()
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            DispatchQueue.main.async { [weak self] in self?.showSettings() }
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting-capture") {
            DispatchQueue.main.async { [weak self] in self?.coordinator.start() }
        }
        #endif
    }

    @objc private func captureArea() {
        coordinator.start()
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 385),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered, defer: false)
            window.title = NSLocalizedString("menu.settings", value: "Lunarium Settings", comment: "")
            window.contentView = NSHostingView(rootView: PreferencesView())
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func checkForUpdates() {
        updater.checkForUpdates()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
