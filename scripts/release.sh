#!/usr/bin/env bash
# Baut eine Release-Fassung und packt sie als .dmg nach dist/.
#
#   ./scripts/release.sh              nur bauen und packen
#   ./scripts/release.sh --publish    zusätzlich Git-Tag setzen und GitHub Release anlegen
#
# Veröffentlicht wird nur auf ausdrückliche Anweisung: ein Tag und ein Release
# lassen sich nicht mehr still zurücknehmen, sobald jemand sie gezogen hat.
set -euo pipefail

cd "$(dirname "$0")/.."
PUBLISH=${1:-}

command -v xcodegen >/dev/null || { echo "xcodegen fehlt: brew install xcodegen"; exit 1; }

VERSION=$(awk -F'"' '/MARKETING_VERSION:/{print $2}' project.yml)
[ -n "$VERSION" ] || { echo "MARKETING_VERSION nicht in project.yml gefunden"; exit 1; }
TAG="v$VERSION"
echo "Version: $VERSION"

if [ -n "$(git status --porcelain)" ]; then
  echo "Arbeitsverzeichnis ist nicht sauber. Erst einchecken, sonst lässt sich"
  echo "später nicht mehr feststellen, was in dieser Fassung steckt."
  exit 1
fi

if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Tag $TAG gibt es schon. Version in project.yml erhöhen."
  exit 1
fi

xcodegen generate

# Ungetestetes wird nicht ausgeliefert.
xcodebuild test -project Floty.xcodeproj -scheme Floty | tail -3

xcodebuild -project Floty.xcodeproj -scheme Floty -configuration Release build | tail -2

BUILT=$(xcodebuild -project Floty.xcodeproj -scheme Floty -configuration Release \
        -showBuildSettings 2>/dev/null | awk -F' = ' '/ BUILT_PRODUCTS_DIR/{print $2}' | head -1)/Floty.app
[ -d "$BUILT" ] || { echo "Nicht gebaut: $BUILT"; exit 1; }

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
cp -R "$BUILT" "$STAGE/Floty.app"
# Der vertraute Ziehen-nach-Programme-Ablauf im Fenster des Abbilds.
ln -s /Applications "$STAGE/Programme"

mkdir -p dist
DMG="dist/Floty-$VERSION.dmg"
rm -f "$DMG"
hdiutil create -volname "Floty $VERSION" -srcfolder "$STAGE" -ov -format UDZO -quiet "$DMG"

echo "Gepackt: $DMG ($(du -h "$DMG" | cut -f1))"
echo
echo "Hinweis: ad-hoc signiert. Auf einem fremden Mac muss die App beim ersten"
echo "Start über Rechtsklick → Öffnen freigegeben werden."

if [ "$PUBLISH" != "--publish" ]; then
  echo
  echo "Zum Veröffentlichen: ./scripts/release.sh --publish"
  exit 0
fi

command -v gh >/dev/null || { echo "gh fehlt: brew install gh"; exit 1; }

NOTES=$(awk "/^## \[$VERSION\]/{f=1;next} /^## \[/{f=0} f" CHANGELOG.md)
[ -n "$NOTES" ] || { echo "Kein CHANGELOG-Abschnitt für $VERSION gefunden."; exit 1; }

git tag -a "$TAG" -m "Floty $VERSION"
git push origin "$TAG"
gh release create "$TAG" "$DMG" --title "Floty $VERSION" --notes "$NOTES"
echo "Veröffentlicht: $TAG"
