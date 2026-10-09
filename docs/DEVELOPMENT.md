# Developing Lunarium

Lunarium is a native macOS app built with Swift, AppKit, SwiftUI and ScreenCaptureKit. Sparkle 2.9.6 is the sole non-Apple runtime dependency. There are no browser runtimes or server components.

## Setup

- macOS 14+ with Xcode 16 or newer
- Install XcodeGen: `brew install xcodegen`
- `make project` generates all icon PNG assets and `Lunarium.xcodeproj`
- `make build` performs an unsigned arm64 Debug build
- To run, open the project in Xcode and execute the Lunarium scheme

## Command Line Tools builds

On an Apple Silicon Mac with Apple's Command Line Tools and XcodeGen installed,
run `make local-build`. This compiles the same Debug sources with `swiftc`,
downloads the pinned Sparkle framework with SHA-256 verification, bundles the
icon and translations, and ad-hoc signs `.build/local/Lunarium.app`.

Copy that app into Applications and open it. Lunarium appears in the menu bar;
use F13 or Command-Shift-2 to capture. Grant Screen Recording permission in
System Settings when prompted. This is a local development build; Xcode is
still required for the XCTest suites and Developer ID release workflow.

`make local-release` builds optimized code without the Debug capture fixture into
`.build/local-release/Lunarium.app`. `make dmg` also creates an ad-hoc signed,
non-notarized development DMG and a SHA-256 checksum in `.build/dist/`.
For a prerelease asset name, use `make dmg RELEASE_LABEL=0.2.0-preview.1`;
the label must match the version in `project.yml`.

### Screen Recording permission after rebuilding

An ad-hoc build has a new signing identity whenever its executable changes.
macOS can keep displaying an enabled Screen Recording switch for an older
build while denying access to the new one. If that happens after rebuilding,
quit Lunarium, run `tccutil reset ScreenCapture io.github.owlCoder.Lunarium`,
and add `/Applications/Lunarium.app` again in the Screen & System Audio
Recording settings. Relaunch the installed copy after approving it.

The generated Xcode project and PNG files are intentionally not committed; their sources are `project.yml` and `scripts/generate-icon.swift`.

## Modules

- **App:** SwiftUI app lifecycle, NSStatusItem, preferences.
- **Capture:** Carbon hotkey registration; screen capture via SCShareableContent, SCContentFilter and SCScreenshotManager.
- **Editor:** one borderless overlay per display, drag selection, custom NSView drawing, toolbar, undo.
- **Services:** crop at pixel resolution, composite annotations and encode PNG.

## Manual validation matrix

Before tagging a release, validate on actual hardware:

1. Apple Silicon Mac with current macOS; clean install, first permission prompt, denied/allowed/revoked Screen Recording.
2. Built-in Retina display, external non-Retina display, two monitors with different scale and negative screen origins.
3. F13 and fallback shortcut; competing screenshot utilities.
4. Tiny, edge-aligned and full-screen selections, Esc during selection, Cmd-Z after annotations.
5. Pen, arrow, ellipse, rectangle, text, Command-C and Control-C copy without saving, paste into another app, and save PNG.
6. Sleep/wake, full-screen spaces, menu bar activation, repeated captures and memory usage.
7. VoiceOver and keyboard access.

No release should be advertised as tested until these checks pass.
