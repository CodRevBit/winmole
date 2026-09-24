# WinMole UI & ANSI Renderer
# Compatible with PowerShell 5.1 & PowerShell 7+

# Ensure UTF-8 Console Output
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$global:WM_ESC = [char]27

function Test-WMVirtualTerminalSupport {
    if ($env:WT_SESSION -or $env:TERM_PROGRAM -eq "vscode" -or ($PSVersionTable.PSVersion.Major -ge 7)) {
        return $true
    }
    try {
        $osVer = [System.Environment]::OSVersion.Version
        if ($osVer.Major -ge 10) {
            return $true
        }
    } catch {}
    return $false
}

$global:WM_HasVT = Test-WMVirtualTerminalSupport

# Glyph Map using char codes for ASCII/Unicode safety
$global:WM_Glyphs = @{
    HLine    = [char]0x2500
    VLine    = [char]0x2502
    TopL     = [char]0x256D
    TopR     = [char]0x256E
    BotL     = [char]0x2570
    BotR     = [char]0x256F
    Block    = [char]0x2588
    Shade    = [char]0x2591
    Check    = [char]0x2714
    Warn     = [char]0x25B2
    Cross    = [char]0x2716
    Point    = [char]0x203A
    Bullet   = [char]0x2022
    Circle   = [char]0x25CB
}

if ($global:WM_HasVT) {
    $global:WM_Color = @{
        Reset        = "$($global:WM_ESC)[0m"
        Bold         = "$($global:WM_ESC)[1m"
        Dim          = "$($global:WM_ESC)[2m"
        Primary      = "$($global:WM_ESC)[38;2;56;189;248m"    # 38BDF8 Sky Blue
        Secondary    = "$($global:WM_ESC)[38;2;129;140;248m"   # 818CF8 Indigo
        Success      = "$($global:WM_ESC)[38;2;52;211;153m"    # 34D399 Emerald
        Warning      = "$($global:WM_ESC)[38;2;251;191;36m"    # FBBF24 Amber
        Danger       = "$($global:WM_ESC)[38;2;248;113;113m"   # F87171 Rose
        Text         = "$($global:WM_ESC)[38;2;248;250;252m"   # F8FAFC Pure White
        Muted        = "$($global:WM_ESC)[38;2;100;116;139m"   # 64748B Slate Muted
        BgHighlight  = "$($global:WM_ESC)[48;2;30;41;59m"     # 1E293B Dark Slate
        ClearScreen  = "$($global:WM_ESC)[2J$($global:WM_ESC)[H"
        CursorHide   = "$($global:WM_ESC)[?25l"
        CursorShow   = "$($global:WM_ESC)[?25h"
    }
} else {
    $global:WM_Color = @{
        Reset        = ""
        Bold         = ""
        Dim          = ""
        Primary      = ""
        Secondary    = ""
        Success      = ""
        Warning      = ""
        Danger       = ""
        Text         = ""
        Muted        = ""
        BgHighlight  = ""
        ClearScreen  = ""
        CursorHide   = ""
        CursorShow   = ""
    }
}

function Format-WMBytes {
    param([int64]$Bytes)
    if ($Bytes -lt 0) { $Bytes = 0 }
    if ($Bytes -lt 1KB) { return "$Bytes B" }
    if ($Bytes -lt 1MB) { return ("{0:N1} KB" -f ($Bytes / 1KB)) }
    if ($Bytes -lt 1GB) { return ("{0:N1} MB" -f ($Bytes / 1MB)) }
    if ($Bytes -lt 1TB) { return ("{0:N2} GB" -f ($Bytes / 1GB)) }
    return ("{0:N2} TB" -f ($Bytes / 1TB))
}

function Format-WMProgressBar {
    param(
        [double]$Percent,
        [int]$Width = 20
    )
    if ($Percent -lt 0) { $Percent = 0 }
    if ($Percent -gt 100) { $Percent = 100 }
    
    $fillCount = [int][math]::Round(($Percent / 100) * $Width)
    if ($fillCount -gt $Width) { $fillCount = $Width }
    $emptyCount = $Width - $fillCount

    $c = $global:WM_Color
    $g = $global:WM_Glyphs

    $color = $c.Success
    if ($Percent -ge 70 -and $Percent -lt 90) { $color = $c.Warning }
    if ($Percent -ge 90) { $color = $c.Danger }

    $filled = [string]::new($g.Block, $fillCount)
    $empty = [string]::new($g.Shade, $emptyCount)

    return ("{0}[{1}{2}{0}{3}]{4} {1}{5:N0}%{4}" -f $c.Muted, $color, $filled, $empty, $c.Reset, $Percent)
}

function Test-WMAdmin {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Write-WMHeader {
    param(
        [string]$Title = "WINMOLE",
        [string]$Subtitle = "Windows System Maintenance & Monitor"
    )
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    $isAdmin = Test-WMAdmin
    $adminTag = if ($isAdmin) { " " + $c.Danger + "[ADMIN]" + $c.Reset } else { "" }
    $divider = [string]::new($g.HLine, 61)
    
    Write-Host ""
    Write-Host ("  {0}{1}{2}{3}{4} {5}{6}{3} {7}{8}{3}" -f $c.Primary, $c.Bold, $Title, $c.Reset, $adminTag, $c.Muted, $g.Bullet, $c.Secondary, $Subtitle)
    Write-Host ("  {0}{1}{2}" -f $c.Muted, $divider, $c.Reset)
}

function Write-WMBannerBox {
    param(
        [string[]]$Lines,
        [int]$Width = 63
    )
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    $h = [string]::new($g.HLine, $Width - 2)

    Write-Host ("{0}{1}{2}{3}{4}" -f $c.Muted, $g.TopL, $h, $g.TopR, $c.Reset)
    foreach ($item in $Lines) {
        $plain = $item -replace "\x1B\[[0-9;]*[a-zA-Z]", ""
        $pad = $Width - 4 - $plain.Length
        if ($pad -lt 0) { $pad = 0 }
        $spaces = " " * $pad
        Write-Host ("{0}{1}{2} {3}{4} {0}{1}{2}" -f $c.Muted, $g.VLine, $c.Reset, $item, $spaces)
    }
    Write-Host ("{0}{1}{2}{3}{4}" -f $c.Muted, $g.BotL, $h, $g.BotR, $c.Reset)
}

function Write-WMPanel {
    param(
        [string]$Title,
        [string[]]$Lines,
        [int]$Width = 63
    )
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    $titleLen = $Title.Length + 4
    $hRight = $Width - 2 - $titleLen
    if ($hRight -lt 2) { $hRight = 2 }
    $hr1 = [string]::new($g.HLine, 2)
    $hr2 = [string]::new($g.HLine, $hRight)
    
    Write-Host ("{0}{1}{2}{3} {4}{5}{6}{7} {0}{8}{9}{3}" -f $c.Muted, $g.TopL, $hr1, $c.Reset, $c.Primary, $c.Bold, $Title, $c.Reset, $hr2, $g.TopR)
    foreach ($item in $Lines) {
        $plain = $item -replace "\x1B\[[0-9;]*[a-zA-Z]", ""
        $pad = $Width - 4 - $plain.Length
        if ($pad -lt 0) { $pad = 0 }
        $spaces = " " * $pad
        Write-Host ("{0}{1}{2} {3}{4} {0}{1}{2}" -f $c.Muted, $g.VLine, $c.Reset, $item, $spaces)
    }
    $hBottom = [string]::new($g.HLine, $Width - 2)
    Write-Host ("{0}{1}{2}{3}{4}" -f $c.Muted, $g.BotL, $hBottom, $g.BotR, $c.Reset)
}

function Write-WMSuccess {
    param([string]$Message)
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    Write-Host ("{0}{1} {2}{3}{4}" -f $c.Success, $g.Check, $c.Text, $Message, $c.Reset)
}

function Write-WMWarning {
    param([string]$Message)
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    Write-Host ("{0}{1} {2}{3}{4}" -f $c.Warning, $g.Warn, $c.Text, $Message, $c.Reset)
}

function Write-WMError {
    param([string]$Message)
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    Write-Host ("{0}{1} {2}{3}{4}" -f $c.Danger, $g.Cross, $c.Text, $Message, $c.Reset)
}

function Write-WMInfo {
    param([string]$Message)
    $c = $global:WM_Color
    Write-Host ("{0}[i] {1}{2}{3}" -f $c.Primary, $c.Text, $Message, $c.Reset)
}
