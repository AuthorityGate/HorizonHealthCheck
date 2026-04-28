# Start of Settings
# End of Settings

$Title          = "ESXi Build and Patch Currency"
$Header         = "[count] ESXi host(s) profiled (build + last patch info)"
$Comments       = "Per-host ESXi version, build, and last-patched timestamp from VMware. Drift across the cluster (mixed builds) is a vMotion risk; very-old builds are CVE-exposed (e.g., ESXi 6.7 EOL Oct 2022, ESXi 7.0 GA EOL Apr 2025)."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = "96 vSphere Standalone"
$Severity       = "P2"
$Recommendation = "Plan upgrade to ESXi 8.0 U2+ (or 7.0 U3+ if hardware compatibility limits 8.0). Same build across all hosts in cluster is required for full vMotion compat. Apply security patches within 30 days of release."

if (-not $Global:VCConnected) { return }

$hosts = @(Get-VMHost -ErrorAction SilentlyContinue)
foreach ($h in $hosts) {
    if (-not $h) { continue }
    $bn = $null; $patched = $null; $hwModel = ''
    try {
        $vmh = Get-View $h.Id -Property 'Config.Product','Hardware.SystemInfo','Summary.QuickStats','Runtime.BootTime' -ErrorAction Stop
        $bn  = $vmh.Config.Product.Build
        $hwModel = "$($vmh.Hardware.SystemInfo.Vendor) $($vmh.Hardware.SystemInfo.Model)"
        $patched = if ($vmh.Runtime.BootTime) { [datetime]$vmh.Runtime.BootTime } else { $null }
    } catch { }
    [pscustomobject]@{
        Host     = $h.Name
        Cluster  = if ($h.Parent) { $h.Parent.Name } else { '' }
        Version  = $h.Version
        Build    = $bn
        ApiVersion = $h.ApiVersion
        Hardware = $hwModel
        BootTime = if ($patched) { $patched.ToString('yyyy-MM-dd HH:mm') } else { '' }
        UptimeDays = if ($patched) { [int]((Get-Date) - $patched).TotalDays } else { '' }
    }
}

$TableFormat = @{
    Version    = { param($v,$row) if ([string]$v -match '^[345]\.') { 'bad' } elseif ([string]$v -match '^6\.') { 'warn' } else { '' } }
    UptimeDays = { param($v,$row) if ([int]"$v" -gt 365) { 'warn' } else { '' } }
}
