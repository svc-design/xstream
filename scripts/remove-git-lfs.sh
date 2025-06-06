#!/bin/bash
set -e

echo "🔍 Step 1: Cleaning .gitattributes ..."
if [ ! -f .gitattributes ]; then
  echo "✅ No .gitattributes found. Skipping."
else
  sed -i '' '/filter=lfs/d' .gitattributes
  git add .gitattributes
  echo "✅ .gitattributes cleaned."
fi

echo "🔍 Step 2: Scanning for Git LFS-tracked files ..."
LFS_FILES=$(git lfs ls-files -n)

if [ -z "$LFS_FILES" ]; then
  echo "✅ No Git LFS-tracked files found. Already clean."
  exit 0
fi

echo "🧹 Step 3: Removing LFS bindings from files ..."
for file in $LFS_FILES; do
  if [ -f "$file" ]; then
    echo "➡️  Restoring file: $file"
    git rm --cached "$file"
    git add "$file"
  else
    echo "⚠️  Skipped missing file: $file"
  fi
done

echo "📝 Step 4: Committing changes ..."
git commit -m "chore: fully remove Git LFS tracking and restore files as regular Git content"

echo "🎉 Done. Git LFS has been removed and files are now tracked normally."


git lfs ls-files -n | while read file; do
  if [ -f "$file" ]; then
    echo "🔁 Restoring: $file"
    git rm --cached "$file"
    git add "$file"
  else
    echo "⚠️ Skipped missing file: $file"
  fi
done
