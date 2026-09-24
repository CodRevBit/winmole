# WinMole Clean Command (Temporary Files & System Cache Cleaner)
# Compatible with PowerShell 5.1 & PowerShell 7+

function Invoke-WinMoleClean {
    param(
        [switch]$DryRun,
        [switch]$Force,
        [switch]$All
    )

    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    $isAdmin = Test-WMAdmin
    $title = if ($DryRun) { "Cache & Temp Cleaner [DRY RUN]" } else { "Cache & Temp Cleaner" }
    Write-WMHeader -Title "WINMOLE CLEAN" -Subtitle $title

    # Targets to scan
    $targets = @(
        @{
            Id = "user_temp"
            Name = "User Temporary Files (%TEMP%)"
            Path = $env:TEMP
            RequiresAdmin = $false
        },
        @{
            Id = "crash_dumps"
            Name = "Windows Error Crash Dumps"
            Path = (Join-Path $env:LOCALAPPDATA "CrashDumps")
            RequiresAdmin = $false
        },
        @{
            Id = "system_temp"
            Name = "Windows System Temp"
            Path = (Join-Path $env:SystemRoot "Temp")
            RequiresAdmin = $true
        }
    )

    if ($All) {
        $targets += @{
            Id = "prefetch"
            Name = "Windows Prefetch Cache"
            Path = (Join-Path $env:SystemRoot "Prefetch")
            RequiresAdmin = $true
        }
    }

    $results = @()
    $totalReclaimableBytes = 0
    $totalFiles = 0

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    foreach ($t in $targets) {
        if ($t.RequiresAdmin -and -not $isAdmin) {
            $results += [PSCustomObject]@{
                Target = $t.Name
                Status = "Skipped"
                Reason = "Requires Administrator shell"
                FileCount = 0
                Bytes = 0
                Files = @()
            }
            continue
        }

        if (-not (Test-Path $t.Path)) {
            continue
        }

        $targetDir = New-Object System.IO.DirectoryInfo($t.Path)
        $tBytes = 0
        $tCount = 0
        $tFiles = @()

        try {
            $files = $targetDir.EnumerateFiles("*", [System.IO.SearchOption]::AllDirectories)
            foreach ($f in $files) {
                $age = (Get-Date) - $f.LastWriteTime
                if ($age.TotalHours -ge 1) {
                    $tBytes += $f.Length
                    $tCount++
                    $tFiles += $f.FullName
                }
            }
        } catch {}

        $results += [PSCustomObject]@{
            Target = $t.Name
            Status = "Scanned"
            Reason = "OK"
            FileCount = $tCount
            Bytes = $tBytes
            Files = $tFiles
            Path = $t.Path
        }

        $totalReclaimableBytes += $tBytes
        $totalFiles += $tCount
    }

    $sw.Stop()

    # Summary Panel
    Write-Host ""
    $statusText = if ($DryRun) { "Simulation / Dry-Run (No files touched)" } else { "Scan Complete" }
    $sumLines = @(
        ("Status: {0}{1}{2}" -f $c.Text, $statusText, $c.Reset),
        ("Eligible Files Found: {0}{1:N0} files{2}  {3}  Time: {4} ms" -f $c.Warning, $totalFiles, $c.Reset, $g.Dot, $sw.ElapsedMilliseconds),
        ("Total Reclaimable Space: {0}{1}{2}{3}" -f $c.Bold, $c.Success, (Format-WMBytes $totalReclaimableBytes), $c.Reset)
    )
    Write-WMPanel -Title "Cleanup Summary" -Lines $sumLines -Width 67

    $div = [string]::new($g.HLine, 67)
    Write-Host ""
    Write-Host ("  {0}Target Category                        Files        Reclaimable Size{1}" -f $c.Muted, $c.Reset)
    Write-Host ("  {0}{1}{2}" -f $c.Border, $div, $c.Reset)

    foreach ($r in $results) {
        $targetPadded = $r.Target.PadRight(38)
        if ($r.Status -eq "Skipped") {
            Write-Host ("  {0}{1}{2}Skipped      {3}{4}" -f $c.Text, $targetPadded, $c.Muted, $r.Reason, $c.Reset)
        } else {
            $countPadded = ("{0:N0}" -f $r.FileCount).PadRight(13)
            $sizePadded = Format-WMBytes $r.Bytes
            Write-Host ("  {0}{1}{2}{3}{4}{5}" -f $c.Text, $targetPadded, $countPadded, $c.Success, $sizePadded, $c.Reset)
        }
    }
    Write-Host ""

    if (-not $isAdmin) {
        Write-WMInfo "Tip: Run WinMole from an Administrator terminal to include Windows System Temp."
        Write-Host ""
    }

    if ($DryRun) {
        Write-WMInfo "[DRY RUN PREVIEW] Zero files were deleted. Re-run without --dry-run to perform cleanup."
        Write-WinMoleLog -Subcommand "clean" -BytesFreed 0 -FilesDeleted 0 -ErrorsCount 0 -DryRun $true -DurationMs $sw.ElapsedMilliseconds
        return
    }

    if ($totalFiles -eq 0) {
        Write-WMSuccess "All temporary cache locations are already clean!"
        return
    }

    # Confirmation
    $confirmed = $Force
    if (-not $confirmed) {
        if (-not [Environment]::UserInteractive -or [Console]::IsInputRedirected) {
            Write-WMWarning "Non-interactive environment detected without --force. Cleanup aborted for safety."
            return
        }
        $resp = Read-Host ("  Proceed with cleaning {0} files ({1})? [y/N]" -f $totalFiles, (Format-WMBytes $totalReclaimableBytes))
        if ($resp -match "^[yY](es)?$") {
            $confirmed = $true
        }
    }

    if (-not $confirmed) {
        Write-WMWarning "Cleanup aborted by user."
        return
    }

    # Execute file deletions safely
    $deletedFiles = 0
    $freedBytes = 0
    $lockedFiles = 0

    Write-WMInfo "Cleaning temporary files..."
    foreach ($r in $results) {
        if ($r.Status -ne "Scanned") { continue }
        foreach ($filePath in $r.Files) {
            try {
                $fi = New-Object System.IO.FileInfo($filePath)
                $len = $fi.Length
                [System.IO.File]::Delete($filePath)
                $deletedFiles++
                $freedBytes += $len
            } catch {
                $lockedFiles++
            }
        }
    }

    Write-Host ""
    Write-WMSuccess ("Cleanup complete! Safely deleted {0:N0} files, reclaimed {1}." -f $deletedFiles, (Format-WMBytes $freedBytes))
    if ($lockedFiles -gt 0) {
        Write-Host ("  {0}({1:N0} active/locked files were safely skipped){2}" -f $c.Muted, $lockedFiles, $c.Reset)
    }

    Write-WinMoleLog -Subcommand "clean" -BytesFreed $freedBytes -FilesDeleted $deletedFiles -ErrorsCount $lockedFiles -DryRun $false -DurationMs $sw.ElapsedMilliseconds
}
