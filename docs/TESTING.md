# Testing

## Automated checks

The macOS GitHub Actions workflow generates icon assets, compiles an unsigned arm64 application, and runs the `LunariumTests` XCTest suite. Tests cover Retina-scaled cropping, opaque redaction, blur/pixelate image generation, annotation geometry, and shortcut defaults.

Locally:

```bash
brew install xcodegen
make project
xcodebuild test -project Lunarium.xcodeproj -scheme Lunarium \
  -destination 'platform=macOS,arch=arm64' -only-testing:LunariumTests CODE_SIGNING_ALLOWED=NO
```

### UI automation

`LunariumUITests/PreferencesUITests.swift` exercises Settings' visible controls. `CaptureUITests` uses the safe built-in **Debug-only** `--uitesting-capture` fixture to verify region selection, copy to clipboard and Escape cancellation without Screen Recording permission or touching real screen pixels. Run it on an **unlocked interactive macOS desktop**:

```bash
xcodebuild test -project Lunarium.xcodeproj -scheme Lunarium \
  -destination 'platform=macOS,arch=arm64' -only-testing:LunariumUITests
```

UI tests are intentionally not a release gate on ephemeral CI runners because Screen Recording permissions and multi-display hardware cannot be simulated reliably. Local macOS tests and manual checks remain mandatory.

## Required human validation before public beta

- Fresh installation, permission denied/approved/revoked and Screen Recording relaunch behavior
- F13 / external Print Screen mapping, customized shortcut, conflict handling and fallback
- Retina and mixed-DPI multiple monitor captures, menu bar on secondary displays
- Solid redaction accuracy, blur/pixelate, text, drag in every direction, undo
- Paste PNG into Preview, save image, verify no private data escapes redaction
- VoiceOver, reduced motion, display scaling and English / Serbian Latin localization
- Signed/notarized first install and Sparkle upgrade from a previous signed release

Results of this matrix have not yet been recorded on real hardware.
