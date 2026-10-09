import SwiftUI

struct PreferencesView: View {
    @AppStorage("showCursor") private var showCursor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 35, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 54, height: 54)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Lunarium").font(.system(size: 25, weight: .semibold))
                    Text("A little moonlight for your screenshots")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("v0.1.0").font(.caption.monospaced()).foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Label("Capture shortcut", systemImage: "keyboard")
                    .font(.headline)
                HStack {
                    Text("Print Screen (F13)").font(.body)
                    Spacer()
                    Text("F13").font(.system(.subheadline, design: .monospaced)).padding(6)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 7))
                }
                HStack {
                    Text("Fallback").foregroundStyle(.secondary)
                    Spacer()
                    Text("⌘ ⇧ 2").font(.system(.subheadline, design: .monospaced)).padding(6)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 7))
                }
                Toggle("Include mouse pointer in captures", isOn: $showCursor)
                    .toggleStyle(.switch)
            }

            Spacer()
            Divider()
            HStack {
                Label("Private by design · No uploads or accounts", systemImage: "lock.shield")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                Spacer()
                Link("GitHub", destination: URL(string: "https://github.com/owlCoder/lunarium")!)
                    .font(.footnote)
            }
        }
        .padding(24)
    }
}
