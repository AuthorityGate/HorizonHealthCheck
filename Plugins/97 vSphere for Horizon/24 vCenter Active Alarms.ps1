# Start of Settings
$MaxRendered = 200
# End of Settings

$Title          = "vCenter Active Alarms"
$Header         = "[count] active vCenter alarm(s)"
$Comments       = "Alarms currently in 'red' or 'yellow' state across all connected vCenters. Alarms on Horizon-managed hosts / pools are direct indicators that something needs attention NOW (datastore full, host network down, license expiring, vSAN component absent)."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = "97 vSphere for Horizon"
$Severity       = "P1"
$Recommendation = "All red alarms need immediate investigation. Yellow alarms should be ack'd or resolved within the change window. If alarms list shows a pattern (same warning across 10 hosts), look for an ESXi-level baseline issue."

if (-not $Global:VCConnected) { return }

$rendered = 0
$servers = @($global:DefaultVIServers | Where-Object { $_ -and $_.IsConnected })
foreach ($srv in $servers) {
    try {
        # Walk the vCenter root and recursively check TriggeredAlarmState
        $rootFolder = Get-View -Server $srv -Id (Get-View ServiceInstance -Server $srv).Content.RootFolder
        $rootFolder.UpdateViewData('TriggeredAlarmState')
        foreach ($alarm in @($rootFolder.TriggeredAlarmState)) {
            if (-not $alarm) { continue }
            if ($alarm.OverallStatus -eq 'green') { continue }
            $alarmDef = Get-View -Server $srv -Id $alarm.Alarm -ErrorAction SilentlyContinue
            $entityView = Get-View -Server $srv -Id $alarm.Entity -ErrorAction SilentlyContinue
            [pscustomobject]@{
                vCenter   = $srv.Name
                Severity  = [string]$alarm.OverallStatus
                AlarmName = if ($alarmDef) { $alarmDef.Info.Name } else { '(unknown)' }
                Entity    = if ($entityView) { $entityView.Name } else { '(unknown)' }
                EntityType = if ($entityView) { $entityView.GetType().Name } else { '' }
                Time      = if ($alarm.Time) { ([datetime]$alarm.Time).ToString('yyyy-MM-dd HH:mm') } else { '' }
                Acknowledged = [bool]$alarm.Acknowledged
            }
            $rendered++
            if ($rendered -ge $MaxRendered) { break }
        }
    } catch { }
    if ($rendered -ge $MaxRendered) { break }
}
if ($rendered -eq 0) {
    [pscustomobject]@{ Note = 'No active alarms above green.' }
}

$TableFormat = @{
    Severity = { param($v,$row) if ($v -eq 'red') { 'bad' } elseif ($v -eq 'yellow') { 'warn' } else { '' } }
    Acknowledged = { param($v,$row) if ($v -eq $true) { 'ok' } elseif ($v -eq $false) { 'warn' } else { '' } }
}
