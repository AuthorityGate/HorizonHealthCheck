# Start of Settings
# End of Settings

$Title          = 'Host DNS Server List Consistency'
$Header         = '[count] cluster(s) with mismatched DNS server lists'
$Comments       = 'Hosts with stale DNS pointing at decommissioned servers cause slow vSphere Client login + cert validation.'
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = '96 vSphere Standalone'
$Severity       = 'P3'
$Recommendation = 'Standardize DNS via host profile.'

if (-not $Global:VCConnected) { return }
Get-Cluster -ErrorAction SilentlyContinue | ForEach-Object {
    $cl = $_
    $sets = @{}
    foreach ($h in (Get-VMHost -Location $cl -ErrorAction SilentlyContinue)) {
        $cfg = $h.ExtensionData.Config.Network.DnsConfig
        if (-not $cfg) { continue }
        $key = ($cfg.Address -join ',')
        $sets[$key] = $true
    }
    if (@($sets.Keys).Count -gt 1) {
        [pscustomobject]@{ Cluster=$cl.Name; DistinctDnsSets=@($sets.Keys).Count }
    }
}
