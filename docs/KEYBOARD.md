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
