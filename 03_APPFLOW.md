# 3. Appflow & Navigation Map — WinMole

> **Project Name:** WinMole (`winmole` / `mo`)  
> **Scope:** Terminal Interaction Flow, Keystroke Navigation, Self-Healing Prompts, and State Transitions

---

## 1. Visual Appflow & State Machine

```mermaid
flowchart TD
    Start([User Terminal Session]) --> InvocationChoice{Command Form?}

    %% Command Form Branching
    InvocationChoice -- "mo (no args)" --> Banner[Render WinMole Header & System Snapshot]
    InvocationChoice -- "mo <subcommand> [flags]" --> ArgDispatcher[Parse Subcommand & Flags]

    %% Interactive Menu Phase
    Banner --> MenuLoop[Render Interactive TUI Menu]
    MenuLoop --> KeyInput[/User Keypress: Arrow Up/Down or Number 0-6/]
    KeyInput -- "1 / Enter on Status" --> RouteStatus[Route: mo status]
    KeyInput -- "2 / Enter on Analyze" --> RouteAnalyze[Route: mo analyze]
    KeyInput -- "3 / Enter on Purge" --> RoutePurge[Route: mo purge]
    KeyInput -- "4 / Enter on Clean" --> RouteClean[Route: mo clean]
    KeyInput -- "5 / Enter on Uninstall" --> RouteUninstall[Route: mo uninstall]
    KeyInput -- "6 / Enter on Doctor" --> RouteDoctor[Route: mo doctor]
    KeyInput -- "0 / 'q' / Esc" --> ExitApp([Clean Console Exit])

    %% Argument Dispatcher Phase
    ArgDispatcher -- "status" --> RouteStatus
    ArgDispatcher -- "analyze" --> RouteAnalyze
    ArgDispatcher -- "purge" --> RoutePurge
    ArgDispatcher -- "clean" --> RouteClean
    ArgDispatcher -- "uninstall" --> RouteUninstall
    ArgDispatcher -- "doctor" --> RouteDoctor
    ArgDispatcher -- "invalid / --help" --> HelpScreen[Display Help & Usage Syntax] --> ExitApp

    %% Status Branch
    RouteStatus --> ProbeStatus{Check 'btm' / 'btop' in PATH?}
    ProbeStatus -- Found --> LaunchBTM[Execute bottom / btop TUI] --> ReturnShell[Restore Terminal Screen]
    ProbeStatus -- Missing --> InstallStatusPrompt{Prompt: Install via winget?}
    InstallStatusPrompt -- "Yes (y)" --> WingetBTM[Run: winget install Clement.bottom] --> LaunchBTM
    InstallStatusPrompt -- "No / Fallback" --> NativeStatus[Run Native PS Live Hardware Loop] --> ReturnShell

    %% Analyze Branch
    RouteAnalyze --> ProbeGDU{Check 'gdu' in PATH?}
    ProbeGDU -- Found --> LaunchGDU[Execute gdu TUI] --> ReturnShell
    ProbeGDU -- Missing --> InstallGDUPrompt{Prompt: Install via winget?}
    InstallGDUPrompt -- "Yes (y)" --> WingetGDU[Run: winget install gdu] --> LaunchGDU
    InstallGDUPrompt -- "No / Fallback" --> NativeAnalyze[Run Native PS Directory Size Profiler] --> ReturnShell

    %% Purge Branch
    RoutePurge --> ProbeKondo{Check 'kondo' in PATH?}
    ProbeKondo -- Found --> LaunchKondo[Execute kondo TUI] --> ReturnShell
    ProbeKondo -- Missing --> NativePurgeScan[Scan for node_modules, target, .venv]
    NativePurgeScan --> PurgeResults[Display Artifact Table & Total Reclaimable Space]
    PurgeResults --> ConfirmPurge{User Confirms [y/N]?}
    ConfirmPurge -- "Yes (y)" --> ExecutePurge[Delete Target Artifact Folders] --> PurgeSummary[Display Freed Disk Space] --> ReturnShell
    ConfirmPurge -- "No (N)" --> AbortPurge[Abort Deletion] --> ReturnShell

    %% Clean Branch
    RouteClean --> CheckDryRun{--dry-run Flag?}
    CheckDryRun -- Yes --> ScanClean[Scan Temp, Prefetch, Crash Dumps] --> RenderDryRun[Render Reclaimable Report - No Deletions] --> ReturnShell
    CheckDryRun -- No --> PromptCleanConfirm{User Confirms [y/N] or --force?}
    PromptCleanConfirm -- Confirmed --> ExecClean[Safely Delete Temp Files & Skip In-Use] --> CleanSummary[Display Freed Space & Skipped Files] --> ReturnShell
    PromptCleanConfirm -- Aborted --> ReturnShell

    %% Uninstall Branch
    RouteUninstall --> ProbeWinget{winget Available?}
    ProbeWinget -- Yes & Query Provided --> ExecWingetUninstall[Execute: winget uninstall query] --> ReturnShell
    ProbeWinget -- Yes & No Query --> InteractiveList[Fetch & Display Filtered winget list] --> SelectApp[/Select App to Remove/] --> ExecWingetUninstall
    ProbeWinget -- No --> FallbackAppMgr[Display Windows Installed Apps via Registry] --> ReturnShell

    %% Doctor Branch
    RouteDoctor --> RunDiagnostics[Run System, PS Version, PATH & Tool Checks] --> RenderReport[Display Diagnostic Matrix] --> ReturnShell

    %% Loop Back
    ReturnShell --> CheckOrigin{Triggered via Menu?}
    CheckOrigin -- Yes --> MenuLoop
    CheckOrigin -- No --> ExitApp
```

---

## 2. Screen-by-Screen Interaction Specifications

### 2.1 Interactive Terminal Menu (`mo`)
- **Navigation Controls:**
  - `↑` / `k`: Move cursor up.
  - `↓` / `j`: Move cursor down.
  - `1` - `6`: Direct jump and execute corresponding item.
  - `Enter` / `Space`: Execute highlighted option.
  - `q` / `Esc`: Exit WinMole immediately.
- **Visual Design:**
  - Active selection highlighted with reverse video or primary brand color (`#38BDF8` Sky Blue).
  - Terminal cursor hidden during menu navigation (`[Console]::CursorVisible = $false`) and restored upon exit.

### 2.2 Live System Monitor (`mo status`)
- **Primary Engine (`btm`):** Full keyboard navigation managed natively by `bottom` (`?` for help, `Tab` to cycle panels, `q` to quit).
- **Native Fallback Loop:**
  - Screen cleared and redrawn every `1000ms`.
  - Pressing `q` or `Esc` immediately breaks the loop and restores the cursor.
  - Pressing `r` forces an instant metric refresh.

### 2.3 Developer Artifact Cleaner (`mo purge`)
- **Scanning Phase:** Shows an animated CLI spinner: `[SCANNING] Discovering build artifacts in C:\Projects...`
- **Results Table:**
  ```
  Path                                   Artifact Type    Size
  -------------------------------------------------------------
  C:\Projects\web-app\node_modules       node_modules     1.42 GB
  C:\Projects\api-server\.venv           Python venv      840.1 MB
  C:\Projects\cli-tool\target            Rust target      3.21 GB
  -------------------------------------------------------------
  Total Reclaimable Space: 5.47 GB across 3 directories.
  ```
- **Action Prompt:**
  - Prompt: `Proceed with permanent deletion? [y/N]: `
  - Pressing `Enter` defaults to `N` (safe cancellation).
  - Pressing `y` triggers asynchronous parallel deletion with visual progress counter.

### 2.4 Cache & Temp Cleaner (`mo clean`)
- **Dry-Run Mode (`mo clean --dry-run`):**
  - Read-only execution.
  - Generates detailed category breakdown:
    - User Temp (`%TEMP%`): `2.1 GB` (4,120 files)
    - System Temp (`C:\Windows\Temp`): `450 MB` (Requires Admin)
    - Crash Dumps: `180 MB` (12 files)
  - No prompt, immediately returns exit code 0.
- **Standard Cleaning Mode (`mo clean`):**
  - Displays summary of targets to be cleaned.
  - Asks: `Clean temporary files? [y/N]: `
  - During execution, locked files are caught and marked as `[SKIPPED: IN USE]` without interrupting remaining cleanup.

---

## 3. Keystroke & Input Handling Matrix

| Context | Key / Input | Action Taken | Fallback / Guard |
|---|---|---|---|
| **Main Menu** | `1` .. `6` | Immediate execution of module | Out-of-bounds keys ignored |
| **Main Menu** | `Arrow Keys` | Move highlight cursor | Clamped to bounds (0 to 6) |
| **Main Menu** | `Enter` | Execute highlighted item | Executes currently selected index |
| **Main Menu** | `q` / `Ctrl+C` | Exit application cleanly | Restores terminal cursor and title |
| **Native Monitor**| `q` / `Esc` | Stop monitor loop | Restores console buffer |
| **Confirmations** | `Enter` (Empty) | Defaults to `No` | Never deletes on accidental Enter |
| **Confirmations** | `y` / `Y` | Confirms action | Begins processing |
| **Confirmations** | `n` / `N` | Aborts action | Prints cancellation notice |
| **Installer Prompt**| `y` / `Y` | Triggers `winget install` | Shows live install output |
| **Installer Prompt**| `n` / `Enter` | Skips install, invokes fallback | Seamless execution continuation |
