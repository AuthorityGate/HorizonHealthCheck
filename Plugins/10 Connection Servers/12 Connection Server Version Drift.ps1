# Start of Settings
# End of Settings

$Title          = "Connection Server Version Drift"
$Header         = "Connection Servers running mixed builds"
$Comments       = "All replica Connection Servers in a pod must run the same version+build. Mixed builds are unsupported."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = "10 Connection Servers"
$Severity       = "P2"
$Recommendation = "Upgrade lagging replicas to the same version+build as the rest of the pod within 24 hours."

$cs = Get-HVConnectionServer
if (-not $cs -or @($cs).Count -lt 2) { return }

$builds = $cs | Group-Object { "$($_.version) ($($_.build))" }
if ($builds.Count -le 1) { return }

foreach ($g in $builds) {
    foreach ($c in $g.Group) {
        [pscustomobject]@{
            Name    = $c.name
            Version = $c.version
            Build   = $c.build
            Cohort  = "{0} servers on this build" -f $g.Count
        }
    }
}
