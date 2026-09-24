# 1. Product Requirements Document (PRD) — WinMole

> **Project Name:** WinMole (`winmole` / `mo`)  
> **Product Category:** Developer & Power-User Terminal System Manager  
> **Target Platform:** Windows 10 / Windows 11 (Windows Terminal, PowerShell 5.1, PowerShell 7+)  
> **Inspiration:** tw93/Mole (macOS CLI toolkit)

---

## 1. Executive Summary & Problem Statement

### 1.1 The Problem
Power users and software developers on Windows regularly perform routine system maintenance: monitoring hardware resource spikes, tracking down disk hogs, cleaning multi-gigabyte build artifacts (`node_modules`, `target`, `.venv`), clearing temporary cache clutter, and managing software installations.

Currently, Windows users are forced to choose between:
1. **Bloated graphical utilities** (CCleaner, heavy proprietary dashboards) packed with ads, background daemons, and sluggish UIs.
2. **Fragmented CLI tools**: Excellent standalone modern CLI tools exist (such as `bottom`, `gdu`, `kondo`), but they have different installation methods (`winget`, `cargo`, `npm`), inconsistent command syntaxes, and zero unified orchestration.
3. **Complex multi-step PowerShell one-liners**: Writing verbose native WMI/CIM queries on the fly is tedious, error-prone, and slow.

### 1.2 The Solution: WinMole
**WinMole** is an all-in-one terminal manager for Windows that acts as an intelligent orchestrator and dispatcher. It delivers a fast, cohesive, Unix-like CLI experience (`mo <command>`) that bridges the gap between high-performance third-party TUI binaries and resilient native PowerShell fallbacks.

### 1.3 Core Value Proposition
- **Single Command Simplicity:** One unified binary/script (`mo` or `winmole`) for all system maintenance workflows.
- **100% Terminal-Native:** Zero external graphical popups, zero Electron apps, zero web views. Works seamlessly over SSH, Windows Terminal, and standard consoles.
- **Self-Healing & Zero Friction:** If a recommended modern TUI engine (`bottom`, `gdu`, `kondo`) is not installed, WinMole prompts for a 1-click `winget` installation or automatically executes an instant native PowerShell fallback.
- **Safety First:** Strict dry-run previews, path verification guards, non-destructive defaults, and elevation safety prevent accidental data loss.

---

## 2. Product Goals & Objectives

### 2.1 Primary User Goals
1. Inspect live system hardware state (CPU, RAM, GPU, Disks, Network) within 500 milliseconds of typing `mo status`.
2. Locate and reclaim gigabytes of disk space interactively via `mo analyze` and `mo purge`.
3. Safely purge temporary system files and caches with `mo clean --dry-run` to preview reclamation before execution.
4. Search, inspect, and uninstall unwanted software without navigating the Windows Settings GUI.
5. Access an interactive, keyboard-navigable menu simply by executing `mo`.

### 2.2 System & Engineering Objectives
- **Startup Latency:** Dispatcher startup overhead must be `< 120ms` in PowerShell 7+ and `< 250ms` in Windows PowerShell 5.1.
- **Portability:** Self-contained script or PowerShell module easily installable into user profile (`$PROFILE`) or `$env:PATH`.
- **Zero Mandatory External Dependencies:** Operates out-of-the-box on a fresh Windows install using native fallbacks without requiring admin rights for basic features.
- **No Background Daemons:** WinMole runs only when invoked; zero background services, zero resource consumption when idle.

---

## 3. Detailed Requirements & Feature Specifications

### 3.1 Command Taxonomy & Dispatch Model
WinMole provides aliases `winmole` and `mo`. All subcommands accept standard flags (`--help`, `-h`, `--verbose`, `-v`).

```
winmole [subcommand] [flags]
mo [subcommand] [flags]
```

#### Feature 1: Interactive TUI Menu (`mo`)
- **Trigger:** Running `mo` without any subcommand.
- **Behavior:**
  - Displays an ANSI-styled header banner with current system snapshot (Host, OS build, CPU load %, Memory free GB, C: Drive free GB).
  - Presents an interactive selection menu with keyboard navigation (Up/Down arrow keys or numbers `1`-`7`):
    - `[1] System Status (Live Monitor)`
    - `[2] Analyze Disk Usage (Storage Visualizer)`
    - `[3] Purge Project Artifacts (Dev Cleaner)`
    - `[4] Clean System Temp & Caches`
    - `[5] Uninstall Applications`
    - `[6] Doctor & Diagnostics`
    - `[0] Exit`
  - Pressing `Enter` executes the selected module and returns to the menu or shell upon exit.

#### Feature 2: Live System Monitor (`mo status`)
- **Primary Engine:** Launch `bottom` (`btm`) if installed, or `btop`.
- **Fallback Engine:** Custom native PowerShell continuous monitor loop:
  - Header: CPU model, Core count, uptime.
  - Live progress bars: CPU Utilization %, Memory Committed/Total %, Disk read/write activity.
  - Top 5 processes sorted by CPU and Memory usage with PID, Name, Working Set (MB), and CPU (%).
  - Refresh rate: 1.0 second. Press `q` or `Ctrl+C` to cleanly exit.
- **Self-Healing:** If neither `btm` nor `btop` is in PATH, prompt: `"bottom (btm) is not installed. Install via winget? [Y/n/fallback]"`.

#### Feature 3: Interactive Disk Usage Explorer (`mo analyze [path]`)
- **Target Path:** Defaults to current working directory (`.`) or specified root (e.g., `mo analyze C:\`).
- **Primary Engine:** Launch `gdu` (Go Disk Usage) or `dua-cli` (interactive mode).
- **Fallback Engine:** High-performance native PowerShell directory analyzer:
  - Scans specified directory (supports `-Depth` flag, default: 2 levels).
  - Aggregates file count and recursive folder size.
  - Renders a color-coded bar chart / tabular breakdown sorted by size descending (GB/MB).
- **Self-Healing:** Offers 1-click `winget install gdu` if absent.

#### Feature 4: Developer Build Artifact Cleaner (`mo purge [path]`)
- **Target Path:** Defaults to current directory tree or projects root (`C:\Projects`, user repo folders).
- **Primary Engine:** Launch `kondo` or `npkill` (`npx npkill`).
- **Fallback Engine:** Native PowerShell scan for target directories:
  - Patterns: `node_modules`, `target` (Rust/Java), `.venv` / `venv` / `__pycache__` (Python), `bin` / `obj` (.NET), `.next` / `.nuxt` / `dist` / `build` (Web).
  - Outputs a summary table: Directory Path, Last Modified, Total Size (MB/GB).
  - Explicit Confirmation: Prompts `"Do you want to permanently delete these X artifact directories? [y/N]"` before triggering deletion.

#### Feature 5: Temporary Files & Cache Cleaner (`mo clean [--dry-run] [--all]`)
- **Clean Targets:**
  - User Temporary Directory (`$env:TEMP`)
  - Windows System Temporary Directory (`C:\Windows\Temp` — requires UAC check)
  - Windows Prefetch (`C:\Windows\Prefetch` — admin only)
  - Windows Error Reporting / Crash Dumps (`%LOCALAPPDATA%\CrashDumps`)
  - Package Manager Caches (`npm cache clean`, `pip cache purge`, `cargo cache` if flags specified)
  - Browser Cache Remnants (Edge/Chrome/Firefox temp cache files)
- **Safety Flags:**
  - `--dry-run`: Calculates and displays exact file paths and reclaimable space without deleting anything.
  - `--force`: Skips interactive confirmation prompts (for automated scripts).
- **In-Use File Handling:** Gracefully skips files locked by running processes (`IOException` / Access Denied) without terminating the process.

#### Feature 6: Package & App Uninstaller (`mo uninstall [query]`)
- **Behavior:**
  - If `query` provided: Runs `winget uninstall <query>` with pass-through flags.
  - If no `query` provided: Executes `winget list`, displays an interactive filterable selector, and prompts for confirmation before invoking uninstallation.
  - Elevates or prompts cleanly if the uninstaller requires UAC permissions.

#### Feature 7: Doctor & Environment Diagnostics (`mo doctor`)
- **Diagnostic Checks:**
  - PowerShell version and execution policy (`Get-ExecutionPolicy`).
  - Terminal capability (ANSI/VT100 support check).
  - Presence of Modern CLI binaries (`btm`, `gdu`, `kondo`, `winget`).
  - Path and profile registration verification.
  - Administrator / elevation status check.

---

## 4. User Personas & Scenarios

### Persona 1: Full-Stack Web Developer (Dev Alex)
- **Context:** Working across multiple JavaScript, Python, and Rust repositories on Windows 11.
- **Pain Point:** `node_modules` and Python virtual environments consume 60+ GB across disk. Finds clicking around Windows Explorer too slow.
- **WinMole Workflow:** Opens Windows Terminal, navigates to `C:\Projects`, runs `mo purge`, selects folders, and reclaims 45 GB in 30 seconds.

### Persona 2: Systems Power-User & SysAdmin (Admin Jordan)
- **Context:** Managing dev workstations and performance tuning.
- **Pain Point:** Needs quick visual inspection of running workloads and disk bloat without installing heavy GUI monitoring apps.
- **WinMole Workflow:** Types `mo status` for instant interactive CPU/RAM inspection, followed by `mo clean --dry-run` to inspect temp file buildup.

---

## 5. Non-Functional Requirements & Constraints

| Metric | Target Specification | Enforcement Mechanism |
|---|---|---|
| **CLI Invocation Overhead** | `< 120 ms` in PS 7+, `< 250 ms` in PS 5.1 | Lazy loading of fallback functions; avoid importing heavy external modules on startup |
| **OS Compatibility** | Windows 10 (1809+) & Windows 11 | Windows Console Host and Windows Terminal compatible |
| **PowerShell Versions** | PowerShell 5.1 (Built-in) and PowerShell 7.x (Core) | Dual-syntax compatibility; avoid PowerShell 7-only operators (`??`, `&&`) without backward-compatible guards |
| **Memory Footprint** | `< 25 MB` private working set | Garbage collection after large directory scans |
| **Data Safety** | 0% unconfirmed deletions | Deletion operations require explicit confirmation or `--force` flag |
| **Installation Footprint** | `< 500 KB` script bundle | Pure script architecture with external binaries managed via winget |

---

## 6. Success Metrics & Key Performance Indicators (KPIs)

1. **Instant Usability:** 100% of subcommands execute valid actions out-of-the-box on a vanilla Windows 11 install without external software pre-installed.
2. **First-Run Time-to-Value:** A new user goes from installation to their first successful `mo status` or `mo clean` run in `< 60 seconds`.
3. **Safety Incident Rate:** 0 reported incidents of unintended file deletions due to dry-run verification and target boundaries.
4. **Execution Reliability:** Graceful handling of locked files and permission boundaries with 0 unhandled fatal script crashes.
