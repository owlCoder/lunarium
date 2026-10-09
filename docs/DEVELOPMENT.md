# Developing Lunarium

Lunarium is a native macOS app built with Swift, AppKit, SwiftUI and ScreenCaptureKit. We keep the app small: no package dependencies, browser runtimes or server components.

## Setup

- macOS 14+ with Xcode 16 or newer
- Install XcodeGen: `brew install xcodegen`
- `make project` generates all icon PNG assets and `Lunarium.xcodeproj`
- `make build` performs an unsigned arm64 Debug build
- To run, open the project in Xcode and execute the Lunarium scheme

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
5. Pen, arrow, ellipse, rectangle, text, copy to Preview and save PNG.
6. Sleep/wake, full-screen spaces, menu bar activation, repeated captures and memory usage.
7. VoiceOver and keyboard access.

No release should be advertised as tested until these checks pass.
