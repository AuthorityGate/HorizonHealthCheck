#Requires -Version 5.1
<#
.SYNOPSIS
    Installs the RSAT Active Directory PowerShell module on the runner workstation.
    Required before the B3 Active Directory plugins can produce real findings.

.DESCRIPTION
    On Windows 10/11 (1809+) and Windows Server 2019+, RSAT ships as an
    optional Windows capability. This script installs it via DISM.
    Requires elevation.

.EXAMPLE
    .\Tools\Install-RSAT.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Already loaded?
if (Get-Module -ListAvailable ActiveDirectory) {
    Write-Host "[+] ActiveDirectory module already available." -ForegroundColor Green
    return
}

# Must be elevated
$me = [System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $me.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "RSAT install requires admin rights. Re-launching elevated..."
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        '-NoProfile','-ExecutionPolicy','Bypass','-File',$PSCommandPath
    )
    return
}

Write-Host "[+] Installing RSAT: ActiveDirectory module..." -ForegroundColor Cyan
try {
    $cap = Get-WindowsCapability -Online -Name 'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0' -ErrorAction Stop
    if ($cap.State -eq 'Installed') {
        Write-Host "[+] Capability already Installed; reloading PowerShell may be required." -ForegroundColor Green
    } else {
        Add-WindowsCapability -Online -Name 'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0' -ErrorAction Stop
        Write-Host "[+] Install complete." -ForegroundColor Green
    }
} catch {
    Write-Warning "Capability install failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Alternative installation paths:" -ForegroundColor Yellow
    Write-Host "  Windows 11 Settings : Settings -> Apps -> Optional Features -> Add a Feature -> 'RSAT: Active Directory Domain Services and Lightweight Directory Services Tools'" -ForegroundColor Yellow
    Write-Host "  Windows Server      : Install-WindowsFeature RSAT-AD-PowerShell" -ForegroundColor Yellow
    return
}

# Verify
if (Get-Module -ListAvailable ActiveDirectory) {
    Write-Host "[+] ActiveDirectory module now available." -ForegroundColor Green
} else {
    Write-Warning "Capability installed but module not yet loadable. Open a NEW PowerShell window and try Import-Module ActiveDirectory."
}
