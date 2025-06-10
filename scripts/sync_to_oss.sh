#!/usr/bin/env bash
set -euo pipefail

DAILY_ID="daily-${GITHUB_RUN_NUMBER}"
RELEASE_DIR="xstream/$DAILY_ID"

echo "🛠 Preparing release directory..."
mkdir -p "$RELEASE_DIR"
cp release-artifacts/**/*.dmg "$RELEASE_DIR/" || true
cp release-artifacts/**/*.zip "$RELEASE_DIR/" || true
cp release-artifacts/**/*.exe "$RELEASE_DIR/" || true
cp release-artifacts/**/*xstream "$RELEASE_DIR/" || true

cd xstream

# 🔢 解析最新版本号
DMG_FILES=(xstream-release-v*.dmg)
VERSIONS=()
for file in "${DMG_FILES[@]}"; do
  version=$(echo "$file" | sed -E 's/xstream-release-(v[0-9]+\.[0-9]+\.[0-9]+).dmg/\1/')
  VERSIONS+=("$version")
done

LATEST=$(printf "%s\n" "${VERSIONS[@]}" | sort -V | tail -n 1)
LATEST_DMG="xstream-release-${LATEST}.dmg"
BUILD_ID=$(git rev-parse --short HEAD || echo "manual")
BUILD_DATE=$(date +%Y-%m-%d)

echo "📦 Latest version: $LATEST"
echo "🔧 BUILD_ID=$BUILD_ID, BUILD_DATE=$BUILD_DATE"

TMP_FILE="update_history.json"
EXISTING="[]"
if ossutil stat oss://mirrors-oss/xstream/update_history.json > /dev/null 2>&1; then
  ossutil cp oss://mirrors-oss/xstream/update_history.json "$TMP_FILE"
  EXISTING=$(cat "$TMP_FILE")
fi

cat > new_entry.json <<EOF
{
  "version": "${LATEST}",
  "build_date": "${BUILD_DATE}",
  "build_id": "${BUILD_ID}",
  "daily": "${DAILY_ID}",
  "download_url": "https://mirrors-oss.oss-cn-wulanchabu.aliyuncs.com/xstream/${DAILY_ID}/${LATEST_DMG}",
  "type": "release",
  "release_notes": "自动发布构建版本 ${LATEST}"
}
EOF

UPDATED=$(echo "$EXISTING" | jq ". + [$(cat new_entry.json)] | sort_by(.build_date) | reverse | .[:100]")
echo "$UPDATED" > update_history.json

echo "$UPDATED" | jq '.[0] | {
  latest: .version,
  build_date: .build_date,
  build_id: .build_id,
  daily: .daily,
  download_url: .download_url,
  release_notes: .release_notes
}' > update.json

echo "🪣 Uploading to OSS..."
ossutil cp "$DAILY_ID" oss://mirrors-oss/xstream/"$DAILY_ID"/ --recursive --force
ossutil cp update.json oss://mirrors-oss/xstream/ --force
ossutil cp update_history.json oss://mirrors-oss/xstream/ --force

echo "✅ Sync and update complete."
