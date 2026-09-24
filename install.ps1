# WinMole Universal Installer
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

Write-Host ""
Write-Host ("{0}{1}WINMOLE INSTALLER{2} {3}•{2} Windows Terminal Maintenance Toolkit" -f $cPrimary, $cBold, $cReset, $cMuted)
Write-Host ("{0}─────────────────────────────────────────────────────────────{1}" -f $cMuted, $cReset)
Write-Host ""

$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetDir = Join-Path $env:USERPROFILE ".winmole"
$BinDir = Join-Path $TargetDir "bin"

# 1. Check & Set Execution Policy if Restricted
try {
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "Undefined") {
        Write-Host ("{0}[i] Setting ExecutionPolicy to RemoteSigned for CurrentUser...{1}" -f $cPrimary, $cReset)
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    }
} catch {
    Write-Host ("{0}▲ Warning: Could not adjust execution policy automatically.{1}" -f $cWarning, $cReset)
}

# 2. Create Target Directories
Write-Host ("{0}[i] Preparing installation directory: {1}{2}" -f $cPrimary, $TargetDir, $cReset)
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}
if (-not (Test-Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

# 3. Copy Files
Write-Host ("{0}[i] Copying WinMole files...{1}" -f $cPrimary, $cReset)
Copy-Item -Path (Join-Path $SourceDir "winmole.ps1") -Destination $TargetDir -Force
Copy-Item -Path (Join-Path $SourceDir "bin\*") -Destination $BinDir -Force -Recurse
Copy-Item -Path (Join-Path $SourceDir "src") -Destination $TargetDir -Force -Recurse

# 4. Add bin to User PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathList = ($userPath -split ";") | Where-Object { $_ -ne "" }

if ($pathList -notcontains $BinDir) {
    Write-Host ("{0}[i] Adding {1} to User PATH environment variable...{2}" -f $cPrimary, $BinDir, $cReset)
    $newPath = $userPath.TrimEnd(';') + ";" + $BinDir
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:PATH = "$env:PATH;$BinDir"
    Write-Host ("{0}✔ User PATH updated successfully.{1}" -f $cSuccess, $cReset)
} else {
    Write-Host ("{0}✔ User PATH already contains WinMole bin directory.{1}" -f $cSuccess, $cReset)
}

# 5. Register in PowerShell $PROFILE
if ($PROFILE) {
    $profileDir = Split-Path -Parent $PROFILE
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    $profileContent = ""
    try {
        $profileContent = [System.IO.File]::ReadAllText($PROFILE)
    } catch {}

    $hookMarker = "# --- WinMole CLI Hook ---"
    if ($profileContent -notmatch $hookMarker) {
        $hookCode = @"

# --- WinMole CLI Hook ---
function global:mo { & "$TargetDir\winmole.ps1" @args }
function global:winmole { & "$TargetDir\winmole.ps1" @args }
"@
        [System.IO.File]::AppendAllText($PROFILE, $hookCode, [System.Text.Encoding]::UTF8)
        Write-Host ("{0}✔ PowerShell Profile hook registered in: {1}{2}" -f $cSuccess, $PROFILE, $cReset)
    } else {
        Write-Host ("{0}✔ PowerShell Profile hook already present.{1}" -f $cSuccess, $cReset)
    }
}

Write-Host ""
Write-Host ("{0}✔ WinMole v1.0.0 installed successfully!{1}" -f $cSuccess, $cReset)
Write-Host ""
Write-Host "  You can now run:"
Write-Host ("    {0}mo{1}             - Open interactive terminal menu" -f $cPrimary, $cReset)
Write-Host ("    {0}mo doctor{1}      - Verify diagnostic health and external tools" -f $cPrimary, $cReset)
Write-Host ("    {0}mo status{1}      - Launch live hardware monitor" -f $cPrimary, $cReset)
Write-Host ("    {0}mo clean{1}       - Clean %TEMP% and cache files" -f $cPrimary, $cReset)
Write-Host ""
Write-Host ("  {0}(Note: Restart your terminal or run '$env:PATH = [Environment]::GetEnvironmentVariable(''Path'',''User'')' to refresh PATH in this window){1}" -f $cMuted, $cReset)
Write-Host ""
