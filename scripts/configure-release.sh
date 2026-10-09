#!/usr/bin/env bash
set -euo pipefail

: "${SPARKLE_PUBLIC_ED_KEY:?Missing Sparkle public key}"
: "${SPARKLE_FEED_URL:?Missing Sparkle feed URL}"
test -f Lunarium/Info.plist || { echo "Run make project first"; exit 1; }

# XcodeGen recreates Info.plist; inject *before* compiling and Developer ID signing.
plutil -insert SUPublicEDKey -string "$SPARKLE_PUBLIC_ED_KEY" Lunarium/Info.plist
plutil -insert SUFeedURL -string "$SPARKLE_FEED_URL" Lunarium/Info.plist
plutil -lint Lunarium/Info.plist
echo "Configured signed-release update feed (private key remains outside the app)."
