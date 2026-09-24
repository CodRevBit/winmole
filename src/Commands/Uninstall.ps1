# WinMole Uninstall Command (Package & Application Uninstaller)
# Compatible with PowerShell 5.1 & PowerShell 7+

function Invoke-WinMoleUninstall {
    param(
        [string]$Query,
        [switch]$Interactive
    )

    $c = $global:WM_Color
    Write-WMHeader -Title "WINMOLE UNINSTALL" -Subtitle "Package & App Manager"

    $hasWinget = Test-WinMoleCommand "winget"
    if (-not $hasWinget) {
        Write-WMError "winget is not available on this system. Please ensure Windows App Installer is installed."
        return
    }

    if ($Query) {
        Write-WMInfo "Delegating to winget uninstall for: $($c.Text)$Query$($c.Reset)"
        Write-Host ""
        & winget uninstall $Query
        return
    }

    $margin = Get-WMMargin -ContentWidth 76

    # Interactive search & select
    Write-Host ""
    Write-Host ("{0}Enter application name to search and uninstall {1}(or press Enter to list all){2}: " -f $margin, $c.Muted, $c.Reset) -NoNewline
    $searchTerm = Read-Host

    Write-Host ""
    Write-WMInfo "Querying installed packages via winget..."
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($searchTerm)) {
        & winget list
    } else {
        & winget list $searchTerm
    }

    Write-Host ""
    Write-Host ("{0}Enter the exact {1}Id{2} or {1}Name{2} to uninstall {3}(or press Enter to cancel){2}: " -f $margin, $c.Primary, $c.Reset, $c.Muted) -NoNewline
    $targetApp = Read-Host

    if ([string]::IsNullOrWhiteSpace($targetApp)) {
        Write-WMWarning "Uninstall cancelled."
        return
    }

    Write-Host ""
    $confirm = Read-Host ("{0}Are you sure you want to uninstall '$targetApp'? [y/N]" -f $margin)
    if ($confirm -match "^[yY](es)?$") {
        Write-Host ""
        Write-WMInfo "Executing: winget uninstall `"$targetApp`"..."
        Write-Host ""
        & winget uninstall $targetApp
    } else {
        Write-WMWarning "Uninstall cancelled."
    }
}
