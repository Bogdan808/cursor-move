const vscode = require('vscode');
const fs = require('fs');
const path = require('path');

const QUEUE_FILENAME = 'move-queue.json';
const RESULT_FILENAME = 'move-result.json';

function activate(context) {
  const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!workspaceRoot) return;

  const cursorDir = path.join(workspaceRoot, '.cursor');
  const queueFile = path.join(cursorDir, QUEUE_FILENAME);
  const resultFile = path.join(cursorDir, RESULT_FILENAME);

  if (!fs.existsSync(cursorDir)) {
    fs.mkdirSync(cursorDir, { recursive: true });
  }

  let processing = false;

  const watcher = vscode.workspace.createFileSystemWatcher(
    new vscode.RelativePattern(cursorDir, QUEUE_FILENAME)
  );

  async function handleQueue() {
    if (processing) return;
    processing = true;

    try {
      if (!fs.existsSync(queueFile)) return;

      const raw = fs.readFileSync(queueFile, 'utf8');
      const { source, destination } = JSON.parse(raw);

      if (!source || !destination) {
        writeResult(resultFile, false, source, destination, 'Missing source or destination');
        return;
      }

      const srcUri = vscode.Uri.file(path.resolve(workspaceRoot, source));
      const dstUri = vscode.Uri.file(path.resolve(workspaceRoot, destination));

      if (!fs.existsSync(srcUri.fsPath)) {
        writeResult(resultFile, false, source, destination, `Source not found: ${source}`);
        return;
      }

      const dstDir = path.dirname(dstUri.fsPath);
      if (!fs.existsSync(dstDir)) {
        fs.mkdirSync(dstDir, { recursive: true });
      }

      const edit = new vscode.WorkspaceEdit();
      edit.renameFile(srcUri, dstUri);
      const success = await vscode.workspace.applyEdit(edit);

      if (success) {
        await vscode.workspace.saveAll(false);
      }

      writeResult(resultFile, success, source, destination,
        success ? null : 'WorkspaceEdit.applyEdit returned false');
    } catch (err) {
      writeResult(resultFile, false, null, null, err.message);
    } finally {
      processing = false;
    }
  }

  watcher.onDidChange(handleQueue);
  watcher.onDidCreate(handleQueue);

  const cmd = vscode.commands.registerCommand('cursorMove.moveFile', async (src, dst) => {
    if (src && dst) {
      fs.writeFileSync(queueFile, JSON.stringify({ source: src, destination: dst }));
      await handleQueue();
    } else {
      const srcInput = await vscode.window.showInputBox({
        prompt: 'Source path (relative to workspace root)',
      });
      if (!srcInput) return;
      const dstInput = await vscode.window.showInputBox({
        prompt: 'Destination path (relative to workspace root)',
      });
      if (!dstInput) return;
      fs.writeFileSync(queueFile, JSON.stringify({ source: srcInput, destination: dstInput }));
      await handleQueue();
    }
  });

  context.subscriptions.push(watcher, cmd);
}

function writeResult(resultFile, success, source, destination, error) {
  const payload = {
    success,
    source,
    destination,
    error: error || null,
    timestamp: Date.now(),
  };
  fs.writeFileSync(resultFile, JSON.stringify(payload, null, 2));
}

function deactivate() {}

module.exports = { activate, deactivate };
