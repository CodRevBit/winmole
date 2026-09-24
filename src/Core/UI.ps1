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

function Get-WMConsoleWidth {
    try {
        if ([Console]::WindowWidth -gt 20) {
            return [Console]::WindowWidth
        }
    } catch {}
    try {
        if ($Host.UI.RawUI.WindowSize.Width -gt 20) {
            return $Host.UI.RawUI.WindowSize.Width
        }
    } catch {}
    return 80
}

function Get-WMMargin {
    param([int]$ContentWidth = 76)
    $consoleWidth = Get-WMConsoleWidth
    $marginLen = [math]::Max(2, [int][math]::Floor(($consoleWidth - $ContentWidth) / 2))
    return (" " * $marginLen)
}

function Write-WMLogo {
    param(
        [int]$Width = 76
    )
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

    $tagline = "clean any junk. status. purge. done."
    $subline = "temp {0} crash dumps {0} node_modules {0} target {0} .venv {0} winget" -f $g.Dot

    $consoleWidth = Get-WMConsoleWidth
    $pad0   = [math]::Max(2, [int][math]::Floor(($consoleWidth - $row0.Length) / 2))
    $padTag = [math]::Max(2, [int][math]::Floor(($consoleWidth - $tagline.Length) / 2))
    $padSub = [math]::Max(2, [int][math]::Floor(($consoleWidth - $subline.Length) / 2))

    Write-Host ("{0}{1}{2}{3}{4}" -f (" " * $pad0), $c.Primary, $row0, $c.Reset, $c.ClearLine)
    Write-Host ("{0}{1}{2}{3}{4}" -f (" " * $pad0), $c.Primary, $row1, $c.Reset, $c.ClearLine)
    Write-Host ("{0}{1}{2}{3}{4}" -f (" " * $pad0), $c.Primary, $row2, $c.Reset, $c.ClearLine)
    Write-Host ("{0}" -f $c.ClearLine)
    Write-Host ("{0}{1}{2}{3}{4}" -f (" " * $padTag), $c.Primary, $tagline, $c.Reset, $c.ClearLine)
    Write-Host ("{0}{1}{2}{3}{4}" -f (" " * $padSub), $c.Muted, $subline, $c.Reset, $c.ClearLine)
}

function Write-WMHeader {
    param(
        [string]$Title = "WINMOLE",
        [string]$Subtitle = "Windows System Maintenance & Monitor",
        [int]$Width = 76
    )
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    $isAdmin = Test-WMAdmin
    $adminTag = if ($isAdmin) { " " + $c.Danger + "[ADMIN]" + $c.Reset } else { "" }
    $adminPlain = if ($isAdmin) { " [ADMIN]" } else { "" }
    
    $headPlain = "{0}{1}  {2}  {3}" -f $Title, $adminPlain, $g.Dot, $Subtitle
    $dividerLen = [math]::Max($Width, $headPlain.Length)

    $consoleWidth = Get-WMConsoleWidth
    $marginLen = [math]::Max(2, [int][math]::Floor(($consoleWidth - $dividerLen) / 2))
    $margin = " " * $marginLen

    $divider = [string]::new($g.HLine, $dividerLen)
    
    Write-Host ""
    Write-Host ("{0}{1}{2}{3}{4}{5}  {6}{7}{4}  {8}{9}{4}{10}" -f $margin, $c.Primary, $c.Bold, $Title, $c.Reset, $adminTag, $c.Border, $g.Dot, $c.Secondary, $Subtitle, $c.ClearLine)
    Write-Host ("{0}{1}{2}{3}{4}" -f $margin, $c.Border, $divider, $c.Reset, $c.ClearLine)
}

function Write-WMPanel {
    param(
        [string]$Title,
        [string[]]$Lines,
        [int]$Width = 76,
        [switch]$CenterLines
    )
    $c = $global:WM_Color
    $g = $global:WM_Glyphs

    $consoleWidth = Get-WMConsoleWidth
    $effectiveWidth = if ($consoleWidth -gt 24 -and $consoleWidth -lt $Width) { $consoleWidth - 2 } else { $Width }
    $marginLen = [math]::Max(2, [int][math]::Floor(($consoleWidth - $effectiveWidth) / 2))
    $margin = " " * $marginLen

    # Yoinks-style panel with embedded top title
    $inner = $effectiveWidth - 2
    $titleStr = " $Title "
    $tailLen = $inner - 1 - $titleStr.Length
    if ($tailLen -lt 1) { $tailLen = 1 }
    $tail = [string]::new($g.HLine, $tailLen)

    Write-Host ("{0}{1}{2}{3}{4}{5}{6}{1}{7}{8}{4}{9}" -f $margin, $c.Border, $g.TopL, $g.HLine, $c.Reset, $c.Primary, $titleStr, $tail, $g.TopR, $c.ClearLine)
    
    foreach ($item in $Lines) {
        $plain = $item -replace "\x1B\[[0-9;]*[a-zA-Z]", ""
        $pad = $effectiveWidth - 4 - $plain.Length
        if ($pad -lt 0) { $pad = 0 }
        if ($CenterLines) {
            $leftPad = [int][math]::Floor($pad / 2)
            $rightPad = $pad - $leftPad
            Write-Host ("{0}{1}{2}{3} {4}{5}{6} {1}{2}{3}{7}" -f $margin, $c.Border, $g.VLine, $c.Reset, (" " * $leftPad), $item, (" " * $rightPad), $c.ClearLine)
        } else {
            $spaces = " " * $pad
            Write-Host ("{0}{1}{2}{3} {4}{5} {1}{2}{3}{6}" -f $margin, $c.Border, $g.VLine, $c.Reset, $item, $spaces, $c.ClearLine)
        }
    }

    $hBottom = [string]::new($g.HLine, $inner)
    Write-Host ("{0}{1}{2}{3}{4}{5}{6}" -f $margin, $c.Border, $g.BotL, $hBottom, $g.BotR, $c.Reset, $c.ClearLine)
}

function Write-WMBannerBox {
    param(
        [string[]]$Lines,
        [int]$Width = 76,
        [switch]$CenterLines
    )
    $c = $global:WM_Color
    $g = $global:WM_Glyphs

    $consoleWidth = Get-WMConsoleWidth
    $effectiveWidth = if ($consoleWidth -gt 24 -and $consoleWidth -lt $Width) { $consoleWidth - 2 } else { $Width }
    $marginLen = [math]::Max(2, [int][math]::Floor(($consoleWidth - $effectiveWidth) / 2))
    $margin = " " * $marginLen

    $h = [string]::new($g.HLine, $effectiveWidth - 2)

    Write-Host ("{0}{1}{2}{3}{4}{5}" -f $margin, $c.Border, $g.TopL, $h, $g.TopR, $c.Reset, $c.ClearLine)
    foreach ($item in $Lines) {
        $plain = $item -replace "\x1B\[[0-9;]*[a-zA-Z]", ""
        $pad = $effectiveWidth - 4 - $plain.Length
        if ($pad -lt 0) { $pad = 0 }
        if ($CenterLines) {
            $leftPad = [int][math]::Floor($pad / 2)
            $rightPad = $pad - $leftPad
            Write-Host ("{0}{1}{2}{3} {4}{5}{6} {1}{2}{3}{7}" -f $margin, $c.Border, $g.VLine, $c.Reset, (" " * $leftPad), $item, (" " * $rightPad), $c.ClearLine)
        } else {
            $spaces = " " * $pad
            Write-Host ("{0}{1}{2}{3} {4}{5} {1}{2}{3}{6}" -f $margin, $c.Border, $g.VLine, $c.Reset, $item, $spaces, $c.ClearLine)
        }
    }
    Write-Host ("{0}{1}{2}{3}{4}{5}" -f $margin, $c.Border, $g.BotL, $h, $g.BotR, $c.Reset, $c.ClearLine)
}

function Write-WMShortcuts {
    param(
        [array]$Items,
        [string]$Leading = "",
        [int]$Width = 76
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
    $joined = $parts -join $sep

    $plain = $joined -replace "\x1B\[[0-9;]*[a-zA-Z]", ""
    $consoleWidth = Get-WMConsoleWidth
    $pad = [math]::Max(2, [int][math]::Floor(($consoleWidth - $plain.Length) / 2))
    $margin = " " * $pad

    Write-Host ($margin + $joined + $c.ClearLine)
}

function Write-WMSuccess {
    param([string]$Message, [int]$Width = 76)
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    $margin = Get-WMMargin -ContentWidth $Width
    Write-Host ("{0}{1}{2}{3} {4}{5}{3}" -f $margin, $c.Success, $g.Check, $c.Reset, $c.Text, $Message)
}

function Write-WMWarning {
    param([string]$Message, [int]$Width = 76)
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    $margin = Get-WMMargin -ContentWidth $Width
    Write-Host ("{0}{1}{2}{3} {4}{5}{3}" -f $margin, $c.Warning, $g.Warn, $c.Reset, $c.Secondary, $Message)
}

function Write-WMError {
    param([string]$Message, [int]$Width = 76)
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    $margin = Get-WMMargin -ContentWidth $Width
    Write-Host ("{0}{1}{2}{3} {4}{5}{3}" -f $margin, $c.Danger, $g.Cross, $c.Reset, $c.Text, $Message)
}

function Write-WMInfo {
    param([string]$Message, [int]$Width = 76)
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    $margin = Get-WMMargin -ContentWidth $Width
    Write-Host ("{0}{1}{2}{3} {4}{5}{3}" -f $margin, $c.Secondary, $g.Arrow, $c.Reset, $c.Secondary, $Message)
}
