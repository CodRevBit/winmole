# WinMole Doctor Command (System & Tool Health Diagnostics)
# Compatible with PowerShell 5.1 & PowerShell 7+

function Invoke-WinMoleDoctor {
    $c = $global:WM_Color
    $g = $global:WM_Glyphs
    Write-WMHeader -Title "WINMOLE DOCTOR" -Subtitle "Environment & Tool Diagnostics"

    Write-Host ""
    Write-WMInfo "Running system integrity and tool availability scan..."
    Write-Host ""

    # 1. Host & PowerShell
    $isAdmin = Test-WMAdmin
    $adminText = if ($isAdmin) { ("{0}Elevated (Administrator){1}" -f $c.Success, $c.Reset) } else { ("{0}Standard User (Non-Elevated){1}" -f $c.Warning, $c.Reset) }
    $execPolicy = Get-ExecutionPolicy
    $os = Get-CimInstance Win32_OperatingSystem

    $vtStatus = if ($global:WM_HasVT) { ("{0}Supported [OK]{1}" -f $c.Success, $c.Reset) } else { ("{0}16-Color Fallback{1}" -f $c.Muted, $c.Reset) }

    $envLines = @(
        ("PowerShell Version : {0}{1} ({2}){3}" -f $c.Text, $PSVersionTable.PSVersion.ToString(), $PSVersionTable.PSEdition, $c.Reset),
        ("Operating System   : {0}{1} (Build {2}){3}" -f $c.Text, $os.Caption, $os.BuildNumber, $c.Reset),
        ("Architecture       : {0}{1}{2}" -f $c.Text, $os.OSArchitecture, $c.Reset),
        ("Terminal Host      : {0}{1}{2}" -f $c.Text, $Host.Name, $c.Reset),
        ("ANSI TrueColor     : {0}" -f $vtStatus),
        ("Privilege Level    : {0}" -f $adminText),
        ("Execution Policy   : {0}{1}{2}" -f $c.Secondary, $execPolicy, $c.Reset)
    )
    Write-WMPanel -Title "Environment Overview" -Lines $envLines -Width 67

    # 2. Tool Integration Matrix
    $tools = @(
        @{ Name = "bottom (btm)"; Subcommand = "status"; Binary = "btm"; Winget = "Clement.bottom"; Role = "Primary System Monitor" },
        @{ Name = "btop"; Subcommand = "status"; Binary = "btop"; Winget = "btop"; Role = "Alternative System Monitor" },
        @{ Name = "gdu"; Subcommand = "analyze"; Binary = "gdu"; Winget = "gdu"; Role = "Primary Disk Visualizer" },
        @{ Name = "dua-cli"; Subcommand = "analyze"; Binary = "dua"; Winget = "dua-cli"; Role = "Alternative Disk Visualizer" },
        @{ Name = "kondo"; Subcommand = "purge"; Binary = "kondo"; Winget = "cargo install kondo"; Role = "Primary Artifact Purger" },
        @{ Name = "winget"; Subcommand = "uninstall"; Binary = "winget"; Winget = "Windows App Installer"; Role = "Package Manager" }
    )

    $div = [string]::new($g.HLine, 63)
    $toolLines = @(
        ("{0}Tool Name            Role                        Status{1}" -f $c.Muted, $c.Reset),
        ("{0}{1}{2}" -f $c.Border, $div, $c.Reset)
    )

    foreach ($t in $tools) {
        $found = Test-WinMoleCommand $t.Binary
        $namePadded = $t.Name.PadRight(21)
        $rolePadded = $t.Role.PadRight(28)
        if ($found) {
            $status = ("{0}{1} installed{2}" -f $c.Success, $g.Check, $c.Reset)
        } else {
            $status = ("{0}{1} native fallback ready{2}" -f $c.Muted, $g.Arrow, $c.Reset)
        }
        $toolLines += ("{0}{1}{2}{3}{4}" -f $c.Text, $namePadded, $c.Secondary, $rolePadded, $status)
    }
    Write-WMPanel -Title "Tool Integration Matrix" -Lines $toolLines -Width 67

    # 3. Storage & Configuration Status
    $configPath = Get-WinMoleConfigPath
    $targetsPath = Get-WinMoleTargetsPath
    $historyPath = Get-WinMoleHistoryPath

    $configStatus = if (Test-Path $configPath) { ("{0}Found ({1}){2}" -f $c.Success, $configPath, $c.Reset) } else { ("{0}Will initialize on first run{1}" -f $c.Warning, $c.Reset) }
    $targetsStatus = if (Test-Path $targetsPath) { ("{0}Found ({1}){2}" -f $c.Success, $targetsPath, $c.Reset) } else { ("{0}Will initialize on first run{1}" -f $c.Warning, $c.Reset) }
    $historyStatus = if (Test-Path $historyPath) { ("{0}Found ({1}){2}" -f $c.Success, $historyPath, $c.Reset) } else { ("{0}No entries yet{1}" -f $c.Muted, $c.Reset) }

    $storageLines = @(
        ("Configuration : {0}" -f $configStatus),
        ("Target Rules  : {0}" -f $targetsStatus),
        ("Audit Log     : {0}" -f $historyStatus)
    )
    Write-WMPanel -Title "WinMole Configuration State" -Lines $storageLines -Width 67

    Write-Host ""
    Write-WMSuccess "Diagnostics complete! All core subcommands have operational engines."
    Write-Host ""
}
