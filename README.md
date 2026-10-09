# Lunarium 🌙

**A fast, native, open-source screenshot and annotation tool for macOS.**

[![macOS CI](https://github.com/owlCoder/lunarium/actions/workflows/macos.yml/badge.svg)](https://github.com/owlCoder/lunarium/actions/workflows/macos.yml)
[![MIT License](https://img.shields.io/badge/license-MIT-818cf8.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue.svg)](https://www.apple.com/macos/)
[![Architecture](https://img.shields.io/badge/arch-Apple%20Silicon-blueviolet.svg)](https://developer.apple.com/)

<p align="center"><img src="Brand/lunarium-banner.svg" alt="Lunarium — Capture the moment. Keep the flow." width="100%"></p>

> **Development preview:** Lunarium is under active development. There is no notarized release yet. Follow the build instructions to test it on a Mac.

Lunarium is built for the workflow that makes Lightshot feel effortless: press a key, drag an area, annotate, and copy or save. Reimagined as a privacy-first macOS utility with a lightweight AppKit overlay and native screen capture.

## Features

- **One-key capture:** F13 (commonly mapped to Print Screen on external keyboards), plus `⌘⇧2` fallback
- **Region selection:** drag to select, with on-screen dimensions and a focused editing toolbar
- **Annotations:** pen, arrow, rectangle, ellipse and text; undo support
- **Export:** copy a PNG to the clipboard, or save a PNG file
- **Multiple displays:** captures each connected display using ScreenCaptureKit
- **Menu bar app:** stays out of the Dock
- **Privacy:** no cloud service, analytics, sign-in, or screenshot uploads

> **Keyboard note:** macOS keyboards do not have a universal Print Screen virtual key. Many external keyboards map Print Screen to F13, but some require remapping. See [keyboard notes](docs/KEYBOARD.md).

## Requirements

- macOS 14 Sonoma or later
- Apple Silicon (arm64) Mac
- Xcode 16 or newer and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- Screen Recording permission (requested when capturing)

## Build from source

```bash
git clone https://github.com/owlCoder/lunarium.git
cd lunarium
brew install xcodegen
make project
open Lunarium.xcodeproj
```

Choose the **Lunarium** scheme, your local signing team if needed, and Run (⌘R). Or use `make build` for a command-line Debug build. Icon assets are generated locally from the included Swift vector drawing script; no external icon binaries or third-party packages are required.

**First launch:** Choose **Capture Area** from the menu bar. macOS may request Screen Recording permission. Grant it in **System Settings → Privacy & Security → Screen & System Audio Recording** and restart Lunarium if prompted. The hotkeys become available while the app is running.

## Use

1. Press **Print Screen / F13** or **⌘⇧2** (or use the menu bar icon).
2. Drag to select a region; press **Escape** to cancel.
3. Select a drawing tool and annotate your screenshot.
4. Use **Copy** to paste a PNG, **Save** to write a PNG, or **Close** to dismiss. `⌘Z` undoes the most recent annotation.

## Architecture

```text
Lunarium/
  App/                  Menu bar lifecycle and settings
  Capture/              ScreenCaptureKit and global shortcuts
  Editor/               Multi-display overlay and annotations
  Services/             Clipboard and PNG export
  Resources/            App icon asset catalog
Brand/                  Source artwork (SVG)
scripts/                Native icon generator
docs/                   Contributor and keyboard notes
.github/workflows/      macOS CI
project.yml             XcodeGen project definition
```

No Electron, embedded browser engine, third-party analytics, or network entitlement.

## Roadmap

- [x] Native app architecture and menu bar workflow
- [x] Region capture, annotation, copy/save workflow (initial implementation)
- [ ] User-configurable capture shortcut
- [ ] Blur / pixelate and richer markup tools
- [ ] Auto-update and signed/notarized DMG releases
- [ ] Localization and comprehensive UI automation tests
- [ ] Public beta after hands-on macOS testing

These checkboxes describe implemented source code, **not** a claim of a tested production release.

See [development notes](docs/DEVELOPMENT.md), [release process](docs/RELEASING.md) and [changelog](CHANGELOG.md) for project status and verification.

## Contributing

Issues and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). Please avoid sharing private screenshot contents in bug reports.

## Security & privacy

Lunarium captures screen pixels only when explicitly invoked and does not transmit screenshots. See [SECURITY.md](SECURITY.md) for responsible disclosure and [PRIVACY.md](PRIVACY.md) for the privacy statement.

## License

MIT © 2026 Lunarium contributors. See [LICENSE](LICENSE).

Lunarium is an independent open-source project, not affiliated with Lightshot or Apple.
