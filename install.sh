#!/usr/bin/env bash
#
# One-command installer for cursor-move.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Bogdan808/cursor-move/main/install.sh | bash
#   — or —
#   ./install.sh            (from a local clone)
#
set -euo pipefail

REPO="Bogdan808/cursor-move"
PREFIX="${PREFIX:-/usr/local}"
BINDIR="$PREFIX/bin"
LIBEXEC="$PREFIX/libexec/cursor-move"
CURSOR_CLI="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33mWarning:\033[0m %s\n' "$*"; }
error() { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

command -v node >/dev/null 2>&1 || error "Node.js is required. Install via: brew install node"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/lib/move-file.js" ]; then
  SRC_DIR="$SCRIPT_DIR"
  info "Installing from local directory: $SRC_DIR"
else
  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT
  info "Downloading cursor-move from GitHub..."
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.tar.gz" | tar xz -C "$TMPDIR" --strip-components=1
  SRC_DIR="$TMPDIR"
fi

if [ ! -f "$SRC_DIR/dist/cursor-move-file.vsix" ]; then
  info "Building VS Code extension..."
  (cd "$SRC_DIR/vscode-extension" && npx @vscode/vsce@latest package --allow-missing-repository --out ../dist/cursor-move-file.vsix)
fi

info "Installing to $PREFIX..."
mkdir -p "$LIBEXEC" "$BINDIR"

cp "$SRC_DIR/lib/move-file.js"             "$LIBEXEC/"
cp "$SRC_DIR/lib/setup.js"                 "$LIBEXEC/"
cp "$SRC_DIR/dist/cursor-move-file.vsix"   "$LIBEXEC/"

sed "s|%%LIBEXEC%%|$LIBEXEC|g" "$SRC_DIR/bin/cursor-move" > "$BINDIR/cursor-move"
chmod +x "$BINDIR/cursor-move"

info "Installing VS Code extension into Cursor..."
if [ -f "$CURSOR_CLI" ]; then
  "$CURSOR_CLI" --install-extension "$LIBEXEC/cursor-move-file.vsix" || warn "Extension install failed. Run: cursor-move --install-ext"
else
  warn "Cursor CLI not found. After installing Cursor, run: cursor-move --install-ext"
fi

echo ""
info "cursor-move installed successfully!"
echo ""
echo "  Quick start (inside your project):"
echo "    cursor-move --setup           # configure workspace"
echo "    cursor-move src/a.ts src/b.ts # move a file"
echo ""
echo "  Reload Cursor window after first install (Cmd+Shift+P -> Reload Window)"
echo ""
