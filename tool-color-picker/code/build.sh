#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="PicPick"
IDENTIFIER="local.picpick.ColorPicker"
BUILD_DIR="$ROOT/.build/release"
APP_DIR="$ROOT/dist/$APP_NAME.app"
ICONSET="$ROOT/.build/PicPick.iconset"

cd "$ROOT"
swift build -c release
rm -rf "$APP_DIR" "$ICONSET"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$ICONSET"
cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"

# Draw a vibrant color ring with an eyedropper in a native vector PDF, then emit all ICNS sizes.
cat > "$ROOT/.build/icon.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<defs><linearGradient id="ring" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#ff424f"/><stop offset=".18" stop-color="#ffb52e"/><stop offset=".36" stop-color="#6bd461"/><stop offset=".54" stop-color="#28c9d5"/><stop offset=".72" stop-color="#4775ff"/><stop offset=".88" stop-color="#b14bff"/><stop offset="1" stop-color="#ff424f"/></linearGradient><linearGradient id="metal" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#263142"/><stop offset="1" stop-color="#101722"/></linearGradient></defs>
<rect x="48" y="48" width="928" height="928" rx="220" fill="#f7f8fc"/>
<circle cx="500" cy="500" r="310" fill="none" stroke="url(#ring)" stroke-width="112"/>
<g transform="rotate(43 650 590)" stroke="#fff" stroke-width="26" stroke-linejoin="round">
<path d="M647 308h118a36 36 0 0 1 36 36v74H611v-74a36 36 0 0 1 36-36Z" fill="url(#metal)"/>
<path d="M610 418h190v322a50 50 0 0 1-50 50h-90a50 50 0 0 1-50-50Z" fill="url(#metal)"/>
<path d="M660 790h90l-45 100Z" fill="#252e3d"/>
<path d="M664 475v225" fill="none" stroke="#cbd4e2" stroke-width="18" stroke-linecap="round"/>
<circle cx="705" cy="793" r="18" fill="#ff7147" stroke="none"/>
</g></svg>
SVG
/usr/bin/sips -s format png "$ROOT/.build/icon.svg" --out "$ROOT/.build/icon-1024.png" >/dev/null
for size in 16 32 128 256 512; do
  /usr/bin/sips -z "$size" "$size" "$ROOT/.build/icon-1024.png" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  twice=$((size * 2))
  /usr/bin/sips -z "$twice" "$twice" "$ROOT/.build/icon-1024.png" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP_DIR/Contents/Resources/AppIcon.icns"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>PicPick</string>
<key>CFBundleDisplayName</key><string>Color Picker</string>
<key>CFBundleIdentifier</key><string>local.picpick.ColorPicker</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
</dict></plist>
PLIST

# Build a native Installer package that places the application in /Applications.
mkdir -p "$ROOT/dist"
pkgbuild --component "$APP_DIR" --install-location /Applications \
  --identifier "$IDENTIFIER" --version 1.0.0 "$ROOT/dist/PicPick-1.0.0.pkg"
echo "Built app: $APP_DIR"
echo "Built installer: $ROOT/dist/PicPick-1.0.0.pkg"
