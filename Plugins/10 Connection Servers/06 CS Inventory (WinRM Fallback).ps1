# Start of Settings
# End of Settings

$Title          = 'Connection Server Inventory (WinRM Fallback)'
$Header         = 'Per-CS Windows-side inventory pulled directly from each host'
$Comments       = @"
Direct WinRM probe of every CS FQDN the operator supplied in the Horizon tab (and any in the optional 'Peer CS FQDNs' field on the Specialized Scope dialog). Bypasses the Horizon REST API entirely so you still get product version + build + services + cert expiry on Horizon 8.6 builds where /v1/monitor/connection-servers and /v1/config/connection-servers return only stub data (id + jwt_info).

Reads from each CS:
- HKLM:\\SOFTWARE\\VMware, Inc.\\VMware VDM\\plugins   (Connection Server install + version)
- 'VMware Horizon Connection Server' service state
- VMware Tomcat / Java cert expiry on the broker port
- OS caption + build + UBR for patch currency cross-reference

Requires: Windows credential supplied via 'Set Deep-Scan Creds...' on the main form. Without it, this plugin emits Tier 1 only (just the FQDN list). With it AND WinRM 5985 reachable, returns full per-host detail.
"@
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = '10 Connection Servers'
$Severity       = 'Info'
$Recommendation = "If 'Tier 2 unavailable - WinRM error' appears: the runner cannot reach 5985/TCP on the CS, OR the supplied credential cannot auth (non-domain-joined runners need TrustedHosts pre-set + -Authentication Negotiate)."

# Source list of CS FQDNs - in priority order:
# 1. The 'Peer CS FQDNs' textbox on the Specialized Scope dialog (operator-supplied)
# 2. The HVServer FQDN(s) typed on the Horizon tab (comma/semicolon separated)
$fqdns = New-Object System.Collections.Generic.HashSet[string]
if ($Global:HVPeerConnectionServers) {
    foreach ($f in @($Global:HVPeerConnectionServers)) {
        $t = ([string]$f).Trim()
        if ($t) { [void]$fqdns.Add($t.ToLower()) }
    }
}
if ($Global:HVServer) {
    foreach ($f in @($Global:HVServer -split '[,;\s]+')) {
        $t = ([string]$f).Trim()
        if ($t) { [void]$fqdns.Add($t.ToLower()) }
    }
}
# As a final fallback, derive from the active session
if ($fqdns.Count -eq 0 -and (Get-HVRestSession)) {
    $sess = Get-HVRestSession
    if ($sess.Server) { [void]$fqdns.Add(([string]$sess.Server).ToLower()) }
}

if ($fqdns.Count -eq 0) {
    [pscustomobject]@{
        Server = '(no FQDNs)'
        Tier   = ''
        Note   = 'No CS FQDN list available. Type Connection Server FQDNs (comma-separated) on the Horizon tab, or list peers in the Specialized Scope dialog.'
    }
    return
}

# Ensure InfraServerScan is loaded
if (-not (Get-Command -Name 'Get-InfraServerScan' -ErrorAction SilentlyContinue)) {
    if ($Global:HVRoot) {
        $modPath = Join-Path $Global:HVRoot 'Modules\InfraServerScan.psm1'
        if (Test-Path $modPath) { Import-Module $modPath -Force -ErrorAction SilentlyContinue }
    }
}
if (-not (Get-Command -Name 'Get-InfraServerScan' -ErrorAction SilentlyContinue)) {
    [pscustomobject]@{ Server='(plugin error)'; Tier=''; Note='InfraServerScan module not loaded.' }
    return
}

$cred = if (Test-Path Variable:Global:HVImageScanCredential) { $Global:HVImageScanCredential } else { $null }

foreach ($srv in $fqdns) {
    $vm = $null
    if ($Global:VCConnected) {
        $shortName = ($srv -split '\.')[0]
        try {
            $vm = Get-VM -ErrorAction SilentlyContinue | Where-Object { $_.Name -ieq $shortName -or $_.Name -ieq $srv } | Select-Object -First 1
        } catch { }
    }
    $scan = Get-InfraServerScan -ServerFqdn $srv -Role 'ConnectionServer' -Credential $cred -Vm $vm

    $g = $scan.Guest
    $vh = $scan.VmHardware
    [pscustomobject]@{
        Server         = $srv
        Tier           = $scan.Tier
        VmName         = if ($vh -and $vh.VmName) { $vh.VmName } else { '' }
        OS             = if ($g -and $g.OsCaption) { $g.OsCaption } elseif ($vh.GuestOS) { $vh.GuestOS } else { '' }
        OsBuild        = if ($g -and $g.OsBuildNumber) { "$($g.OsBuildNumber).$($g.UBR)" } else { '' }
        CSVersion      = if ($g -and $g.HorizonCSVersion) { $g.HorizonCSVersion } else { '' }
        BrokerSvc      = if ($g -and $g.HorizonCSServiceState) { $g.HorizonCSServiceState } else { '' }
        CertDaysLeft   = if ($g -and $null -ne $g.CSCertDaysToExpiry) { [int]$g.CSCertDaysToExpiry } else { '' }
        IPAddress      = if ($vh.IPAddress) { $vh.IPAddress } else { '' }
        Note           = if ($scan.Tier -eq 'Tier1') {
                            if ($g -and $g.WinRmError) { "Tier 2 unavailable: $($g.WinRmError)" } else { 'Tier 2 unavailable - set Deep-Scan Creds on the main form and verify WinRM 5985 reachable.' }
                         } elseif ($scan.Tier -eq 'Tier2' -and -not $g.HorizonCSVersion) { 'Tier 2 connected but Horizon CS registry key not found - is this actually a Connection Server?' }
                         else { '' }
    }
}

$TableFormat = @{
    Tier = { param($v,$row) if ($v -eq 'Tier2') { 'ok' } elseif ($v -eq 'Tier1') { 'warn' } else { 'bad' } }
    BrokerSvc = { param($v,$row) if ($v -eq 'Running') { 'ok' } elseif ($v) { 'bad' } else { '' } }
    CertDaysLeft = { param($v,$row)
        if ([string]$v -eq '') { '' }
        elseif ([int]$v -lt 30) { 'bad' }
        elseif ([int]$v -lt 90) { 'warn' }
        else { 'ok' }
    }
}
