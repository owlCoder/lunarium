#!/bin/bash
# Local build using Command Line Tools when full Xcode is unavailable.
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_dir"
configuration="${1:-Debug}"
case "$configuration" in
    Debug) build_dir="$repo_dir/.build/local"; swift_flags=(-D DEBUG -Onone) ;;
    Release) build_dir="$repo_dir/.build/local-release"; swift_flags=(-O) ;;
    *) echo "Usage: $0 [Debug|Release]" >&2; exit 1 ;;
esac
app_dir="$build_dir/Lunarium.app"

# Keep this version aligned with project.yml. Checksum from Sparkle's Package.swift.
sparkle_version="2.9.6"
sparkle_checksum="8d5fb41d960b43f4a68aa14126bf62b098544ec8d191cdcc73eb14e63a8e7606"
dependency_root="$repo_dir/.build/local/dependencies"
archive="$dependency_root/Sparkle-$sparkle_version.zip"
dependency_dir="$dependency_root/sparkle-$sparkle_version"
framework_dir="$dependency_dir/Sparkle.xcframework/macos-arm64_x86_64"

mkdir -p "$dependency_root"
if [[ ! -f "$archive" ]]; then
    curl -fL --retry 2 --connect-timeout 20 \
        "https://github.com/sparkle-project/Sparkle/releases/download/$sparkle_version/Sparkle-for-Swift-Package-Manager.zip" \
        -o "$archive.tmp"
    mv "$archive.tmp" "$archive"
fi
printf '%s  %s\n' "$sparkle_checksum" "$archive" | shasum -a 256 -c -
ditto -x -k "$archive" "$dependency_dir"

mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources" "$app_dir/Contents/Frameworks"
sources=(Lunarium/App/*.swift Lunarium/Capture/*.swift Lunarium/Editor/*.swift Lunarium/Services/*.swift)
xcrun swiftc -swift-version 5 -parse-as-library \
    -target arm64-apple-macos14.0 -sdk "$(xcrun --show-sdk-path)" \
    -module-name Lunarium "${swift_flags[@]}" \
    -F "$framework_dir" -framework Sparkle \
    -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
    "${sources[@]}" -o "$app_dir/Contents/MacOS/Lunarium"

cp Lunarium/Info.plist "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleDevelopmentRegion en' "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleExecutable Lunarium' "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier io.github.owlCoder.Lunarium' "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :LSMinimumSystemVersion string 14.0' "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string AppIcon' "$app_dir/Contents/Info.plist"
for localization in Lunarium/Resources/*.lproj; do
    ditto "$localization" "$app_dir/Contents/Resources/$(basename "$localization")"
done
ditto Lunarium/Resources/ThirdPartyLicenses "$app_dir/Contents/Resources/ThirdPartyLicenses"
ditto "$framework_dir/Sparkle.framework" "$app_dir/Contents/Frameworks/Sparkle.framework"

iconset="$build_dir/AppIcon.iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
    cp "Lunarium/Resources/Assets.xcassets/AppIcon.appiconset/icon-$size.png" "$iconset/icon_${size}x${size}.png"
    cp "Lunarium/Resources/Assets.xcassets/AppIcon.appiconset/icon-$((size * 2)).png" "$iconset/icon_${size}x${size}@2x.png"
done
iconutil -c icns "$iconset" -o "$app_dir/Contents/Resources/AppIcon.icns"
codesign --force --sign - --identifier io.github.owlCoder.Lunarium "$app_dir"
codesign --verify --deep --strict "$app_dir"
printf '\nLocal %s app (ad-hoc signed, not notarized): %s\n' "$configuration" "$app_dir"
