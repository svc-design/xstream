#!/bin/bash
set -e

echo "🚧 Step 1: Removing all LFS tracking rules from .gitattributes..."
# 删除包含 filter=lfs 的所有行
sed -i '' '/filter=lfs/d' .gitattributes

echo "✅ .gitattributes cleaned."
git add .gitattributes
git commit -m "chore: remove LFS tracking rules from .gitattributes"

echo "🚧 Step 2: Finding LFS-tracked files..."
# 提取所有曾被 LFS 跟踪的文件路径
FILES=$(git lfs ls-files -n)

if [ -z "$FILES" ]; then
  echo "✅ No LFS files found to clean. Done."
  exit 0
fi

echo "🚧 Step 3: Replacing LFS pointers with actual file content..."
for file in $FILES; do
  if [ -f "$file" ]; then
    git rm --cached "$file"
    git add "$file"
    echo "🔁 Re-added: $file"
  else
    echo "⚠️  Skipped missing file: $file"
  fi
done

echo "✅ All LFS-tracked files are now Git-tracked."

git commit -m "chore: replace LFS files with normal Git tracked files"

echo "🎉 Cleanup complete. Git LFS fully removed."

echo "🔍 查找所有被 LFS 跟踪的文件..."
FILES=$(git lfs ls-files -n)

if [ -z "$FILES" ]; then
  echo "✅ 没有 LFS 文件，已清理完毕"
  exit 0
fi

echo "🧹 移除 Git index 中的 LFS 绑定（不删除文件）..."
for file in $FILES; do
  if [ -f "$file" ]; then
    echo "➡️  重置追踪文件: $file"
    git rm --cached "$file"
    git add "$file"
  else
    echo "⚠️  文件不存在，跳过: $file"
  fi
done

echo "✅ 所有文件已恢复为普通 Git 文件。准备提交..."
git commit -m "chore: fully restore all LFS-tracked files to normal Git tracked files"

