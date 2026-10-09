# Security Policy

## Supported versions
Lunarium is a prerelease project. Security fixes target `main` and the latest preview until a stable release exists. Older preview builds are not maintained separately.

## Reporting a vulnerability
**Please do not post exploitable vulnerabilities in public issues.** Use [GitHub private vulnerability reporting](https://github.com/owlCoder/lunarium/security/advisories/new) for this repository. Reports go to the repository maintainers and are not published as public issues.

Include a concise description, reproduction steps, affected macOS version, and a safe proof of concept if available. Do not provide real user screenshots or sensitive information.

## Security model
Screen Recording permission is managed by macOS. Lunarium requests it for user-triggered capture. Screenshot pixels remain local; there is no telemetry, screenshot upload, or remote image hosting service in the application. Opaque redaction is applied to the final exported pixels; blur and pixelation are visual effects and should not be relied on to erase secrets.

Current preview downloads are ad-hoc signed and not notarized. Automatic updates are disabled in these builds. Developer ID distribution and Sparkle updates require separate signing credentials; see [release setup](docs/RELEASE_SETUP.md).
