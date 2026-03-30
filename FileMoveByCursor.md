# Skill: move TypeScript/JavaScript files via Cursor (cursor-move)

Use this skill when an **AI coding agent** (Cursor Agent, Claude Code, Codex CLI, or similar) must **rename or relocate** a source file in a project and **keep imports correct** without manual search-and-replace.

## Problem this solves

- **Wrong approach:** read file → write to new path → delete old file → hand-edit imports. That **breaks git history** (delete + add instead of rename) and is **error-prone**.
- **Right approach:** trigger a **real workspace rename** inside **Cursor** so the TypeScript/JavaScript language service runs **`onWillRenameFiles`** and updates imports.

**cursor-move** connects a shell CLI to Cursor’s **`WorkspaceEdit.renameFile()`** API through a tiny VS Code extension, using a queue file under `.cursor/`.

## When to use

- Moving `.ts`, `.tsx`, `.js`, `.jsx` (or other files your TS/JS tooling tracks) **within the same repo**.
- Refactors that **only change paths** (feature folders, barrel files, colocation).
- **Agent-driven** batch moves where the user has **Cursor open** on the project.

## When not to use

- **Cursor is not running** or the workspace is not open — the extension will not process the queue.
- **No Node.js** on the machine running the CLI.
- **Destination already exists** — fix manually first.
- **Cross-repo** or **generated-only** files with no language service — prefer normal git moves or project-specific tools.

## Prerequisites (once per machine)

1. **macOS** with **Cursor** in `/Applications/Cursor.app` (current packaging target).
2. **Node.js** ≥ 18.
3. **Install the tool** (Homebrew recommended):

   ```bash
   brew tap Bogdan808/cursor-move
   brew install cursor-move
   ```

4. **Install the extension into Cursor** (Homebrew `post_install` tries this; otherwise):

   ```bash
   cursor-move --install-ext
   ```

5. **Per project**, enable automatic import updates on rename:

   ```bash
   cursor-move --setup
   ```

   Then **Reload Window** in Cursor (**Cmd+Shift+P** → Reload Window).

## Agent workflow (all assistants)

1. **Confirm** the user has the repo opened in **Cursor** and has run **`cursor-move --setup`** once (or offer to run it).
2. **Do not** simulate a move by copy/delete + import edits unless the user explicitly wants that.
3. From the **project root** (or a cwd that still resolves to the workspace root via `.git` / `package.json` / `tsconfig.json`):

   ```bash
   cursor-move <source> <destination>
   ```

   Paths are **relative to the workspace root** the tool discovers.

4. **Wait for the command to exit successfully** — the CLI polls `.cursor/move-result.json` after the extension performs the rename.
5. **Continue** with the rest of the task (tests, commits) using the **new paths**.

### Examples

```bash
cursor-move components/Button.tsx components/ui/Button.tsx
cursor-move src/utils/api.ts src/services/api.ts
```

## Operational model (for agent reasoning)

```
CLI writes .cursor/move-queue.json
    → Extension in Cursor reads it
    → WorkspaceEdit.renameFile(source, destination)
    → Language service updates imports
    → Extension writes .cursor/move-result.json
    → CLI exits
```

If the CLI **times out**, Cursor may be busy, the extension inactive, or the workspace path wrong — **do not** blindly retry in a loop; check Cursor is focused on the correct folder.

## Commands reference

| Command | Role |
| ------- | ---- |
| `cursor-move <src> <dst>` | Perform the rename with import updates |
| `cursor-move --setup` | Write `.vscode/settings.json` so renames do not block on prompts |
| `cursor-move --install-ext` | Install the VSIX into Cursor |
| `cursor-move --help` | Help text |

## Anti-patterns

- **Patching every import by hand** after a “fake” move — defeats the tool and risks missed references.
- **Running `cursor-move` without Cursor open** — queue will not be processed.
- **Assuming Codex/Claude “natively” knows the workspace** — they still need the **local CLI + Cursor** on the user’s machine for this flow.

## Upstream

- Repository: `https://github.com/Bogdan808/cursor-move`
- Install and maintainer notes: see `README.md`

## License

Same as the project (MIT).
