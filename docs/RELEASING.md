# Releasing Lunarium

Lunarium has two distribution paths: development previews built locally, and Developer ID releases produced by the gated GitHub Actions workflow. Never present an ad-hoc preview as notarized or enable the stable Sparkle feed for it.

## Development previews

Use a prerelease tag such as `v0.2.0-preview.1`. The app's `CFBundleShortVersionString` remains the numeric `0.2.0`; the tag and asset name identify the preview iteration.

1. Update `CHANGELOG.md` and verify the version in `project.yml`.
2. Run unit tests with `make test` in Xcode and the relevant local/manual checks from [TESTING.md](TESTING.md). Record any incomplete checks in the release notes.
3. Build an optimized app and package the DMG:

   ```bash
   make dmg RELEASE_LABEL=0.2.0-preview.1
   ```

4. Mount the DMG read-only, verify the contained app's code signature, and compare its executable with the build output. Check that it includes the Applications shortcut, license, and installation notes.
5. Verify the checksum from the asset directory:

   ```bash
   cd .build/dist
   shasum -a 256 -c Lunarium-0.2.0-preview.1-arm64.dmg.sha256
   ```

6. Commit and push the tested sources to `main`, wait for macOS CI, and tag that exact commit.
7. Publish a **GitHub prerelease** with the DMG and checksum. Include macOS/architecture requirements, installation steps, known limitations, verification results, and an explicit **ad-hoc signed, not notarized** notice.

Preview tags are excluded from the stable signing job. The local packaging command retains build and staging files under the ignored `.build/` directory. It does not install the app, create an Apple certificate, notarize it, or update the Sparkle feed.

## Developer ID releases

The CI workflow builds an unsigned arm64 development app and runs unit tests. Its ZIP artifact is for development. The separate **Signed macOS Release** workflow creates notarized DMGs and signed Sparkle updates when the required maintainer secrets are supplied; see [RELEASE_SETUP.md](RELEASE_SETUP.md).

1. Complete the hardware validation in [TESTING.md](TESTING.md) and resolve CI failures.
2. Bump `CFBundleShortVersionString` and increment `CFBundleVersion` in `project.yml`; update `CHANGELOG.md`.
3. Verify the Release build, Developer ID signing, hardened runtime, notarization, and Gatekeeper installation on a clean Mac.
4. Tag the tested commit as `vX.Y.Z` and push the tag.
5. Approve the `production` environment job. It signs and notarizes the app and DMG, signs the update ZIP with Sparkle EdDSA, publishes release assets, and updates `appcast.xml` on `main`.
6. Download the published DMG on another Mac and test installation and an upgrade from the previous signed release.

Keep Apple credentials, certificates, and private Sparkle keys in encrypted GitHub Actions secrets, never in source files or release assets.
