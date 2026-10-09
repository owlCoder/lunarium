# Print Screen and macOS keyboard mapping

Lunarium registers two system-wide shortcuts using Carbon RegisterEventHotKey:

- **F13** with no modifiers — commonly the virtual key sent by Print Screen on external PC-style keyboards attached to Macs.
- **Command–Shift–2** — fallback for Apple laptop keyboards and mappings that do not have F13.

**Important:** There is no universal Print Screen event on macOS. Some keyboards send a different key, and macOS may reserve or intercept combinations. The app cannot guarantee that physically pressing a key labeled PrtScn always emits F13.

If Print Screen does not trigger Lunarium:

1. Use **⌘⇧2** immediately.
2. Inspect your keyboard's own firmware/driver utility, or macOS Keyboard settings, and map Print Screen to **F13**.
3. Restart Lunarium after changing keyboard mappings.
4. Quit competing screenshot utilities that may capture the same shortcut.

The app does **not** intercept keystrokes through a global event tap or require Accessibility permission. Configurable key recording is planned.

## Custom shortcut recorder

Open Lunarium's Settings and click the shortcut button, then press the desired combination. Escape cancels. Bare F13–F20 keys are supported; letters/numbers require Command, Control or Option so normal typing is never intercepted. If a key combination is already registered by macOS or another utility, Settings displays a warning; use the fallback shortcut instead.

The fallback **⌘⇧2** remains available unless another application already owns that hotkey.
