import AppKit
import SwiftUI
import ServiceManagement

struct PreferencesView: View {
    @AppStorage("showCursor") private var showCursor = false
    @AppStorage("shortcutWarning") private var shortcutWarning = ""
    @State private var shortcut = CaptureShortcut.load()
    @State private var message = ""
    @State private var startsAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(LinearGradient(colors: [.indigo, .purple],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lunarium").font(.system(size: 26, weight: .semibold))
                    Text("settings.tagline").foregroundStyle(.secondary)
                }
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.2.0")
                    .font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            Divider()
            HStack {
                Label("settings.shortcut", systemImage: "keyboard").font(.headline)
                Spacer()
                ShortcutRecorder(shortcut: shortcut, onChange: { value in
                    shortcut = value
                    message = ""
                    value.save()
                }, onInvalid: {
                    message = NSLocalizedString("shortcut.invalid",
                         value: "Use F13–F20 or a combination with ⌘, ⌃ or ⌥.", comment: "")
                })
                .frame(width: 155, height: 30)
            }
            HStack {
                Text("settings.fallback").foregroundStyle(.secondary)
                Spacer()
                Text("⌘⇧2").font(.system(.subheadline, design: .monospaced))
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 7))
            }
            if !message.isEmpty { Text(message).foregroundStyle(.orange).font(.caption) }
            if !shortcutWarning.isEmpty {
                Text(shortcutWarning).foregroundStyle(.orange).font(.caption)
            }
            Divider()
            Toggle("settings.cursor", isOn: $showCursor)
            Toggle("settings.login", isOn: $startsAtLogin)
                .onChange(of: startsAtLogin) { enabled in
                    do {
                        if enabled { try SMAppService.mainApp.register() }
                        else { try SMAppService.mainApp.unregister() }
                    } catch {
                        startsAtLogin = SMAppService.mainApp.status == .enabled
                        message = error.localizedDescription
                    }
                }
            Spacer()
            Divider()
            HStack {
                Label("settings.privacy", systemImage: "lock.shield")
                    .foregroundStyle(.secondary).font(.footnote)
                Spacer()
                Link("GitHub", destination: URL(string: "https://github.com/owlCoder/lunarium")!)
                    .font(.footnote)
            }
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 365)
    }
}
