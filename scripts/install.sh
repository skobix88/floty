#!/usr/bin/env bash
# Baut Floty als Release und legt es nach /Applications.
# Bis Developer ID und .dmg da sind (M4), ist das der Installationsweg.
set -euo pipefail

cd "$(dirname "$0")/.."

command -v xcodegen >/dev/null || { echo "xcodegen fehlt: brew install xcodegen"; exit 1; }

xcodegen generate
xcodebuild -project Floty.xcodeproj -scheme Floty -configuration Release build

BUILT=$(xcodebuild -project Floty.xcodeproj -scheme Floty -configuration Release \
        -showBuildSettings 2>/dev/null | awk -F' = ' '/ BUILT_PRODUCTS_DIR/{print $2}' | head -1)/Floty.app

[ -d "$BUILT" ] || { echo "Nicht gebaut: $BUILT"; exit 1; }

# Läuft die alte Fassung noch, ließe sie sich nicht überschreiben.
pkill -x Floty 2>/dev/null || true
sleep 1

rm -rf /Applications/Floty.app
cp -R "$BUILT" /Applications/Floty.app

# Ad-hoc signierte Apps aus dem Build-Ordner tragen keine Quarantäne, eine aus
# einem Release schon - hier vorsorglich entfernen, damit der erste Start nicht
# an Gatekeeper hängen bleibt.
xattr -dr com.apple.quarantine /Applications/Floty.app 2>/dev/null || true

echo "Installiert: /Applications/Floty.app"
