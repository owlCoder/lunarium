import AppKit
import Carbon.HIToolbox

struct CaptureShortcut: Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    var label: String

    static let defaultShortcut = CaptureShortcut(keyCode: UInt32(kVK_F13), modifiers: 0, label: "F13")
    static let fallback = CaptureShortcut(keyCode: UInt32(kVK_ANSI_2), modifiers: UInt32(cmdKey | shiftKey), label: "2")

    static func load() -> CaptureShortcut {
        let prefs = UserDefaults.standard
        if prefs.object(forKey: "shortcutKeyCode") == nil { return .defaultShortcut }
        return CaptureShortcut(keyCode: UInt32(prefs.integer(forKey: "shortcutKeyCode")),
                               modifiers: UInt32(prefs.integer(forKey: "shortcutModifiers")),
                               label: prefs.string(forKey: "shortcutLabel") ?? "F13")
    }
    func save() {
        let prefs = UserDefaults.standard
        prefs.set(Int(keyCode), forKey: "shortcutKeyCode")
        prefs.set(Int(modifiers), forKey: "shortcutModifiers")
        prefs.set(label, forKey: "shortcutLabel")
        NotificationCenter.default.post(name: .lunariumShortcutChanged, object: nil)
    }
    var displayName: String {
        var result = ""
        if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        return result + label
    }
    static func from(event: NSEvent) -> CaptureShortcut? {
        let flags = event.modifierFlags.intersection([.command, .shift, .control, .option])
        var mods: UInt32 = 0
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        if flags.contains(.shift) { mods |= UInt32(shiftKey) }
        if flags.contains(.option) { mods |= UInt32(optionKey) }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        let fn: [Int: String] = [
            Int(kVK_F1): "F1", Int(kVK_F2): "F2", Int(kVK_F3): "F3", Int(kVK_F4): "F4",
            Int(kVK_F5): "F5", Int(kVK_F6): "F6", Int(kVK_F7): "F7", Int(kVK_F8): "F8",
            Int(kVK_F9): "F9", Int(kVK_F10): "F10", Int(kVK_F11): "F11", Int(kVK_F12): "F12",
            Int(kVK_F13): "F13", Int(kVK_F14): "F14", Int(kVK_F15): "F15",
            Int(kVK_F16): "F16", Int(kVK_F17): "F17", Int(kVK_F18): "F18",
            Int(kVK_F19): "F19", Int(kVK_F20): "F20"
        ]
        let bareAllowed = [Int(kVK_F13), Int(kVK_F14), Int(kVK_F15), Int(kVK_F16),
                           Int(kVK_F17), Int(kVK_F18), Int(kVK_F19), Int(kVK_F20)]
                           .contains(Int(event.keyCode))
        // Unmodified letter/number keys and Shift+letter must not hijack typing.
        guard (mods & ~UInt32(shiftKey)) != 0 || bareAllowed else { return nil }
        let label = fn[Int(event.keyCode)] ??
            (event.charactersIgnoringModifiers?.uppercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        guard !label.isEmpty else { return nil }
        return CaptureShortcut(keyCode: UInt32(event.keyCode), modifiers: mods, label: label)
    }
}

extension Notification.Name {
    static let lunariumShortcutChanged = Notification.Name("LunariumShortcutChanged")
}

@MainActor
final class HotkeyManager {
    private var handler: EventHandlerRef?
    private var hotkeys: [EventHotKeyRef] = []
    private var observer: NSObjectProtocol?
    private let action: @MainActor () -> Void

    init(action: @escaping @MainActor () -> Void) { self.action = action }

    func register() {
        if handler == nil {
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                          eventKind: UInt32(kEventHotKeyPressed))
            let callback: EventHandlerUPP = { _, _, userData in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let owner = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { owner.action() }
                return noErr
            }
            let context = Unmanaged.passUnretained(self).toOpaque()
            InstallEventHandler(GetApplicationEventTarget(), callback, 1, &eventType, context, &handler)
            observer = NotificationCenter.default.addObserver(
                forName: .lunariumShortcutChanged, object: nil, queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.updateRegistration() }
            }
        }
        updateRegistration()
    }

    private func updateRegistration() {
        hotkeys.forEach { UnregisterEventHotKey($0) }
        hotkeys.removeAll()
        UserDefaults.standard.removeObject(forKey: "shortcutWarning")
        let custom = CaptureShortcut.load()
        registerKey(custom, id: 1)
        if custom.keyCode != CaptureShortcut.fallback.keyCode ||
           custom.modifiers != CaptureShortcut.fallback.modifiers {
            registerKey(.fallback, id: 2)
        }
    }

    private func registerKey(_ shortcut: CaptureShortcut, id: UInt32) {
        var ref: EventHotKeyRef?
        let keyID = EventHotKeyID(signature: OSType(0x4C554E41), id: id)
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers,
                                         keyID, GetApplicationEventTarget(), 0, &ref)
        if status == noErr, let ref {
            hotkeys.append(ref)
        } else {
            let detail = "Could not register \(shortcut.displayName) (macOS error \(status)); it may already be in use."
            UserDefaults.standard.set(detail, forKey: "shortcutWarning")
            NSLog("Lunarium: %@", detail)
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        hotkeys.forEach { UnregisterEventHotKey($0) }
        if let handler { RemoveEventHandler(handler) }
    }
}
