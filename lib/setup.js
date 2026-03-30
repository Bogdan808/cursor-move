#!/usr/bin/env node

/**
 * cursor-move --setup
 *
 * Ensures the current workspace has the VS Code setting:
 *   typescript.updateImportsOnFileMove.enabled: "always"
 *
 * Without this setting VS Code shows a confirmation dialog on every
 * rename, which blocks automated (agent) use.
 */

const fs = require('fs');
const path = require('path');

const SETTING_KEY = 'typescript.updateImportsOnFileMove.enabled';
const SETTING_VALUE = 'always';

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

const root = findWorkspaceRoot(process.cwd());
const vscodeDir = path.join(root, '.vscode');
const settingsFile = path.join(vscodeDir, 'settings.json');

if (!fs.existsSync(vscodeDir)) {
  fs.mkdirSync(vscodeDir, { recursive: true });
}

let settings = {};
if (fs.existsSync(settingsFile)) {
  try {
    settings = JSON.parse(fs.readFileSync(settingsFile, 'utf8'));
  } catch (err) {
    console.warn(`Warning: could not parse ${settingsFile}: ${err.message}`);
    console.warn('Creating a new settings file.');
    settings = {};
  }
}

if (settings[SETTING_KEY] === SETTING_VALUE) {
  console.warn(`Already configured: ${SETTING_KEY} = "${SETTING_VALUE}"`);
  console.warn(`File: ${settingsFile}`);
  process.exit(0);
}

settings[SETTING_KEY] = SETTING_VALUE;
fs.writeFileSync(settingsFile, JSON.stringify(settings, null, 2) + '\n');

console.warn(`Set: ${SETTING_KEY} = "${SETTING_VALUE}"`);
console.warn(`File: ${settingsFile}`);
console.warn('');
console.warn('Reload your Cursor window to apply (Cmd+Shift+P -> Reload Window).');
