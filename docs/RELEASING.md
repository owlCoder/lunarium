# Release checklist

The CI workflow builds an **unsigned** arm64 development app and runs unit tests. It retains a ZIP as a temporary GitHub Actions artifact. The separate gated `Signed macOS Release` workflow is configured to create notarized DMGs and signed Sparkle updates when the required maintainer secrets are supplied. See [RELEASE_SETUP.md](RELEASE_SETUP.md).

For a public macOS download:
1. Complete hardware UI validation from [DEVELOPMENT.md](DEVELOPMENT.md) and resolve all CI errors.
2. Bump `CFBundleShortVersionString` / `CFBundleVersion` in `project.yml`; update CHANGELOG.md.
3. Build Release for arm64 with the official Xcode toolchain.
4. Sign with an Apple Developer ID Application certificate, enable hardened runtime, and notarize with Apple's notarytool.
5. Staple the notarization ticket, package a DMG and verify Gatekeeper installation on a clean Mac.
6. Tag `vX.Y.Z` and attach the verified binary and SHA-256 checksum to GitHub Releases.

Do not upload signing identities or Apple credentials to the repository. Future automated publishing may use encrypted GitHub Actions secrets.
