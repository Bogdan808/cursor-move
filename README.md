# cursor-move

Move files in **Cursor IDE** with automatic import updates — built for AI agents.

When an AI agent needs to move a file, it typically reads the file, writes it to a
new location, deletes the old file, and then manually rewrites every import. This
breaks git history (delete + create instead of rename) and is error-prone.

**cursor-move** solves this by calling Cursor's internal
`WorkspaceEdit.renameFile()` API through a lightweight VS Code extension. The
TypeScript language server then updates every import automatically.

## For AI agents (Cursor, Codex, Claude, …)

If you are an **agent** or you maintain agent instructions, use the standalone skill doc **[FileMoveByCursor.md](./FileMoveByCursor.md)** — when to use `cursor-move`, prerequisites, workflow, and anti-patterns. Point tools or rules at that file so every assistant follows the same rename flow.

## Install

### Homebrew (recommended)

```bash
brew tap Bogdan808/cursor-move
brew install cursor-move
```

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/Bogdan808/cursor-move/main/install.sh | bash
```

### From source

```bash
git clone https://github.com/Bogdan808/cursor-move.git
cd cursor-move
make build install install-ext
```

## Setup

Run this once inside each project:

```bash
cursor-move --setup
```

This adds `"typescript.updateImportsOnFileMove.enabled": "always"` to
`.vscode/settings.json`. Without it, Cursor shows a confirmation dialog on
every rename, which blocks automated use.

Then reload the Cursor window: **Cmd+Shift+P** → *Reload Window*.

## Usage

```bash
cursor-move <source> <destination>
```

Paths are relative to the workspace root.

### Examples

```bash
cursor-move components/Button.tsx components/ui/Button.tsx
cursor-move src/utils/api.ts src/services/api.ts
cursor-move hooks/useAuth.ts hooks/auth/useAuth.ts
```

### All commands

| Command                      | Description                              |
| ---------------------------- | ---------------------------------------- |
| `cursor-move src dst`        | Move a file, imports update automatically |
| `cursor-move --setup`        | Add required VS Code setting             |
| `cursor-move --install-ext`  | Install the VS Code extension            |
| `cursor-move --help`         | Show help                                |

## How it works

```
Agent calls:  cursor-move src dst
                    │
                    ▼
          scripts writes to .cursor/move-queue.json
                    │
                    ▼
        VS Code extension detects the file change
                    │
                    ▼
    WorkspaceEdit.renameFile(src, dst) is applied
                    │
                    ▼
      TypeScript LS fires onWillRenameFiles
        and updates all imports automatically
                    │
                    ▼
      Extension writes result to .cursor/move-result.json
                    │
                    ▼
         CLI reads result and exits
```

## Uninstall

```bash
# Homebrew
brew uninstall cursor-move

# Manual
make uninstall
```

## Requirements

- **macOS** (Cursor is macOS/Linux/Windows, but this tool targets Mac via Homebrew)
- **Node.js** >= 18
- **Cursor IDE** installed in `/Applications/Cursor.app`

## Publish to GitHub (maintainer)

Creates `Bogdan808/cursor-move` and `Bogdan808/homebrew-cursor-move`, pushes tag `v0.1.0`, and fills in the formula `sha256`.

```bash
brew install gh   # if needed
gh auth login
./scripts/publish.sh
```

## License

MIT
