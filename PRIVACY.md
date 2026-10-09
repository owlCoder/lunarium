# Privacy

Lunarium is local-first. The application does not include accounts, analytics, advertising SDKs, telemetry, or automatic screenshot uploads.

When you invoke capture, Apple's ScreenCaptureKit reads pixels from available displays with your permission. You choose which region to select and what to copy or save. Captured content is retained in process memory while the overlay is open, and an exported PNG is written only when you explicitly copy or save it.

The clipboard is managed by macOS; other applications may be able to read its contents. Saved screenshots remain in the location you select.

## Network activity

Capture, annotation, and export work locally. In builds configured for signed releases, Sparkle can contact the HTTPS update feed and download signed updates from GitHub. These requests do not include screenshot content, but the hosting service receives normal connection information such as your IP address. Automatic updates are disabled in current ad-hoc preview builds; choosing **Check for Updates** opens GitHub Releases in your browser.

macOS itself controls permission settings, and OS-provided system diagnostics may apply independently of Lunarium. The project does not claim to control third-party applications or macOS internals.
