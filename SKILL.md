---
name: FileMoveByCursor
description: Move or rename TS/JS source files via the cursor-move CLI + Cursor extension so WorkspaceEdit.renameFile runs and imports update automatically. Use when refactoring paths, colocating components, or any agent-driven rename where copy-delete-manual-import-edits would break git history or miss references. Requires Cursor open, Node, and cursor-move installed (brew tap Bogdan808/cursor-move). Do not use when Cursor is not running or the workspace is not the active project.
---

# File move via Cursor (cursor-move)

## Problem

- **Wrong:** read → write new path → delete old → hand-edit imports → bad for git and error-prone.
- **Right:** a **real workspace rename** in Cursor so the language service runs **`onWillRenameFiles`** and fixes imports.

**cursor-move** bridges the shell CLI to **`WorkspaceEdit.renameFile()`** through a small extension, using `.cursor/move-queue.json` / `.cursor/move-result.json`.

## When to use

- Moving `.ts`, `.tsx`, `.js`, `.jsx` (or files your TS/JS stack tracks) **inside one repo**.
- Refactors that change **only paths** (folders, barrels, colocation).
- **Any agent** (Cursor, Codex, Claude, …) when the user has **Cursor** open on the project.

## When not to use

- **Cursor not running** or wrong workspace — the queue is never processed.
- **No Node.js** where the CLI runs.
- **Destination path already exists** — resolve first.
- **Cross-repo** moves — use git/project tools instead.

## One-shot prerequisites (agent checklist)

1. **macOS** + Cursor at `/Applications/Cursor.app` (current install target).
2. **Node.js** ≥ 18.
3. Tool installed:

   ```bash
   brew tap Bogdan808/cursor-move
   brew install cursor-move
   ```

4. Extension in Cursor (Homebrew may have done this):

   ```bash
   cursor-move --install-ext
   ```

5. **Per repo** (once):

   ```bash
   cursor-move --setup
   ```

   Then **Reload Window** (**Cmd+Shift+P** → Reload Window).

## Agent workflow

1. Ensure the **correct folder is open in Cursor** and setup was run (`cursor-move --setup` once).
2. **Do not** fake a move with copy/delete + bulk import edits unless the user insists.
3. From a cwd whose tree resolves to the workspace root (`.git` / `package.json` / `tsconfig.json`):

   ```bash
   cursor-move <source> <destination>
   ```

   Paths are **relative to the discovered workspace root**.

4. **Wait** until the CLI exits successfully (it polls `.cursor/move-result.json`).
5. Continue work (tests, commits) using **new paths**.

### Examples

```bash
cursor-move components/Button.tsx components/ui/Button.tsx
cursor-move src/utils/api.ts src/services/api.ts
```

## Operational model

```
CLI → .cursor/move-queue.json
  → extension → WorkspaceEdit.renameFile(src, dst)
  → language service updates imports
  → .cursor/move-result.json
  → CLI exits
```

If the CLI **times out**, do not spam retries — check Cursor focus, extension, and workspace root.

## Commands

| Command | Purpose |
| ------- | ------- |
| `cursor-move <src> <dst>` | Rename with automatic import updates |
| `cursor-move --setup` | Add VS Code setting so renames are not blocked by prompts |
| `cursor-move --install-ext` | Install VSIX into Cursor |
| `cursor-move --help` | Help |

## Anti-patterns

- Manual import patching after a fake move.
- Running `cursor-move` with Cursor closed.
- Assuming the agent can rename files “inside the model” without the **local CLI + Cursor**.

## Upstream

- Repo: `https://github.com/Bogdan808/cursor-move`
- Install / publish: `README.md`
