# WinMole Interactive Menu (Yoinks Design Language)
# Compatible with PowerShell 5.1 & PowerShell 7+

function Wait-WMMenuFallback {
    $c = $global:WM_Color
    $g = $global:WM_Glyphs

    if (-not [Environment]::UserInteractive -or [Console]::IsInputRedirected) {
        return $true
    }

    Write-Host ""
    # Yoinks-style action card
    Write-Host ("  {0}{1}{2}{3}" -f $c.Border, $g.TopL, ([string]::new($g.HLine, 26)), $g.TopR)
    Write-Host ("  {0}{1}{2}   {3}{4} return to menu{2}     {0}{1}{2}" -f $c.Border, $g.VLine, $c.Reset, $c.Primary, [char]0x21B5)
    Write-Host ("  {0}{1}{2}{3}" -f $c.Border, $g.BotL, ([string]::new($g.HLine, 26)), $g.BotR)
    Write-Host ""

    $shortcuts = @(
        @("esc", "menu"),
        @([char]0x21B5, "return"),
        @("q", "exit")
    )
    Write-WMShortcuts -Items $shortcuts

    while ($true) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Escape -or $key.Key -eq [ConsoleKey]::Enter -or $key.Key -eq [ConsoleKey]::Spacebar) {
            return $true
        } elseif ($key.KeyChar -eq 'q' -or ($key.Key -eq [ConsoleKey]::C -and $key.Modifiers -band [ConsoleModifiers]::Control)) {
            return $false
        }
    }
}

function Show-WinMoleMenu {
    $c = $global:WM_Color
    $g = $global:WM_Glyphs

    $menuOptions = @(
        @{ Key = "1"; Name = "System Status";   Desc = "Live hardware monitoring (bottom/btop)";  Cmd = "status" },
        @{ Key = "2"; Name = "Disk Analyzer";   Desc = "Interactive disk visualizer (gdu)";       Cmd = "analyze" },
        @{ Key = "3"; Name = "Purge Artifacts"; Desc = "Clean dev build junk (node_modules,...)";Cmd = "purge" },
        @{ Key = "4"; Name = "Clean Caches";    Desc = "Purge %TEMP%, crash dumps & junk";       Cmd = "clean" },
        @{ Key = "5"; Name = "Uninstall Apps";  Desc = "Search and remove applications (winget)"; Cmd = "uninstall" },
        @{ Key = "6"; Name = "System Doctor";   Desc = "Verify tool installation and health";    Cmd = "doctor" },
        @{ Key = "0"; Name = "Exit";            Desc = "Quit WinMole";                           Cmd = "exit" }
    )

    $selectedIndex = 0

    # Non-interactive fallback
    if (-not [Environment]::UserInteractive -or [Console]::IsInputRedirected) {
        Write-WMHeader -Title "WINMOLE" -Subtitle "System Maintenance Menu"
        foreach ($opt in $menuOptions) {
            Write-Host ("  [{0}] {1} {2}" -f $opt.Key, $opt.Name.PadRight(18), $opt.Desc)
        }
        return
    }

    $inMenuLoop = $true
    while ($inMenuLoop) {
        # Fetch live stats for snapshot panel
        $os = Get-CimInstance Win32_OperatingSystem
        $totalRamGB = [math]::Round(($os.TotalVisibleMemorySize * 1024) / 1GB, 1)
        $freeRamGB = [math]::Round(($os.FreePhysicalMemory * 1024) / 1GB, 1)
        $usedRamGB = [math]::Round($totalRamGB - $freeRamGB, 1)
        $ramPct = if ($totalRamGB -gt 0) { [math]::Round(($usedRamGB / $totalRamGB) * 100) } else { 0 }

        $cDrive = Get-PSDrive -Name C -ErrorAction SilentlyContinue
        $cFreeGB = if ($cDrive) { [math]::Round($cDrive.Free / 1GB) } else { 0 }

        $cpuPct = 0
        try {
            $cpuMetrics = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
            $cpuPct = [math]::Round($cpuMetrics.Average)
        } catch {}

        Write-Host ("{0}" -f $c.CursorHide) -NoNewline
        $cmdToRun = $null

        try {
            while ($true) {
                Write-Host ("{0}" -f $c.ClearScreen) -NoNewline

                # Yoinks block logo & tagline
                Write-WMLogo

                Write-Host ""

                # Yoinks-style Snapshot Panel
                $snapWidth = 72
                $snapLine = ("Host: {0}  {1}  CPU: {2}%  {1}  RAM: {3}/{4} GB ({5}%)  {1}  C: {6} GB free" -f $env:COMPUTERNAME, $g.Dot, $cpuPct, $usedRamGB, $totalRamGB, $ramPct, $cFreeGB)
                Write-WMPanel -Title "Snapshot" -Lines @($snapLine) -Width $snapWidth

                Write-Host ""

                # Yoinks-style Tasks Selection Panel
                $taskLines = @()
                for ($i = 0; $i -lt $menuOptions.Count; $i++) {
                    $opt = $menuOptions[$i]
                    $isSel = ($i -eq $selectedIndex)

                    $indicator = if ($isSel) { ("{0}{1}{2}" -f $c.Primary, $g.Point, $c.Reset) } else { " " }
                    $keyDisp   = if ($isSel) { ("{0}{1}{2}" -f $c.Primary, $opt.Key, $c.Reset) } else { ("{0}{1}{2}" -f $c.Muted, $opt.Key, $c.Reset) }
                    $nameDisp  = if ($isSel) { ("{0}{1}{2}" -f $c.Primary, $opt.Name.PadRight(18), $c.Reset) } else { ("{0}{1}{2}" -f $c.Text, $opt.Name.PadRight(18), $c.Reset) }
                    $descDisp  = if ($isSel) { ("{0}{1}{2}" -f $c.Secondary, $opt.Desc, $c.Reset) } else { ("{0}{1}{2}" -f $c.Muted, $opt.Desc, $c.Reset) }

                    $taskLines += ("{0} {1}  {2}  {3}" -f $indicator, $keyDisp, $nameDisp, $descDisp)
                }

                Write-WMPanel -Title "Tasks" -Lines $taskLines -Width $snapWidth

                Write-Host ""

                # Footer shortcuts
                $shortcuts = @(
                    @("esc/q", "exit"),
                    @([char]0x2191 + [char]0x2193, "choose"),
                    @([char]0x21B5, "select"),
                    @("1-6", "direct"),
                    @("^c", "quit")
                )
                Write-WMShortcuts -Items $shortcuts

                # Read key without blocking render
                $key = [Console]::ReadKey($true)

                if ($key.Key -eq [ConsoleKey]::UpArrow) {
                    $selectedIndex--
                    if ($selectedIndex -lt 0) { $selectedIndex = $menuOptions.Count - 1 }
                } elseif ($key.Key -eq [ConsoleKey]::DownArrow) {
                    $selectedIndex++
                    if ($selectedIndex -ge $menuOptions.Count) { $selectedIndex = 0 }
                } elseif ($key.Key -eq [ConsoleKey]::Enter) {
                    $cmdToRun = $menuOptions[$selectedIndex].Cmd
                    break
                } elseif ($key.KeyChar -eq 'q' -or $key.Key -eq [ConsoleKey]::Escape) {
                    $cmdToRun = "exit"
                    break
                } elseif ($key.KeyChar -ge '0' -and $key.KeyChar -le '6') {
                    $targetKey = $key.KeyChar.ToString()
                    $foundOpt = $menuOptions | Where-Object { $_.Key -eq $targetKey }
                    if ($foundOpt) {
                        $cmdToRun = $foundOpt.Cmd
                        break
                    }
                }
            }
        } finally {
            Write-Host ("{0}" -f $c.CursorShow) -NoNewline
        }

        if (-not $cmdToRun -or $cmdToRun -eq "exit") {
            break
        }

        Write-Host ""
        switch ($cmdToRun) {
            "status" {
                $statusRes = Invoke-WinMoleStatus -FromMenu
                if ($statusRes -eq "quit") {
                    $inMenuLoop = $false
                }
            }
            "analyze" {
                Invoke-WinMoleAnalyze
                $fallback = Wait-WMMenuFallback
                if (-not $fallback) { $inMenuLoop = $false }
            }
            "purge" {
                Invoke-WinMolePurge
                $fallback = Wait-WMMenuFallback
                if (-not $fallback) { $inMenuLoop = $false }
            }
            "clean" {
                Invoke-WinMoleClean
                $fallback = Wait-WMMenuFallback
                if (-not $fallback) { $inMenuLoop = $false }
            }
            "uninstall" {
                Invoke-WinMoleUninstall
                $fallback = Wait-WMMenuFallback
                if (-not $fallback) { $inMenuLoop = $false }
            }
            "doctor" {
                Invoke-WinMoleDoctor
                $fallback = Wait-WMMenuFallback
                if (-not $fallback) { $inMenuLoop = $false }
            }
        }
    }
}
