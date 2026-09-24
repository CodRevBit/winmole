# WinMole (mo) 🐾

> **Unified Windows Terminal Maintenance & Monitoring Toolkit**  
> Inspired by macOS [Mole](https://github.com/tw93/Mole) (`tw93/Mole`), reimagined for Windows Terminal, PowerShell 5.1, and PowerShell 7+.

[![Tests](https://img.shields.io/badge/Pester%20Tests-11%20Passed-brightgreen)](file:///C:/Projects/winmole/tests/WinMole.Tests.ps1)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-blue)]()
[![Shell](https://img.shields.io/badge/Shell-PowerShell%205.1%2B%20%7C%20CMD-purple)]()

---

## Overview

**WinMole** (`mo` / `winmole`) is a fast, keyboard-driven terminal utility that unifies system monitoring, disk space exploration, build artifact purging, temporary file cleaning, and application uninstallation into a single, cohesive command-line interface.

Instead of heavy electron apps or slow graphic interfaces, WinMole executes **100% inside your terminal**. It delegates to high-performance CLI/TUI tools (`bottom`, `gdu`, `kondo`, `winget`) when available, while providing seamless, zero-dependency native PowerShell fallbacks when external tools are absent.

---

## Quick Installation

Run the 1-click installer from an elevated or standard PowerShell terminal:

```powershell
.\install.ps1
```

The installer will:
1. Copy WinMole to `~/.winmole`
2. Add `~/.winmole/bin` to your User `PATH` (enabling `mo` and `winmole` in CMD and PowerShell)
3. Register CLI function hooks inside your PowerShell `$PROFILE`
4. Ensure your `ExecutionPolicy` allows local scripts

To remove WinMole:
```powershell
.\uninstall.ps1
```

---

## Command Reference

Run `winmole` without arguments to launch the **Interactive Terminal Menu**, or use direct subcommands:

```
  USAGE:
    winmole [command] [options]

  COMMANDS:
    status               Live system monitor (CPU, RAM, Disk, Procs) [bottom/btop]
    analyze [path]       Interactive disk usage visualizer [gdu/dua]
    purge   [path]       Developer build artifact cleaner (node_modules, target, .venv)
    clean                System temp, crash dump, and cache cleaner
    uninstall [app]      Interactive package and application uninstaller [winget]
    doctor               System and external tool health diagnostic report
    (none)               Launch interactive keyboard-navigable terminal menu

  OPTIONS:
    --dry-run, WhatIf    Preview files and reclaimed space without modifying anything
    --force, -f          Bypass confirmation prompts for automated/CI runs
    --all, -a            Include optional deep clean targets (clean command)
    --native             Force built-in pure PowerShell engine (bypass external tools)
    -h, --help           Display help manual
    -v, --version        Display WinMole version information
```

### Examples

```powershell
# Open interactive keyboard-navigable menu
winmole

# Launch system performance monitor
winmole status

# Analyze disk space usage in current or target folder
winmole analyze C:\Projects

# Scan for dev build junk (node_modules, target, etc.) in dry-run mode
winmole purge --dry-run

# Purge developer artifacts in a specific project without prompt
winmole purge C:\Projects\my-app -f

# Clean temp files and error crash dumps safely
winmole clean

# Run environment and tool diagnostics
winmole doctor
```

---

## Safety Guarantees

1. **Root Directory Protection**: Subcommands (`purge`, `clean`) strictly refuse execution on critical system roots (`C:\`, `C:\Windows`, `C:\Program Files`, `C:\Users`).
2. **Dry-Run Mode First**: Every destructive subcommand supports `--dry-run` to preview exact paths and file sizes before anything is modified.
3. **Audit Logging**: All purge and clean actions append structured JSONL records to `~/.winmole/history.jsonl` for full traceability.
4. **Zero Forced Dependencies**: If tools like `bottom` or `gdu` are not installed, WinMole prompts for 1-click winget install or runs pure native PowerShell engines with zero errors.

---

## Architecture & Design Documents

WinMole was engineered following mikenwo.ai's 6-document pre-vibecoding architecture:

| Document | Purpose |
|---|---|
| [`01_PRD.md`](file:///C:/Projects/winmole/01_PRD.md) | Product Requirements Document: user personas, requirements & safety matrix |
| [`02_TRD.md`](file:///C:/Projects/winmole/02_TRD.md) | Technical Requirements Document: runtime architecture, dispatcher & tool matrix |
| [`03_APPFLOW.md`](file:///C:/Projects/winmole/03_APPFLOW.md) | Appflow & Interactive Navigation Map (Mermaid diagrams) |
| [`04_UI_UX_DESIGN.md`](file:///C:/Projects/winmole/04_UI_UX_DESIGN.md) | Terminal UI/UX Design Brief & ANSI palette specification |
| [`05_BACKEND_SCHEMA.md`](file:///C:/Projects/winmole/05_BACKEND_SCHEMA.md) | Local Schema, Config Specs & ER Model |
| [`06_IMPLEMENTATION_PLAN.md`](file:///C:/Projects/winmole/06_IMPLEMENTATION_PLAN.md) | 6-Phase Sequential Implementation Plan & QA Exit Gates |

---

## Running the Automated Test Suite

WinMole includes a Pester unit test suite:

```powershell
Invoke-Pester .\tests\WinMole.Tests.ps1
```

All 11 tests verify:
- Default configuration schema loading & paths
- Root directory deletion protection
- Dependency resolver detection & fallbacks
- `--dry-run` zero-deletion guarantee
- Deletion execution on allowed target paths
- CLI entrypoint version and help routing
