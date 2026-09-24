# WinMole - Pre-Vibecoding Architectural Blueprint

> **Generated via `docu` skill based on mikenwo.ai's 6-document pre-vibecoding architecture.**  
> **Status:** Documentation Phase Complete & Verified. Ready for implementation on user trigger.  
> **Core Axiom:** Do not write application code until these 6 documents are thoroughly reviewed, validated, and aligned.

---

## Executive Overview
**WinMole** (`winmole` / `mo`) is a unified, lightweight command-line maintenance and system monitoring toolkit engineered specifically for Windows (PowerShell 5.1 & PowerShell 7+ in Windows Terminal). Inspired by the philosophy of macOS **Mole** ([tw93/Mole](https://github.com/tw93/Mole)), WinMole unifies the fragmented Windows terminal maintenance ecosystem.

Instead of reinventing complex interactive hardware visualizers and disk profilers in bloated custom binaries, WinMole serves as a high-performance terminal dispatcher, dependency orchestrator, and interactive TUI suite. It binds together best-in-class Rust/Go/native TUI tools (`bottom`, `gdu`, `kondo`, `winget`) with robust, zero-dependency native PowerShell fallbacks.

Everything runs **100% inside the terminal** without launching external graphical windows, web views, or background telemetry daemons.

---

## Architectural Documentation Index

| # | Document | Purpose & Scope | Direct Link |
|---|---|---|---|
| **01** | **Product Requirements Document (PRD)** | Core problem statement, user personas, command taxonomy, feature requirements, safety requirements, and success metrics. | [`01_PRD.md`](file:///C:/Projects/winmole/01_PRD.md) |
| **02** | **Technical Requirements Document (TRD)** | Technical architecture, dispatcher execution model, runtime compatibility (PS 5.1/7+), tool matrix, winget integration, and telemetry policies. | [`02_TRD.md`](file:///C:/Projects/winmole/02_TRD.md) |
| **03** | **Appflow & Navigation Map** | Interactive menu workflows, subcommand execution state trees, 1-click self-healing installation flows, and Mermaid flowcharts. | [`03_APPFLOW.md`](file:///C:/Projects/winmole/03_APPFLOW.md) |
| **04** | **UI/UX Design Brief** | Terminal ANSI/VT100 aesthetics, box-drawing characters, 16-color & truecolor palette, responsive terminal layout rules, and anti-slop guidelines. | [`04_UI_UX_DESIGN.md`](file:///C:/Projects/winmole/04_UI_UX_DESIGN.md) |
| **05** | **Backend Schema & State Models** | Local file configurations (`config.json`), clean targets registry, cache manifest schema, metrics history, and Mermaid ER diagrams. | [`05_BACKEND_SCHEMA.md`](file:///C:/Projects/winmole/05_BACKEND_SCHEMA.md) |
| **06** | **Implementation Plan** | 6-phase engineering build sequence, unit test specifications (Pester), exit gates, and safety verification protocols. | [`06_IMPLEMENTATION_PLAN.md`](file:///C:/Projects/winmole/06_IMPLEMENTATION_PLAN.md) |

---

## Quick Reference: Command Matrix

| Command | Subcommand Action | Primary Modern TUI Engine | Automatic Install Command | Built-in Native PS Fallback |
| :--- | :--- | :--- | :--- | :--- |
| `mo` / `winmole` | Interactive Dashboard | Pure PS Terminal TUI Menu | None (Native) | Arrow-key / numbered console menu |
| `mo status` | Live Hardware Monitor | `bottom` (`btm`) / `btop` | `winget install Clement.bottom` | Live polling loop (`Get-CimInstance`, counters) |
| `mo analyze` | Interactive Disk Explorer | `gdu` / `dua-cli` | `winget install gdu` | Recursive directory size profiler |
| `mo purge` | Dev Build Artifact Cleaner | `kondo` / `npkill` | `cargo install kondo` / `npx npkill` | Recursive search for `node_modules`, `target`, `.venv` |
| `mo clean` | Temp, Cache & Junk Cleaner | Curated PowerShell Cleaner / BleachBit | `winget install BleachBit.BleachBit` | Multi-target `%TEMP%`, prefetch, crashdump cleaner |
| `mo uninstall` | Package & App Uninstaller | `winget uninstall` | Native Windows 10/11 | Filtered package search & uninstall wrapper |
| `mo doctor` | Environment Health Check | Diagnostic Engine | None (Native) | Tool availability, UAC status, disk health scan |

---

## Directory Structure
```
C:\Projects\winmole\
├── README.md                  # Project overview, architecture index & agent guide
├── 01_PRD.md                  # Product Requirements Document
├── 02_TRD.md                  # Technical Requirements Document
├── 03_APPFLOW.md              # Appflow & Interactive Navigation Map (Mermaid)
├── 04_UI_UX_DESIGN.md         # Terminal UI/UX Design Brief & ANSI Theme Spec
├── 05_BACKEND_SCHEMA.md       # Local Schema, Config Specs & ER Model (Mermaid)
└── 06_IMPLEMENTATION_PLAN.md  # 6-Phase Sequential Implementation Plan & QA Gates
```

---
*Verified against user requirements and prompt analysis specifications.*
