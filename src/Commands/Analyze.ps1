# WinMole Analyze Command (Interactive Disk Usage Explorer)
# Compatible with PowerShell 5.1 & PowerShell 7+

function Invoke-WinMoleAnalyze {
    param(
        [string]$Path = (Get-Location).Path,
        [switch]$Native
    )

    $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        Write-WMError "Target path does not exist: $Path"
        return
    }
    $targetPath = $resolvedPath.Path

    $resolution = Resolve-WinMoleTool -Subcommand "analyze" -PreferNative:$Native
    if ($resolution.Mode -eq "cancel") { return }

    if ($resolution.Mode -eq "binary" -and $resolution.Binary) {
        & $resolution.Binary $targetPath
        return
    }

    Invoke-WinMoleNativeAnalyze -TargetPath $targetPath
}

function Invoke-WinMoleNativeAnalyze {
    param(
        [Parameter(Mandatory=$true)][string]$TargetPath
    )

    $c = $global:WM_Color
    $g = $global:WM_Glyphs

    Write-WMHeader -Title "WINMOLE ANALYZE" -Subtitle "Directory Size Profiler"
    Write-WMInfo ("Scanning: {0}{1}{2}..." -f $c.Text, $TargetPath, $c.Reset)

    $dirInfo = New-Object System.IO.DirectoryInfo($TargetPath)
    $results = @()
    $totalRootBytes = 0

    try {
        $subDirs = $dirInfo.GetDirectories()
    } catch {
        Write-WMError "Permission denied or failed to access directories in $TargetPath"
        return
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    foreach ($sub in $subDirs) {
        $dirBytes = 0
        $fileCount = 0
        try {
            $files = $sub.EnumerateFiles("*", [System.IO.SearchOption]::AllDirectories)
            foreach ($f in $files) {
                $dirBytes += $f.Length
                $fileCount++
            }
        } catch {}

        $results += [PSCustomObject]@{
            Name = $sub.Name
            Type = "Folder"
            Bytes = $dirBytes
            FileCount = $fileCount
        }
        $totalRootBytes += $dirBytes
    }

    # Top-Level Files
    $rootFilesBytes = 0
    $rootFilesCount = 0
    try {
        $rootFiles = $dirInfo.GetFiles()
        foreach ($rf in $rootFiles) {
            $rootFilesBytes += $rf.Length
            $rootFilesCount++
        }
        if ($rootFilesCount -gt 0) {
            $results += [PSCustomObject]@{
                Name = "(files in root)"
                Type = "Files"
                Bytes = $rootFilesBytes
                FileCount = $rootFilesCount
            }
            $totalRootBytes += $rootFilesBytes
        }
    } catch {}

    $sw.Stop()

    $sorted = $results | Sort-Object -Property Bytes -Descending

    Write-Host ""
    $summaryLines = @(
        ("Path: {0}{1}{2}" -f $c.Text, $TargetPath, $c.Reset),
        ("Items Scanned: {0}{1}{2} {3} Time: {4}{5} ms{2}" -f $c.Text, $results.Count, $c.Reset, $g.Bullet, $c.Secondary, $sw.ElapsedMilliseconds),
        ("Total Analyzed Space: {0}{1}{2}{3}" -f $c.Bold, $c.Primary, (Format-WMBytes $totalRootBytes), $c.Reset)
    )
    Write-WMPanel -Title "Scan Summary" -Lines $summaryLines -Width 65

    $div = [string]::new($g.HLine, 61)
    Write-Host ""
    Write-Host ("  {0}Name                            Size          Files    Proportion{1}" -f $c.Muted, $c.Reset)
    Write-Host ("  {0}{1}{2}" -f $c.Muted, $div, $c.Reset)

    foreach ($item in $sorted) {
        $pct = if ($totalRootBytes -gt 0) { ($item.Bytes / $totalRootBytes) * 100 } else { 0 }
        
        $nameDisplay = if ($item.Name.Length -gt 28) { $item.Name.Substring(0, 25) + "..." } else { $item.Name }
        $namePadded = $nameDisplay.PadRight(30)
        $sizePadded = (Format-WMBytes $item.Bytes).PadRight(14)
        $filesPadded = ($item.FileCount.ToString("N0")).PadRight(9)

        $barLength = 12
        $fillCount = [int][math]::Round(($pct / 100) * $barLength)
        if ($fillCount -gt $barLength) { $fillCount = $barLength }
        $emptyCount = $barLength - $fillCount
        $barFilled = [string]::new($g.Block, $fillCount)
        $barEmpty = [string]::new($g.Shade, $emptyCount)
        $bar = "{0}{1}{2}{3}{4}" -f $c.Primary, $barFilled, $c.Muted, $barEmpty, $c.Reset

        Write-Host ("  {0}{1}{2}{3}{4} {5:N1}%{6}" -f $c.Text, $namePadded, $sizePadded, $filesPadded, $bar, $pct, $c.Reset)
    }
    Write-Host ""
}
