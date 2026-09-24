# 2. Technical Requirements Document (TRD) — WinMole

> **Project Name:** WinMole (`winmole` / `mo`)  
> **Technical Scope:** Architecture, Dispatcher Model, Execution Runtimes, and Tool Orchestration  
> **Primary Runtime:** PowerShell 5.1 & PowerShell 7.x (Core)  
> **Host Environment:** Windows Terminal / Windows Console Subsystem

---

## 1. System Architecture Overview

WinMole is built using a **Tiered Dispatcher Architecture**:
1. **CLI Shim & Profile Hook Layer**: Provides universal terminal availability (`mo` and `winmole` executable from PowerShell, cmd.exe, and Windows Terminal).
2. **Core Dispatcher & Parameter Router**: Parses subcommands and flags (`--dry-run`, `--force`, `-v`), evaluates execution context, and routes execution.
3. **Dependency Resolver & Self-Healing Engine**: Probes system `$env:PATH` for modern third-party TUI binaries (`btm`, `gdu`, `kondo`). If found, delegates terminal control; if missing, manages auto-installation or triggers Tier 4.
4. **Resilient Native PowerShell Fallback Layer**: 100% self-contained pure PowerShell implementations of status monitoring, disk analysis, directory purging, and cache cleaning with zero external dependencies.

```
+-------------------------------------------------------------------------+
|                         User Input: mo <command>                         |
+-------------------------------------------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                  Core Dispatcher (winmole.ps1 / mo.cmd)                 |
|  - Argument parsing & flag extraction (--dry-run, --force, --help)      |
|  - Elevation (UAC) check & ANSI terminal capability detection           |
+-------------------------------------------------------------------------+
                                     |
         +---------------------------+---------------------------+
         |                                                       |
         v                                                       v
 [Subcommand Specified]                                  [No Subcommand]
 (status, analyze, purge, clean, ...)                            |
         |                                                       v
         |                                           +-----------------------+
         |                                           |  Interactive TUI Menu |
         |                                           |  (Arrow-key selector) |
         |                                           +-----------------------+
         |                                                       |
         +---------------------------+---------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                     Dependency Resolver / Self-Healer                   |
|  - Check: Is Primary Binary in PATH? (e.g. btm, gdu, kondo, winget)      |
+-------------------------------------------------------------------------+
                  |                                     |
           [Binary Present]                      [Binary Missing]
                  |                                     |
                  v                                     v
      +-----------------------+             +-----------------------+
      | Delegate Execution to |             | Prompt User:          |
      | External TUI Binary   |             | 1) Install via winget |
      +-----------------------+             | 2) Run Native Fallback|
                                            +-----------------------+
                                                        |
                                                [Fallback Chosen]
                                                        |
                                                        v
                                            +-----------------------+
                                            | Execute Pure Native   |
                                            | PowerShell Engine     |
                                            +-----------------------+
```

---

## 2. Technology Stack & Execution Strategy

### 2.1 Core Scripting Runtime
- **Primary Language:** PowerShell (PS1).
- **Compatibility Matrix:**
  - **Windows PowerShell 5.1** (Standard built-in on Windows 10/11, .NET Framework 4.8).
  - **PowerShell 7.x** (PowerShell Core, modern cross-platform, .NET 8/9).
- **Compatibility Rules:**
  - Strict backward compatibility: avoid PowerShell 7-only operators (`??`, `||`, `&&`, ternary `?:`) in core dispatcher code, or wrap them in backward-compatible syntax constructs (`if ($a) { $a } else { $b }`).
  - Native .NET Calls: Use `[System.IO.DirectoryInfo]`, `[System.IO.File]`, `[System.Diagnostics.Stopwatch]` for high-performance file operations rather than slow pipeline wrappers.

### 2.2 CLI Shims and Invocation Interfaces
To ensure `mo` and `winmole` work everywhere regardless of how the user opens their terminal:
1. **`mo.cmd` & `winmole.cmd` Shim**: Placed in `~/.winmole/bin` and added to user `$env:PATH`. Invokes `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\winmole.ps1" %*` (or `pwsh.exe` if detected).
2. **PowerShell Module / Profile Export**: Direct PowerShell function definition added to `$PROFILE` for ultra-fast in-process execution without spawning a child PowerShell process.

### 2.3 Modern TUI Binary Integration Matrix

| Subcommand | Primary Binary | Package Identifier | Verification Command | Exit / Handover Protocol |
|---|---|---|---|---|
| `mo status` | `bottom` (`btm.exe`) | `Clement.bottom` | `Get-Command btm` | Pass-through terminal I/O; clean screen restore on exit |
| `mo analyze` | `gdu` (`gdu.exe`) | `gdu` | `Get-Command gdu` | Pass-through args (target path, flags); full terminal TUI |
| `mo purge` | `kondo` (`kondo.exe`) | `cargo install kondo` | `Get-Command kondo` | Pass-through target directory; keyboard-driven purge |
| `mo clean` | Native Engine / BleachBit | `BleachBit.BleachBit` | `Get-Command bleachbit_console` | Native cleaner by default; optional BleachBit delegation |
| `mo uninstall` | `winget.exe` | Native Windows Tool | `Get-Command winget` | Direct argument forwarding to `winget uninstall` |

---

## 3. Subcommand Routing & Module Specifications

### 3.1 Subcommand: `mo status`
- **Execution Flow:**
  1. Test for `btm.exe` in `$env:PATH`. If found, invoke `& btm` directly.
  2. If missing, test for `btop.exe`. If found, invoke `& btop`.
  3. If missing, prompt user:
     - `[1] Install bottom (recommended) via winget`
     - `[2] Run native PowerShell monitor`
     - `[3] Cancel`
  4. Native Fallback Implementation:
     - Uses `Get-CimInstance Win32_Processor`, `Win32_OperatingSystem`, and `Get-Volume`.
     - Displays live ANSI bar graphs with a 1-second refresh loop.
     - Uses `$Host.UI.RawUI.KeyAvailable` to listen for `q` keypress without blocking the render loop.

### 3.2 Subcommand: `mo analyze [path]`
- **Execution Flow:**
  1. Sanitize input `path`. Defaults to current working directory (`Get-Location`).
  2. Test for `gdu.exe` or `dua.exe`. If found, invoke `& gdu $resolvedPath`.
  3. If missing, offer `winget install gdu` or run native fallback.
  4. Native Fallback Implementation:
     - Uses `[System.IO.DirectoryInfo]::new($resolvedPath).EnumerateDirectories()` and calculates size recursively via `.EnumerateFiles('*', [System.IO.SearchOption]::AllDirectories)`.
     - Renders sorted table with formatted size (`GB`, `MB`), item counts, and relative visual bar graph.

### 3.3 Subcommand: `mo purge [path]`
- **Execution Flow:**
  1. Default root: current working directory.
  2. If `kondo` exists in PATH, invoke `& kondo $resolvedPath`.
  3. If missing, test for `npx` and execute `npx npkill` if user prefers.
  4. Native Fallback Implementation:
     - Targets directory names matching:
       `node_modules`, `target`, `.venv`, `venv`, `__pycache__`, `bin`, `obj`, `.next`, `.nuxt`, `dist`, `build`.
     - Scans breadth-first, pruning nested scans inside target directories.
     - Calculates size of each identified directory.
     - Displays itemized summary table and prompts for explicit confirmation (`[y/N]`) before calling `[System.IO.Directory]::Delete($dir, $true)`.

### 3.4 Subcommand: `mo clean [--dry-run] [--all] [--force]`
- **Targets Matrix:**
  - `UserTemp`: `$env:TEMP` (Files older than 24 hours or unlocked files).
  - `SystemTemp`: `C:\Windows\Temp` (requires Administrator privilege).
  - `Prefetch`: `C:\Windows\Prefetch` (requires Administrator privilege).
  - `CrashDumps`: `%LOCALAPPDATA%\CrashDumps`.
  - `PackageCaches`:
    - npm cache (`npm cache clean --force` if npm installed and `--all` specified).
    - pip cache (`pip cache purge` if python/pip installed and `--all` specified).
- **Dry-Run Behavior:**
  - Iterates target files and accumulates count and file byte size.
  - Outputs formatted report:
    `[DRY RUN] Would delete: 1,420 files | Reclaimable space: 3.42 GB`
  - Zero modifications to disk.
- **Error Resiliency:**
  - Every file deletion wrapped in `try / catch [System.IO.IOException], [System.UnauthorizedAccessException]`.
  - Locked files are silently counted under `Skipped (In Use)` rather than terminating execution.

### 3.5 Subcommand: `mo uninstall [query]`
- **Execution Flow:**
  1. Check for `winget.exe`.
  2. If `query` provided: invoke `winget uninstall $query`.
  3. If no query provided: invoke `winget list`, capture installed packages, and present a numbered interactive terminal search list for the user to select and confirm.

---

## 4. Security, Elevation, and Data Safety Policies

### 4.1 Privilege & Elevation Protocol
- WinMole is designed to run in **non-elevated user mode** by default.
- If a subcommand or target (e.g., `C:\Windows\Temp`, `Prefetch`) requires Administrator privileges:
  - Check elevation: `([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)`.
  - If non-elevated: Warn the user and skip protected directories without crashing:
    `[INFO] Skipping C:\Windows\Temp (Requires elevated Administrator prompt).`
  - Offer command to elevate if user explicitly runs `mo clean --all`.

### 4.2 Destruction Prevention Guards
- **Root Protection:** Forbids running `mo purge` or `mo clean` against filesystem roots (`C:\`, `C:\Windows`, `C:\Program Files`, `C:\Users`).
- **Confirmation Default:** Deletions default to `[y/N]` (No is the safe default when pressing Enter).
- **Execution Policy Safety:** Provides clean, signed or user-scoped policy commands (`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`) during installation.

---

## 5. Performance Budgets & Optimization Directives

1. **Lazy Loading:** Subcommand scripts (`Status.ps1`, `Analyze.ps1`, `Purge.ps1`, `Clean.ps1`, `Uninstall.ps1`) are dot-sourced only when their respective command is triggered.
2. **Avoid Pipeline Overhead:** In high-iteration file scanning, avoid `Get-ChildItem | ForEach-Object`. Use fast .NET enumerators:
   ```powershell
   $dirInfo = [System.IO.DirectoryInfo]::new($path)
   foreach ($file in $dirInfo.EnumerateFiles("*", [System.IO.SearchOption]::AllDirectories)) {
       $totalBytes += $file.Length
   }
   ```
3. **VT100 / ANSI Escape Codes:** Use direct ANSI escape sequences (``e[38;2;...m``) for terminal styling instead of repeated `Write-Host -ForegroundColor` calls, reducing render cycle latency by 85%.
