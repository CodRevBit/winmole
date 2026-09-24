# 6. Implementation Plan — WinMole

> **Project Name:** WinMole (`winmole` / `mo`)  
> **Methodology:** Sequential Phased Engineering with Strict QA Exit Gates  
> **Status:** Ready for build upon explicit user approval.

---

## 1. Phased Build Sequence & Roadmap

```
+--------------------------------------------------------------------+
| Phase 1: Scaffolding, Project Structure & Environment Verification  |
+--------------------------------------------------------------------+
                                  |
                                  v
+--------------------------------------------------------------------+
| Phase 2: Core Dispatcher, Config System & Parameter Engine         |
+--------------------------------------------------------------------+
                                  |
                                  v
+--------------------------------------------------------------------+
| Phase 3: Terminal UI Engine & Interactive Menu System              |
+--------------------------------------------------------------------+
                                  |
                                  v
+--------------------------------------------------------------------+
| Phase 4: Subcommand Engines & Dependency Self-Healing              |
|  [4.1] Status  [4.2] Analyze  [4.3] Purge  [4.4] Clean  [4.5] App  |
+--------------------------------------------------------------------+
                                  |
                                  v
+--------------------------------------------------------------------+
| Phase 5: Installer, Environment PATH & Profile Registration        |
+--------------------------------------------------------------------+
                                  |
                                  v
+--------------------------------------------------------------------+
| Phase 6: Pester Testing, Safety Audits & Release Checklist         |
+--------------------------------------------------------------------+
```

---

## 2. Phase-by-Phase Technical Breakdown

### Phase 1: Scaffolding & Architecture Skeleton
- **Goals:** Set up the modular directory layout, git repository, and base script templates.
- **Tasks:**
  1. Create directory hierarchy:
     ```
     C:\Projects\winmole\
     ├── bin\                    # mo.cmd and winmole.cmd shell shims
     ├── src\                    # Modular PowerShell source files
     │   ├── Core\               # Dispatcher, config, ANSI renderer, logger
     │   ├── Commands\           # Individual subcommand implementations
     │   └── Modules\            # Native fallbacks (Status, Analyze, Purge, Clean)
     ├── tests\                  # Pester test suites
     ├── install.ps1             # 1-click user installer
     └── README.md               # User documentation
     ```
  2. Implement `bin/mo.cmd` and `bin/winmole.cmd` wrappers ensuring universal cmd/pwsh execution.
  3. Validate PowerShell 5.1 and PowerShell 7+ compatibility in execution harness.
- **Exit Gate 1:** Running `bin\mo.cmd --version` prints the scaffolded version from both CMD and PowerShell without errors.

---

### Phase 2: Core Dispatcher & Configuration Engine
- **Goals:** Robust argument parsing, configuration loading, safety validation, and dry-run flag routing.
- **Tasks:**
  1. Build `src/Core/Config.ps1`:
     - Creates `$env:USERPROFILE\.winmole\config.json` with sane defaults on first run.
     - Implements `Get-WinMoleConfig` and `Set-WinMoleConfig`.
  2. Build `src/Core/Dispatcher.ps1`:
     - Implements `param([string]$Subcommand, [switch]$DryRun, [switch]$Force, [switch]$Help, [string]$Path)`.
     - Checks for root directory protection (blocks `C:\`, `C:\Windows` targets).
     - Checks elevation (UAC) status.
  3. Build `src/Core/DependencyResolver.ps1`:
     - `Test-WinMoleBinary -Name <name>`: Probes system PATH.
     - `Install-WinMoleBinary -Tool <tool>`: Runs `winget install` with status feedback.
- **Exit Gate 2:** Dispatcher correctly routes mock subcommands, handles unknown flags gracefully, and loads configuration in under 80ms.

---

### Phase 3: Terminal UI & Interactive Menu Engine
- **Goals:** Deliver the flicker-free ANSI terminal interface and arrow-key interactive menu.
- **Tasks:**
  1. Build `src/Core/UI.ps1`:
     - ANSI truecolor formatting helpers: `Write-WMHeader`, `Write-WMBox`, `Format-WMProgressBar`.
     - Virtual terminal capability detection (falls back to 16-color for legacy conhost).
  2. Build `src/Core/Menu.ps1`:
     - Renders system snapshot banner (CPU, RAM, Disk).
     - Captures keyboard inputs (`[Console]::ReadKey($true)`):
       - Arrow Up (`[ConsoleKey]::UpArrow`), Arrow Down (`[ConsoleKey]::DownArrow`).
       - Numeric keys (`1` - `6`, `0`).
       - Escape / `q` for clean exit.
- **Exit Gate 3:** Executing `mo` without parameters presents a responsive, interactive menu that navigates smoothly without screen tearing or cursor ghosting.

---

### Phase 4: Subcommand Implementations & Native Fallbacks
- **Goals:** Implement all 6 operational subcommands with primary tool delegation and robust native fallbacks.

#### 4.1: `mo status`
- Detect `btm.exe` or `btop.exe`; invoke if present.
- Fallback: Native PowerShell live loop reading CPU (`Win32_Processor`), RAM (`Win32_OperatingSystem`), and Disks with `q` key listener.

#### 4.2: `mo analyze`
- Detect `gdu.exe` or `dua.exe`; invoke if present with target path.
- Fallback: High-performance .NET directory size analyzer rendering descending size bars.

#### 4.3: `mo purge`
- Detect `kondo.exe`; invoke if present.
- Fallback: Pure PowerShell recursive scan for `node_modules`, `target`, `.venv`, `bin/obj`. Displays tabular summary and requires explicit `[y/N]` confirmation.

#### 4.4: `mo clean`
- Multi-target cleaner for `%TEMP%`, system temp, and crash dumps.
- Full support for `--dry-run` to preview files and size without deleting.
- Exception handling to skip locked/in-use files safely.

#### 4.5: `mo uninstall`
- Wrap `winget uninstall` with interactive search/filtering if no query is given.

#### 4.6: `mo doctor`
- Diagnostic report verifying PowerShell version, ANSI support, execution policy, and status of external TUI binaries.

- **Exit Gate 4:** All 6 subcommands execute successfully in both primary mode (when tools installed) and native fallback mode (when tools missing).

---

### Phase 5: Installer & Profile Registration
- **Goals:** 1-click seamless installation for end users.
- **Tasks:**
  1. Build `install.ps1`:
     - Copies WinMole into `$env:USERPROFILE\.winmole`.
     - Adds `$env:USERPROFILE\.winmole\bin` to the user's `$env:PATH`.
     - Optionally appends `Import-Module` or function definition to `$PROFILE`.
     - Automatically configures `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` if restricted.
  2. Build `uninstall.ps1` for clean removal.
- **Exit Gate 5:** Opening a brand new terminal window permits immediate execution of `mo` from any directory.

---

### Phase 6: Automated Testing & Verification
- **Goals:** Comprehensive safety verification and test coverage.
- **Tasks:**
  1. Pester unit test suite (`tests/WinMole.Tests.ps1`):
     - Test argument parsing and subcommand routing.
     - Test `--dry-run` ensures zero file deletions.
     - Test root path protection prevents execution on critical system drives.
     - Test config schema parsing and default fallbacks.
  2. Manual verification run on both PowerShell 5.1 and PowerShell 7.4+.
- **Exit Gate 6:** 100% Pester test pass rate; zero regressions; documentation verified against actual CLI behavior.
