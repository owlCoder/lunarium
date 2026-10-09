import AppKit
import Carbon.HIToolbox

/// RegisterEventHotKey works without global event taps or Accessibility permission.
/// Most external keyboard Print Screen keys translate to F13 on macOS, but not all.
@MainActor
final class HotkeyManager {
    private var handler: EventHandlerRef?
    private var hotkeys: [EventHotKeyRef] = []
    private let action: @MainActor () -> Void

    init(action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    func register() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: EventHandlerUPP = { _, _, userData in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let owner = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { owner.action() }
            return noErr
        }
        InstallEventHandler(GetApplicationEventTarget(), callback, 1, &eventType, context, &handler)

        registerKey(code: UInt32(kVK_F13), modifiers: 0, id: 1)
        registerKey(code: UInt32(kVK_ANSI_2), modifiers: UInt32(cmdKey | shiftKey), id: 2)
    }

    private func registerKey(code: UInt32, modifiers: UInt32, id: UInt32) {
        var ref: EventHotKeyRef?
        let keyID = EventHotKeyID(signature: OSType(0x4C554E41), id: id) // "LUNA"
        let status = RegisterEventHotKey(code, modifiers, keyID, GetApplicationEventTarget(), 0, &ref)
        if status == noErr, let ref {
            hotkeys.append(ref)
        } else {
            NSLog("Lunarium: could not register hotkey id=%u status=%d", id, status)
        }
    }

    deinit {
        for ref in hotkeys { UnregisterEventHotKey(ref) }
        if let handler { RemoveEventHandler(handler) }
    }
}
