#Requires -Version 5.1
<#
.SYNOPSIS
    Read-only check of every prerequisite. Returns an object describing the
    state of each item; the GUI uses this to decide whether to launch the
    auto-installer.
#>
[CmdletBinding()]
param()

$out = [pscustomobject]@{
    PowerShellOk    = $false
    PSVersion       = $PSVersionTable.PSVersion.ToString()
    Tls12Available  = $false
    NuGetProvider   = $null
    PSGalleryTrusted = $false
    PowerCLIInstalled = $false
    PowerCLIVersion = $null
    WordInstalled   = $false
    AllRequiredOk   = $false
    Missing         = @()
}

# 1. PowerShell version
$out.PowerShellOk = ($PSVersionTable.PSVersion -ge [version]'5.1')
if (-not $out.PowerShellOk) { $out.Missing += 'PowerShell 5.1+' }

# 2. TLS 1.2 capability
$out.Tls12Available = ([Net.ServicePointManager]::SecurityProtocol -band [Net.SecurityProtocolType]::Tls12) -ne 0 `
    -or ([Enum]::IsDefined([Net.SecurityProtocolType], 'Tls12'))

# 3. NuGet provider
$nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending | Select-Object -First 1
$out.NuGetProvider = if ($nuget) { $nuget.Version.ToString() } else { $null }

# 4. PSGallery trust
$gal = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
$out.PSGalleryTrusted = ($gal -and $gal.InstallationPolicy -eq 'Trusted')

# 5. VMware.PowerCLI
$pc = Get-Module -ListAvailable -Name VMware.PowerCLI -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending | Select-Object -First 1
if ($pc) {
    $out.PowerCLIInstalled = $true
    $out.PowerCLIVersion = $pc.Version.ToString()
} else {
    # Fallback: VMware.VimAutomation.Core counts (PowerCLI meta-module installs many packages)
    $core = Get-Module -ListAvailable -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending | Select-Object -First 1
    if ($core) {
        $out.PowerCLIInstalled = $true
        $out.PowerCLIVersion = "core $($core.Version)"
    } else {
        $out.Missing += 'VMware.PowerCLI'
    }
}

# 6. Word - optional, informational only
try {
    $word = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like 'Microsoft Office*' -or $_.DisplayName -like 'Microsoft 365*' }
    $out.WordInstalled = [bool]$word
} catch { }

$out.AllRequiredOk = $out.PowerShellOk -and $out.PowerCLIInstalled
$out
