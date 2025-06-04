#!/bin/bash

set -e

BASE_IMAGE="assets/logo.png"

# Check if ImageMagick is installed
if ! command -v convert &>/dev/null; then
  echo "❌ Error: ImageMagick 'convert' is not installed." >&2
  exit 1
fi

echo "✅ Base image: $BASE_IMAGE"

### --- iOS Icon Generation ---
IOS_OUT="ios/Runner/Assets.xcassets/AppIcon.appiconset"
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

echo "📱 Generating iOS icons..."
for entry in "${IOS_ICONS[@]}"; do
  set -- $entry
  SIZE=$1
  FILENAME=$2
  echo "  → $FILENAME (${SIZE}x${SIZE})"
  convert "$BASE_IMAGE" -resize "${SIZE}x${SIZE}" png32:"$IOS_OUT/$FILENAME"
done

### --- Android Icon Generation ---
ANDROID_RES="android/app/src/main/res"
declare -A ANDROID_SIZES=(
  [mdpi]=48
  [hdpi]=72
  [xhdpi]=96
  [xxhdpi]=144
  [xxxhdpi]=192
)

echo "🤖 Generating Android icons..."
for density in "${!ANDROID_SIZES[@]}"; do
  SIZE=${ANDROID_SIZES[$density]}
  DEST="$ANDROID_RES/mipmap-$density/ic_launcher.png"
  mkdir -p "$(dirname "$DEST")"
  echo "  → $DEST (${SIZE}x${SIZE})"
  convert "$BASE_IMAGE" -resize "${SIZE}x${SIZE}" png32:"$DEST"
done

### --- macOS Icon Generation ---
MAC_OUT="macos/Runner/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$MAC_OUT"
declare -A MAC_SIZES=(
  [app_icon_16.png]=16
  [app_icon_32.png]=32
  [app_icon_64.png]=64
  [app_icon_128.png]=128
  [app_icon_256.png]=256
  [app_icon_512.png]=512
  [app_icon_1024.png]=1024
)

echo "🍎 Generating macOS icons..."
for name in "${!MAC_SIZES[@]}"; do
  SIZE=${MAC_SIZES[$name]}
  echo "  → $MAC_OUT/$name (${SIZE}x${SIZE})"
  convert "$BASE_IMAGE" -resize "${SIZE}x${SIZE}" png32:"$MAC_OUT/$name"
done

### --- Windows Icon Generation ---
WIN_OUT="windows/runner/resources/app_icon.ico"
mkdir -p "$(dirname "$WIN_OUT")"

echo "🪟 Generating Windows .ico file..."
convert "$BASE_IMAGE" \
  -resize 16x16 png32:icon_16.png \
  -resize 32x32 png32:icon_32.png \
  -resize 48x48 png32:icon_48.png \
  -resize 256x256 png32:icon_256.png \
  "$WIN_OUT"
rm -f icon_16.png icon_32.png icon_48.png icon_256.png

### --- Linux Icon Generation ---
LINUX_OUT="linux/app_icon.png"
mkdir -p "$(dirname "$LINUX_OUT")"
echo "🐧 Generating Linux icon (256x256)"
convert "$BASE_IMAGE" -resize 256x256 png32:"$LINUX_OUT"

echo "✅ All icons generated successfully."


