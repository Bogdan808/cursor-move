#!/usr/bin/env bash
# Publish cursor-move + Homebrew tap to GitHub (Bogdan808).
# Prerequisites: brew install gh && gh auth login
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="v0.1.0"

if ! command -v gh >/dev/null 2>&1; then
  echo "Install GitHub CLI: brew install gh" >&2
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "Run: gh auth login" >&2
  exit 1
fi

cd "$ROOT"

if gh repo view Bogdan808/cursor-move >/dev/null 2>&1; then
  if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "https://github.com/Bogdan808/cursor-move.git"
  fi
  git push -u origin main
elif ! git remote get-url origin >/dev/null 2>&1; then
  gh repo create Bogdan808/cursor-move --public --source=. --remote=origin --push
else
  git push -u origin main
fi

git push origin "$TAG" 2>/dev/null || git push origin "refs/tags/$TAG"

SHA256="$(
  curl -fsSL "https://github.com/Bogdan808/cursor-move/archive/refs/tags/${TAG}.tar.gz" | shasum -a 256 | awk '{print $1}'
)"
echo "Release tarball sha256: $SHA256"

update_sha() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    return 0
  fi
  if [[ "$(uname)" == Darwin ]]; then
    sed -i '' "s/sha256 \"REPLACE_WITH_SHA256_AFTER_GITHUB_RELEASE\"/sha256 \"$SHA256\"/" "$f"
  else
    sed -i "s/sha256 \"REPLACE_WITH_SHA256_AFTER_GITHUB_RELEASE\"/sha256 \"$SHA256\"/" "$f"
  fi
}

update_sha "$ROOT/Formula/cursor-move.rb"
update_sha "$ROOT/homebrew-cursor-move/Formula/cursor-move.rb"

git add Formula/cursor-move.rb
git commit -m "Set Homebrew formula sha256 for ${TAG}" || true
git push origin main

cd "$ROOT/homebrew-cursor-move"
git branch -m main 2>/dev/null || true
git add Formula/cursor-move.rb
git commit -m "Set formula sha256 for ${TAG}" || true

if gh repo view Bogdan808/homebrew-cursor-move >/dev/null 2>&1; then
  if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "https://github.com/Bogdan808/homebrew-cursor-move.git"
  fi
  git push -u origin main
elif ! git remote get-url origin >/dev/null 2>&1; then
  gh repo create Bogdan808/homebrew-cursor-move --public --source=. --remote=origin --push
else
  git push -u origin main
fi

echo ""
echo "Done. Users can install with:"
echo "  brew tap Bogdan808/cursor-move"
echo "  brew install cursor-move"
