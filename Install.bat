@echo off
setlocal EnableExtensions
set "PZ_INSTALLER_DIR=%~dp0"
if not exist "%PZ_INSTALLER_DIR%Install.ps1" (
    echo ERRO: Install.ps1 nao encontrado.
    echo Extraia o ZIP completo antes de rodar o Install.bat.
    echo.
    pause
    exit /b 1
)

if not defined LOCALAPPDATA set "LOCALAPPDATA=%USERPROFILE%\AppData\Local"
if not defined LOCALAPPDATA (
    echo ERRO: pasta LOCALAPPDATA nao encontrada.
    pause
    exit /b 1
)

set "PZ_STABLE_DIR=%LOCALAPPDATA%\PZViewpoint\installer"
if /I "%~dp0"=="%PZ_STABLE_DIR%\" goto :ready

echo Copiando instalador para uma pasta local...
robocopy "%~dp0." "%PZ_STABLE_DIR%" /E /XD ".git" /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 (
    echo ERRO: nao foi possivel copiar o instalador para %PZ_STABLE_DIR%.
    echo Extraia o ZIP para Desktop ou Downloads e tente de novo.
    echo.
    pause
    exit /b 1
)
if not exist "%PZ_STABLE_DIR%\Install.ps1" (
    echo ERRO: copia do instalador incompleta.
    pause
    exit /b 1
)
set "PZ_INSTALLER_DIR=%PZ_STABLE_DIR%\"

:ready
set "PZ_INSTALLER=%PZ_INSTALLER_DIR%Install.bat"

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
