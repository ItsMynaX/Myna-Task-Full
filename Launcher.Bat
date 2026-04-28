@echo off
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Admin rights...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "appPath=%~dp0MynaTask.ps1"
set "psexecPath=%~dp0lib.exe"

if not exist "%appPath%" (
    echo [ERROR] File not found: %appPath%
    pause
    exit /b
)

if exist "%psexecPath%" (
    echo Running %appPath% under SYSTEM rights...
    "%psexecPath%" -i -s powershell.exe -ExecutionPolicy Bypass -File "%appPath%"
) else (
    echo [WARNING] Cannot find lib.exe, running with regular PowerShell...
    powershell -ExecutionPolicy Bypass -File "%appPath%"
)

exit
