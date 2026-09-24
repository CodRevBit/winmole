# WinMole Uninstaller
# Compatible with PowerShell 5.1 & PowerShell 7+

# Ensure UTF-8 Output
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$ESC = [char]27
$cPrimary = "$ESC[38;2;56;189;248m"
$cSuccess = "$ESC[38;2;52;211;153m"
$cWarning = "$ESC[38;2;251;191;36m"
$cDanger  = "$ESC[38;2;248;113;113m"
$cMuted   = "$ESC[38;2;100;116;139m"
$cBold    = "$ESC[1m"
$cReset   = "$ESC[0m"

$divider = [string]::new([char]45, 61)

Write-Host ""
Write-Host ("{0}{1}WINMOLE UNINSTALLER{2}" -f $cDanger, $cBold, $cReset)
Write-Host ("{0}{1}{2}" -f $cMuted, $divider, $cReset)
Write-Host ""

$confirm = Read-Host "Are you sure you want to completely uninstall WinMole? [y/N]"
if ($confirm -notmatch "^[yY](es)?$") {
    Write-Host "Uninstallation cancelled."
    exit 0
}

$TargetDir = Join-Path $env:USERPROFILE ".winmole"
$BinDir = Join-Path $TargetDir "bin"

# 1. Remove from User PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath) {
    $pathList = ($userPath -split ";") | Where-Object { $_ -ne "" -and $_ -ne $BinDir }
    $newPath = $pathList -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host ("{0}[OK] Removed WinMole from User PATH.{1}" -f $cSuccess, $cReset)
}

# 2. Clean PowerShell $PROFILE Hook
if ($PROFILE -and (Test-Path $PROFILE)) {
    try {
        $lines = Get-Content -Path $PROFILE
        $cleaned = @()
        $skip = $false
        foreach ($line in $lines) {
            if ($line -match "# --- WinMole CLI Hook ---") {
                $skip = $true
                continue
            }
            if ($skip -and ($line -match "^function global:(mo|winmole)" -or [string]::IsNullOrWhiteSpace($line))) {
                continue
            }
            $skip = $false
            $cleaned += $line
        }
        [System.IO.File]::WriteAllLines($PROFILE, $cleaned, [System.Text.Encoding]::UTF8)
        Write-Host ("{0}[OK] Removed hook from PowerShell profile.{1}" -f $cSuccess, $cReset)
    } catch {
        Write-Host ("{0}[!] Warning: Could not clean profile file: {1}{2}" -f $cWarning, $_.Exception.Message, $cReset)
    }
}

# 3. Remove .winmole folder
if (Test-Path $TargetDir) {
    Remove-Item -Path $TargetDir -Recurse -Force
    Write-Host ("{0}[OK] Removed {1} directory.{2}" -f $cSuccess, $TargetDir, $cReset)
}

Write-Host ""
Write-Host ("{0}[OK] WinMole has been completely removed from your system.{1}" -f $cSuccess, $cReset)
Write-Host ""
