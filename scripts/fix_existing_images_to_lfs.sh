#!/bin/bash

set -e

echo "🧹 移除已提交但未通过 LFS 管理的图像缓存..."

# 清除图标缓存
git rm --cached $(git ls-files '*.png' '*.ico') || true

echo "➕ 重新添加图像资源..."
git add $(find . -type f \( -iname "*.png" -o -iname "*.ico" \))

echo "✅ 资源已重置为 LFS 跟踪"
echo "📦 请执行：git commit -m 'fix(lfs): migrate image assets to Git LFS'"
