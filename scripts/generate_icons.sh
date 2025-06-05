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

generate_ios_icons() {
  echo "📱 Generating iOS icons..."
  local IOS_OUT="ios/Runner/Assets.xcassets/AppIcon.appiconset"
  mkdir -p "$IOS_OUT"

  declare -a IOS_ICONS=(
    "20 Icon-App-20x20@1x.png"
    "40 Icon-App-20x20@2x.png"
    "60 Icon-App-20x20@3x.png"
    "29 Icon-App-29x29@1x.png"
    "58 Icon-App-29x29@2x.png"
    "87 Icon-App-29x29@3x.png"
    "40 Icon-App-40x40@1x.png"
    "80 Icon-App-40x40@2x.png"
    "120 Icon-App-40x40@3x.png"
    "120 Icon-App-60x60@2x.png"
    "180 Icon-App-60x60@3x.png"
    "76 Icon-App-76x76@1x.png"
    "152 Icon-App-76x76@2x.png"
    "167 Icon-App-83.5x83.5@2x.png"
    "1024 Icon-App-1024x1024@1x.png"
  )

  for entry in "${IOS_ICONS[@]}"; do
    set -- $entry
    SIZE=$1
    FILENAME=$2
    echo "  → $FILENAME (${SIZE}x${SIZE})"
    resize_sips "$BASE_IMAGE" "$SIZE" "$IOS_OUT/$FILENAME"
  done
}

generate_android_icons() {
  echo "🤖 Generating Android icons..."
  local ANDROID_RES="android/app/src/main/res"
  declare -A ANDROID_SIZES=(
    [mdpi]=48
    [hdpi]=72
    [xhdpi]=96
    [xxhdpi]=144
    [xxxhdpi]=192
  )

  for density in "${!ANDROID_SIZES[@]}"; do
    SIZE=${ANDROID_SIZES[$density]}
    DEST="$ANDROID_RES/mipmap-$density/ic_launcher.png"
    mkdir -p "$(dirname "$DEST")"
    echo "  → $DEST (${SIZE}x${SIZE})"
    resize_sips "$BASE_IMAGE" "$SIZE" "$DEST"
  done
}

generate_macos_icons() {
  echo "🍎 Generating macOS icons..."
  local MAC_OUT="macos/Runner/Assets.xcassets/AppIcon.appiconset"
  mkdir -p "$MAC_OUT"
  find "$MAC_OUT" -type f \( -name "icon_*.png" -o -name "app_icon_*.png" \) -delete

  declare -A MAC_ICONS=(
    [icon_16x16.png]=16
    [icon_16x16@2x.png]=32
    [icon_32x32.png]=32
    [icon_32x32@2x.png]=64
    [icon_128x128.png]=128
    [icon_128x128@2x.png]=256
    [icon_256x256.png]=256
    [icon_256x256@2x.png]=512
    [icon_512x512.png]=512
    [icon_512x512@2x.png]=1024
  )

  for name in "${!MAC_ICONS[@]}"; do
    SIZE=${MAC_ICONS[$name]}
    echo "  → $name (${SIZE}x${SIZE})"
    resize_sips "$BASE_IMAGE" "$SIZE" "$MAC_OUT/$name"
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
  echo "🐧 Generating Linux icon (256x256)..."
  local LINUX_OUT="linux/app_icon.png"
  mkdir -p "$(dirname "$LINUX_OUT")"
  resize_sips "$BASE_IMAGE" 256 "$LINUX_OUT"
}

generate_windows_icons() {
  echo "🪟 Generating Windows .ico source PNGs..."
  local ICO_TMP="windows/runner/resources/iconset"
  mkdir -p "$ICO_TMP"

  for SIZE in 16 32 48 256; do
    echo "  → icon_${SIZE}x${SIZE}.png"
    resize_sips "$BASE_IMAGE" "$SIZE" "$ICO_TMP/icon_${SIZE}x${SIZE}.png"
  done

  # Optionally: integrate png2ico for real .ico generation if desired
}

### --- Run All ---
generate_ios_icons
generate_android_icons
generate_macos_icons
generate_linux_icon
generate_windows_icons

echo "✅ All platform icons generated successfully (macOS-native only)."
