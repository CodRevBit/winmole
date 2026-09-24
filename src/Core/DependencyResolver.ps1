# WinMole Dependency Resolver & Self-Healing Engine
# Compatible with PowerShell 5.1 & PowerShell 7+

function Test-WinMoleCommand {
    param([string]$CommandName)
    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    return ($null -ne $cmd)
}

function Find-WinMoleBinary {
    param([string]$Subcommand)
    
    switch ($Subcommand) {
        "status" {
            if (Test-WinMoleCommand "btm") { return "btm" }
            if (Test-WinMoleCommand "btop") { return "btop" }
            return $null
        }
        "analyze" {
            if (Test-WinMoleCommand "gdu") { return "gdu" }
            if (Test-WinMoleCommand "dua") { return "dua" }
            return $null
        }
        "purge" {
            if (Test-WinMoleCommand "kondo") { return "kondo" }
            return $null
        }
        "uninstall" {
            if (Test-WinMoleCommand "winget") { return "winget" }
            return $null
        }
        default {
            return $null
        }
    }
}

function Resolve-WinMoleTool {
    param(
        [Parameter(Mandatory=$true)][string]$Subcommand,
        [switch]$PreferNative
    )

    $c = $global:WM_Color

    if ($PreferNative) {
        return @{
            Mode = "native"
            Binary = $null
        }
    }

    $existingBinary = Find-WinMoleBinary -Subcommand $Subcommand
    if ($existingBinary) {
        return @{
            Mode = "binary"
            Binary = $existingBinary
        }
    }

    # If binary is missing, check tool profile
    $toolSpec = $null
    switch ($Subcommand) {
        "status" {
            $toolSpec = @{
                Name = "bottom (btm)"
                WingetId = "Clement.bottom"
                Description = "High-performance graphical terminal process & hardware monitor"
            }
        }
        "analyze" {
            $toolSpec = @{
                Name = "gdu"
                WingetId = "gdu"
                Description = "Fast, keyboard-navigable disk usage analyzer"
            }
        }
        "purge" {
            $toolSpec = @{
                Name = "kondo"
                WingetId = $null
                InstallCmd = "cargo install kondo"
                Description = "Developer project build artifact cleaner"
            }
        }
    }

    # If no tool specification or clean command, fall back to native
    if (-not $toolSpec) {
        return @{
            Mode = "native"
            Binary = $null
        }
    }

    # Prompt user for 1-click self-healing installation or fallback
    Write-Host ""
    Write-WMWarning "Primary tool '$($toolSpec.Name)' is not currently installed in PATH."
    Write-Host "  $($c.Muted)Description:$($c.Reset) $($toolSpec.Description)"
    Write-Host ""
    if ($toolSpec.WingetId) {
        Write-Host "  $($c.Primary)[1]$($c.Reset) Install $($toolSpec.Name) via winget $($c.Muted)($($toolSpec.WingetId))$($c.Reset)"
    } elseif ($toolSpec.InstallCmd) {
        Write-Host "  $($c.Primary)[1]$($c.Reset) Attempt install via: $($toolSpec.InstallCmd)"
    }
    Write-Host "  $($c.Success)[2]$($c.Reset) Run built-in native PowerShell fallback $($c.Muted)(instant, zero install)$($c.Reset)"
    Write-Host "  $($c.Muted)[3]$($c.Reset) Cancel"
    Write-Host ""

    $choice = Read-Host "  Select option [1-3, default 2]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "2" }

    if ($choice -eq "1") {
        if ($toolSpec.WingetId) {
            Write-WMInfo "Running: winget install --id $($toolSpec.WingetId) --accept-source-agreements --accept-package-agreements"
            try {
                & winget install --id $toolSpec.WingetId --accept-source-agreements --accept-package-agreements
                # Refresh PATH in current session
                $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                $recheck = Find-WinMoleBinary -Subcommand $Subcommand
                if ($recheck) {
                    Write-WMSuccess "Successfully installed $($toolSpec.Name)!"
                    return @{ Mode = "binary"; Binary = $recheck }
                } else {
                    Write-WMWarning "Installation completed, but binary not yet in current session PATH. Falling back to native."
                }
            } catch {
                Write-WMError "winget installation failed: $_. Falling back to native engine."
            }
        } elseif ($toolSpec.InstallCmd) {
            Write-WMInfo "Please install $($toolSpec.Name) in a new terminal with: $($toolSpec.InstallCmd)"
            Write-WMInfo "Routing to native fallback for this session."
        }
        return @{ Mode = "native"; Binary = $null }
    } elseif ($choice -eq "3") {
        return @{ Mode = "cancel"; Binary = $null }
    } else {
        return @{ Mode = "native"; Binary = $null }
    }
}
