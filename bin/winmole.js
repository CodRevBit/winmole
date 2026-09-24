#!/usr/bin/env node

/**
 * WinMole - Node.js CLI Wrapper & Entrypoint
 * Bridges npm / npx execution to WinMole's native PowerShell core engine.
 */

const { spawn } = require('child_process');
const path = require('path');

const scriptPath = path.join(__dirname, '..', 'winmole.ps1');
const userArgs = process.argv.slice(2);

const powershellArgs = [
  '-NoProfile',
  '-ExecutionPolicy',
  'Bypass',
  '-File',
  scriptPath,
  ...userArgs
];

const child = spawn('powershell.exe', powershellArgs, {
  stdio: 'inherit',
  windowsHide: false
});

child.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
  } else {
    process.exit(code !== null ? code : 0);
  }
});

child.on('error', (err) => {
  console.error(`[winmole] Failed to execute PowerShell core engine: ${err.message}`);
  process.exit(1);
});
