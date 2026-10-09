#!/bin/bash
# Package a local ad-hoc build as a development DMG. No notarization is performed.
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_dir"
app_path="${1:-.build/local-release/Lunarium.app}"
test -d "$app_path" || { echo "Missing app: $app_path. Run make local-release first." >&2; exit 1; }
codesign --verify --deep --strict "$app_path"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_path/Contents/Info.plist")"
release_label="${2:-$version}"
[[ "$release_label" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$ ]] || { echo "Invalid release label" >&2; exit 1; }
[[ "$release_label" == "$version" || "$release_label" == "$version"-* ]] || { echo "Release label must match app version $version" >&2; exit 1; }

mkdir -p .build/dist
staging_dir="$(mktemp -d "$repo_dir/.build/dmg-staging.XXXXXX")"
ditto "$app_path" "$staging_dir/Lunarium.app"
ln -s /Applications "$staging_dir/Applications"
cp LICENSE "$staging_dir/LICENSE.txt"
cp THIRD_PARTY_NOTICES.md "$staging_dir/THIRD_PARTY_NOTICES.md"
cat > "$staging_dir/READ ME.txt" <<'EOF'
Lunarium — native screenshots and annotations for macOS

Development preview for Apple Silicon, macOS 14 or later.
This app is ad-hoc signed, not signed with Apple Developer ID or notarized.
macOS may block opening it because its developer cannot be verified.
Automatic updates are disabled in this build.

Drag Lunarium.app to Applications, then launch the installed copy.
Lunarium appears as a moon icon in the menu bar.
Choose Capture Area or press Command-Shift-2 (F13 is also supported).
Allow Screen Recording in System Settings > Privacy & Security, then
quit and reopen Lunarium if macOS asks you to do so.

Drag a region, annotate, and press Command-C or Control-C to copy a PNG.
Copy does not save a file. Save opens a file chooser; Escape cancels.
Screenshots remain local. No accounts, analytics, or screenshot uploads.

Source, documentation, support, and license:
https://github.com/owlCoder/lunarium

Lunarium is free and open-source software under the MIT License.
EOF

asset_name="Lunarium-$release_label-arm64.dmg"
hdiutil create -volname Lunarium -srcfolder "$staging_dir" -fs HFS+ \
    -format UDZO -ov "$repo_dir/.build/dist/$asset_name"
hdiutil verify "$repo_dir/.build/dist/$asset_name"
(cd .build/dist && shasum -a 256 "$asset_name" > "$asset_name.sha256")
printf '\nDevelopment DMG: %s\nChecksum: %s\n' \
    "$repo_dir/.build/dist/$asset_name" "$repo_dir/.build/dist/$asset_name.sha256"
