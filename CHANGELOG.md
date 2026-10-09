# Changelog

All notable changes to Lunarium will be documented here. The project uses [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) conventions and plans to use [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Configurable global shortcut and launch-at-login preference.
- Blur, pixelate, highlighter, line, opaque redaction and color picker.
- English and Serbian Latin localizations.
- Sparkle 2.9.6 updater integration (enabled for signed releases only).
- Developer ID/notarized release pipeline and signed update feed automation (requires maintainer secrets).
- XCTest coverage of crop dimensions, solid redaction, effects and shortcut formatting; UI smoke test.

- Native SwiftUI menu bar application and preferences.
- ScreenCaptureKit screenshot collection across connected displays.
- F13 and Command–Shift–2 global capture shortcuts.
- AppKit region selection and contextual markup toolbar.
- Pen, arrow, rectangle, ellipse, text, undo, copy and save operations.
- Vector icon source and macOS AppIcon PNG generation.
- macOS arm64 GitHub Actions build workflow.
- OSS documentation, issue forms, and privacy policy.

### Known limitations
- Signed releases and update feed cannot be activated without Apple Developer ID and Sparkle signing keys.
- UI smoke testing is not a substitute for multi-monitor hardware testing.
- Shortcut configuration is not yet user-editable.
- Print Screen may require OS/keyboard remapping to F13.
- Real-world multi-monitor, permission, and UI smoke testing is still needed before publishing a release.
