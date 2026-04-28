# Start of Settings
# End of Settings

$Title          = 'ESXi Lockdown Exception List Audit'
$Header         = "[count] host(s) with lockdown exception list entries"
$Comments       = "Lockdown Mode (Strict / Normal) restricts host management to vCenter. The exception list explicitly allows specific accounts to bypass lockdown. Over-broad exception list defeats the security control."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = '95 vSphere Backing Infra'
$Severity       = 'P2'
$Recommendation = "Exception list should be empty (Strict mode) OR contain only documented break-glass accounts. Each exception requires written justification + audit trail."

if (-not $Global:VCConnected) { return }

foreach ($h in (Get-VMHost -ErrorAction SilentlyContinue)) {
    if ($h.ConnectionState -ne 'Connected') { continue }
    try {
        $exc = Get-View -Id $h.ExtensionData.ConfigManager.HostAccessManager -ErrorAction Stop
        $list = $exc.QueryLockdownExceptions()
        if ($list -and @($list).Count -gt 0) {
            foreach ($u in @($list)) {
                [pscustomobject]@{
                    Host = $h.Name
                    Cluster = if ($h.Parent) { $h.Parent.Name } else { '' }
                    LockdownMode = $h.ExtensionData.Config.LockdownMode
                    ExceptionUser = $u
                    Note = 'Document the business justification.'
                }
            }
        }
    } catch { }
}

$TableFormat = @{
    LockdownMode = { param($v,$row) if ($v -eq 'lockdownDisabled') { 'bad' } elseif ($v -eq 'lockdownNormal') { 'warn' } else { '' } }
}
