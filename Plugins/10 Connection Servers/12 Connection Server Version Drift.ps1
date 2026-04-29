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

$cs = @(Get-HVConnectionServer)
if (-not $cs -or $cs.Count -lt 2) { return }

# Resilient field lookup - 2206+ shapes sometimes return name under
# host_name / display_name / dns_name and version under product_version.
function Get-CSField { param($Obj,[string[]]$Names)
    if ($null -eq $Obj) { return $null }
    if ($Obj -is [string]) { if ($Names -contains 'name') { return $Obj }; return $null }
    if (-not $Obj.PSObject) { return $null }
    foreach ($n in $Names) {
        if (-not $Obj.PSObject.Properties[$n]) { continue }
        $v = $Obj.PSObject.Properties[$n].Value
        if ($null -ne $v -and "$v" -ne '') { return $v }
    }
    return $null
}

# Build per-CS rows once with normalized name/version/build, then group.
$rows = foreach ($c in $cs) {
    if ($null -eq $c) { continue }
    [pscustomobject]@{
        Name    = "$(Get-CSField $c @('name','dns_name','host_name','hostname','server_name','cs_name','fqdn','id'))"
        Version = "$(Get-CSField $c @('version','cs_version','product_version','build_version'))"
        Build   = "$(Get-CSField $c @('build','build_number','build_id','product_build_number'))"
    }
}
$builds = @($rows | Group-Object { "$($_.Version) ($($_.Build))" })
if ($builds.Count -le 1) { return }

foreach ($g in $builds) {
    foreach ($c in $g.Group) {
        [pscustomobject]@{
            Name    = if ($c.Name) { $c.Name } else { '(unknown)' }
            Version = $c.Version
            Build   = $c.Build
            Cohort  = "{0} server(s) on this build" -f $g.Count
        }
    }
}
