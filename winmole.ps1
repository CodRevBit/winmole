<#
.SYNOPSIS
    WinMole (mo) - Unified Windows Terminal Maintenance & Monitoring Toolkit.
.DESCRIPTION
    All-in-one terminal manager for Windows inspired by macOS Mole (tw93/Mole).
    Integrates live system monitoring, disk space exploration, build artifact purging,
    temporary file cleaning, and package uninstallation 100% inside the terminal.
#>

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Subcommand,

    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$RemainingArgs,

    [Alias("WhatIf", "Dry")]
    [switch]$DryRun,
    [Alias("f")]
    [switch]$Force,
    [Alias("a")]
    [switch]$All,
    [switch]$Native,
    [Alias("h", "?")]
    [switch]$Help,
    [Alias("v")]
    [switch]$Version
)

# Ensure UTF-8 Console Output
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$WinMoleVersion = "1.0.0"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Dot-source Core Modules
. (Join-Path $ScriptDir "src\Core\Config.ps1")
. (Join-Path $ScriptDir "src\Core\UI.ps1")
. (Join-Path $ScriptDir "src\Core\DependencyResolver.ps1")
. (Join-Path $ScriptDir "src\Core\Menu.ps1")

# Dot-source Commands
. (Join-Path $ScriptDir "src\Commands\Status.ps1")
. (Join-Path $ScriptDir "src\Commands\Analyze.ps1")
. (Join-Path $ScriptDir "src\Commands\Purge.ps1")
. (Join-Path $ScriptDir "src\Commands\Clean.ps1")
. (Join-Path $ScriptDir "src\Commands\Uninstall.ps1")
. (Join-Path $ScriptDir "src\Commands\Doctor.ps1")

# Handle --version / -v
if ($Version -or $Subcommand -eq "--version" -or $Subcommand -eq "-v") {
    Write-Host ("winmole version {0}" -f $WinMoleVersion)
    exit 0
}

# Handle --help / -h / help
if ($Help -or $Subcommand -eq "--help" -or $Subcommand -eq "-h" -or $Subcommand -eq "help") {
    $c = $global:WM_Color
    $g = $global:WM_Glyphs

    $margin = Get-WMMargin -ContentWidth 76

    Write-WMLogo -Width 76
    Write-Host ""
    Write-Host ("{0}{1}USAGE:{2}" -f $margin, $c.Primary, $c.Reset)
    Write-Host ("{0}  winmole [command] [options]" -f $margin)
    Write-Host ""
    Write-Host ("{0}{1}COMMANDS:{2}" -f $margin, $c.Primary, $c.Reset)
    Write-Host ("{0}  {1}status{2}               Live system monitor (CPU, RAM, Disk, Procs) [bottom/btop]" -f $margin, $c.Text, $c.Reset)
    Write-Host ("{0}  {1}analyze{2} [path]        Interactive disk usage visualizer [gdu/dua]" -f $margin, $c.Text, $c.Reset)
    Write-Host ("{0}  {1}purge{2}   [path]        Developer build artifact cleaner (node_modules, target,...)" -f $margin, $c.Text, $c.Reset)
    Write-Host ("{0}  {1}clean{2}                 System temp, crash dump and cache cleaner" -f $margin, $c.Text, $c.Reset)
    Write-Host ("{0}  {1}uninstall{2} [app]       Interactive package and application uninstaller [winget]" -f $margin, $c.Text, $c.Reset)
    Write-Host ("{0}  {1}doctor{2}                System and external tool health diagnostic report" -f $margin, $c.Text, $c.Reset)
    Write-Host ("{0}  {1}(none){2}                Launch interactive keyboard-navigable terminal menu" -f $margin, $c.Muted, $c.Reset)
    Write-Host ""
    Write-Host ("{0}{1}OPTIONS:{2}" -f $margin, $c.Primary, $c.Reset)
    Write-Host ("{0}  {1}--dry-run{2}           Preview files and space without making modifications" -f $margin, $c.Secondary, $c.Reset)
    Write-Host ("{0}  {1}--force{2}             Bypass confirmation prompts for automated runs" -f $margin, $c.Secondary, $c.Reset)
    Write-Host ("{0}  {1}--all{2}               Include all optional target caches (clean command)" -f $margin, $c.Secondary, $c.Reset)
    Write-Host ("{0}  {1}--native{2}            Force built-in pure PowerShell engine (skip external tools)" -f $margin, $c.Secondary, $c.Reset)
    Write-Host ("{0}  {1}-h, --help{2}          Display this help manual" -f $margin, $c.Secondary, $c.Reset)
    Write-Host ("{0}  {1}-v, --version{2}       Display WinMole version information" -f $margin, $c.Secondary, $c.Reset)
    Write-Host ""
    Write-Host ("{0}{1}EXAMPLES:{2}" -f $margin, $c.Primary, $c.Reset)
    Write-Host ("{0}  {1}winmole{2}                        {3}# Open interactive menu{2}" -f $margin, $c.Text, $c.Reset, $c.Muted)
    Write-Host ("{0}  {1}winmole status{2}                 {3}# Launch live terminal monitor{2}" -f $margin, $c.Text, $c.Reset, $c.Muted)
    Write-Host ("{0}  {1}winmole analyze C:\Projects{2}    {3}# Profile disk space{2}" -f $margin, $c.Text, $c.Reset, $c.Muted)
    Write-Host ("{0}  {1}winmole purge --dry-run{2}        {3}# Scan project build junk without deleting{2}" -f $margin, $c.Text, $c.Reset, $c.Muted)
    Write-Host ("{0}  {1}winmole clean{2}                  {3}# Clean %TEMP% and crash dumps{2}" -f $margin, $c.Text, $c.Reset, $c.Muted)
    Write-Host ("{0}  {1}winmole uninstall vlc{2}          {3}# Uninstall application via winget{2}" -f $margin, $c.Text, $c.Reset, $c.Muted)
    Write-Host ("{0}  {1}winmole doctor{2}                 {3}# Run environment diagnostics{2}" -f $margin, $c.Text, $c.Reset, $c.Muted)
    Write-Host ""
    exit 0
}

# If no subcommand passed, display interactive menu
if ([string]::IsNullOrWhiteSpace($Subcommand)) {
    Show-WinMoleMenu
    exit 0
}

# Extract double-dash flags and normalize remaining arguments
$filteredArgs = @()
if ($RemainingArgs) {
    foreach ($a in $RemainingArgs) {
        if ($a -in @("--dry-run", "-dry-run", "/dry-run")) { $DryRun = $true }
        elseif ($a -in @("--force", "-force", "/force")) { $Force = $true }
        elseif ($a -in @("--all", "-all", "/all")) { $All = $true }
        elseif ($a -in @("--native", "-native", "/native")) { $Native = $true }
        elseif ($a -in @("--help", "-help", "/help", "-h", "/h", "/?")) { $Help = $true }
        elseif ($a -in @("--version", "-version", "/version", "-v", "/v")) { $Version = $true }
        else { $filteredArgs += $a }
    }
}
$RemainingArgs = $filteredArgs

# Determine target path from remaining args if provided
$targetPath = (Get-Location).Path
if ($RemainingArgs -and $RemainingArgs.Count -gt 0) {
    $firstArg = $RemainingArgs[0]
    if (Test-Path $firstArg) {
        $targetPath = $firstArg
    }
}

# Route Subcommands
switch ($Subcommand.ToLower()) {
    "status" {
        Invoke-WinMoleStatus -Native:$Native
    }
    "analyze" {
        Invoke-WinMoleAnalyze -Path $targetPath -Native:$Native
    }
    "purge" {
        Invoke-WinMolePurge -Path $targetPath -DryRun:$DryRun -Force:$Force -Native:$Native
    }
    "clean" {
        Invoke-WinMoleClean -DryRun:$DryRun -Force:$Force -All:$All
    }
    "uninstall" {
        $query = ""
        if ($RemainingArgs -and $RemainingArgs.Count -gt 0) {
            $query = ($RemainingArgs -join " ")
        }
        Invoke-WinMoleUninstall -Query $query
    }
    "doctor" {
        Invoke-WinMoleDoctor
    }
    default {
        Write-WMError ("Unknown subcommand '{0}'." -f $Subcommand)
        Write-Host "Run 'winmole --help' for a list of available commands."
        exit 1
    }
}
