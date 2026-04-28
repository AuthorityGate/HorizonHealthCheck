# Start of Settings
# End of Settings

$Title          = 'vSAN Slack Space Headroom'
$Header         = 'vSAN cluster slack-space % (target: 25-30% free)'
$Comments       = "Reference: 'vSAN Capacity Management'. Below 25% slack, vSAN can't rebalance after host failure."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = '98 vSAN'
$Severity       = 'P1'
$Recommendation = 'Add capacity (drives or hosts) before slack falls below 25%.'

if (-not $Global:VCConnected) { return }
Get-Cluster -ErrorAction SilentlyContinue | Where-Object { $_.VsanEnabled } | ForEach-Object {
    $u = $_ | Get-VsanSpaceUsage -ErrorAction SilentlyContinue
    if (-not $u) { return }
    $pct = if ($u.TotalCapacityGB -gt 0) { [math]::Round(($u.FreeSpaceGB / $u.TotalCapacityGB) * 100, 1) } else { 0 }
    [pscustomobject]@{ Cluster=$_.Name; FreePct=$pct; FreeGB=[math]::Round($u.FreeSpaceGB,1); TotalGB=[math]::Round($u.TotalCapacityGB,1) }
}
