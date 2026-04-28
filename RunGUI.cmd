@echo off
rem Launches the Horizon HealthCheck GUI without any prompts.
setlocal
set SCRIPT=%~dp0Start-HorizonHealthCheckGUI.ps1
where pwsh.exe >nul 2>&1 && (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
) || (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
)
