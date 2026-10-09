# Privacy

Lunarium is local-first. The application does not include accounts, analytics, advertising SDKs, telemetry, or automatic screenshot uploads.

When you invoke capture, Apple's ScreenCaptureKit reads pixels from available displays with your permission. You choose which region to select and what to copy or save. Captured content is retained in process memory while the overlay is open, and an exported PNG is written only when you explicitly copy or save it.

The clipboard is managed by macOS and can be read by other applications you choose to paste into. Saved screenshots remain in the location you select.

macOS itself controls permission settings, and OS-provided system diagnostics may apply independently of Lunarium. The project does not claim to control third-party applications or macOS internals.
