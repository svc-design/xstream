#!/bin/bash

# Set base image path
BASE_IMAGE="assets/logo.png"
OUT_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Ensure output directory exists
mkdir -p "$OUT_DIR"

# Define sizes and output filenames
declare -a ICONS=(
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

# Check if ImageMagick is installed
if ! command -v convert &>/dev/null; then
  echo "Error: ImageMagick 'convert' is not installed." >&2
  exit 1
fi

# Generate icons
for entry in "${ICONS[@]}"; do
  set -- $entry
  SIZE=$1
  FILENAME=$2

  echo "Generating $FILENAME (${SIZE}x${SIZE})"
  convert "$BASE_IMAGE" -resize "${SIZE}x${SIZE}" "$OUT_DIR/$FILENAME"
done

echo "All icons generated in $OUT_DIR"
