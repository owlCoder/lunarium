# Contributing to Lunarium

Thanks for helping make screenshot capture more useful on macOS.

## Development

1. Check [open issues](https://github.com/owlCoder/lunarium/issues) before starting a substantial change.
2. Fork the repository and branch from `main`.
3. Install XcodeGen (`brew install xcodegen`) and Xcode 16+ for development and tests. Apple's Command Line Tools are sufficient for `make local-build`.
4. Run `make project`, open `Lunarium.xcodeproj`, and build the Lunarium scheme, or start with `make local-build`.
5. Keep changes focused, explain the motivation, and link relevant issues in your pull request.

## Design and engineering

- Keep capture fast, unobtrusive, and privacy preserving.
- Prefer Swift, AppKit, ScreenCaptureKit, and system frameworks over dependencies.
- Preserve multi-monitor and Retina correctness; test different scaling factors.
- Treat permissions as user-facing workflows. Do not ask for Accessibility when a Carbon hotkey suffices.
- Avoid creating network dependencies for local screenshot features.
- Use approachable accessibility labels and test keyboard-only interactions.

## Pull requests
Describe the problem, the resulting behavior, how you tested it, and your macOS/Xcode versions. UI changes should include non-sensitive screenshots. Update documentation and [CHANGELOG.md](CHANGELOG.md) when user-facing behavior changes.

Run `make test` for relevant code changes. Run `make ui-test` on an unlocked Mac when changing capture or Settings interactions, and describe any manual checks. See [development notes](docs/DEVELOPMENT.md) and the [test plan](docs/TESTING.md). CI builds the app and runs unit tests; permissions and mixed-display behavior require hardware validation.

## Reporting bugs
Use the [bug report form](https://github.com/owlCoder/lunarium/issues/new?template=bug_report.yml), include reproduction steps and console errors where useful, and remove personal data from all screenshots/logs. Include the app version and whether you used a release download or a source build. Security issues should be disclosed privately under [SECURITY.md](SECURITY.md).

By participating, you agree to follow our [Code of Conduct](CODE_OF_CONDUCT.md).
