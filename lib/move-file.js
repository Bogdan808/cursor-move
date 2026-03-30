#!/usr/bin/env node

/**
 * cursor-move CLI — queues a file move for the Cursor VS Code extension.
 *
 * The extension watches .cursor/move-queue.json in the workspace root,
 * calls WorkspaceEdit.renameFile(), which lets the TypeScript language
 * server update every import automatically.
 */

const fs = require('fs');
const path = require('path');

const POLL_INTERVAL_MS = 200;
const TIMEOUT_MS = 15000;

function findWorkspaceRoot(startDir) {
  let dir = startDir;
  while (dir !== path.dirname(dir)) {
    if (fs.existsSync(path.join(dir, '.git')) ||
        fs.existsSync(path.join(dir, 'package.json')) ||
        fs.existsSync(path.join(dir, 'tsconfig.json'))) {
      return dir;
    }
    dir = path.dirname(dir);
  }
  return startDir;
}

const [source, destination] = process.argv.slice(2);

if (!source || !destination) {
  console.warn('Usage: cursor-move <source> <destination>');
  console.warn('Paths are relative to the workspace root (or cwd).');
  process.exit(1);
}

const root = findWorkspaceRoot(process.cwd());
const cursorDir = path.join(root, '.cursor');
const queueFile = path.join(cursorDir, 'move-queue.json');
const resultFile = path.join(cursorDir, 'move-result.json');

const srcAbsolute = path.resolve(root, source);
if (!fs.existsSync(srcAbsolute)) {
  console.warn(`Error: source not found: ${source} (resolved to ${srcAbsolute})`);
  process.exit(1);
}

const dstAbsolute = path.resolve(root, destination);
if (fs.existsSync(dstAbsolute)) {
  console.warn(`Error: destination already exists: ${destination}`);
  process.exit(1);
}

if (!fs.existsSync(cursorDir)) {
  fs.mkdirSync(cursorDir, { recursive: true });
}

if (fs.existsSync(resultFile)) {
  fs.unlinkSync(resultFile);
}

const command = { source, destination, requestedAt: Date.now() };
fs.writeFileSync(queueFile, JSON.stringify(command, null, 2));
console.warn(`Queued: ${source} -> ${destination}`);
console.warn('Waiting for Cursor extension...');

const start = Date.now();

const poll = setInterval(() => {
  if (fs.existsSync(resultFile)) {
    let result;
    try {
      result = JSON.parse(fs.readFileSync(resultFile, 'utf8'));
    } catch {
      return;
    }

    if (result.timestamp < command.requestedAt) return;

    clearInterval(poll);

    if (result.success) {
      console.warn(`Moved: ${source} -> ${destination}`);
      console.warn('Imports updated by Cursor TypeScript LS.');
      process.exit(0);
    } else {
      console.warn(`Failed: ${result.error || 'unknown error'}`);
      process.exit(1);
    }
  }

  if (Date.now() - start > TIMEOUT_MS) {
    clearInterval(poll);
    console.warn('Timeout: Cursor extension did not respond within 15 s.');
    console.warn('');
    console.warn('Troubleshooting:');
    console.warn('  1. Is Cursor open with this workspace?');
    console.warn('  2. Run: cursor-move --install-ext');
    console.warn('  3. Reload the Cursor window (Cmd+Shift+P -> Reload Window)');
    process.exit(1);
  }
}, POLL_INTERVAL_MS);
