<div align="center">

# WinMole 🐾

_Clean, purge, analyze, and monitor your Windows PC — 100% inside your terminal._

[![Latest Release](https://img.shields.io/github/v/release/CodRevBit/winmole?style=flat-square&color=blue)](https://github.com/CodRevBit/winmole/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6?style=flat-square&logo=windows&logoColor=white)](https://github.com/CodRevBit/winmole)
[![Shell](https://img.shields.io/badge/Shell-PowerShell%205.1%2B%20%7C%20PWSH%207%2B-5391FE?style=flat-square&logo=powershell&logoColor=white)](https://github.com/CodRevBit/winmole)
[![Tests](https://img.shields.io/badge/Pester%20Tests-11%20Passed-brightgreen?style=flat-square)](tests/WinMole.Tests.ps1)
[![uv tool](https://img.shields.io/badge/uv-supported-DE5FE9?style=flat-square&logo=python&logoColor=white)](https://github.com/astral-sh/uv)
[![npm](https://img.shields.io/badge/npm-supported-CB3837?style=flat-square&logo=npm&logoColor=white)](https://www.npmjs.com/)

<br>

Inspired by macOS [Mole](https://github.com/tw93/Mole) (`tw93/Mole`), **WinMole** is a unified, lightning-fast Windows terminal maintenance and system monitoring toolkit. It brings clean, keyboard-driven system maintenance, developer artifact purging, interactive disk visualization, and live hardware monitoring into one cohesive command-line experience.

<br>

[Quick Start](#quick-start) · [Installation](#installation) · [Features](#features) · [Commands](#command-reference) · [Architecture](#system-architecture) · [Safety](#safety-guarantees) · [Testing](#running-tests)

</div>

---

```text
  WINMOLE DASHBOARD • v1.0.0
  Unified Windows Terminal Maintenance Toolkit
  ─────────────────────────────────────────────────────────────

  CPU: 14% [====                ]  RAM: 58% [==========        ]
  Disk C:\: 68% [============    ] 142 GB free

╭── Select an Action ───────────────────────────────────────────╮
│  [1]  Status       Live system hardware monitor               │
│  [2]  Analyze      Explore disk space usage                   │
│  [3]  Purge        Clean project build artifacts              │
│  [4]  Clean        Remove temporary files and crash dumps     │
│  [5]  Uninstall    Search & remove installed applications     │
│  [6]  Doctor       Run environment health check               │
│  [0]  Exit         Close WinMole                              │
╰───────────────────────────────────────────────────────────────╯

  Tip: Run 'winmole <command>' directly from any shell (e.g. 'winmole clean')
```

---

## Features

- **🐾 All-In-One Terminal Hub**: Eliminates fragmented utilities, bloated Electron cleaners, and slow GUI tools. Everything runs **100% inside your terminal**.
- **🧹 Deep Temporary Cleaner**: Safely inspects and clears user `%TEMP%`, Windows error crash dumps, system temp, and prefetch caches with single-millisecond overhead.
- **⚡ Developer Build Artifact Purger**: Recursively scans and reclaims gigabytes wasted by forgotten `node_modules`, `target`, `.venv`, `bin/obj`, and web build caches.
- **📊 Live Hardware Dashboard**: High-refresh system resource visualizer for CPU cores, RAM distribution, disk I/O, and top processes.
- **💾 Interactive Disk Explorer**: Rapidly profiles storage consumption with proportional size bars to pinpoint disk hogs.
- **🛡️ Self-Healing & Zero Forced Dependencies**: Integrates with best-in-class tools (`bottom`, `gdu`, `kondo`, `winget`) when available, and automatically falls back to built-in pure PowerShell engines when they are absent.
- **🔒 Dry-Run Simulation First**: Every destructive command supports `--dry-run` to preview eligible paths and bytes before any file is touched.

---

## Installation

Choose your preferred package manager or installer:

### Method 1: 1-Line PowerShell Web Installer (Recommended)

Run directly from any standard or Administrator PowerShell prompt:

```powershell
irm https://raw.githubusercontent.com/CodRevBit/winmole/master/install.ps1 | iex
```

### Method 2: Install via `uv` / `uvx` (Python)

If you use [uv](https://github.com/astral-sh/uv), you can run WinMole immediately without manual installation:

```bash
# Instant execution:
uvx --from git+https://github.com/CodRevBit/winmole.git winmole

# Permanent tool installation:
uv tool install git+https://github.com/CodRevBit/winmole.git
```

### Method 3: Install via `npm` / `npx` (Node.js)

```bash
# Instant execution via npx:
npx winmole

# Permanent global install:
npm install -g winmole
```

### Method 4: Clone & Local Install

```powershell
git clone https://github.com/CodRevBit/winmole.git
cd winmole
.\install.ps1
```

> **Uninstallation:** To completely remove WinMole at any time, run `.\uninstall.ps1` or run `winmole uninstall`.

---

## Quick Start

Launch the interactive dashboard:

```powershell
winmole
```

Or invoke subcommands directly:

```powershell
winmole status                 # Launch live hardware monitor
winmole analyze C:\Projects    # Explore disk usage in target folder
winmole purge --dry-run        # Preview project junk without deleting
winmole purge                  # Reclaim space from node_modules, target, .venv
winmole clean                  # Clean %TEMP% and crash dumps
winmole uninstall vlc          # Search and uninstall app via winget
winmole doctor                 # Check tool availability and system health
```

---

## Features in Detail

### 1. `winmole clean` — Temporary Files & Cache Cleaner

Cleans safe Windows temporary storage, error crash dumps, and system caches. Supports `--dry-run` for safe previewing and `--all` for deep system caches.

```text
  WINMOLE CLEAN • Cache & Temp Cleaner [DRY RUN]
  ─────────────────────────────────────────────────────────────

╭── Cleanup Summary ────────────────────────────────────────────╮
│ Status: Simulation / Dry-Run (No files touched)               │
│ Eligible Files Found: 733 files • Time: 414 ms                │
│ Total Reclaimable Space: 81.6 MB                              │
╰───────────────────────────────────────────────────────────────╯

  Target Category                        Files        Reclaimable Size
  ─────────────────────────────────────────────────────────────────
  User Temporary Files (%TEMP%)         724          16.4 MB
  Windows Error Crash Dumps             9            65.2 MB
  Windows System Temp                   Skipped      Requires Administrator shell

[i] [DRY RUN PREVIEW] Zero files were deleted. Re-run without --dry-run to perform cleanup.
```

### 2. `winmole purge` — Developer Build Artifact Cleaner

Recursively discovers heavy developer dependencies and build caches across multiple language ecosystems (`node_modules`, `target/`, `.venv/`, `bin/obj/`, `.next/`).

```text
  WINMOLE PURGE • Build Artifact Cleaner [DRY RUN]
  ─────────────────────────────────────────────────────────────
[i] Scanning for build artifacts in: C:\Projects...

╭── Artifacts Detected ─────────────────────────────────────────╮
│ Target Root: C:\Projects                                      │
│ Found: 3 artifact directories • Scan Time: 86 ms              │
│ Total Reclaimable Space: 1.44 GB                              │
╰───────────────────────────────────────────────────────────────╯

  Artifact Path                                      Type         Size
  ─────────────────────────────────────────────────────────────────
  C:\Projects\web-frontend\node_modules             Node.js      842.1 MB
  C:\Projects\core-engine\target                    Rust/Cargo   412.0 MB
  C:\Projects\ai-service\.venv                      Python       189.5 MB

[i] [DRY RUN PREVIEW] No files were deleted. Re-run without --dry-run to delete.
```

### 3. `winmole doctor` — Diagnostic & Integration Matrix

Inspects your terminal capabilities, execution policies, UAC privilege levels, and probes for installed high-performance TUI tools.

```text
  WINMOLE DOCTOR • Environment & Tool Diagnostics
  ─────────────────────────────────────────────────────────────

[i] Running system integrity and tool availability scan...

╭── Environment Overview ─────────────────────────────────────────╮
│ PowerShell Version : 5.1.26100.9549 (Desktop)                   │
│ Operating System   : Microsoft Windows 11 Home (Build 26200)    │
│ Architecture       : 64-bit                                     │
│ Terminal Host      : Windows Terminal / ConsoleHost             │
│ ANSI TrueColor     : Supported [OK]                             │
│ Privilege Level    : Standard User (Non-Elevated)               │
│ Execution Policy   : RemoteSigned                               │
╰───────────────────────────────────────────────────────────────╯
╭── Tool Integration Matrix ──────────────────────────────────────╮
│ Tool Name            Role                        Status         │
│ ───────────────────────────────────────────────────────────────── │
│ bottom (btm)         Primary System Monitor      ✔ Installed    │
│ gdu                  Primary Disk Visualizer     ✔ Installed    │
│ kondo                Primary Artifact Purger     ✔ Installed    │
│ winget               Package Manager             ✔ Installed    │
╰─────────────────────────────────────────────────────────────────╯
╭── WinMole Configuration State ──────────────────────────────────╮
│ Configuration : Found (C:\Users\<user>\.winmole\config.json)    │
│ Target Rules  : Found (C:\Users\<user>\.winmole\targets.json)   │
│ Audit Log     : Found (C:\Users\<user>\.winmole\history.jsonl)  │
╰─────────────────────────────────────────────────────────────────╯

✔ Diagnostics complete! All core subcommands have operational engines.
```

---

## System Architecture

After installation, WinMole lives entirely inside your user directory at `~/.winmole` (`C:\Users\<user>\.winmole`). It operates as a self-contained, modular toolkit with instant startup (< 80ms), zero background services, zero telemetry, and zero mandatory external dependencies.

### 1. Installed Layout & System Wiring

When you install WinMole (via the 1-line PowerShell installer, `npm`, or `uv`), it creates a clean, isolated footprint in your home directory and hooks into your terminal environment:

```
~/.winmole/                          # WinMole Root Installation Directory
├── bin/                             # Added to User PATH environment variable
│   ├── winmole.cmd                  # Global CMD / terminal shim
│   └── mo.cmd                       # Short alias shim ('mo <command>')
├── winmole.ps1                      # Central execution dispatcher
├── config.json                      # User preferences & threshold configurations
├── targets.json                     # Search patterns for artifact and cache cleaning
├── history.jsonl                    # Immutable JSON Lines audit log
└── src/
    ├── Core/
    │   ├── Config.ps1               # State manager & schema initializer
    │   ├── DependencyResolver.ps1   # Probes PATH for external TUI tools
    │   ├── Menu.ps1                 # Interactive arrow-key console menu
    │   └── UI.ps1                   # VT100 / ANSI TrueColor rendering engine
    └── Commands/
        ├── Status.ps1               # Live hardware monitor (CPU, RAM, Disk)
        ├── Analyze.ps1              # Interactive disk usage explorer
        ├── Purge.ps1                # Developer build artifact cleaner
        ├── Clean.ps1                # System & user temp cache cleaner
        ├── Uninstall.ps1            # App uninstaller wrapper via winget
        └── Doctor.ps1               # Environment & diagnostic matrix
```

#### Shell Integration

- **PowerShell `$PROFILE` Hook**: WinMole adds lightweight in-process functions (`winmole` and `mo`) directly to your PowerShell profile. When invoked, it calls `~/.winmole/winmole.ps1` in-process with sub-millisecond execution overhead.
- **User `PATH`**: The `~/.winmole/bin` directory is added to your User `PATH`, making `winmole` and `mo` accessible from any shell (CMD, Windows Terminal, Git Bash, Nushell).

---

### 2. Internal Execution Architecture

When you type `winmole` (or `mo`), the internal modules inside `~/.winmole` coordinate across four core layers:

```
                      User types: 'winmole [command]'
                                     │
         ┌───────────────┬───────────┴───┬───────────────┬──────────────┐
         ▼               ▼               ▼               ▼              ▼
  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌────────────┐ ┌────────────┐
  │   Status    │ │   Analyze   │ │    Purge    │ │   Clean    │ │  Doctor    │
  ├─────────────┤ ├─────────────┤ ├─────────────┤ ├────────────┤ ├────────────┤
  │ bottom/btm  │ │ gdu/dua-cli │ │    kondo    │ │ Built-in   │ │ Health &   │
  │     OR      │ │     OR      │ │     OR      │ │ Multi-Temp │ │ System     │
  │ CIM Poller  │ │ .NET Engine │ │ Native Scan │ │ Cleaner    │ │ Diagnostic │
  └─────────────┘ └─────────────┘ └─────────────┘ └────────────┘ └────────────┘
         │               │               │               │              │
         └───────────────┴───────────────┼───────────────┴──────────────┘
                                         ▼
                         ┌───────────────────────────────┐
                         │   src/Core/UI & Menu Engine   │
                         │   • VT100 / ANSI TrueColor    │
                         │   • Arrow-key interactive TUI │
                         │   • Formatted summary tables  │
                         └───────────────────────────────┘
```

---

### 3. How It Works Inside After Installation

Here is the exact internal sequence executed inside `~/.winmole` whenever a command is run:

1. **Dispatcher Routing (`winmole.ps1`)**:
   - The central entrypoint normalizes passed arguments and flags (`--dry-run`, `--all`, `--non-interactive`).
   - If invoked with no arguments, it routes immediately to the interactive dashboard (`src/Core/Menu.ps1`).
   - If invoked with a subcommand (e.g. `winmole clean`), it loads only the required command module from `src/Commands/` to guarantee sub-millisecond execution.
2. **State & Profile Hydration (`src/Core/Config.ps1`)**:
   - WinMole reads your configuration from `~/.winmole/config.json` (thresholds, default dry-run preference) and target patterns from `targets.json`.
   - Missing files are auto-generated from internal default schemas without crashing or requiring manual setup.
3. **Dynamic Dependency Resolution (`src/Core/DependencyResolver.ps1`)**:
   - For subcommands that benefit from dedicated TUI performance (`status`, `analyze`, `purge`, `uninstall`), WinMole probes the system `PATH`:
     - **External tool detected**: If `bottom`, `gdu`, `kondo`, or `winget` is present, WinMole delegates directly to the binary for peak speed.
     - **External tool absent**: WinMole automatically and silently activates its built-in native PowerShell/.NET fallback engine. There are no mandatory downloads or broken commands.
4. **Safety & Guardrail Gate**:
   - Before executing file operations, paths are validated against protected system root directories (`C:\`, `C:\Windows`, `C:\Program Files`, `C:\Users`).
   - If `--dry-run` is active, the engine scans and calculates recoverable bytes without modifying or deleting any files on disk.
   - Every completed operation appends a structured record (timestamp, duration, reclaimed bytes, errors) to `~/.winmole/history.jsonl`.
5. **Terminal UI Rendering (`src/Core/UI.ps1`)**:
   - Renders output using standard VT100 ANSI escape sequences, rounded Unicode borders, and TrueColor gradients. It automatically degrades gracefully to 16-color ANSI on legacy console hosts.

---

### 4. Subsystem Reference

| Subsystem File          | Location Inside `~/.winmole/`     | Internal Role & Functionality                                                                     |
| :---------------------- | :-------------------------------- | :------------------------------------------------------------------------------------------------ |
| **Dispatcher**          | `winmole.ps1`                     | Central entrypoint; parses parameters, sets output encoding, and dispatches tasks.                |
| **Config Engine**       | `src/Core/Config.ps1`             | Loads, saves, and updates `config.json`, `targets.json`, and records to `history.jsonl`.          |
| **Dependency Resolver** | `src/Core/DependencyResolver.ps1` | PATH detection for external binaries (`btm`, `gdu`, `kondo`, `winget`) and fallback routing.      |
| **UI Engine**           | `src/Core/UI.ps1`                 | ANSI TrueColor rendering, rounded card frames, progress bars, and formatted status badges.        |
| **Menu Engine**         | `src/Core/Menu.ps1`               | Interactive, flicker-free terminal dashboard with arrow-key navigation and live hardware metrics. |
| **Command Modules**     | `src/Commands/*.ps1`              | Dedicated implementations for `Status`, `Analyze`, `Purge`, `Clean`, `Uninstall`, and `Doctor`.   |

---

## Tool Integration & Fallback Matrix

WinMole seamlessly bridges external high-performance binaries with zero-dependency native PowerShell fallbacks:

| Command             | Action                    | Primary Binary            | Automatic Install               | Built-In Native Fallback                                                |
| :------------------ | :------------------------ | :------------------------ | :------------------------------ | :---------------------------------------------------------------------- |
| `winmole`           | Interactive Dashboard     | Built-in                  | None (Native)                   | Arrow-key ANSI terminal menu (ESC to fall back / exit)                  |
| `winmole status`    | Live Hardware Monitor     | `bottom` (`btm`) / `btop` | `winget install Clement.bottom` | Live polling loop (`Win32_Processor`, `Win32_OperatingSystem`)          |
| `winmole analyze`   | Interactive Disk Explorer | `gdu` / `dua-cli`         | `winget install gdu`            | High-performance .NET directory size profiler                           |
| `winmole purge`     | Build Artifact Cleaner    | `kondo`                   | `cargo install kondo`           | Pure recursive scanner for `node_modules`, `target`, `.venv`, `bin/obj` |
| `winmole clean`     | Temp & Cache Cleaner      | Curated Cleaner           | None (Built-in)                 | Multi-target scanner for `%TEMP%`, crash dumps, system temp             |
| `winmole uninstall` | Package Uninstaller       | `winget`                  | Windows 10/11 built-in          | Filtered search & uninstall wrapper                                     |
| `winmole doctor`    | Health & Tool Check       | Diagnostic Engine         | None (Built-in)                 | Environment overview, ANSI test, and tool matrix                        |

---

## Safety Guarantees

1. **Root Directory Protection**: Subcommands strictly prohibit execution on critical system drives or root paths (`C:\`, `C:\Windows`, `C:\Program Files`, `C:\Users`).
2. **Dry-Run Simulation**: Destructive actions support `--dry-run` to preview exact files, directories, and reclaimed byte totals without deleting anything.
3. **Structured Audit Trail**: Every file deletion is recorded to `~/.winmole/history.jsonl` with timestamps, duration, freed bytes, and error counts for accountability.
4. **Elevation-Aware**: System directories (such as `C:\Windows\Temp`) are safely skipped with a helpful notice unless running from an elevated Administrator prompt.

---

## Command Reference

```text
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
    --dry-run, WhatIf    Preview files and space without making modifications
    --force, -f          Bypass confirmation prompts for automated/CI runs
    --all, -a            Include optional deep clean targets (clean command)
    --native             Force built-in pure PowerShell engine (skip external tools)
    -h, --help           Display this help manual
    -v, --version        Display WinMole version information
```

---

## Running Tests

WinMole comes with a comprehensive [Pester](https://github.com/pester/Pester) automated test suite:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Pester .\tests\WinMole.Tests.ps1"
```

All 13 unit tests verify:

- Configuration schema loading and path defaults
- Root directory deletion protection guards
- Dependency resolver detection and native fallback routing
- Interactive menu rendering and ESC key fallback navigation
- `--dry-run` simulation guarantees (zero file deletions)
- Targeted build artifact purging and directory cleanup
- CLI parameter routing, versioning, and help dispatching

---

## License

MIT © [AKSniperNinja](LICENSE) (CodRevBit)
