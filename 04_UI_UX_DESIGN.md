# 4. UI/UX Design Brief — WinMole

> **Project Name:** WinMole (`winmole` / `mo`)  
> **Medium:** Terminal User Interface (TUI) & Command-Line Output  
> **Aesthetic Philosophy:** Clean, high-density, modern terminal aesthetic inspired by Charmbracelet (Gum/Huh), Starship prompt, and macOS Mole. Zero visual slop, crisp box borders, intentional color hierarchy, and instant rendering.

---

## 1. Aesthetic Direction & Design Principles

1. **Information Density with Breathing Room:** Dense, actionable data organized into crisp box-drawing panels with consistent 2-space indentation.
2. **Terminal Native:** Uses standard UTF-8 box-drawing characters (`╭─╮`, `│`, `╰─╯`) and graceful ASCII fallbacks (`+-+`, `|`) for legacy environments.
3. **Zero Visual Jitter:** In live loops (e.g., `mo status`), updates use in-place line overwrites (`\r` or VT100 cursor repositioning `\e[H`) rather than continuous scrolling, preventing terminal flicker.
4. **Accessible Color Contrast:** Colors are chosen specifically to remain legible across both dark mode and light mode terminal themes, with a 16-color ANSI fallback mode for legacy `conhost.exe`.

---

## 2. Color Palette & ANSI Token Specifications

### 2.1 TrueColor (24-bit RGB) & 256-Color Palette

| Token Name | HEX Code | ANSI Escape Sequence | Semantic Role / Context |
|---|---|---|---|
| **Primary Brand** | `#38BDF8` | `\e[38;2;56;189;248m` | WinMole logo, headers, highlighted menu selection, active metrics |
| **Secondary Accent** | `#818CF8` | `\e[38;2;129;140;248m` | Category labels, command examples, sub-headers |
| **Success** | `#34D399` | `\e[38;2;52;211;153m` | Freed disk space, healthy metric (<70%), successful operations |
| **Warning** | `#FBBF24` | `\e[38;2;251;191;36m` | High resource usage (70-90%), locked files, non-critical warnings |
| **Danger / Destructive** | `#F87171` | `\e[38;2;248;113;113m` | Deletion prompts, critical thresholds (>90%), errors |
| **Text Primary** | `#F8FAFC` | `\e[38;2;248;250;252m` | Primary metric numbers, table data, active titles |
| **Text Secondary / Muted** | `#64748B` | `\e[38;2;100;116;139m` | Borders, timestamps, file paths, unselected menu options |
| **Background Highlight** | `#1E293B` | `\e[48;2;30;41;59m` | Highlight background for active interactive menu cursor |

### 2.2 16-Color Console Fallback Matrix
When running inside legacy Windows PowerShell 5.1 without virtual terminal processing enabled:
- **Primary:** `Cyan`
- **Secondary:** `Magenta`
- **Success:** `Green`
- **Warning:** `Yellow`
- **Danger:** `Red`
- **Muted:** `DarkGray`
- **Text:** `White`

---

## 3. Typography, Glyphs & Visual Elements

### 3.1 Progress Bar & Meter Styling
- Bar Length: Fixed 20 characters for uniform alignment.
- Fill Character: `█` (Unicode `U+2588`) or `■` (Fallback: `#`).
- Empty Character: `░` (Unicode `U+2591`) or `·` (Fallback: `-`).
- Visual Representation:
  - `[████████████░░░░░░░░] 60%` (Healthy - Green)
  - `[████████████████░░░░] 82%` (Warning - Yellow)
  - `[███████████████████░] 96%` (Critical - Red)

### 3.2 Status Glyphs & Indicators
- Success: `✔` (`[OK]`)
- Warning: `▲` (`[WARN]`)
- Error / Block: `✖` (`[ERR]`)
- Info: `ℹ` (`[INFO]`)
- Bullet / Pointer: `›` (`>`)

---

## 4. Screen Wireframe Specifications

### 4.1 Interactive Menu Wireframe (`mo`)
```
╭─────────────────────────────────────────────────────────────╮
│  WINMOLE v1.0.0  •  Windows System Maintenance & Monitor    │
│  Host: DESKTOP-PRO  •  OS: Windows 11 Pro  •  Arch: x64     │
│  CPU: 18%  •  RAM: 14.2 / 31.9 GB (44%)  •  C: 184 GB Free  │
╰─────────────────────────────────────────────────────────────╯

  Use [↑/↓] or [1-6] to select, [Enter] to run, [q] to exit:

  › [1]  System Status       Live hardware monitoring (bottom/btop)
    [2]  Disk Analyzer       Interactive disk usage visualizer (gdu)
    [3]  Purge Artifacts     Clean dev build junk (node_modules, target)
    [4]  Clean Caches        Purge %TEMP%, crash dumps & system junk
    [5]  Uninstall Apps      Search and remove applications (winget)
    [6]  System Doctor       Verify tool installation and health
    [0]  Exit

  ─────────────────────────────────────────────────────────────
  Tip: Run 'mo <command>' directly from any shell (e.g. 'mo clean')
```

### 4.2 Native Status Monitor Dashboard Wireframe (`mo status` fallback)
```
╭─ Live System Status ────────────────────────────────────────╮
│ CPU: AMD Ryzen 9 5900X (12 Cores, 24 Threads)   Uptime: 2d 7h│
│ [██████░░░░░░░░░░░░░░]  28%                                 │
│                                                             │
│ Memory: 15.4 GB / 32.0 GB                                   │
│ [██████████░░░░░░░░░░]  48%                                 │
│                                                             │
│ Storage:                                                    │
│ C: [██████████████░░░░]  72% (128 GB Free of 512 GB)        │
│ D: [████░░░░░░░░░░░░░░]  22% (1.4 TB Free of 2.0 TB)        │
╰─────────────────────────────────────────────────────────────╯
╭─ Top Processes (by CPU / Memory) ───────────────────────────╮
│ PID     Process Name          CPU %     Memory (MB)         │
│ 14208   code.exe              4.2%      1,240 MB            │
│ 8920    chrome.exe            3.8%      2,150 MB            │
│ 3120    powershell.exe        1.1%        180 MB            │
│ 104     dwm.exe               0.9%        240 MB            │
╰─────────────────────────────────────────────────────────────╯
  Press [q] to quit, [r] to refresh
```

### 4.3 Developer Artifact Purge Wireframe (`mo purge`)
```
╭─ WinMole Purge ─────────────────────────────────────────────╮
│ Target Root: C:\Projects                                    │
│ Found 4 build artifact directories                          │
╰─────────────────────────────────────────────────────────────╯

  Path                                Type           Size
  ───────────────────────────────────────────────────────────
  C:\Projects\frontend\node_modules   node_modules   1.84 GB
  C:\Projects\backend\.venv           Python venv    640.2 MB
  C:\Projects\cli-engine\target       Rust target    4.12 GB
  C:\Projects\mobile\.next            Next.js build  512.0 MB
  ───────────────────────────────────────────────────────────
  Total Reclaimable Space: 7.11 GB

  ? Delete these 4 artifact directories? [y/N]: _
```

### 4.4 Temp & Cache Cleaning Dry-Run Wireframe (`mo clean --dry-run`)
```
╭─ WinMole Clean [DRY RUN PREVIEW] ───────────────────────────╮
│ Scan complete. No files were modified or deleted.           │
╰─────────────────────────────────────────────────────────────╯

  Target Category               Files       Reclaimable Size
  ───────────────────────────────────────────────────────────
  User Temporary Files (%TEMP%) 3,842       2.48 GB
  Windows Error Crash Dumps     8           340.5 MB
  System Temp (Non-Elevated)    Skipped     (Requires Admin)
  ───────────────────────────────────────────────────────────
  Total Reclaimable: 2.82 GB (3,850 files)

  To execute cleanup, run: mo clean
  To include elevated system targets, run in Administrator shell.
```
