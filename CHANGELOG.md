# Changelog

All notable changes to Lunarium will be documented here. The project uses [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) conventions and plans to use [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.0-preview.1] - 2026-10-10

First public development preview for Apple Silicon. The download is ad-hoc signed and not notarized; automatic updates are disabled.

### Added
- Command-C and Control-C copy the annotated PNG without saving a file.
- Command Line Tools builds and reproducible development DMG packaging with SHA-256 checksums.
- Configurable global shortcut and launch-at-login preference.
- Blur, pixelate, highlighter, line, opaque redaction and color picker.
- English and Serbian Latin localizations.
- Sparkle 2.9.6 updater integration (enabled for signed releases only).
- Developer ID/notarized release pipeline and signed update feed automation (requires maintainer secrets).
- XCTest coverage of crop dimensions, solid redaction, effects, shortcut formatting, capture-window initialization, and clipboard shortcuts; UI smoke tests.
- Native SwiftUI menu bar application and preferences.
- ScreenCaptureKit screenshot collection across connected displays.
- F13 and Command–Shift–2 global capture shortcuts.
- AppKit region selection and contextual markup toolbar.
- Pen, arrow, rectangle, ellipse, text, undo, copy and save operations.
- Vector icon source and macOS AppIcon PNG generation.
- macOS arm64 GitHub Actions build workflow.
- OSS documentation, issue forms, and privacy policy.

### Changed
- White selection outline and a centered, two-row toolbar with balanced action buttons.
- English project documentation with installation, contribution, privacy, and preview release instructions.

### Fixed
- Capture-window initialization crash caused by an NSWindow convenience initializer.
- Capture keyboard focus and restoration of the previous foreground app after copying or dismissing.

### Known limitations
- Signed releases and update feed cannot be activated without Apple Developer ID and Sparkle signing keys.
- UI smoke testing is not a substitute for multi-monitor hardware testing.
- Print Screen may require OS/keyboard remapping to F13.
- The complete permission, multi-monitor, and accessibility acceptance matrix remains required before a stable release.

[Unreleased]: https://github.com/owlCoder/lunarium/compare/v0.2.0-preview.1...HEAD
[0.2.0-preview.1]: https://github.com/owlCoder/lunarium/releases/tag/v0.2.0-preview.1
