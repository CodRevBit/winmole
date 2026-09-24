# WinMole Status Command (Live System Monitor)
# Compatible with PowerShell 5.1 & PowerShell 7+

function Invoke-WinMoleStatus {
    param(
        [switch]$Native,
        [switch]$FromMenu
    )

    $resolution = Resolve-WinMoleTool -Subcommand "status" -PreferNative:$Native
    if ($resolution.Mode -eq "cancel") { return "menu" }

    if ($resolution.Mode -eq "binary" -and $resolution.Binary) {
        & $resolution.Binary
        if ($FromMenu) {
            $fallback = Wait-WMMenuFallback
            if (-not $fallback) { return "quit" }
            return "menu"
        }
        return "quit"
    }

    # Native PowerShell live monitoring fallback
    $statusResult = Invoke-WinMoleNativeStatus -FromMenu:$FromMenu
    if ($statusResult -eq "menu" -and -not $FromMenu) {
        if (Get-Command Show-WinMoleMenu -ErrorAction SilentlyContinue) {
            Show-WinMoleMenu
        }
    }
    return $statusResult
}

function Invoke-WinMoleNativeStatus {
    param(
        [switch]$FromMenu
    )
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    
    $cpuInfo = Get-CimInstance Win32_Processor | Select-Object -First 1 Name, NumberOfCores, NumberOfLogicalProcessors
    $cpuName = if ($cpuInfo.Name) { $cpuInfo.Name.Trim() } else { "Generic CPU" }
    $cpuDetails = "{0} Cores / {1} Threads" -f $cpuInfo.NumberOfCores, $cpuInfo.NumberOfLogicalProcessors

    Clear-WMScreen
    Write-Host ("{0}" -f $c.CursorHide) -NoNewline

    $statusResult = "quit"
    try {
        while ($true) {
            # Check keypress without blocking
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq [ConsoleKey]::Escape) {
                    $statusResult = "menu"
                    break
                } elseif ($key.KeyChar -eq 'q') {
                    $statusResult = "quit"
                    break
                }
            }

            # 1. Fetch CPU Usage
            $cpuPct = 0
            try {
                $cpuMetrics = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
                $cpuPct = [math]::Round($cpuMetrics.Average, 1)
            } catch {
                $cpuPct = 0
            }

            # 2. Fetch Memory Usage
            $os = Get-CimInstance Win32_OperatingSystem
            $totalRamBytes = [int64]$os.TotalVisibleMemorySize * 1024
            $freeRamBytes = [int64]$os.FreePhysicalMemory * 1024
            $usedRamBytes = $totalRamBytes - $freeRamBytes
            $ramPct = if ($totalRamBytes -gt 0) { [math]::Round(($usedRamBytes / $totalRamBytes) * 100, 1) } else { 0 }

            # 3. Fetch Drive Usages
            $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null -and $_.Used -ne $null }

            # 4. Fetch Top Processes
            $topProcs = Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 5

            # Uptime
            $uptime = (Get-Date) - $os.LastBootUpTime
            $uptimeStr = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes

            # Render Screen Buffer
            Write-Host ("{0}[H" -f $global:WM_ESC) -NoNewline
            Write-WMHeader -Title "WINMOLE STATUS" -Subtitle "Live Terminal Monitor" -Width 76
            Write-WMShortcuts -Items @(@("esc", "menu"), @("q", "exit"), @("r", "refresh")) -Width 76
            Write-Host ""

            # Panel 1: Hardware Summary
            $hwLines = @(
                ("CPU: {0}{1}{2} ({3})" -f $c.Text, $cpuName, $c.Reset, $cpuDetails),
                ("     {0}" -f (Format-WMProgressBar -Percent $cpuPct -Width 24)),
                "",
                ("Memory: {0}{1} / {2}{3}" -f $c.Text, (Format-WMBytes $usedRamBytes), (Format-WMBytes $totalRamBytes), $c.Reset),
                ("     {0}" -f (Format-WMProgressBar -Percent $ramPct -Width 24)),
                "",
                ("System Uptime: {0}{1}{2}  {3}  OS: {4}{5}{2}" -f $c.Secondary, $uptimeStr, $c.Reset, $g.Dot, $c.Text, $os.Caption)
            )
            Write-WMPanel -Title "Hardware Overview" -Lines $hwLines -Width 76

            # Panel 2: Storage Drives
            $driveLines = @()
            foreach ($d in $drives) {
                $totalDrive = $d.Used + $d.Free
                $drivePct = if ($totalDrive -gt 0) { [math]::Round(($d.Used / $totalDrive) * 100, 1) } else { 0 }
                $driveLines += ("Drive {0}{1}:{2}  {3}  {4} free of {5}" -f $c.Bold, $d.Name, $c.Reset, (Format-WMProgressBar -Percent $drivePct -Width 18), (Format-WMBytes $d.Free), (Format-WMBytes $totalDrive))
            }
            Write-WMPanel -Title "Storage Drives" -Lines $driveLines -Width 76

            # Panel 3: Top Processes
            $procDiv = [string]::new($g.HLine, 72)
            $procLines = @(
                ("{0}PID       Process Name                    Memory        Handles{1}" -f $c.Muted, $c.Reset),
                ("{0}{1}{2}" -f $c.Border, $procDiv, $c.Reset)
            )
            foreach ($p in $topProcs) {
                $pName = if ($p.ProcessName.Length -gt 28) { $p.ProcessName.Substring(0, 25) + "..." } else { $p.ProcessName }
                $pNamePadded = $pName.PadRight(30)
                $pidPadded = $p.Id.ToString().PadRight(8)
                $memPadded = (Format-WMBytes $p.WorkingSet).PadRight(12)
                $procLines += ("{0}{1}{2}{3}{4}{5}" -f $c.Text, $pidPadded, $pNamePadded, $memPadded, $p.Handles, $c.Reset)
            }
            Write-WMPanel -Title "Top Processes by Memory" -Lines $procLines -Width 76

            Start-Sleep -Milliseconds 1000
        }
    } finally {
        Write-Host ("{0}" -f $c.CursorShow) -NoNewline
        Write-Host ""
    }
    return $statusResult
}
