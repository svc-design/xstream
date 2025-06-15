#!/usr/bin/env bash
set -e

# 基础路径
BUNDLE_DIR="build/linux/x64/release/bundle"
LIB_DIR="$BUNDLE_DIR/lib"
OUTPUT_ZIP="$BUNDLE_DIR/xstream-linux.zip"

echo ">>> Preparing directories..."
mkdir -p "$LIB_DIR"

echo ">>> Searching and copying libgo_native_bridge.so ..."
FOUND=false

# 查找并复制
while IFS= read -r sofile; do
    cp -u "$sofile" "$LIB_DIR/"
    FOUND=true
done < <(find . -name 'libgo_native_bridge.so')

# 检查是否找到并复制成功
if [ "$FOUND" != true ]; then
    echo "Error: libgo_native_bridge.so not found!"
    exit 1
fi

echo ">>> Packaging bundle..."
cd "$BUNDLE_DIR"
zip -r xstream-linux.zip .

echo ">>> Verifying package content..."
unzip -l xstream-linux.zip
unzip -l xstream-linux.zip | grep 'lib/libgo_native_bridge.*\.so' || (echo "Missing native bridge so file in zip!" && exit 1)

echo ">>> Package complete!"
