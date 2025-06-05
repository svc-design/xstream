#!/bin/bash

set -e

echo "📦 初始化 Git LFS..."
git lfs install

echo "🔍 搜索图像资源并配置 Git LFS 跟踪..."

# 遍历相关路径下的 .png 和 .ico 文件
for dir in assets docs/images ios android macos windows linux; do
  if [ -d "$dir" ]; then
    find "$dir" -type f \( -iname "*.png" -o -iname "*.ico" \) | while read -r file; do
      ext="${file##*.}"
      echo "🧷 跟踪 $file"
      git lfs track "$file"
    done
  fi
done

echo "📝 确保 .gitattributes 被 Git 管理..."
git add .gitattributes

echo "✅ Git LFS 跟踪配置完成"

