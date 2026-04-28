# Start of Settings
# End of Settings

$Title          = 'Cluster EVC Mode'
$Header         = '[count] cluster(s) without EVC enabled'
$Comments       = 'Enhanced vMotion Compatibility (EVC) baselines CPU feature exposure across hosts in a cluster. Without EVC, mixing CPU generations breaks vMotion and migration. Even on a homogenous cluster, setting EVC future-proofs hardware refresh.'
$Display        = 'Table'
$Author         = 'AuthorityGate'
$PluginVersion  = 1.0
$PluginCategory = '95 vSphere Backing Infra'
$Severity       = 'P2'
$Recommendation = 'Cluster -> Configure -> VMware EVC -> Enable. Choose the lowest-generation CPU baseline that all current and likely future hosts can match.'

if (-not $Global:VCConnected) { return }

foreach ($c in (Get-Cluster -ErrorAction SilentlyContinue | Sort-Object Name)) {
    $evc = $c.EVCMode
    if (-not $evc) {
        [pscustomobject]@{
            Cluster   = $c.Name
            EVCMode   = '(disabled)'
            HostCount = ($c | Get-VMHost).Count
            Issue     = 'EVC not enabled - vMotion fails when CPU generations diverge.'
        }
    }
}

$TableFormat = @{
    EVCMode = { param($v,$row) if ($v -eq '(disabled)') { 'warn' } else { '' } }
}
