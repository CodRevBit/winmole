# WinMole Configuration & State Manager
# Compatible with PowerShell 5.1 & PowerShell 7+

function Get-WinMoleHome {
    $dir = Join-Path $env:USERPROFILE ".winmole"
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    return $dir
}

function Get-WinMoleConfigPath {
    return (Join-Path (Get-WinMoleHome) "config.json")
}

function Get-WinMoleTargetsPath {
    return (Join-Path (Get-WinMoleHome) "targets.json")
}

function Get-WinMoleHistoryPath {
    return (Join-Path (Get-WinMoleHome) "history.jsonl")
}

function Get-WinMoleDefaultConfig {
    return @{
        version = "1.0.0"
        ui = @{
            truecolor_enabled = $true
            theme = "dark_modern"
            show_banner_tips = $true
            refresh_rate_ms = 1000
        }
        safety = @{
            dry_run_default = $false
            confirm_deletions = $true
            max_purge_depth = 5
            protected_paths = @(
                "C:\",
                "C:\Windows",
                "C:\Program Files",
                "C:\Program Files (x86)",
                "C:\Users"
            )
        }
        tools = @{
            status = @{
                preferred = "bottom"
                binary = "btm.exe"
                winget_id = "Clement.bottom"
                fallback = "native"
            }
            analyze = @{
                preferred = "gdu"
                binary = "gdu.exe"
                winget_id = "gdu"
                fallback = "native"
            }
            purge = @{
                preferred = "kondo"
                binary = "kondo.exe"
                install_cmd = "cargo install kondo"
                fallback = "native"
            }
            clean = @{
                preferred = "native"
                binary = "native"
                winget_id = "BleachBit.BleachBit"
                fallback = "native"
            }
            uninstall = @{
                preferred = "winget"
                binary = "winget.exe"
                fallback = "native"
            }
        }
    }
}

function Get-WinMoleConfig {
    $path = Get-WinMoleConfigPath
    if (-not (Test-Path $path)) {
        $defaultConfig = Get-WinMoleDefaultConfig
        $json = $defaultConfig | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($path, $json, [System.Text.Encoding]::UTF8)
        return $defaultConfig
    }
    try {
        $raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
        return (ConvertFrom-Json -InputObject $raw)
    } catch {
        return (Get-WinMoleDefaultConfig)
    }
}

function Set-WinMoleConfig {
    param([Parameter(Mandatory=$true)]$Config)
    $path = Get-WinMoleConfigPath
    $json = $Config | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($path, $json, [System.Text.Encoding]::UTF8)
}

function Get-WinMoleTargets {
    $path = Get-WinMoleTargetsPath
    if (-not (Test-Path $path)) {
        $defaultTargets = @{
            version = "1.0.0"
            clean_targets = @(
                @{
                    id = "user_temp"
                    category = "temp"
                    description = "User Temporary Files (%TEMP%)"
                    path_template = "%TEMP%"
                    requires_admin = $false
                    retention_hours = 24
                    enabled = $true
                },
                @{
                    id = "system_temp"
                    category = "temp"
                    description = "Windows System Temp"
                    path_template = "$env:SystemRoot\Temp"
                    requires_admin = $true
                    retention_hours = 48
                    enabled = $true
                },
                @{
                    id = "crash_dumps"
                    category = "system"
                    description = "User Crash Dumps"
                    path_template = "$env:LOCALAPPDATA\CrashDumps"
                    requires_admin = $false
                    retention_hours = 0
                    enabled = $true
                },
                @{
                    id = "prefetch"
                    category = "system"
                    description = "Windows Prefetch Cache"
                    path_template = "$env:SystemRoot\Prefetch"
                    requires_admin = $true
                    retention_hours = 0
                    enabled = $false
                }
            )
            purge_rules = @(
                @{
                    id = "node_modules"
                    pattern = "node_modules"
                    ecosystem = "JavaScript/Node.js"
                    description = "Node package dependencies"
                    enabled = $true
                },
                @{
                    id = "python_venv"
                    pattern = "^(\.venv|venv)$"
                    ecosystem = "Python"
                    description = "Python virtual environments"
                    enabled = $true
                },
                @{
                    id = "python_cache"
                    pattern = "^__pycache__$"
                    ecosystem = "Python"
                    description = "Python bytecode cache"
                    enabled = $true
                },
                @{
                    id = "rust_target"
                    pattern = "^target$"
                    ecosystem = "Rust/Cargo"
                    description = "Cargo compilation target"
                    enabled = $true
                },
                @{
                    id = "dotnet_bin_obj"
                    pattern = "^(bin|obj)$"
                    ecosystem = ".NET/C#"
                    description = ".NET compiled output"
                    enabled = $true
                },
                @{
                    id = "web_framework_build"
                    pattern = "^(\.next|\.nuxt|dist|build)$"
                    ecosystem = "Web Frameworks"
                    description = "Production build caches"
                    enabled = $true
                }
            )
        }
        $json = $defaultTargets | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($path, $json, [System.Text.Encoding]::UTF8)
        return $defaultTargets
    }
    try {
        $raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
        return (ConvertFrom-Json -InputObject $raw)
    } catch {
        return $null
    }
}

function Write-WinMoleLog {
    param(
        [string]$Subcommand,
        [int64]$BytesFreed = 0,
        [int]$FilesDeleted = 0,
        [int]$ErrorsCount = 0,
        [bool]$DryRun = $false,
        [int]$DurationMs = 0
    )
    $logPath = Get-WinMoleHistoryPath
    $entry = @{
        session_id = "wm-$([guid]::NewGuid().ToString().Substring(0,8))"
        timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        subcommand = $Subcommand
        duration_ms = $DurationMs
        total_bytes_freed = $BytesFreed
        files_deleted = $FilesDeleted
        errors_count = $ErrorsCount
        dry_run = $DryRun
    }
    $line = ($entry | ConvertTo-Json -Compress)
    [System.IO.File]::AppendAllText($logPath, ($line + [System.Environment]::NewLine), [System.Text.Encoding]::UTF8)
}
