# WinMole UI & ANSI Renderer (Yoinks Design Language)
# Compatible with PowerShell 5.1 & PowerShell 7+ across all Windows codepages

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

# Glyph Map using pure char codes for universal ASCII/Unicode encoding safety
$global:WM_Glyphs = @{
    HLine    = [char]0x2500  # -
    VLine    = [char]0x2502  # |
    TopL     = [char]0x256D  # /
    TopR     = [char]0x256E  # \
    BotL     = [char]0x2570  # \
    BotR     = [char]0x256F  # /
    Block    = [char]0x2588  # full block
    Shade    = [char]0x2591  # light shade
    Medium   = [char]0x2592  # medium shade
    Dark     = [char]0x2593  # dark shade
    HalfTop  = [char]0x2580  # upper half block
    HalfBot  = [char]0x2584  # lower half block
    Check    = [char]0x2713  # check mark
    Warn     = [char]0x25B2  # warning triangle
    Cross    = [char]0x2717  # cross
    Point    = [char]0x276F  # heavy right chevron
    Dot      = [char]0x00B7  # middle dot
    Bullet   = [char]0x00B7  # middle dot
    Arrow    = [char]0x25B8  # right triangle
    Enter    = [char]0x21B5  # return arrow
}

if ($global:WM_HasVT) {
    # Yoinks-inspired minimal monochrome & zinc palette
    $global:WM_Color = @{
        Reset        = "$($global:WM_ESC)[0m"
        Bold         = "$($global:WM_ESC)[1m"
        Dim          = "$($global:WM_ESC)[2m"
        Inverse      = "$($global:WM_ESC)[7m"
        Primary      = "$($global:WM_ESC)[1;97m"               # Bold bright white
        Secondary    = "$($global:WM_ESC)[38;2;161;161;170m"   # Zinc 400 (slate light)
        Muted        = "$($global:WM_ESC)[38;2;113;113;122m"   # Zinc 500 (dim text/dots)
        Border       = "$($global:WM_ESC)[38;2;82;82;91m"     # Zinc 600 (subtle frame borders)
        Success      = "$($global:WM_ESC)[38;2;52;211;153m"    # Emerald 400
        Warning      = "$($global:WM_ESC)[38;2;251;191;36m"    # Amber 400
        Danger       = "$($global:WM_ESC)[38;2;248;113;113m"   # Rose 400
        Text         = "$($global:WM_ESC)[38;2;244;244;245m"   # Zinc 100
        BgHighlight  = "$($global:WM_ESC)[48;2;39;39;42m"     # Zinc 800 subtle card highlight
        ClearScreen  = "$($global:WM_ESC)[2J$($global:WM_ESC)[H"
        CursorHome   = "$($global:WM_ESC)[H"
        ClearLine    = "$($global:WM_ESC)[K"
        CursorHide   = "$($global:WM_ESC)[?25l"
        CursorShow   = "$($global:WM_ESC)[?25h"
    }
} else {
    $global:WM_Color = @{
        Reset        = ""
        Bold         = ""
        Dim          = ""
        Inverse      = ""
        Primary      = ""
        Secondary    = ""
        Muted        = ""
        Border       = ""
        Success      = ""
        Warning      = ""
        Danger       = ""
        Text         = ""
        BgHighlight  = ""
        ClearScreen  = ""
        CursorHome   = ""
        ClearLine    = ""
        CursorHide   = ""
        CursorShow   = ""
    }
}

function Clear-WMScreen {
    try {
        Clear-Host
    } catch {
        if ($global:WM_HasVT) {
            Write-Host ("{0}[2J{0}[H" -f $global:WM_ESC) -NoNewline
        }
    }
}

function Move-WMCursorHome {
    if ($global:WM_HasVT) {
        Write-Host ("{0}[H" -f $global:WM_ESC) -NoNewline
    } else {
        try {
            [Console]::SetCursorPosition(0, 0)
        } catch {
            try {
                $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0, 0
            } catch {}
        }
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
        [int]$Width = 24
    )
    if ($Percent -lt 0) { $Percent = 0 }
    if ($Percent -gt 100) { $Percent = 100 }
    
    $fillCount = [int][math]::Round(($Percent / 100) * $Width)
    if ($fillCount -gt $Width) { $fillCount = $Width }
    $emptyCount = $Width - $fillCount

    $c = $global:WM_Color
    $g = $global:WM_Glyphs

    $color = $c.Primary
    if ($Percent -ge 75 -and $Percent -lt 90) { $color = $c.Warning }
    if ($Percent -ge 90) { $color = $c.Danger }

    $filled = [string]::new($g.Block, $fillCount)
    $empty = [string]::new($g.Shade, $emptyCount)

    return ("{0}{1}{2}{3}{4} {5}{6,4:N0}%{4}" -f $color, $filled, $c.Border, $empty, $c.Reset, $c.Primary, $Percent)
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

function Write-WMLogo {
    $c = $global:WM_Color
    $g = $global:WM_Glyphs

    $b = $g.Block    # █
    $d = $g.Dark     # ▓
    $t = $g.HalfTop  # ▀
    $u = $g.HalfBot  # ▄

    # Pablo Stanley / Yoinks compact 3-row block art for WINMOLE
    $row0 = -join @($b, ' ', $d, ' ', $b, ' ', $t, $b, $t, ' ', $b, $t, $b, ' ', $b, $t, $u, $t, $b, ' ', $b, $t, $b, ' ', $b, '   ', $b, $t, $t)
    $row1 = -join @($b, ' ', $b, ' ', $b, '  ', $d, '  ', $b, ' ', $d, ' ', $b, ' ', $d, ' ', $b, ' ', $b, ' ', $d, ' ', $b, '   ', $b, $t, $t)
    $row2 = -join @(' ', $t, ' ', $t, '  ', $t, $t, $t, ' ', $t, ' ', $t, ' ', $t, '   ', $t, ' ', $t, $t, $t, ' ', $t, $t, $t, ' ', $t, $t, $t)

    Write-Host ("  {0}{1}{2}{3}" -f $c.Primary, $row0, $c.Reset, $c.ClearLine)
    Write-Host ("  {0}{1}{2}{3}" -f $c.Primary, $row1, $c.Reset, $c.ClearLine)
    Write-Host ("  {0}{1}{2}{3}" -f $c.Primary, $row2, $c.Reset, $c.ClearLine)
    Write-Host ("{0}" -f $c.ClearLine)
    Write-Host ("  {0}clean any junk. status. purge. done.{1}{2}" -f $c.Primary, $c.Reset, $c.ClearLine)
    Write-Host ("  {0}temp {1} crash dumps {1} node_modules {1} target {1} .venv {1} winget{2}{3}" -f $c.Muted, $g.Dot, $c.Reset, $c.ClearLine)
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
    $divider = [string]::new($g.HLine, 65)
    
    Write-Host ""
    Write-Host ("  {0}{1}{2}{3}{4}  {5}{6}{3}  {7}{8}{3}{9}" -f $c.Primary, $c.Bold, $Title, $c.Reset, $adminTag, $c.Border, $g.Dot, $c.Secondary, $Subtitle, $c.ClearLine)
    Write-Host ("  {0}{1}{2}{3}" -f $c.Border, $divider, $c.Reset, $c.ClearLine)
}

function Write-WMPanel {
    param(
        [string]$Title,
        [string[]]$Lines,
        [int]$Width = 67
    )
    $c = $global:WM_Color
    $g = $global:WM_Glyphs

    # Yoinks-style panel with embedded top title
    $inner = $Width - 2
    $titleStr = " $Title "
    $tailLen = $inner - 1 - $titleStr.Length
    if ($tailLen -lt 1) { $tailLen = 1 }
    $tail = [string]::new($g.HLine, $tailLen)

    Write-Host ("  {0}{1}{2}{3}{4}{5}{0}{6}{7}{3}{8}" -f $c.Border, $g.TopL, $g.HLine, $c.Reset, $c.Primary, $titleStr, $tail, $g.TopR, $c.ClearLine)
    
    foreach ($item in $Lines) {
        $plain = $item -replace "\x1B\[[0-9;]*[a-zA-Z]", ""
        $pad = $Width - 4 - $plain.Length
        if ($pad -lt 0) { $pad = 0 }
        $spaces = " " * $pad
        Write-Host ("  {0}{1}{2} {3}{4} {0}{1}{2}{5}" -f $c.Border, $g.VLine, $c.Reset, $item, $spaces, $c.ClearLine)
    }

    $hBottom = [string]::new($g.HLine, $inner)
    Write-Host ("  {0}{1}{2}{3}{4}{5}" -f $c.Border, $g.BotL, $hBottom, $g.BotR, $c.Reset, $c.ClearLine)
}

function Write-WMBannerBox {
    param(
        [string[]]$Lines,
        [int]$Width = 67
    )
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    $h = [string]::new($g.HLine, $Width - 2)

    Write-Host ("  {0}{1}{2}{3}{4}{5}" -f $c.Border, $g.TopL, $h, $g.TopR, $c.Reset, $c.ClearLine)
    foreach ($item in $Lines) {
        $plain = $item -replace "\x1B\[[0-9;]*[a-zA-Z]", ""
        $pad = $Width - 4 - $plain.Length
        if ($pad -lt 0) { $pad = 0 }
        $spaces = " " * $pad
        Write-Host ("  {0}{1}{2} {3}{4} {0}{1}{2}{5}" -f $c.Border, $g.VLine, $c.Reset, $item, $spaces, $c.ClearLine)
    }
    Write-Host ("  {0}{1}{2}{3}{4}{5}" -f $c.Border, $g.BotL, $h, $g.BotR, $c.Reset, $c.ClearLine)
}

function Write-WMShortcuts {
    param(
        [array]$Items,
        [string]$Leading = ""
    )
    $c = $global:WM_Color
    $g = $global:WM_Glyphs

    $parts = @()
    if ($Leading) {
        $parts += $Leading
    }

    foreach ($entry in $Items) {
        $key = $entry[0]
        $label = $entry[1]
        $parts += ("{0}{1}{2} {3}{4}{2}" -f $c.Primary, $key, $c.Reset, $c.Muted, $label)
    }

    $sep = ("  {0}{1}{2}  " -f $c.Border, $g.Dot, $c.Reset)
    Write-Host ("  " + ($parts -join $sep) + $c.ClearLine)
}

function Write-WMSuccess {
    param([string]$Message)
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    Write-Host ("  {0}{1}{2} {3}{4}{2}" -f $c.Success, $g.Check, $c.Reset, $c.Text, $Message)
}

function Write-WMWarning {
    param([string]$Message)
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    Write-Host ("  {0}{1}{2} {3}{4}{2}" -f $c.Warning, $g.Warn, $c.Reset, $c.Secondary, $Message)
}

function Write-WMError {
    param([string]$Message)
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    Write-Host ("  {0}{1}{2} {3}{4}{2}" -f $c.Danger, $g.Cross, $c.Reset, $c.Text, $Message)
}

function Write-WMInfo {
    param([string]$Message)
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    Write-Host ("  {0}{1}{2} {3}{4}{2}" -f $c.Secondary, $g.Arrow, $c.Reset, $c.Secondary, $Message)
}
