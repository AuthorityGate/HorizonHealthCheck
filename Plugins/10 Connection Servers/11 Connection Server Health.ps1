# Start of Settings
# End of Settings

$Title          = "Connection Servers - Unhealthy"
$Header         = "[count] Connection Server(s) report a non-OK status"
$Comments       = "Any CS whose REST monitor status is not 'OK' or whose replication is degraded is listed."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = "10 Connection Servers"
$Severity       = "P1"
$Recommendation = "Open Horizon Console -> Server Health, identify the failed service, restart 'VMware Horizon Connection Server' if safe, and verify event-DB / vCenter connectivity."

$cs = Get-HVConnectionServer
if (-not $cs) { return }

$bad = foreach ($c in $cs) {
    $statusOk = ($c.status -eq 'OK')
    $repOk    = (-not $c.replication) -or ($c.replication -eq 'OK') -or ($c.replication.status -eq 'OK')
    if (-not ($statusOk -and $repOk)) {
        [pscustomobject]@{
            Name        = $c.name
            Status      = $c.status
            Replication = if ($c.replication.status) { $c.replication.status } else { $c.replication }
            Version     = $c.version
            Build       = $c.build
        }
    }
}
$bad

$TableFormat = @{
    Status      = { param($v,$row) if ($v -ne 'OK') { 'bad' } else { '' } }
    Replication = { param($v,$row) if ($v -and $v -ne 'OK') { 'bad' } else { '' } }
}
