@echo off
setlocal EnableExtensions
set "PZ_INSTALLER=%~f0"
set "PZ_INSTALLER_DIR=%~dp0"

if "%PZ_INSTALLER_DIR:~0,2%"=="\\" (
    echo This installer cannot run from a network path.
    echo Copy the folder to a local disk first, for example Desktop or Downloads.
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 1 }"
if errorlevel 1 goto :elevate
goto :run

:elevate
echo Requesting administrator permissions...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath $env:PZ_INSTALLER -Verb RunAs -WorkingDirectory $env:PZ_INSTALLER_DIR -ErrorAction Stop } catch { Write-Host 'Administrator permission was not granted.' -ForegroundColor Red; exit 1 }"
if errorlevel 1 (
    echo.
    echo Administrator permission was not granted. Right-click Install.bat and choose Run as administrator.
    echo.
    pause
    exit /b 1
)
exit /b 0

:run
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1"
echo.
pause
