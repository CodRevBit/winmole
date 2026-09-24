@echo off
setlocal
set "SCRIPT_DIR=%~dp0.."
if exist "%SCRIPT_DIR%\winmole.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\winmole.ps1" %*
) else (
    echo [ERROR] winmole.ps1 not found in %SCRIPT_DIR%
    exit /b 1
)
endlocal
