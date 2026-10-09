# Contributing to Lunarium

Thanks for helping make screenshot capture more useful on macOS.

## Development
1. Check open issues and discussions before starting a substantial change.
2. Fork the repository and branch from `main`.
3. Install Xcode 16+ and XcodeGen (`brew install xcodegen`).
4. Run `make project`, open `Lunarium.xcodeproj`, and build the Lunarium scheme.
5. Keep changes focused, explain the motivation, and link relevant issues in your pull request.

## Design and engineering
- Keep capture fast, unobtrusive, and privacy preserving.
- Prefer Swift, AppKit, ScreenCaptureKit, and system frameworks over dependencies.
- Preserve multi-monitor and Retina correctness; test different scaling factors.
- Treat permissions as user-facing workflows. Do not ask for Accessibility when a Carbon hotkey suffices.
- Avoid creating network dependencies for local screenshot features.
- Use approachable accessibility labels and test keyboard-only interactions.

## Pull requests
Describe what changed, how you tested it, macOS/Xcode versions, and any permissions or screenshots needed to reproduce behavior. UI changes should include non-sensitive screenshots. If you add a new feature, update README/docs appropriately.

## Reporting bugs
Use the bug report form, include reproduction steps and console errors where useful, and remove personal data from all screenshots/logs. Security issues should be disclosed privately under [SECURITY.md](SECURITY.md).

By participating, you agree to follow our [Code of Conduct](CODE_OF_CONDUCT.md).
