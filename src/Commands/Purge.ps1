# WinMole Purge Command (Developer Build Artifact Cleaner)
# Compatible with PowerShell 5.1 & PowerShell 7+

function Test-WinMoleProtectedPath {
    param([string]$Path)
    $config = Get-WinMoleConfig
    $protected = $config.safety.protected_paths
    if (-not $protected) {
        $protected = @("C:\", "C:\Windows", "C:\Program Files", "C:\Program Files (x86)", "C:\Users")
    }

    $norm = [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    foreach ($p in $protected) {
        $normP = [System.IO.Path]::GetFullPath($p).TrimEnd('\', '/')
        if ($norm -ieq $normP) {
            return $true
        }
    }
    return $false
}

function Invoke-WinMolePurge {
    param(
        [string]$Path = (Get-Location).Path,
        [switch]$DryRun,
        [switch]$Force,
        [switch]$Native
    )

    $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        Write-WMError "Target path does not exist: $Path"
        return
    }
    $targetPath = $resolvedPath.Path

    if (Test-WinMoleProtectedPath -Path $targetPath) {
        Write-WMError ("Target path '{0}' is a protected system directory! Operation aborted." -f $targetPath)
        return
    }

    # If kondo exists and not dry-run / native, delegate
    if (-not $DryRun -and -not $Native) {
        $resolution = Resolve-WinMoleTool -Subcommand "purge" -PreferNative:$Native
        if ($resolution.Mode -eq "cancel") { return }
        if ($resolution.Mode -eq "binary" -and $resolution.Binary) {
            & $resolution.Binary $targetPath
            return
        }
    }

    Invoke-WinMoleNativePurge -TargetPath $targetPath -DryRun:$DryRun -Force:$Force
}

function Invoke-WinMoleNativePurge {
    param(
        [Parameter(Mandatory=$true)][string]$TargetPath,
        [switch]$DryRun,
        [switch]$Force
    )

    $c = $global:WM_Color
    $g = $global:WM_Glyphs

    $subTitle = if ($DryRun) { "Build Artifact Cleaner [DRY RUN]" } else { "Build Artifact Cleaner" }
    Write-WMHeader -Title "WINMOLE PURGE" -Subtitle $subTitle
    Write-WMInfo ("Scanning for build artifacts in: {0}{1}{2}..." -f $c.Text, $TargetPath, $c.Reset)

    $targetsData = Get-WinMoleTargets
    $rules = $targetsData.purge_rules
    if (-not $rules) {
        $rules = @(
            @{ pattern = "node_modules"; ecosystem = "Node.js"; description = "Node dependencies" },
            @{ pattern = "^(\.venv|venv)$"; ecosystem = "Python"; description = "Python virtual environment" },
            @{ pattern = "^__pycache__$"; ecosystem = "Python"; description = "Python bytecode" },
            @{ pattern = "^target$"; ecosystem = "Rust/Cargo"; description = "Rust target" },
            @{ pattern = "^(bin|obj)$"; ecosystem = ".NET/C#"; description = ".NET build output" },
            @{ pattern = "^(\.next|\.nuxt|dist|build)$"; ecosystem = "Web Frameworks"; description = "Web build artifacts" }
        )
    }

    $foundArtifacts = New-Object System.Collections.ArrayList
    $totalReclaimable = 0
    $maxDepth = 5

    function Search-Artifacts([string]$dir, [int]$currentDepth) {
        if ($currentDepth -gt $maxDepth) { return }
        
        $dirInfo = New-Object System.IO.DirectoryInfo($dir)
        try {
            $children = $dirInfo.GetDirectories()
        } catch {
            return
        }

        foreach ($sub in $children) {
            $matchedRule = $null
            foreach ($rule in $rules) {
                if ($rule.pattern -match "\^|\$|\|") {
                    if ($sub.Name -match $rule.pattern) {
                        $matchedRule = $rule
                        break
                    }
                } else {
                    if ($sub.Name -ieq $rule.pattern) {
                        $matchedRule = $rule
                        break
                    }
                }
            }

            if ($matchedRule) {
                $size = 0
                $count = 0
                try {
                    $files = $sub.EnumerateFiles("*", [System.IO.SearchOption]::AllDirectories)
                    foreach ($f in $files) {
                        $size += $f.Length
                        $count++
                    }
                } catch {}

                [void]$foundArtifacts.Add([PSCustomObject]@{
                    Path = $sub.FullName
                    Name = $sub.Name
                    Ecosystem = $matchedRule.ecosystem
                    Description = $matchedRule.description
                    Size = $size
                    FileCount = $count
                })
            } else {
                Search-Artifacts -dir $sub.FullName -currentDepth ($currentDepth + 1)
            }
        }
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Search-Artifacts -dir $TargetPath -currentDepth 1
    $sw.Stop()

    foreach ($item in $foundArtifacts) {
        $totalReclaimable += $item.Size
    }

    if ($foundArtifacts.Count -eq 0) {
        Write-Host ""
        Write-WMSuccess ("No developer build artifacts found in {0}. Clean!" -f $TargetPath)
        return
    }

    Write-Host ""
    $summaryLines = @(
        ("Target Root: {0}{1}{2}" -f $c.Text, $TargetPath, $c.Reset),
        ("Found: {0}{1} artifact directories{2}  {3}  Scan Time: {4} ms" -f $c.Warning, $foundArtifacts.Count, $c.Reset, $g.Dot, $sw.ElapsedMilliseconds),
        ("Total Reclaimable Space: {0}{1}{2}{3}" -f $c.Bold, $c.Success, (Format-WMBytes $totalReclaimable), $c.Reset)
    )
    Write-WMPanel -Title "Artifacts Detected" -Lines $summaryLines -Width 67

    $div = [string]::new($g.HLine, 67)
    Write-Host ""
    Write-Host ("  {0}Artifact Path                                        Type         Size{1}" -f $c.Muted, $c.Reset)
    Write-Host ("  {0}{1}{2}" -f $c.Border, $div, $c.Reset)

    foreach ($item in $foundArtifacts) {
        $pathDisplay = $item.Path
        if ($pathDisplay.Length -gt 47) {
            $pathDisplay = "..." + $pathDisplay.Substring($pathDisplay.Length - 44)
        }
        $pathPadded = $pathDisplay.PadRight(49)
        $ecoPadded = $item.Ecosystem.PadRight(13)
        $sizePadded = Format-WMBytes $item.Size
        Write-Host ("  {0}{1}{2}{3}{4}{5}{6}" -f $c.Text, $pathPadded, $c.Secondary, $ecoPadded, $c.Success, $sizePadded, $c.Reset)
    }
    Write-Host ""

    if ($DryRun) {
        Write-WMInfo "[DRY RUN PREVIEW] No files were deleted. Re-run without --dry-run to delete."
        return
    }

    $confirmed = $Force
    if (-not $confirmed) {
        if (-not [Environment]::UserInteractive -or [Console]::IsInputRedirected) {
            Write-WMWarning "Non-interactive environment detected without --force. Purge aborted for safety."
            return
        }
        Write-Host ("  {0}Caution: Deleted build artifacts cannot be restored from the Recycle Bin.{1}" -f $c.Danger, $c.Reset)
        $resp = Read-Host ("  Delete these {0} artifact directories? [y/N]" -f $foundArtifacts.Count)
        if ($resp -match "^[yY](es)?$") {
            $confirmed = $true
        }
    }

    if (-not $confirmed) {
        Write-WMWarning "Purge operation cancelled by user."
        return
    }

    $deletedCount = 0
    $freedBytes = 0
    $errorCount = 0

    foreach ($item in $foundArtifacts) {
        try {
            Write-Host ("  {0}Purging:{1} {2}... " -f $c.Muted, $c.Reset, $item.Path) -NoNewline
            [System.IO.Directory]::Delete($item.Path, $true)
            $deletedCount++
            $freedBytes += $item.Size
            Write-Host ("{0}Done{1}" -f $c.Success, $c.Reset)
        } catch {
            $errorCount++
            Write-Host ("{0}Failed ({1}){2}" -f $c.Danger, $_.Exception.Message, $c.Reset)
        }
    }

    Write-Host ""
    Write-WMSuccess ("Purge complete! Deleted {0} directories, reclaimed {1}." -f $deletedCount, (Format-WMBytes $freedBytes))
    if ($errorCount -gt 0) {
        Write-WMWarning ("{0} directories could not be deleted (files locked or permission denied)." -f $errorCount)
    }

    Write-WinMoleLog -Subcommand "purge" -BytesFreed $freedBytes -FilesDeleted $deletedCount -ErrorsCount $errorCount -DryRun $false -DurationMs $sw.ElapsedMilliseconds
}
