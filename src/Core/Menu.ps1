# WinMole Interactive Menu
# Compatible with PowerShell 5.1 & PowerShell 7+

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

    # Get quick snapshot stats for the banner
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

    # Check if console is interactive
    if (-not [Environment]::UserInteractive -or [Console]::IsInputRedirected) {
        Write-WMHeader -Title "WINMOLE" -Subtitle "System Maintenance Menu"
        foreach ($opt in $menuOptions) {
            Write-Host ("  [{0}] {1} {2}" -f $opt.Key, $opt.Name.PadRight(18), $opt.Desc)
        }
        return
    }

    Write-Host ("{0}" -f $c.CursorHide) -NoNewline

    try {
        while ($true) {
            Write-Host ("{0}" -f $c.ClearScreen) -NoNewline

            # Banner
            $bannerLines = @(
                ("WINMOLE v1.0.0  {0}  Windows System Maintenance & Monitor" -f $g.Bullet),
                ("Host: {0}  {1}  OS: {2} ({3})" -f $env:COMPUTERNAME, $g.Bullet, $os.Caption, $os.OSArchitecture),
                ("CPU: {0}%  {1}  RAM: {2} / {3} GB ({4}%)  {1}  C: {5} GB Free" -f $cpuPct, $g.Bullet, $usedRamGB, $totalRamGB, $ramPct, $cFreeGB)
            )
            Write-WMBannerBox -Lines $bannerLines -Width 67

            Write-Host ""
            Write-Host ("  {0}Use {1}[Up/Down]{0} or {1}[1-6]{0} to select, {1}[Enter]{0} to run, {1}[q]{0} to exit:{2}" -f $c.Muted, $c.Text, $c.Reset)
            Write-Host ""

            for ($i = 0; $i -lt $menuOptions.Count; $i++) {
                $opt = $menuOptions[$i]
                $isSel = ($i -eq $selectedIndex)

                $pointer = if ($isSel) { ("{0}{1}{2} " -f $c.Primary, $g.Point, $c.Reset) } else { "  " }
                $keyDisplay = if ($isSel) { ("{0}[{1}]{2}" -f $c.Primary, $opt.Key, $c.Reset) } else { ("{0}[{1}]{2}" -f $c.Muted, $opt.Key, $c.Reset) }
                $nameDisplay = if ($isSel) { ("{0}{1}{2}{3}" -f $c.Bold, $c.Text, $opt.Name.PadRight(18), $c.Reset) } else { ("{0}{1}{2}" -f $c.Text, $opt.Name.PadRight(18), $c.Reset) }
                $descDisplay = if ($isSel) { ("{0}{1}{2}" -f $c.Secondary, $opt.Desc, $c.Reset) } else { ("{0}{1}{2}" -f $c.Muted, $opt.Desc, $c.Reset) }

                Write-Host ("{0}{1}  {2}  {3}" -f $pointer, $keyDisplay, $nameDisplay, $descDisplay)
            }

            $div = [string]::new($g.HLine, 65)
            Write-Host ""
            Write-Host ("  {0}{1}{2}" -f $c.Muted, $div, $c.Reset)
            Write-Host ("  {0}Tip: Run {1}'mo <command>'{0} directly from any shell (e.g. {2}'mo clean'{0}){3}" -f $c.Muted, $c.Primary, $c.Text, $c.Reset)

            # Read Key
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

    if ($cmdToRun -and $cmdToRun -ne "exit") {
        Write-Host ""
        switch ($cmdToRun) {
            "status"    { Invoke-WinMoleStatus }
            "analyze"   { Invoke-WinMoleAnalyze }
            "purge"     { Invoke-WinMolePurge }
            "clean"     { Invoke-WinMoleClean }
            "uninstall" { Invoke-WinMoleUninstall }
            "doctor"    { Invoke-WinMoleDoctor }
        }
    }
}
