# Start of Settings
# Threshold scale 1 (apply only top priority recommendations) -> 5 (apply all).
# 3 is vSphere default and balances stability vs load-balance aggressiveness.
$RecommendedThreshold = 3
# End of Settings

$Title          = 'DRS Migration Threshold'
$Header         = '[count] cluster(s) with non-default DRS migration threshold'
$Comments       = 'DRS migration threshold drives how aggressively DRS rebalances. 1 = ignore everything but priority-1; 5 = apply every recommendation. 3 is vSphere default and recommended for most production clusters.'
$Display        = 'Table'
$Author         = 'AuthorityGate'
$PluginVersion  = 1.0
$PluginCategory = '95 vSphere Backing Infra'
$Severity       = 'P3'
$Recommendation = 'Cluster -> Configure -> vSphere DRS -> Edit -> Migration Threshold = level 3 unless workload tells you otherwise.'

if (-not $Global:VCConnected) { return }

foreach ($c in (Get-Cluster -ErrorAction SilentlyContinue | Where-Object { $_.DrsEnabled } | Sort-Object Name)) {
    $thr = $c.DrsMigrationThreshold
    if ($thr -ne $RecommendedThreshold) {
        [pscustomobject]@{
            Cluster            = $c.Name
            MigrationThreshold = $thr
            Recommended        = $RecommendedThreshold
            Note               = if ($thr -lt $RecommendedThreshold) { 'Conservative - DRS will migrate less' } else { 'Aggressive - DRS will migrate more' }
        }
    }
}
