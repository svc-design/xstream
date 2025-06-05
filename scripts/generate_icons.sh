#!/bin/bash
set -e

BASE_IMAGE="assets/logo.png"

if ! command -v sips &>/dev/null; then
  echo "❌ Error: macOS 'sips' command not found. This script requires macOS." >&2
  exit 1
fi

echo "🎨 Base image: $BASE_IMAGE"

resize_sips() {
  local src="$1"
  local size="$2"
  local dst="$3"
  sips -z "$size" "$size" "$src" --out "$dst" &>/dev/null
}

generate_macos_icons() {
  echo "🍎 Generating macOS icons..."
  local MAC_OUT="macos/Runner/Assets.xcassets/AppIcon.appiconset"
  mkdir -p "$MAC_OUT"
  find "$MAC_OUT" -type f \( -name "icon_*.png" -o -name "app_icon_*.png" \) -delete

  local -a KEYS=(
    icon_16x16.png 16
    icon_16x16@2x.png 32
    icon_32x32.png 32
    icon_32x32@2x.png 64
    icon_128x128.png 128
    icon_128x128@2x.png 256
    icon_256x256.png 256
    icon_256x256@2x.png 512
    icon_512x512.png 512
    icon_512x512@2x.png 1024
  )

  for ((i=0; i<${#KEYS[@]}; i+=2)); do
    name="${KEYS[$i]}"
    size="${KEYS[$i+1]}"
    echo "  → $MAC_OUT/$name (${size}x${size})"
    resize_sips "$BASE_IMAGE" "$size" "$MAC_OUT/$name"
  done

  cat > "$MAC_OUT/Contents.json" <<EOF
{
  "images": [
    { "idiom": "mac", "size": "16x16", "scale": "1x", "filename": "icon_16x16.png" },
    { "idiom": "mac", "size": "16x16", "scale": "2x", "filename": "icon_16x16@2x.png" },
    { "idiom": "mac", "size": "32x32", "scale": "1x", "filename": "icon_32x32.png" },
    { "idiom": "mac", "size": "32x32", "scale": "2x", "filename": "icon_32x32@2x.png" },
    { "idiom": "mac", "size": "128x128", "scale": "1x", "filename": "icon_128x128.png" },
    { "idiom": "mac", "size": "128x128", "scale": "2x", "filename": "icon_128x128@2x.png" },
    { "idiom": "mac", "size": "256x256", "scale": "1x", "filename": "icon_256x256.png" },
    { "idiom": "mac", "size": "256x256", "scale": "2x", "filename": "icon_256x256@2x.png" },
    { "idiom": "mac", "size": "512x512", "scale": "1x", "filename": "icon_512x512.png" },
    { "idiom": "mac", "size": "512x512", "scale": "2x", "filename": "icon_512x512@2x.png" }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
EOF
}

generate_linux_icon() {
  echo "🐧 Generating Linux icon..."
  local LINUX_OUT="linux/app_icon.png"
  mkdir -p "$(dirname "$LINUX_OUT")"
  resize_sips "$BASE_IMAGE" 256 "$LINUX_OUT"
}

generate_windows_icons() {
  echo "🪟 Generating Windows .ico source PNGs..."
  local ICO_TMP="windows/runner/resources/iconset"
  local ICO_OUT="windows/runner/resources/app_icon.ico"
  mkdir -p "$ICO_TMP"

  for SIZE in 16 32 48 256; do
    local OUT="$ICO_TMP/icon_${SIZE}x${SIZE}.png"
    echo "  → $OUT"
    resize_sips "$BASE_IMAGE" "$SIZE" "$OUT"
  done

  if command -v convert &>/dev/null; then
    echo "🛠  Converting PNGs to Windows .ico"
    convert "$ICO_TMP"/icon_*.png "$ICO_OUT"
    echo "✅ Generated .ico: $ICO_OUT"
  else
    echo "⚠️  ImageMagick 'convert' not found. Please install it with 'brew install imagemagick'."
  fi
}

### --- Run ---
generate_macos_icons
generate_linux_icon
generate_windows_icons

echo "✅ macOS, Linux, Windows icons generated. Android & iOS → use flutter_launcher_icons."
