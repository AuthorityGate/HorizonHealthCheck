# Start of Settings
# End of Settings

$Title          = "AD LAPS Deployment Coverage"
$Header         = "[count] computer(s) reporting LAPS-managed local-admin password"
$Comments       = "Counts machines whose AD computer object has the ms-Mcs-AdmPwdExpirationTime attribute populated (legacy LAPS) OR msLAPS-PasswordExpirationTime (Windows LAPS, the 2023 successor). Ratio of LAPS-managed to total = local-admin-credential rotation coverage. Without LAPS, every machine has the same baked-in local Administrator password = lateral-movement gold."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = "B3 Active Directory"
$Severity       = "P1"
$Recommendation = "Below 90% LAPS coverage = compliance gap on every modern security baseline. Migrate from legacy LAPS to Windows LAPS (built-in to Win11 + Server 2019+); the modern attribute is msLAPS-PasswordExpirationTime."

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    [pscustomobject]@{ Note = 'ActiveDirectory PowerShell module not available.' }
    return
}
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

try {
    $totalCmp     = @(Get-ADComputer -Filter { Enabled -eq $true } -ErrorAction Stop).Count
    $legacyLaps   = @(Get-ADComputer -Filter { Enabled -eq $true } -Properties 'ms-Mcs-AdmPwdExpirationTime' -ErrorAction Stop |
                      Where-Object { $_.'ms-Mcs-AdmPwdExpirationTime' -gt 0 }).Count
    $windowsLaps  = @(Get-ADComputer -Filter { Enabled -eq $true } -Properties 'msLAPS-PasswordExpirationTime' -ErrorAction Stop |
                      Where-Object { $_.'msLAPS-PasswordExpirationTime' -gt 0 }).Count
} catch {
    [pscustomobject]@{ Note = "AD query failed: $($_.Exception.Message)" }
    return
}

$totalCovered = ($legacyLaps + $windowsLaps)
$pct = if ($totalCmp -gt 0) { [math]::Round(($totalCovered / $totalCmp) * 100, 1) } else { 0 }

[pscustomobject]@{
    EnabledComputers      = $totalCmp
    LegacyLapsCovered     = $legacyLaps
    WindowsLapsCovered    = $windowsLaps
    TotalLapsCovered      = $totalCovered
    PctLapsCovered        = $pct
    SchemaHasLegacyAttr   = [bool](Get-ADObject -Filter "lDAPDisplayName -eq 'ms-Mcs-AdmPwd'" -SearchBase ((Get-ADRootDSE).schemaNamingContext) -ErrorAction SilentlyContinue)
    SchemaHasWindowsAttr  = [bool](Get-ADObject -Filter "lDAPDisplayName -eq 'msLAPS-Password'" -SearchBase ((Get-ADRootDSE).schemaNamingContext) -ErrorAction SilentlyContinue)
}

$TableFormat = @{
    PctLapsCovered = { param($v,$row) if ([double]"$v" -lt 50) { 'bad' } elseif ([double]"$v" -lt 90) { 'warn' } else { 'ok' } }
}
