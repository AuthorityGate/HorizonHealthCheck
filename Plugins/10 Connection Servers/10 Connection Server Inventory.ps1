# Start of Settings
# End of Settings

$Title          = "Connection Server Inventory"
$Header         = "Found [count] Connection Server(s)"
$Comments       = "All Connection Servers known to this pod, with version and last-startup time."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = "10 Connection Servers"
$Severity       = "Info"

$cs = Get-HVConnectionServer
if (-not $cs) { return }

foreach ($c in $cs) {
    [pscustomobject]@{
        Name           = $c.name
        Version        = $c.version
        Build          = $c.build
        Status         = $c.status
        StartTime      = if ($c.start_time)   { (Get-Date '1970-01-01').AddMilliseconds($c.start_time).ToLocalTime() } else { $null }
        LastUpdated    = if ($c.last_updated_timestamp) { (Get-Date '1970-01-01').AddMilliseconds($c.last_updated_timestamp).ToLocalTime() } else { $null }
        Replication    = $c.replication
    }
}
