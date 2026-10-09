# Configuring signed macOS releases

**Status:** Development previews can be packaged locally without Apple credentials; see [RELEASING.md](RELEASING.md). The Developer ID workflow below requires maintainer credentials before it can publish notarized releases and automatic updates.

## Required credentials

Create a GitHub Actions environment named `production` with required reviewer approval. Add these encrypted secrets (repository or environment scope):

- `APPLE_CERTIFICATE_P12_BASE64`: base64 of a Developer ID Application certificate exported as password-protected `.p12`
- `APPLE_CERTIFICATE_PASSWORD`: corresponding export password
- `APPLE_TEAM_ID`: Apple Developer Team ID
- `APPLE_ID`: Apple account authorized for notarization
- `APPLE_APP_SPECIFIC_PASSWORD`: Apple app-specific password, or adjust workflow to use a Notary API key
- `SPARKLE_PUBLIC_ED_KEY`: public EdDSA key from Sparkle's `generate_keys`
- `SPARKLE_PRIVATE_ED_KEY`: matching base64 private EdDSA key exported from Sparkle's key management tool

**Never commit or paste private keys, Apple credentials or certificates into source files or issues.** Avoid third-party fork PRs gaining release credentials.

Generate and back up a single Sparkle keypair **before** your first signed release. The public key is embedded in `Info.plist`; the private key signs update ZIPs. If the private key is lost, update migration requires careful signing-key rotation.

## Publishing

1. Run `make project`, `make build`, XCTest and UI tests on a physical Apple Silicon Mac.
2. Complete [TESTING.md](TESTING.md) manual acceptance matrix and verify VoiceOver.
3. Set `CFBundleShortVersionString` and increment numeric `CFBundleVersion` in `project.yml`.
4. Merge to `main`; tag the exact tested commit using `vX.Y.Z` and push the tag.
5. Approve the `production` environment job. The release workflow builds with Developer ID, verifies code signing, notarizes/staples the app and DMG, signs the ZIP with Sparkle EdDSA, uploads both archives, and writes `appcast.xml` to `main`.
6. Download the DMG on a different Mac, verify Gatekeeper, test updating from the previous notarized release.

Only **stable** vX.Y.Z tags enter this workflow; preview tags containing a hyphen are skipped. The public Sparkle feed URL is `https://raw.githubusercontent.com/owlCoder/lunarium/main/appcast.xml`. Protect main from unreviewed edits and restrict access to the `production` environment. Publishing the appcast requires GitHub Actions to have write permission to `main`; if branch protections block it, adjust repository policy or use a separate protected Pages deployment.

In local Debug, Release, and preview builds, no Sparkle key is bundled; “Check for Updates” opens GitHub Releases. The updater activates only in builds containing both an HTTPS feed and matching public key.

The signed workflow cannot succeed without these secrets. A Developer ID signing certificate and notarization credentials must be provisioned by the maintainer; ad-hoc development previews can be published separately.
