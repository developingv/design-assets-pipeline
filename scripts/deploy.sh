#!/usr/bin/env bash
# Deploys build/ to orphan 'assets' branch → served via jsDelivr CDN
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
COMMIT_MSG="sync: assets $(date +%Y-%m-%d)"

cd "$ROOT"

git config user.name "asset-bot"
git config user.email "bot@localhost"

# Create or replace 'assets' branch with only build/
git branch -D assets 2>/dev/null || true
git checkout --orphan assets
git rm -rf . 2>/dev/null || true

# Copy build/ contents to root of branch
cp -r "$BUILD"/* .
cp "$BUILD"/manifest.json .
cp "$BUILD"/tags-index.json .

# Remove build/ from assets branch (we copied contents to root)
rm -rf build

git add -A
git commit -m "$COMMIT_MSG"
git push origin assets --force 2>&1

# Back to main
git checkout main 2>/dev/null || git checkout master 2>/dev/null || true

echo ""
echo "══════════════════════════════════════════"
echo "Deploy concluído!"
echo "Branch: assets"
echo "Base CDN: https://cdn.jsdelivr.net/gh/developingv/design-assets-pipeline@assets/"
echo "Manifest: https://cdn.jsdelivr.net/gh/developingv/design-assets-pipeline@assets/manifest.json"
echo "══ Tags: https://cdn.jsdelivr.net/gh/developingv/design-assets-pipeline@assets/tags-index.json"
echo "══════════════════════════════════════════"
