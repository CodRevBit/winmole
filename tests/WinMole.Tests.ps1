# WinMole Pester Test Suite
# Tests CLI routing, configuration management, safety guards, and dry-run guarantees.

$ScriptDir = Split-Path -Parent $PSScriptRoot
$WinMoleRoot = $ScriptDir

# Dot-source Core and Command modules
. (Join-Path $WinMoleRoot "src\Core\Config.ps1")
. (Join-Path $WinMoleRoot "src\Core\UI.ps1")
. (Join-Path $WinMoleRoot "src\Core\DependencyResolver.ps1")
. (Join-Path $WinMoleRoot "src\Commands\Purge.ps1")
. (Join-Path $WinMoleRoot "src\Commands\Clean.ps1")
. (Join-Path $WinMoleRoot "src\Commands\Status.ps1")
. (Join-Path $WinMoleRoot "src\Commands\Doctor.ps1")

Describe "WinMole Configuration & Safety" {
    It "Loads default configuration schema correctly" {
        $defaultConfig = Get-WinMoleDefaultConfig
        $defaultConfig.version | Should Be "1.0.0"
        $defaultConfig.safety.dry_run_default | Should Be $false
        $defaultConfig.safety.protected_paths.Count | Should BeGreaterThan 0
    }

    It "Blocks protected root directories from deletion" {
        (Test-WinMoleProtectedPath -Path "C:\") | Should Be $true
        (Test-WinMoleProtectedPath -Path "C:\Windows") | Should Be $true
        (Test-WinMoleProtectedPath -Path "C:\Program Files") | Should Be $true
    }

    It "Allows non-protected project directories" {
        $safePath = Join-Path $env:TEMP "winmole_safe_test_dir"
        (Test-WinMoleProtectedPath -Path $safePath) | Should Be $false
    }
}

Describe "WinMole Dependency Resolver" {
    It "Correctly identifies presence of standard Windows binaries" {
        (Test-WinMoleCommand "cmd.exe") | Should Be $true
        (Test-WinMoleCommand "powershell.exe") | Should Be $true
    }

    It "Correctly returns false for non-existent binaries" {
        (Test-WinMoleCommand "non_existent_fake_tool_12345.exe") | Should Be $false
    }

    It "Returns native mode when PreferNative is switch-specified" {
        $res = Resolve-WinMoleTool -Subcommand "purge" -PreferNative
        $res.Mode | Should Be "native"
    }
}

Describe "WinMole Purge Engine & Safety" {
    BeforeEach {
        $script:testSandbox = Join-Path $env:TEMP ("winmole_purge_test_" + (Get-Random))
        $script:nodeModulesDir = Join-Path $script:testSandbox "project\node_modules"
        $script:dummyFile = Join-Path $script:nodeModulesDir "package.json"

        New-Item -ItemType Directory -Path $script:nodeModulesDir -Force | Out-Null
        Set-Content -Path $script:dummyFile -Value '{"name": "test-pkg"}'
    }

    AfterEach {
        if ($script:testSandbox -and (Test-Path $script:testSandbox)) {
            Remove-Item -Path $script:testSandbox -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Ensures --dry-run scans target artifact without deleting files" {
        (Test-Path $script:dummyFile) | Should Be $true

        # Run native purge in DryRun mode
        Invoke-WinMoleNativePurge -TargetPath $script:testSandbox -DryRun -Force

        # Verify file and directory still exist untouched
        (Test-Path $script:dummyFile) | Should Be $true
        (Test-Path $script:nodeModulesDir) | Should Be $true
    }

    It "Deletes target artifacts when DryRun is false and Force is true" {
        (Test-Path $script:dummyFile) | Should Be $true

        Invoke-WinMoleNativePurge -TargetPath $script:testSandbox -Force

        # Verify node_modules was removed
        (Test-Path $script:nodeModulesDir) | Should Be $false
    }
}

Describe "WinMole Clean Engine & Safety" {
    It "Executes Clean with --dry-run safely without errors" {
        { Invoke-WinMoleClean -DryRun -Force } | Should Not Throw
    }
}

Describe "WinMole CLI Entrypoint" {
    It "Executes winmole.ps1 -v successfully" {
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $WinMoleRoot "winmole.ps1") -v
        $output | Should Match "winmole version 1\.0\.0"
    }

    It "Executes winmole.ps1 help and displays usage" {
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $WinMoleRoot "winmole.ps1") help
        ($output -join "`n") | Should Match "COMMANDS"
    }
}
