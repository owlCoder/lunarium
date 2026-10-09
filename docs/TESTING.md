# Testing

## Automated checks

The macOS GitHub Actions workflow generates icon assets, compiles an unsigned arm64 application, and runs the `LunariumTests` XCTest suite. Tests cover Retina-scaled cropping, opaque redaction, blur/pixelate image generation, annotation geometry, shortcut defaults, capture-window initialization, and Command-C / Control-C clipboard export without a save panel.

Locally:

```bash
brew install xcodegen
make project
make test
```

### UI automation

`LunariumUITests/PreferencesUITests.swift` exercises Settings' visible controls. `CaptureUITests` uses the built-in **Debug-only** `--uitesting-capture` fixture to verify region selection, button and keyboard clipboard export, and Escape cancellation without Screen Recording permission or touching real screen pixels. Run it on an **unlocked interactive macOS desktop**:

```bash
make ui-test
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

The complete matrix is not yet certified. Local checks on 2026-10-10 covered capture-window creation and repeated closing, PNG export, both copy shortcuts without a save panel, toolbar alignment, and Screen Recording approval after an ad-hoc rebuild. These checks do not replace the mixed-display, accessibility, and notarized-upgrade checks above.

Opaque redaction is asserted on decoded PNG pixel data, not only on the on-screen overlay; this is a privacy regression gate.
